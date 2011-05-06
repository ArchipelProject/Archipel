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
TNPreferencesControllerLocaleChangeNotification           = @"TNPreferencesControllerLocaleChangeNotification";

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
    @outlet CPPopUpButton   buttonDebugLevel;
    @outlet CPPopUpButton   buttonLanguage;
    @outlet CPTabView       tabViewMain;
    @outlet CPTextField     fieldBOSHResource;
    @outlet CPTextField     fieldModuleLoadingDelay;
    @outlet CPTextField     fieldWelcomePageUrl;
    @outlet CPView          viewPreferencesGeneral;
    @outlet CPWindow        mainWindow @accessors(readonly);
    @outlet TNSwitch        switchUseAnimations;
    @outlet TNSwitch        switchUseXMPPMonitoring;

    id                      _appController  @accessors(property=appController);

    CPArray                 _modules;
    TNStrophePrivateStorage _xmppStorage;
}


#pragma mark -
#pragma mark Initialization

/*! Initialization at CIB awaking
*/
- (void)awakeFromCib
{
    var tabViewItemPreferencesGeneral = [[CPTabViewItem alloc] initWithIdentifier:@"id1"],
        scrollViewContainer = [[TNUIKitScrollView alloc] initWithFrame:[tabViewMain bounds]],
        moduleViewFrame = [viewPreferencesGeneral frame];

    moduleViewFrame.size.width = [scrollViewContainer contentSize].width;
    [viewPreferencesGeneral setFrame:moduleViewFrame];
    [viewPreferencesGeneral setAutoresizingMask:CPViewWidthSizable];

    [scrollViewContainer setAutohidesScrollers:YES];
    [scrollViewContainer setDocumentView:viewPreferencesGeneral];

    [tabViewItemPreferencesGeneral setLabel:@"General"];
    [tabViewItemPreferencesGeneral setView:scrollViewContainer];
    [tabViewMain addTabViewItem:tabViewItemPreferencesGeneral];

    [buttonDebugLevel removeAllItems];
    [buttonDebugLevel addItemsWithTitles:[@"trace", @"debug", @"info", @"warn", @"error", @"critical"]];

    [buttonLanguage removeAllItems];
    [buttonLanguage addItemsWithTitles:[@"en", @"fr"]];

    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_didModulesLoadComplete:) name:TNArchipelModulesLoadingCompleteNotification object:nil];
    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_didPreferencesSaveToXMPPServer:) name:TNStrophePrivateStorageSetNotification object:nil];
    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_didPreferencesFailToXMPPServer:) name:TNStrophePrivateStorageSetErrorNotification object:nil];
    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(saveToFromXMPPServer:) name:TNPreferencesControllerSavePreferencesRequestNotification object:nil];
    [mainWindow setDefaultButton:buttonSave];

    [fieldBOSHResource setToolTip:CPLocalizedString(@"The resource to use", @"The resource to use")];
    [fieldModuleLoadingDelay setToolTip:CPLocalizedString(@"Delay before loading a module. This avoid to load server with stanzas", @"Delay before loading a module. This avoid to load server with stanzas")];
    [fieldWelcomePageUrl setToolTip:CPLocalizedString(@"The URL of the welcome page", @"The URL of the welcome page")];
    [switchUseAnimations setToolTip:CPLocalizedString(@"Turn this ON to activate eye candy animation. Turn it off to gain performances", @"Turn this ON to activate eye candy animation. Turn it off to gain performances")];
    [switchUseXMPPMonitoring setToolTip:CPLocalizedString(@"Turn this ON to activate XMPP monitoring. Turn it off to gain performances", @"Turn this ON to activate XMPP monitoring. Turn it off to gain performances")];
    [buttonDebugLevel setToolTip:CPLocalizedString(@"Set the log level of the client. The more verbose, the less performance.", @"Set the log level of the client. The more verbose, the less performance.")]
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
    [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Preferences saved" message:@"Your preferences have been saved to the XMPP server"];
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
    @param aSender
*/
- (IBAction)showWindow:(id)aSender
{
    var defaults = [CPUserDefaults standardUserDefaults];

    [fieldWelcomePageUrl setStringValue:[defaults objectForKey:@"TNArchipelHelpWindowURL"]];
    [fieldModuleLoadingDelay setFloatValue:[defaults floatForKey:@"TNArchipelModuleLoadingDelay"]];
    [fieldBOSHResource setStringValue:[defaults objectForKey:@"TNArchipelBOSHResource"]];
    [buttonDebugLevel selectItemWithTitle:[defaults objectForKey:@"TNArchipelConsoleDebugLevel"]];
    [buttonLanguage selectItemWithTitle:[defaults objectForKey:@"CPBundleLocale"]];
    [switchUseAnimations setOn:[defaults boolForKey:@"TNArchipelUseAnimations"] animated:YES sendAction:NO];
    [switchUseXMPPMonitoring setOn:[defaults boolForKey:@"TNArchipelMonitorStanza"] animated:YES sendAction:NO];
    [checkBoxUpdate setState:([defaults boolForKey:@"TNArchipelAutoCheckUpdate"]) ? CPOnState : CPOffState];

    for (var i = 0; i < [_modules count]; i++)
    {
        var module = [_modules objectAtIndex:i];

        if ([module viewPreferences] !== nil)
            [module loadPreferences];
    }

    [mainWindow center];
    [mainWindow makeKeyAndOrderFront:aSender];
}

/*! When save button is pressed, saves all general preferences
    and send message savePreferences to all modules
    @param aSender
*/
- (IBAction)savePreferences:(id)sender
{
    var defaults = [CPUserDefaults standardUserDefaults],
        oldLocale = [defaults objectForKey:@"CPBundleLocale"];

    [defaults setObject:[fieldWelcomePageUrl stringValue] forKey:@"TNArchipelHelpWindowURL"];
    [defaults setFloat:[fieldModuleLoadingDelay floatValue] forKey:@"TNArchipelModuleLoadingDelay"];
    [defaults setObject:[fieldBOSHResource stringValue] forKey:@"TNArchipelBOSHResource"];
    [defaults setObject:[buttonDebugLevel title] forKey:@"TNArchipelConsoleDebugLevel"];
    [defaults setObject:[buttonLanguage title] forKey:@"CPBundleLocale"];
    [defaults setBool:[switchUseAnimations isOn] forKey:@"TNArchipelUseAnimations"];
    [defaults setBool:([checkBoxUpdate state] == CPOnState) forKey:@"TNArchipelAutoCheckUpdate"];
    [defaults setBool:[switchUseXMPPMonitoring isOn] forKey:@"TNArchipelMonitorStanza"];

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
    [mainWindow close];

    if (oldLocale != [defaults objectForKey:@"CPBundleLocale"])
        [[CPNotificationCenter defaultCenter] postNotificationName:TNPreferencesControllerLocaleChangeNotification object:self];
}

/*! clean the content of the XMPP storage
    @param aSender
*/
- (IBAction)resetPreferences:(id)aSender
{
    var defaultsRegistration = [[CPUserDefaults standardUserDefaults]._domains objectForKey:CPRegistrationDomain];

    [[CPUserDefaults standardUserDefaults] registerDefaults:defaultsRegistration];
    [[CPUserDefaults standardUserDefaults]._domains setObject:[CPDictionary dictionary] forKey:CPApplicationDomain];
    [[CPUserDefaults standardUserDefaults] synchronize];
    [self cleanXMPPStorage];
    [mainWindow close];
}

/*! clean the content of the XMPP storage
    @param aSender
*/
- (IBAction)languageChanged:(id)aSender
{

}

#pragma mark -
#pragma mark Archiving

/*! send the content of CPUserDefaults in the private storage of the
    XMPP server
*/
- (void)saveToFromXMPPServer
{
    [_xmppStorage setObject:[[CPUserDefaults standardUserDefaults]._domains objectForKey:CPApplicationDomain] forKey:TNArchipelXMPPPrivateStoragePrefsKey];
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

    [[CPNotificationCenter defaultCenter] postNotificationName:TNPreferencesControllerRestoredNotification object:self];

    return NO;
}

@end