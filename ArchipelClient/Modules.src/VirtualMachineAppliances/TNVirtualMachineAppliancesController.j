/*
 * TNSampleTabModule.j
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
@import <AppKit/CPButtonBar.j>
@import <AppKit/CPScrollView.j>
@import <AppKit/CPSearchField.j>
@import <AppKit/CPTableView.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPView.j>
@import <AppKit/CPWindow.j>

@import <TNKit/TNAlert.j>
@import <TNKit/TNTableViewDataSource.j>

@import "TNInstalledAppliancesObject.j";



var TNArchipelTypeVirtualMachineVMCasting           = @"archipel:virtualmachine:vmcasting",
    TNArchipelTypeVirtualMachineVMCastingGet        = @"get",
    TNArchipelTypeVirtualMachineVMCastingAttach     = @"attach",
    TNArchipelTypeVirtualMachineVMCastingDetach     = @"detach",
    TNArchipelTypeVirtualMachineVMCastingPackage    = @"package",
    TNArchipelPushNotificationVMCasting             = @"archipel:push:vmcasting";

/*! @defgroup  virtualmachinepackaging Module VirtualMachine Appliances
    @desc Allow to attach virtual machine from installed appliances
*/

/*! @ingroup virtualmachinepackaging
    main class of the module
*/
@implementation TNVirtualMachineAppliancesController : TNModule
{
    @outlet CPButtonBar                 buttonBarControl;
    @outlet CPScrollView                mainScrollView;
    @outlet CPSearchField               fieldFilterAppliance;
    @outlet CPTextField                 fieldJID;
    @outlet CPTextField                 fieldName;
    @outlet CPTextField                 fieldNewApplianceName;
    @outlet CPView                      maskingView;
    @outlet CPView                      viewTableContainer;
    @outlet CPWindow                    windowNewAppliance;

    CPButton                            _detachButton;
    CPButton                            _attachButton;
    CPButton                            _packageButton;
    CPTableView                         _tableAppliances;
    TNTableViewDataSource               _appliancesDatasource;
}


#pragma mark -
#pragma mark Initialization

