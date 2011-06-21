/*
 * TNWindowPreferences.j
 *
 * Copyright (C) 2010 Antoine Mercadal <antoine.mercadal@inframonde.eu>
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

@import <Foundation/Foundation.j>

@import <AppKit/CPButton.j>
@import <AppKit/CPCheckBox.j>
@import <AppKit/CPPopUpButton.j>
@import <AppKit/CPTabView.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPView.j>
@import <AppKit/CPWindow.j>

@import <GrowlCappuccino/TNGrowlCenter.j>

@import "../Views/TNSwitch.j"

TNPreferencesControllerSavePreferencesRequestNotification = @"TNPreferencesControllerSavePreferencesRequestNotification";

var TNArchipelXMPPPrivateStoragePrefsNamespace  = "archipel:preferences",
    TNArchipelXMPPPrivateStoragePrefsKey        = @"archipel";

TNPreferencesControllerRestoredNotification = @"TNPreferencesControllerRestoredNotification";

/*! @ingroup archipelcore

    This class is a representation of the preferences window of Archipel
    it contains the general Archipel application and will be able to load
    preferences view for each module with a viewPreferences containing a view
    This view will be inserted into a CPTabView labelized with the module label.
*/
@implementation TNPreferencesController : CPObject
{
    @outlet CPButton        buttonCancel;
    @outlet CPButton        buttonSave;
    @outlet CPCheckBox      checkBoxUpdate;
    @outlet CPCheckBox      checkBoxHideOfflineContacts;
    @outlet CPPopUpButton   buttonDebugLevel;
    @outlet CPPopUpButton   buttonLanguage;
    @outlet CPTabView       tabViewMain;
    @outlet CPTextField     fieldBOSHResource;
    @outlet CPTextField     fieldModuleLoadingDelay;
    @outlet CPView          viewContentWindowPreferences;
    @outlet CPView          viewPreferencesGeneral;
    @outlet TNSwitch        switchUseAnimations;
    @outlet TNSwitch        switchUseXMPPMonitoring;

    CPArray                 _excludedTokensNames;
    CPDictionary            _excludedTokens             @accessors(getter=excludedTokens);
    CPWindow                _mainWindow                 @accessors(getter=mainWindow);
    id                      _appController              @accessors(property=appController);

    CPArray                 _modules;
    TNStrophePrivateStorage _xmppStorage;
}


#pragma mark -
#pragma mark Initialization

/*! Initialization at CIB awaking
*/
- (void)awakeFromCib
{
    _mainWindow = [[CPWindow alloc] initWithContentRect:CPRectMake(0.0, 0.0, 631.0, 543.0) styleMask:CPDocModalWindowMask];
    [_mainWindow setContentView:viewContentWindowPreferences];

    var tabViewItemPreferencesGeneral = [[CPTabViewItem alloc] initWithIdentifier:@"id1"],
        scrollViewContainer = [[TNUIKitScrollView alloc] initWithFrame:[tabViewMain bounds]],
        moduleViewFrame = [viewPreferencesGeneral frame];

    moduleViewFrame.size.width = [scrollViewContainer contentSize].width;
    [viewPreferencesGeneral setFrame:moduleViewFrame];
    [viewPreferencesGeneral setAutoresizingMask:CPViewWidthSizable];

    [scrollViewContainer setAutohidesScrollers:YES];
    [scrollViewContainer setDocumentView:viewPreferencesGeneral];

    [tabViewMain setDelegate:self];
    [tabViewItemPreferencesGeneral setLabel:@"General"];
    [tabViewItemPreferencesGeneral setView:scrollViewContainer];
    [tabViewMain addTabViewItem:tabViewItemPreferencesGeneral];

    [buttonDebugLevel removeAllItems];
    [buttonDebugLevel addItemsWithTitles:[@"trace", @"debug", @"info", @"warn", @"error", @"critical"]];

    [buttonLanguage removeAllItems];
    [buttonLanguage addItemsWithTitles:[@"en", @"fr", @"de"]];

    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_didModulesLoadComplete:) name:TNArchipelModulesLoadingCompleteNotification object:nil];
    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_didPreferencesSaveToXMPPServer:) name:TNStrophePrivateStorageSetNotification object:nil];
    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_didPreferencesFailToXMPPServer:) name:TNStrophePrivateStorageSetErrorNotification object:nil];
    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(saveToFromXMPPServer:) name:TNPreferencesControllerSavePreferencesRequestNotification object:nil];
    [_mainWindow setDefaultButton:buttonSave];

    [fieldBOSHResource setToolTip:CPLocalizedString(@"The resource to use", @"The resource to use")];
    [fieldModuleLoadingDelay setToolTip:CPLocalizedString(@"Delay before loading a module. This avoid to load server with stanzas", @"Delay before loading a module. This avoid to load server with stanzas")];
    [switchUseAnimations setToolTip:CPLocalizedString(@"Turn this ON to activate eye candy animation. Turn it off to gain performances", @"Turn this ON to activate eye candy animation. Turn it off to gain performances")];
    [switchUseXMPPMonitoring setToolTip:CPLocalizedString(@"Turn this ON to activate XMPP monitoring. Turn it off to gain performances", @"Turn this ON to activate XMPP monitoring. Turn it off to gain performances")];
    [buttonDebugLevel setToolTip:CPLocalizedString(@"Set the log level of the client. The more verbose, the less performance.", @"Set the log level of the client. The more verbose, the less performance.")]

    _excludedTokens = [CPDictionary dictionary];
    _excludedTokensNames = [@"TNArchipelPropertyControllerEnabled", @"TNArchipelBOSHCredentialHistory", @"TNArchipelBOSHJID",
                            @"TNArchipelBOSHPassword", @"TNArchipelBOSHService", @"TNArchipelBOSHRememberCredentials",
                            @"TNArchipelTagsVisible", @"mainSplitViewPosition", @"TNArchipelModuleControllerOpenedTabRegistry"];
}

