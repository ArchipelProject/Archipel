/*
 * TNSampleToolbarModule.j
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
@import <AppKit/CPSearchField.j>
@import <AppKit/CPTableView.j>
@import <AppKit/CPView.j>

@import <TNKit/TNTableViewDataSource.j>
@import <TNKit/TNUIKitScrollView.j>


var TNArchipelTypeHypervisorControl             = @"archipel:hypervisor:control",
    TNArchipelTypeHypervisorControlRosterVM     = @"rostervm",
    TNArchipelTypeVirtualMachineControl         = @"archipel:vm:control",
    TNArchipelTypeVirtualMachineControlMigrate  = @"migrate";


/*! @defgroup  toolbarmigration Module Toolbar Migration

    @desc This module offers a general panel to manage virtual machine migrations
*/


/*! @ingroup toolbarmigration
    Sample toolbar module implementation
*/
@implementation TNToolbarMigrationController : TNModule
{
    @outlet CPButton            buttonMigrate;
    @outlet CPSearchField       searchHypervisorDestination;
    @outlet CPSearchField       searchHypervisorOrigin;
    @outlet CPSearchField       searchVirtualMachine;
    @outlet CPTableView         tableHypervisorDestination;
    @outlet CPTableView         tableHypervisorOrigin;
    @outlet CPTableView         tableHypervisorVirtualMachines;

    TNTableViewDataSource       _hypervisorDestinationDatasource;
    TNTableViewDataSource       _hypervisorOriginDatasource;
    TNTableViewDataSource       _virtualMachinesDatasource;
}


#pragma mark -
#pragma mark Initialization

/*! called at cib awaking
*/
- (void)awakeFromCib
{
    // table hypervisor origin
    _hypervisorOriginDatasource  = [[TNTableViewDataSource alloc] init];
    [tableHypervisorOrigin setDelegate:self];
    [searchHypervisorOrigin setTarget:_hypervisorOriginDatasource];
    [searchHypervisorOrigin setAction:@selector(filterObjects:)];
    [_hypervisorOriginDatasource setSearchableKeyPaths:[@"nickname"]];
    [_hypervisorOriginDatasource setTable:tableHypervisorOrigin];
    [tableHypervisorOrigin setDataSource:_hypervisorOriginDatasource];

    // table virtual machines
    _virtualMachinesDatasource = [[TNTableViewDataSource alloc] init];
    [tableHypervisorVirtualMachines setDelegate:self];
    [searchVirtualMachine setTarget:_virtualMachinesDatasource];
    [searchVirtualMachine setAction:@selector(filterObjects:)];
    [_virtualMachinesDatasource setSearchableKeyPaths:[@"nickname"]];
    [_virtualMachinesDatasource setTable:tableHypervisorVirtualMachines];
    [tableHypervisorVirtualMachines setDataSource:_virtualMachinesDatasource];

    // table hypervisor destination
    _hypervisorDestinationDatasource = [[TNTableViewDataSource alloc] init];
    [tableHypervisorDestination setDelegate:self];
    [searchHypervisorDestination setTarget:_hypervisorDestinationDatasource];
    [searchHypervisorDestination setAction:@selector(filterObjects:)];
    [_hypervisorDestinationDatasource setSearchableKeyPaths:[@"nickname"]];
    [_hypervisorDestinationDatasource setTable:tableHypervisorDestination];
    [tableHypervisorDestination setDataSource:_hypervisorDestinationDatasource];
}


#pragma mark -
#pragma mark TNModule overrides

/*! called when module is loaded
*/
- (void)willLoad
{
    [super willLoad];
    // message sent when view will be added from superview;
}

/*! called when module is unloaded
*/
- (void)willUnload
{
    [super willUnload];
}

/*! called when module becomes visible
*/
- (BOOL)willShow
{
    if (![super willShow])
        return NO;

    var center = [CPNotificationCenter defaultCenter];

    [center addObserver:self selector:@selector(refresh:) name:TNStropheContactNicknameUpdatedNotification object:nil];
    [center addObserver:self selector:@selector(refresh:) name:TNStropheContactPresenceUpdatedNotification object:nil];

    [buttonMigrate setEnabled:NO];

    [tableHypervisorOrigin setDelegate:nil];
    [tableHypervisorDestination setDelegate:nil];
    [tableHypervisorVirtualMachines setDelegate:nil];

    [tableHypervisorOrigin setDelegate:self];
    [tableHypervisorDestination setDelegate:self];
    [tableHypervisorVirtualMachines setDelegate:self];

    [self populateHypervisorOriginTable];

    return YES;
}

/*! called when module becomes unvisible
*/
- (void)willHide
{
    [super willHide];

    [[CPNotificationCenter defaultCenter] removeObserver:self];

    [_hypervisorOriginDatasource removeAllObjects];
    [_hypervisorDestinationDatasource removeAllObjects];
    [_virtualMachinesDatasource removeAllObjects];

    [tableHypervisorOrigin deselectAll];
    [tableHypervisorVirtualMachines deselectAll];
    [tableHypervisorDestination deselectAll];

    [self refresh:nil];
}


#pragma mark -
#pragma mark Notification handlers

/*! refresh all the tables
*/
- (void)refresh:(CPNotification)aNotification
{
    [tableHypervisorOrigin reloadData];
    [tableHypervisorDestination reloadData];
    [tableHypervisorVirtualMachines reloadData];
}


#pragma mark -
#pragma mark Utilities