/*! called at cib awaking
*/
- (void)awakeFromCib
{
    [viewTableContainer setBorderedWithHexColor:@"#C0C7D2"];
    [fieldJID setSelectable:YES];

    // Media table view
    _appliancesDatasource    = [[TNTableViewDataSource alloc] init];
    _tableAppliances         = [[CPTableView alloc] initWithFrame:[mainScrollView bounds]];

    var bundle = [CPBundle bundleForClass:[self class]];

    [mainScrollView setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [mainScrollView setAutohidesScrollers:YES];
    [mainScrollView setDocumentView:_tableAppliances];

    [_tableAppliances setUsesAlternatingRowBackgroundColors:YES];
    [_tableAppliances setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [_tableAppliances setAllowsColumnReordering:YES];
    [_tableAppliances setAllowsColumnResizing:YES];
    [_tableAppliances setTarget:self];
    [_tableAppliances setDoubleAction:@selector(tableDoubleClicked:)];
    [_tableAppliances setAllowsEmptySelection:YES];
    [_tableAppliances setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];

    var columnName      = [[CPTableColumn alloc] initWithIdentifier:@"name"],
        columnComment   = [[CPTableColumn alloc] initWithIdentifier:@"comment"],
        columnStatus    = [[CPTableColumn alloc] initWithIdentifier:@"status"],
        imgView         = [[CPImageView alloc] initWithFrame:CGRectMake(0,0,16,16)];

    [columnName setWidth:200]
    [[columnName headerView] setStringValue:@"Name"];
    [columnName setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];

    [columnComment setWidth:250];
    [[columnComment headerView] setStringValue:@"Comment"];
    [columnComment setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"comment" ascending:YES]];

    [imgView setImageScaling:CPScaleNone];
    [columnStatus setDataView:imgView];
    [columnStatus setWidth:16];
    [[columnStatus headerView] setStringValue:@" "];

    [_tableAppliances addTableColumn:columnStatus];
    [_tableAppliances addTableColumn:columnName];
    [_tableAppliances addTableColumn:columnComment];

    [_appliancesDatasource setTable:_tableAppliances];
    [_appliancesDatasource setSearchableKeyPaths:[@"name", @"path", @"comment"]]

    [_tableAppliances setDataSource:_appliancesDatasource];

    [fieldFilterAppliance setTarget:_appliancesDatasource];
    [fieldFilterAppliance setAction:@selector(filterObjects:)];

    var menu = [[CPMenu alloc] init];
    [menu addItemWithTitle:@"Install" action:@selector(attach:) keyEquivalent:@""];
    [menu addItemWithTitle:@"Detach" action:@selector(detach:) keyEquivalent:@""];
    [_tableAppliances setMenu:menu];

    _packageButton  = [CPButtonBar plusButton];
    [_packageButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/package.png"] size:CPSizeMake(16, 16)]];
    [_packageButton setTarget:self];
    [_packageButton setAction:@selector(openNewApplianceWindow:)];
    [_packageButton setToolTip:@"Create a package from the virtual machine and publish it into the hypervisor's VMCast feed"];

    _attachButton  = [CPButtonBar plusButton];
    [_attachButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/lock.png"] size:CPSizeMake(16, 16)]];
    [_attachButton setTarget:self];
    [_attachButton setAction:@selector(attach:)];
    [_attachButton setEnabled:NO];
    [_attachButton setToolTip:@"Use the selected appliance for this virtual machine"];

    _detachButton  = [CPButtonBar plusButton];
    [_detachButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/unlock.png"] size:CPSizeMake(16, 16)]];
    [_detachButton setTarget:self];
    [_detachButton setAction:@selector(detach:)];
    [_detachButton setEnabled:NO];
    [_detachButton setToolTip:@"Stop using selected appliance for this virtual machine (it will allow to change appliance)"];

    [buttonBarControl setButtons:[_attachButton, _detachButton, _packageButton]];
}


#pragma mark -
#pragma mark TNModule overrides

/*! called when module is loaded
*/
- (void)willLoad
{
    [super willLoad];

    var center = [CPNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(_didUpdateNickName:) name:TNStropheContactNicknameUpdatedNotification object:_entity];
    [center addObserver:self selector:@selector(_didUpdatePresence:) name:TNStropheContactPresenceUpdatedNotification object:_entity];
    [center postNotificationName:TNArchipelModulesReadyNotification object:self];

    [self registerSelector:@selector(_didReceivePush:) forPushNotificationType:TNArchipelPushNotificationVMCasting];

    [_tableAppliances setDelegate:nil];
    [_tableAppliances setDelegate:self]; // hum....

    [self getInstalledAppliances];
}

/*! called when module is unloaded
*/
- (void)willUnload
{
    [_appliancesDatasource removeAllObjects];
    [_tableAppliances reloadData];

    [super willUnload];
}

/*! called when module becomes visible
*/
- (BOOL)willShow
{
    if (![super willShow])
        return NO;

    [fieldName setStringValue:[_entity nickname]];
    [fieldJID setStringValue:[_entity JID]];

    [self checkIfRunning];

    return YES;
}

/*! called when module becomes unvisible
*/
- (void)willHide
{
    [super willHide];
}

/*! called when MainMenu is ready
*/
- (void)menuReady
{
    [[_menu addItemWithTitle:@"Attach selected appliance" action:@selector(attach:) keyEquivalent:@""] setTarget:self];
    [[_menu addItemWithTitle:@"Dettach from selected appliance" action:@selector(detach:) keyEquivalent:@""] setTarget:self];
    [_menu addItem:[CPMenuItem separatorItem]];
    [[_menu addItemWithTitle:@"Create appliance from this virtual machine" action:@selector(package:) keyEquivalent:@""] setTarget:self];
}

/*! called when permissions changes
*/
- (void)permissionsChanged
{
    [self setControl:_packageButton enabledAccordingToPermission:@"appliance_package"];
    [self setControl:_attachButton enabledAccordingToPermission:@"appliance_attach"];
    [self setControl:_detachButton enabledAccordingToPermission:@"appliance_detach"];

    if ([self currentEntityHasPermission:@"appliance_package"])
        [windowNewAppliance close];

    [self tableViewSelectionDidChange:nil];
}


#pragma mark -
#pragma mark Notification handlers

/*! called when entity's nickname changes
    @param aNotification the notification
*/
- (void)_didUpdateNickName:(CPNotification)aNotification
{
    if ([aNotification object] == _entity)
    {
       [fieldName setStringValue:[_entity nickname]]
    }
}

/*! called if entity changes it presence and call checkIfRunning
    @param aNotification the notification
*/
- (void)_didUpdatePresence:(CPNotification)aNotification
{
    [self checkIfRunning];
}

/*! called when an Archipel push is received
    @param somePushInfo CPDictionary containing the push information
*/
- (BOOL)_didReceivePush:(CPDictionary)somePushInfo
{
    var sender  = [somePushInfo objectForKey:@"owner"],
        type    = [somePushInfo objectForKey:@"type"],
        change  = [somePushInfo objectForKey:@"change"],
        date    = [somePushInfo objectForKey:@"date"];

    CPLog.info(@"PUSH NOTIFICATION: from: " + sender + ", type: " + type + ", change: " + change);

    if (change == @"applianceinstalled")
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Appliance" message:"Appliance is installed"];
    }

    if ((change != "applianceunpacking") && (change != "applianceunpacked") && (change != @"appliancecopying"))
        [self getInstalledAppliances];

    return YES;
}


#pragma mark -
#pragma mark Utilities

/*! Checks if virtualmacine is not running otherwise displays the masking view
*/
- (void)checkIfRunning
{
    if ([_entity XMPPShow] == TNStropheContactStatusBusy)
    {
        [maskingView removeFromSuperview];
    }
    else
    {
        [maskingView setFrame:[[self view] bounds]];
        [[self view] addSubview:maskingView];
    }
}


#pragma mark -
#pragma mark Actions

/*! Open the new appliance window
    @param sender the sender of the action
*/
- (IBAction)openNewApplianceWindow:(id)aSender
{
    [fieldNewApplianceName setStringValue:[CPString UUID]];
    [windowNewAppliance makeFirstResponder:fieldNewApplianceName];
    [windowNewAppliance makeKeyAndOrderFront:nil];
}

/*! performed when we double click on package from table view.
    it will attach or detach
    @param sender the sender of the action
*/
- (IBAction)tableDoubleClicked:(id)aSender
{
    if ([_tableAppliances numberOfSelectedRows] <= 0)
        return;

    var selectedIndex   = [[_tableAppliances selectedRowIndexes] firstIndex],
        appliance       = [_appliancesDatasource objectAtIndex:selectedIndex];

    if ([appliance statusString] == TNArchipelApplianceStatusInstalled)
        [self detach];
    else
        [self attach];

}

/*! attach the selected appliance
    @param sender the sender of the action
*/
- (IBAction)attach:(id)aSender
{
    [self attach];
}

/*! detach the selected appliance
    @param sender the sender of the action
*/
- (IBAction)detach:(id)aSender
{
    [self detach];
}

/*! package the selected appliance
    @param sender the sender of the action
*/
- (IBAction)package:(id)aSender
{
    [self package];
}


#pragma mark -
#pragma mark XMPP Controls

/*! ask for installed appliances
*/
- (void)getInstalledAppliances
{
    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeVirtualMachineVMCasting}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeVirtualMachineVMCastingGet}];

    [self setModuleStatus:TNArchipelModuleStatusWaiting];
    [_entity sendStanza:stanza andRegisterSelector:@selector(_didReceiveInstalledAppliances:) ofObject:self];
}

