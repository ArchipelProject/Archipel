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
@import <AppKit/AppKit.j>


/*! @ingroup archipelcore

    This class is a representation of the preferences window of Archipel
    it contains the general Archipel application and will be able to load
    preferences view for each module with a viewPreferences containing a view
    This view will be inserted into a CPTabView labelized with the module label.
*/
@implementation TNPreferencesController : CPObject
{
    @outlet CPTabView       tabViewMain;
    @outlet CPView          viewPreferencesGeneral;
    @outlet CPTextField     fieldWelcomePageUrl;
    @outlet CPTextField     fieldModuleLoadingDelay;
    @outlet CPTextField     fieldBOSHResource;
    @outlet CPPopUpButton   buttonDebugLevel;
    @outlet TNSwitch        switchUseAnimations;
    @outlet CPWindow        mainWindow @accessors(readonly);

    CPArray                 _modules;
}


#pragma mark -
#pragma mark Initialization
/*! Initialization at CIB awaking
*/
- (void)awakeFromCib
{
    var tabViewItemPreferencesGeneral = [[CPTabViewItem alloc] initWithIdentifier:@"id1"];

    [tabViewItemPreferencesGeneral setLabel:@"General"];
    [tabViewItemPreferencesGeneral setView:viewPreferencesGeneral];
    [tabViewMain addTabViewItem:tabViewItemPreferencesGeneral];

    [buttonDebugLevel removeAllItems];
    [buttonDebugLevel addItemsWithTitles:[@"trace", @"debug", @"info", @"warning", @"error", @"critical"]];

    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(didModulesLoadComplete:) name:TNArchipelModulesLoadingCompleteNotification object:nil];
}


#pragma mark -
#pragma mark Notification handles

/*! triggered when all modules are loaded. it will create the tab view
    containing the preferences view (if any) as item for each module
*/
- (void)didModulesLoadComplete:(CPNotification)aNotification
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
            var tabViewModuleItem = [[CPTabViewItem alloc] initWithIdentifier:[module name]];

            [tabViewModuleItem setLabel:[module label]];
            [tabViewModuleItem setView:[module viewPreferences]];
            [tabViewMain addTabViewItem:tabViewModuleItem];
        }
    }
}


#pragma mark -
#pragma mark Actions

/*! When window is ordering front, refresh all general preferences
    and send message loadPreferences to all modules
*/
- (IBAction)showWindow:(id)sender
{
    var defaults = [CPUserDefaults standardUserDefaults];

    // hack...
    [buttonDebugLevel selectItemWithTitle:@"info"];

    [fieldWelcomePageUrl setStringValue:[defaults objectForKey:@"TNArchipelHelpWindowURL"]];
    [fieldModuleLoadingDelay setFloatValue:[defaults floatForKey:@"TNArchipelModuleLoadingDelay"]];
    [fieldBOSHResource setStringValue:[defaults objectForKey:@"TNArchipelBOSHResource"]];
    [buttonDebugLevel selectItemWithTitle:[defaults objectForKey:@"TNArchipelConsoleDebugLevel"]];
    [switchUseAnimations setOn:[defaults boolForKey:@"TNArchipelUseAnimations"] animated:YES sendAction:NO];

    for (var i = 0; i < [_modules count]; i++)
    {
        var module = [_modules objectAtIndex:i];

        if ([module viewPreferences] !== nil)
            [module loadPreferences];
    }

    [mainWindow center];
    [mainWindow makeKeyAndOrderFront:sender];
}

/*! When save button is pressed, saves all general preferences
    and send message savePreferences to all modules
*/
- (IBAction)savePreferences:(id)sender
{
    var defaults = [CPUserDefaults standardUserDefaults];

    [defaults setObject:[fieldWelcomePageUrl stringValue] forKey:@"TNArchipelHelpWindowURL"];
    [defaults setFloat:[fieldModuleLoadingDelay floatValue] forKey:@"TNArchipelModuleLoadingDelay"];
    [defaults setObject:[fieldBOSHResource stringValue] forKey:@"TNArchipelBOSHResource"];
    [defaults setObject:[buttonDebugLevel title] forKey:@"TNArchipelConsoleDebugLevel"];
    [defaults setBool:[switchUseAnimations isOn] forKey:@"TNArchipelUseAnimations"];

    CPLogUnregister(CPLogConsole);
    CPLogRegister(CPLogConsole, [buttonDebugLevel title]);

    for (var i = 0; i < [_modules count]; i++)
    {
        var module = [_modules objectAtIndex:i];

        if ([module viewPreferences] !== nil)
            [module savePreferences];
    }

    [mainWindow close];
}


@end