/*! populate the content of the origin table
*/
- (void)populateHypervisorOriginTable
{
    [_hypervisorOriginDatasource removeAllObjects];

    var rosterItems = [[[TNStropheIMClient defaultClient] roster] contacts];

    for (var i = 0; i < [rosterItems count]; i++)
    {
        var item = [rosterItems objectAtIndex:i];

        if ([[[TNStropheIMClient defaultClient] roster] analyseVCard:[item vCard]] == TNArchipelEntityTypeHypervisor)
            [_hypervisorOriginDatasource addObject:item]
    }
    [tableHypervisorOrigin reloadData];

}

/*! populate the content of the destination table
*/
- (void)populateHypervisorDestinationTable
{
    [_hypervisorDestinationDatasource removeAllObjects];

    var rosterItems = [[[TNStropheIMClient defaultClient] roster] contacts];

    for (var i = 0; i < [rosterItems count]; i++)
    {
        var item                = [rosterItems objectAtIndex:i],
            index               = [[tableHypervisorOrigin selectedRowIndexes] firstIndex],
            currentHypervisor   = [_hypervisorOriginDatasource objectAtIndex:index];

        if (currentHypervisor != item)
        {
            if ([[[TNStropheIMClient defaultClient] roster] analyseVCard:[item vCard]] == TNArchipelEntityTypeHypervisor)
                [_hypervisorDestinationDatasource addObject:item]
        }
    }
    [tableHypervisorDestination reloadData];
}


#pragma mark -
#pragma mark Actions

/*! perform a live migration
    @param sender the sender of the action
*/
- (IBAction)migrate:(id)aSender
{
    [self migrate];
}


#pragma mark -
#pragma mark XMPP Controls

/*! perform a live migration
*/
- (void)migrate
{
    var virtualMachine          = [_virtualMachinesDatasource objectAtIndex:[[tableHypervisorVirtualMachines selectedRowIndexes] firstIndex]],
        destinationHypervisor   = [_hypervisorDestinationDatasource objectAtIndex:[[tableHypervisorDestination selectedRowIndexes] firstIndex]],
        stanza                  = [TNStropheStanza iqWithType:@"set"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeVirtualMachineControl}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeVirtualMachineControlMigrate,
        "hypervisorjid": [[destinationHypervisor JID] full]}];

    [virtualMachine sendStanza:stanza andRegisterSelector:@selector(_didMigrate:) ofObject:self];
}

/*! compute the migration result
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)_didMigrate:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        [tableHypervisorDestination deselectAll];
        [tableHypervisorVirtualMachines deselectAll];
        [tableHypervisorOrigin deselectAll];

        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:CPBundleLocalizedString(@"Migration", @"Migration")
                                                         message:CPBundleLocalizedString(@"Migration has started. It can take a while", @"Migration has started. It can take a while")];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}

/*! ask hypervisor's roster
    @param anHypervisor the hypervisor to ask
*/
- (void)rosterOfHypervisor:(TNStropheContact)anHypervisor
{
    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorControl}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorControlRosterVM}];


    [anHypervisor sendStanza:stanza andRegisterSelector:@selector(_didReceiveRoster:) ofObject:self];
}

/*! compute the content of the roster
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)_didReceiveRoster:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        var queryItems  = [aStanza childrenWithName:@"item"],
            center      = [CPNotificationCenter defaultCenter];

        [_virtualMachinesDatasource removeAllObjects];

        for (var i = 0; i < [queryItems count]; i++)
        {
            var JID     = [TNStropheJID stropheJIDWithString:[[queryItems objectAtIndex:i] text]],
                entry   = [[[TNStropheIMClient defaultClient] roster] contactWithJID:JID];

            if (entry && ([[[TNStropheIMClient defaultClient] roster] analyseVCard:[entry vCard]] == TNArchipelEntityTypeVirtualMachine))
                [_virtualMachinesDatasource addObject:entry];
        }
        [tableHypervisorVirtualMachines reloadData];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}


#pragma mark -
#pragma mark Delegates

- (void)tableViewSelectionDidChange:(CPNotification)aNotification
{
    if ([aNotification object] == tableHypervisorOrigin)
    {
        [buttonMigrate setEnabled:NO];
        [_hypervisorDestinationDatasource removeAllObjects];
        [tableHypervisorDestination reloadData];
        if ([tableHypervisorOrigin numberOfSelectedRows] == 0)
        {
            [_virtualMachinesDatasource removeAllObjects];
            [tableHypervisorVirtualMachines reloadData];
            [tableHypervisorVirtualMachines deselectAll];
            return;
        }
        var index               = [[tableHypervisorOrigin selectedRowIndexes] firstIndex],
            currentHypervisor   = [_hypervisorOriginDatasource objectAtIndex:index];

        [self rosterOfHypervisor:currentHypervisor];
    }
    else if ([aNotification object] == tableHypervisorVirtualMachines)
    {
        [buttonMigrate setEnabled:NO];
        if ([tableHypervisorVirtualMachines numberOfSelectedRows] == 0)
        {
            [_hypervisorDestinationDatasource removeAllObjects];
            [tableHypervisorDestination reloadData];
            [tableHypervisorDestination deselectAll];
            return;
        }
        [self populateHypervisorDestinationTable];
    }
    else if ([aNotification object] == tableHypervisorDestination)
    {
        if ([tableHypervisorDestination numberOfSelectedRows] == 0)
            [buttonMigrate setEnabled:NO];
        else
            [buttonMigrate setEnabled:YES];
    }
}

@end


// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNToolbarMigrationController], comment);
}