/*! compute the answer containing the appliances
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)_didReceiveInstalledAppliances:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        [_appliancesDatasource removeAllObjects];

        var appliances = [aStanza childrenWithName:@"appliance"];

        for (var i = 0; i < [appliances count]; i++)
        {
            var appliance       = [appliances objectAtIndex:i],
                name            = [appliance valueForAttribute:@"name"],
                comment         = [appliance valueForAttribute:@"description"],
                path            = [appliance valueForAttribute:@"path"],
                uuid            = [appliance valueForAttribute:@"uuid"],
                status          = [appliance valueForAttribute:@"status"],
                newAppliance    = [TNInstalledAppliance InstalledApplianceWithName:name UUID:uuid path:path comment:comment status:status];

            [_appliancesDatasource addObject:newAppliance];
        }
        [_tableAppliances reloadData];
        [self setModuleStatus:TNArchipelModuleStatusReady];
    }
    else
    {
        [self setModuleStatus:TNArchipelModuleStatusError];
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}

/*! attach the selected appliance. but before ask user confirmation
*/
- (void)attach
{
    if (([_tableAppliances numberOfRows]) && ([_tableAppliances numberOfSelectedRows] <= 0))
    {
         [CPAlert alertWithTitle:@"Error" message:@"You must select an appliance"];
         return;
    }

    var alert = [TNAlert alertWithMessage:@"Attach appliance"
                                informative:@"Are you sure you want to attach this appliance? This will reset all your virtual machine."
                                 target:self
                                 actions:[["Attach", @selector(performAttach:)], ["Cancel", nil]]];
    [alert runModal];


}