/*! initialize the XMPP storage
*/
- (void)initXMPPStorage
{
    var connection= [[TNStropheIMClient defaultClient] connection];
    _xmppStorage = [TNStrophePrivateStorage strophePrivateStorageWithConnection:connection namespace:TNArchipelXMPPPrivateStoragePrefsNamespace];
}


#pragma mark -
#pragma mark Notification handles

/*! triggered when all modules are loaded. it will create the tab view
    containing the preferences view (if any) as item for each module
    @param aNotification the notification
*/
- (void)_didModulesLoadComplete:(CPNotification)aNotification
{
    _moduleLoader = [aNotification object];

    var tabModules          = [_moduleLoader loadedTabModules],
        toolbarModules      = [[_moduleLoader loadedToolbarModules] allValues],
        notSortedModules    = [tabModules arrayByAddingObjectsFromArray:toolbarModules],
        sortDescriptor      = [CPSortDescriptor sortDescriptorWithKey:@"label" ascending:YES];

    _modules = [notSortedModules sortedArrayUsingDescriptors:[CPArray arrayWithObject:sortDescriptor]];

    for (var i = 0; i < [_modules count]; i++)
    {
        var module = [_modules objectAtIndex:i];

        if ([module viewPreferences] !== nil)
        {
            var tabViewModuleItem = [[CPTabViewItem alloc] initWithIdentifier:[module name]],
                scrollViewContainer = [[TNUIKitScrollView alloc] initWithFrame:[tabViewMain bounds]],
                moduleViewFrame = [[module viewPreferences] frame];

            moduleViewFrame.size.width = [scrollViewContainer contentSize].width;
            [[module viewPreferences] setFrame:moduleViewFrame];
            [[module viewPreferences] setAutoresizingMask:CPViewWidthSizable];

            [scrollViewContainer setAutohidesScrollers:YES];
            [scrollViewContainer setDocumentView:[module viewPreferences]];

            [tabViewModuleItem setLabel:[module label]];
            [tabViewModuleItem setView:scrollViewContainer];
            [tabViewMain addTabViewItem:tabViewModuleItem];
        }
    }
}

/*! trigger when storage is sucessfulll
    @param aNotification the notification
*/
- (void)_didPreferencesSaveToXMPPServer:(CPNotification)aNotification
{
    [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:CPLocalizedString(@"Preferences saved", @"Preferences saved")
                                                     message:CPLocalizedString(@"Your preferences have been saved to the XMPP server", @"Your preferences have been saved to the XMPP server")];

    [self reinjectUnwantedTokens];
}

/*! trigger when storage is sucessfulll
    @param aNotification the notification
*/
- (void)_didPreferencesFailToXMPPServer:(CPNotification)aNotification
{
    [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:CPLocalizedString(@"Preferences saved", @"Preferences saved")
                                                     message:CPLocalizedString(@"Cannot save your preferences to the XMPP server", @"Cannot save your preferences to the XMPP server")
                                                         icon:TNGrowlIconError];
    CPLog.error("Cannot save your preferences to the XMPP server:" + [[aNotification userInfo] stringValue]);

    [self reinjectUnwantedTokens];
}