/*! attach the selected appliance
*/
- (void)performAttach:(id)someUserInfo
{
    var selectedIndex   = [[_tableAppliances selectedRowIndexes] firstIndex],
        appliance       = [_appliancesDatasource objectAtIndex:selectedIndex],
        stanza          = [TNStropheStanza iqWithType:@"set"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeVirtualMachineVMCasting}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeVirtualMachineVMCastingAttach,
        "uuid": [appliance UUID]}];

    if ([self currentEntityHasPermission:@"appliance_attach"])
        [_attachButton setEnabled:NO];

    [_entity sendStanza:stanza andRegisterSelector:@selector(_didAttach:) ofObject:self];
}

/*! compute the attachement results
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)_didAttach:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Appliance" message:@"Instanciation has started"];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}

/*! detach the selected appliance. but before ask user confirmation
*/
- (void)detach
{
    if (([_tableAppliances numberOfRows]) && ([_tableAppliances numberOfSelectedRows] <= 0))
    {
         [CPAlert alertWithTitle:@"Error" message:@"You must select an appliance"];
         return;
    }

    var alert = [TNAlert alertWithMessage:@"Detach from appliance"
                                informative:@"Are you sure you want to detach virtual machine from this appliance?"
                                 target:self
                                 actions:[["Detach", @selector(performDetach:)], ["Cancel", nil]]];
    [alert runModal];
}

/*! detach the selected appliance
*/
- (void)performDetach:(id)someUserInfo
{
    var selectedIndex   = [[_tableAppliances selectedRowIndexes] firstIndex],
        appliance       = [_appliancesDatasource objectAtIndex:selectedIndex],
        stanza          = [TNStropheStanza iqWithType:@"set"];

    if ([appliance statusString] != TNArchipelApplianceStatusInstalled)
        return;


    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeVirtualMachineVMCasting}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeVirtualMachineVMCastingDetach}];

    if ([self currentEntityHasPermission:@"appliance_attach"])
        [_detachButton setEnabled:NO];

    [_entity sendStanza:stanza andRegisterSelector:@selector(_didDetach:) ofObject:self];
}

/*! compute the detachment results
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)_didDetach:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Appliance" message:@"Appliance has been detached"];

        [self setControl:_attachButton enabledAccordingToPermission:@"appliance_attach"];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}

/*! package the selected appliance
*/
- (void)package
{
    if ([_entity XMPPShow] != TNStropheContactStatusBusy)
    {
         [CPAlert alertWithTitle:@"Error" message:@"Virtual machine must not be running to package it."];
         return;
    }

    var stanza  = [TNStropheStanza iqWithType:@"get"],
        name    = [fieldNewApplianceName stringValue];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeVirtualMachineVMCasting}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeVirtualMachineVMCastingPackage,
        "name": name}];

    [_entity sendStanza:stanza andRegisterSelector:@selector(_didPackageAppliance:) ofObject:self];

    [windowNewAppliance close];
}

/*! compute the packaging results
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)_didPackageAppliance:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Appliance" message:@"Virtual machine has been packaged"];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}


#pragma mark -
#pragma mark Delegates

- (void)tableViewSelectionDidChange:(CPTableView)aTableView
{
    [_attachButton setEnabled:NO];
    [_detachButton setEnabled:NO];

    if ([_tableAppliances numberOfSelectedRows] <= 0)
        return;

    var selectedIndex   = [[_tableAppliances selectedRowIndexes] firstIndex],
        appliance       = [_appliancesDatasource objectAtIndex:selectedIndex];

    if ([appliance statusString] == TNArchipelApplianceStatusInstalled)
        [self setControl:_detachButton enabledAccordingToPermission:@"appliance_detach"];
    else
        [self setControl:_attachButton enabledAccordingToPermission:@"appliance_attach"];
}

@end