/*! proxy for saveToFromXMPPServer
    @param aNotification the notification
*/
- (void)saveToFromXMPPServer:(CPNotification)aNotification
{
    [self saveToFromXMPPServer];
}


#pragma mark -
#pragma mark Actions

/*! When window is ordering front, refresh all general preferences
    and send message loadPreferences to all modules
    @param aSender the sender of the action
*/
- (IBAction)showWindow:(id)aSender
{
    if ([_mainWindow isVisible])
    {
        [self hideWindow:aSender];
        return;
    }

    var defaults = [CPUserDefaults standardUserDefaults];

    [fieldModuleLoadingDelay setFloatValue:[defaults floatForKey:@"TNArchipelModuleLoadingDelay"]];
    [fieldBOSHResource setStringValue:[defaults objectForKey:@"TNArchipelBOSHResource"]];
    [buttonDebugLevel selectItemWithTitle:[defaults objectForKey:@"TNArchipelConsoleDebugLevel"]];
    [buttonLanguage selectItemWithTitle:[defaults objectForKey:@"CPBundleLocale"]];
    [switchUseAnimations setOn:[defaults boolForKey:@"TNArchipelUseAnimations"] animated:YES sendAction:NO];
    [switchUseXMPPMonitoring setOn:[defaults boolForKey:@"TNArchipelMonitorStanza"] animated:YES sendAction:NO];
    [checkBoxUpdate setState:([defaults boolForKey:@"TNArchipelAutoCheckUpdate"]) ? CPOnState : CPOffState];
    [checkBoxHideOfflineContacts setState:([defaults boolForKey:@"TNHideOfflineContacts"]) ? CPOnState : CPOffState];

    for (var i = 0; i < [_modules count]; i++)
    {
        var module = [_modules objectAtIndex:i];

        if ([module viewPreferences] !== nil)
            [module loadPreferences];
    }

    [CPApp beginSheet:_mainWindow modalForWindow:[CPApp mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

/*! hide the preference window
    @param aSender the sender of the action
*/
- (IBAction)hideWindow:(id)aSender
{
    [CPApp endSheet:_mainWindow];
}

/*! When save button is pressed, saves all general preferences
    and send message savePreferences to all modules
    @param aSender the sender of the action
*/
- (IBAction)savePreferences:(id)sender
{
    [self hideWindow:nil];

    var defaults = [CPUserDefaults standardUserDefaults],
        oldLocale = [defaults objectForKey:@"CPBundleLocale"];

    [defaults setFloat:[fieldModuleLoadingDelay floatValue] forKey:@"TNArchipelModuleLoadingDelay"];
    [defaults setObject:[fieldBOSHResource stringValue] forKey:@"TNArchipelBOSHResource"];
    [defaults setObject:[buttonDebugLevel title] forKey:@"TNArchipelConsoleDebugLevel"];
    [defaults setObject:[buttonLanguage title] forKey:@"CPBundleLocale"];
    [defaults setBool:[switchUseAnimations isOn] forKey:@"TNArchipelUseAnimations"];
    [defaults setBool:([checkBoxUpdate state] == CPOnState) forKey:@"TNArchipelAutoCheckUpdate"];
    [defaults setBool:([checkBoxHideOfflineContacts state] == CPOnState) forKey:@"TNHideOfflineContacts"];
    [defaults setBool:[switchUseXMPPMonitoring isOn] forKey:@"TNArchipelMonitorStanza"];

    // reload the roster in order to take care of hiding offline contacts changes
    [[[TNStropheIMClient defaultClient] roster] setHideOfflineContacts:[defaults boolForKey:@"TNHideOfflineContacts"]];
    [[CPNotificationCenter defaultCenter] postNotificationName:TNArchipelRosterOutlineViewReload object:self];

    CPLogUnregister(CPLogConsole);
    CPLogRegister(CPLogConsole, [buttonDebugLevel title]);

    [_appController monitorXMPP:[switchUseXMPPMonitoring isOn]];

    for (var i = 0; i < [_modules count]; i++)
    {
        var module = [_modules objectAtIndex:i];

        if ([module viewPreferences] !== nil)
            [module savePreferences];
    }

    [self saveToFromXMPPServer];

    if (oldLocale != [defaults objectForKey:@"CPBundleLocale"])
    {
         var alert = [TNAlert alertWithMessage:CPLocalizedString(@"Locale change", @"Locale change")
                                informative:CPLocalizedString(@"You need to reload the application to complete the locale change.", @"You need to reload the application to complete the locale change.")
                                     target:self
                                    actions:[[CPBundleLocalizedString(@"OK", @"OK"), @selector(_performApplicationReload:)], [CPBundleLocalizedString(@"Later", @"Later"), nil]]];
        [alert runModal];
    }
}

/*! Reload the application
    @param aSender the sender of the action
*/
- (IBAction)_performApplicationReload:(id)aSender
{
    if (window)
        window.location.reload();
}

/*! clean the content of the XMPP storage
    @param aSender the sender of the action
*/
- (IBAction)resetPreferences:(id)aSender
{
    var defaultsRegistration = [[CPUserDefaults standardUserDefaults]._domains objectForKey:CPRegistrationDomain];

    [[CPUserDefaults standardUserDefaults] registerDefaults:defaultsRegistration];
    [[CPUserDefaults standardUserDefaults]._domains setObject:[CPDictionary dictionary] forKey:CPApplicationDomain];
    [[CPUserDefaults standardUserDefaults] synchronize];
    [self cleanXMPPStorage];
    [self hideWindow:nil];
}

/*! message sent when user change the locale
    @param aSender
*/
- (IBAction)languageChanged:(id)aSender
{

}

#pragma mark -
#pragma mark Archiving


/*! exclude tokens
*/
- (void)excludeUnwantedTokens
{
    var defaults = [CPUserDefaults standardUserDefaults];

    for (var i = 0; i < [_excludedTokensNames count]; i++)
    {
        var key = [_excludedTokensNames objectAtIndex:i],
            value = [defaults objectForKey:key];

        [_excludedTokens setObject:value forKey:key];
        [defaults removeObjectForKey:key];
    }
}

/*! reinject excluded tokens
*/
- (void)reinjectUnwantedTokens
{
    var defaults = [CPUserDefaults standardUserDefaults];

    for (var i = 0; i < [_excludedTokensNames count]; i++)
    {
        var key = [_excludedTokensNames objectAtIndex:i],
            value = [_excludedTokens objectForKey:key];

        [_excludedTokens removeObjectForKey:key];
        if (value)
        {
            switch (typeof(value))
            {
                case "number":
                    [defaults setInteger:value forKey:key];
                    break;
                case "boolean":
                    [defaults setBool:value forKey:key];
                    break;
                default:
                    [defaults setObject:value forKey:key];
            }
        }
    }
    [[CPUserDefaults standardUserDefaults] synchronize];
}


/*! send the content of CPUserDefaults in the private storage of the
    XMPP server
*/
- (void)saveToFromXMPPServer
{
    var defaults = [CPUserDefaults standardUserDefaults];

    [self excludeUnwantedTokens];

    [_xmppStorage setObject:[defaults._domains objectForKey:CPApplicationDomain] forKey:TNArchipelXMPPPrivateStoragePrefsKey];
}

- (void)cleanXMPPStorage
{
    [_xmppStorage setObject:nil forKey:TNArchipelXMPPPrivateStoragePrefsKey];
}

/*! get the content the private storage of the  XMPP server
    and set it back in CPUserDefaults
*/
- (void)recoverFromXMPPServer
{
    [self excludeUnwantedTokens];
    [_xmppStorage objectForKey:TNArchipelXMPPPrivateStoragePrefsKey target:self selector:@selector(_objectRetrievedWithStanza:object:)];
}

/*! called when recover result is received
    @params aStanza the stanza containing the result
*/
- (void)_objectRetrievedWithStanza:(TNStropheStanza)aStanza object:(id)anObject
{
    if (anObject)
    {
        [[CPUserDefaults standardUserDefaults]._domains setObject:anObject forKey:CPApplicationDomain];
        [CPUserDefaults standardUserDefaults]._searchListNeedsReload = YES;
        [[CPUserDefaults standardUserDefaults] synchronize];
    }
    else
    {
        CPLog.warn("Unable to get configuration from XMPP Storage.")
    }
    [self reinjectUnwantedTokens];
    [[CPNotificationCenter defaultCenter] postNotificationName:TNPreferencesControllerRestoredNotification object:self];

    return NO;
}


#pragma mark -
#pragma mark Delegates

/*! CPTabView delegate
*/
- (void)tabView:(CPTabView)aTabView didSelectTabViewItem:(CPTabViewItem)anItem
{
    var newFrame = [[[anItem view] documentView] frame];
    newFrame.origin = [_mainWindow frame].origin;
    newFrame.size.width = [_mainWindow frame].size.width;
    newFrame.size.height += 100;

    [_mainWindow setFrame:newFrame display:NO animate:YES];
}

@end