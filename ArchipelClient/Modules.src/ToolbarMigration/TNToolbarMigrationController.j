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
@import <AppKit/AppKit.j>

TNArchipelTypeHypervisorControl             = @"archipel:hypervisor:control";
TNArchipelTypeHypervisorControlRosterVM     = @"rostervm";

TNArchipelTypeVirtualMachineControl         = @"archipel:vm:control";
TNArchipelTypeVirtualMachineControlMigrate  = @"migrate";

/*! @defgroup  toolbarmigration Module Toolbar Migration

    @desc This module offers a general panel to manage virtual machine migrations
*/


/*! @ingroup toolbarmigration
    Sample toolbar module implementation
*/
@implementation TNToolbarMigrationController : TNModule
{
    @outlet     CPView          documentView;
    @outlet     CPScrollView    scrollViewTableHypervisorOrigin;
    @outlet     CPScrollView    scrollViewTableHypervisorDestination;
    @outlet     CPScrollView    scrollViewTableVirtualMachines;
    @outlet     CPButton        buttonMigrate;
    @outlet     CPSearchField   searchHypervisorOrigin;
    @outlet     CPSearchField   searchHypervisorDestination;
    @outlet     CPSearchField   searchVirtualMachine;

    CPTableView             _tableHypervisorOrigin;
    CPTableView             _tableHypervisorVirtualMachines;
    CPTableView             _tableHypervisorDestination;

    TNTableViewDataSource   _hypervisorOriginDatasource;
    TNTableViewDataSource   _hypervisorDestinationDatasource;
    TNTableViewDataSource   _virtualMachinesDatasource;
}


#pragma mark -
#pragma mark Initialization

/*! called at cib awaking
*/
- (void)awakeFromCib
{
    [scrollViewTableHypervisorOrigin setBorderedWithHexColor:@"#C0C7D2"];
    [scrollViewTableHypervisorDestination setBorderedWithHexColor:@"#C0C7D2"];
    [scrollViewTableVirtualMachines setBorderedWithHexColor:@"#C0C7D2"];

    // [[self view] setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];

    [documentView setAutoresizingMask:CPViewWidthSizable];
    [[self view] setBackgroundColor:[CPColor whiteColor]];
    [[self view] setDocumentView:documentView];

    // table hypervisor origin
    _hypervisorOriginDatasource  = [[TNTableViewDataSource alloc] init];
    _tableHypervisorOrigin       = [[CPTableView alloc] initWithFrame:[scrollViewTableHypervisorOrigin bounds]];

    [scrollViewTableHypervisorOrigin setAutohidesScrollers:YES];
    [scrollViewTableHypervisorOrigin setDocumentView:_tableHypervisorOrigin];

    [_tableHypervisorOrigin setUsesAlternatingRowBackgroundColors:YES];
    [_tableHypervisorOrigin setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [_tableHypervisorOrigin setAllowsColumnResizing:YES];
    [_tableHypervisorOrigin setAllowsEmptySelection:YES];
    [_tableHypervisorOrigin setAllowsMultipleSelection:NO];
    [_tableHypervisorOrigin setDelegate:self];
    [_tableHypervisorOrigin setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];

    var columnHypervisorName = [[CPTableColumn alloc] initWithIdentifier:@"nickname"],
        columnHypervisorStatus  = [[CPTableColumn alloc] initWithIdentifier:@"statusIcon"],
        imgView1                 = [[CPImageView alloc] initWithFrame:CGRectMake(0,0,16,16)];

    [columnHypervisorName setWidth:250];
    [[columnHypervisorName headerView] setStringValue:@"Name"];
    [columnHypervisorName setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"nickname" ascending:YES]];

    [imgView1 setImageScaling:CPScaleNone];
    [columnHypervisorStatus setDataView:imgView1];
    [columnHypervisorStatus setResizingMask:CPTableColumnAutoresizingMask ];
    [columnHypervisorStatus setWidth:16];
    [[columnHypervisorStatus headerView] setStringValue:@""];

    [searchHypervisorOrigin setTarget:_hypervisorOriginDatasource];
    [searchHypervisorOrigin setAction:@selector(filterObjects:)];
    [_hypervisorOriginDatasource setSearchableKeyPaths:[@"nickname"]];

    [_tableHypervisorOrigin addTableColumn:columnHypervisorStatus];
    [_tableHypervisorOrigin addTableColumn:columnHypervisorName];
    [_hypervisorOriginDatasource setTable:_tableHypervisorOrigin];
    [_tableHypervisorOrigin setDataSource:_hypervisorOriginDatasource];


    // table virtual machines
    _virtualMachinesDatasource      = [[TNTableViewDataSource alloc] init];
    _tableHypervisorVirtualMachines = [[CPTableView alloc] initWithFrame:[scrollViewTableVirtualMachines bounds]];

    [scrollViewTableVirtualMachines setAutohidesScrollers:YES];
    [scrollViewTableVirtualMachines setDocumentView:_tableHypervisorVirtualMachines];

    [_tableHypervisorVirtualMachines setUsesAlternatingRowBackgroundColors:YES];
    [_tableHypervisorVirtualMachines setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [_tableHypervisorVirtualMachines setAllowsColumnResizing:YES];
    [_tableHypervisorVirtualMachines setAllowsEmptySelection:YES];
    [_tableHypervisorVirtualMachines setAllowsMultipleSelection:NO];
    [_tableHypervisorVirtualMachines setDelegate:self];
    [_tableHypervisorVirtualMachines setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];

    var columnVMName    = [[CPTableColumn alloc] initWithIdentifier:@"nickname"],
        columnVMStatus  = [[CPTableColumn alloc] initWithIdentifier:@"statusIcon"],
        imgView2        = [[CPImageView alloc] initWithFrame:CGRectMake(0,0,16,16)];

    [columnVMName setWidth:250];
    [[columnVMName headerView] setStringValue:@"Name"];
    [columnVMName setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"nickname" ascending:YES]];

    [imgView2 setImageScaling:CPScaleNone];
    [columnVMStatus setDataView:imgView2];
    [columnVMStatus setResizingMask:CPTableColumnAutoresizingMask ];
    [columnVMStatus setWidth:16];
    [[columnVMStatus headerView] setStringValue:@""];

    [searchVirtualMachine setTarget:_virtualMachinesDatasource];
    [searchVirtualMachine setAction:@selector(filterObjects:)];
    [_virtualMachinesDatasource setSearchableKeyPaths:[@"nickname"]];

    [_tableHypervisorVirtualMachines addTableColumn:columnVMStatus];
    [_tableHypervisorVirtualMachines addTableColumn:columnVMName];
    [_virtualMachinesDatasource setTable:_tableHypervisorVirtualMachines];
    [_tableHypervisorVirtualMachines setDataSource:_virtualMachinesDatasource];


    // table hypervisor destination
    _hypervisorDestinationDatasource    = [[TNTableViewDataSource alloc] init];
    _tableHypervisorDestination         = [[CPTableView alloc] initWithFrame:[scrollViewTableHypervisorDestination bounds]];

    [scrollViewTableHypervisorDestination setAutohidesScrollers:YES];
    [scrollViewTableHypervisorDestination setDocumentView:_tableHypervisorDestination];

    [_tableHypervisorDestination setUsesAlternatingRowBackgroundColors:YES];
    [_tableHypervisorDestination setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [_tableHypervisorDestination setAllowsColumnResizing:YES];
    [_tableHypervisorDestination setAllowsEmptySelection:YES];
    [_tableHypervisorDestination setAllowsMultipleSelection:NO];
    [_tableHypervisorDestination setDelegate:self];
    [_tableHypervisorDestination setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];

    var columnHypervisorDestName    = [[CPTableColumn alloc] initWithIdentifier:@"nickname"],
        columnHypervisorDestStatus  = [[CPTableColumn alloc] initWithIdentifier:@"statusIcon"],
        imgView3                    = [[CPImageView alloc] initWithFrame:CGRectMake(0,0,16,16)];

    [columnHypervisorDestName setWidth:250];
    [[columnHypervisorDestName headerView] setStringValue:@"Name"];
    [columnHypervisorDestName setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"nickname" ascending:YES]];

    [imgView3 setImageScaling:CPScaleNone];
    [columnHypervisorDestStatus setDataView:imgView3];
    [columnHypervisorDestStatus setResizingMask:CPTableColumnAutoresizingMask ];
    [columnHypervisorDestStatus setWidth:16];
    [[columnHypervisorDestStatus headerView] setStringValue:@""];

    [searchHypervisorDestination setTarget:_hypervisorDestinationDatasource];
    [searchHypervisorDestination setAction:@selector(filterObjects:)];
    [_hypervisorDestinationDatasource setSearchableKeyPaths:[@"nickname"]];

    [_tableHypervisorDestination addTableColumn:columnHypervisorDestStatus];
    [_tableHypervisorDestination addTableColumn:columnHypervisorDestName];
    [_hypervisorDestinationDatasource setTable:_tableHypervisorDestination];
    [_tableHypervisorDestination setDataSource:_hypervisorDestinationDatasource];
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
- (void)willShow
{
    [super willShow];

    var bounds = [[[self view] contentView] bounds];
    bounds.size.height = [documentView bounds].size.height;
    [documentView setFrame:bounds];

    var center = [CPNotificationCenter defaultCenter];

    [center addObserver:self selector:@selector(refresh:) name:TNStropheContactNicknameUpdatedNotification object:nil];
    [center addObserver:self selector:@selector(refresh:) name:TNStropheContactPresenceUpdatedNotification object:nil];

    [buttonMigrate setEnabled:NO];

    [_tableHypervisorOrigin setDelegate:nil];
    [_tableHypervisorDestination setDelegate:nil];
    [_tableHypervisorVirtualMachines setDelegate:nil];

    [_tableHypervisorOrigin setDelegate:self];
    [_tableHypervisorDestination setDelegate:self];
    [_tableHypervisorVirtualMachines setDelegate:self];

    [self populateHypervisorOriginTable];
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

    [_tableHypervisorOrigin deselectAll];
    [_tableHypervisorVirtualMachines deselectAll];
    [_tableHypervisorDestination deselectAll];

    [self refresh:nil];
}


#pragma mark -
#pragma mark Notification handlers

/*! refresh all the tables
*/
- (void)refresh:(CPNotification)aNotification
{
    [_tableHypervisorOrigin reloadData];
    [_tableHypervisorDestination reloadData];
    [_tableHypervisorVirtualMachines reloadData];
}


#pragma mark -
#pragma mark Utilities

/*! populate the content of the origin table
*/
- (void)populateHypervisorOriginTable
{
    [_hypervisorOriginDatasource removeAllObjects];

    var rosterItems = [_roster contacts];

    for (var i = 0; i < [rosterItems count]; i++)
    {
        var item = [rosterItems objectAtIndex:i];

        if ([[[item vCard] firstChildWithName:@"TYPE"] text] == @"hypervisor")
            [_hypervisorOriginDatasource addObject:item]
    }
    [_tableHypervisorOrigin reloadData];

}

/*! populate the content of the destination table
*/
- (void)populateHypervisorDestinationTable
{
    [_hypervisorDestinationDatasource removeAllObjects];

    var rosterItems = [_roster contacts];

    for (var i = 0; i < [rosterItems count]; i++)
    {
        var item                = [rosterItems objectAtIndex:i],
            index               = [[_tableHypervisorOrigin selectedRowIndexes] firstIndex],
            currentHypervisor   = [_hypervisorOriginDatasource objectAtIndex:index];

        if (currentHypervisor != item)
        {
            if ([[[item vCard] firstChildWithName:@"TYPE"] text] == @"hypervisor")
                [_hypervisorDestinationDatasource addObject:item]
        }
    }
    [_tableHypervisorDestination reloadData];
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
    var virtualMachine          = [_virtualMachinesDatasource objectAtIndex:[[_tableHypervisorVirtualMachines selectedRowIndexes] firstIndex]],
        destinationHypervisor   = [_hypervisorDestinationDatasource objectAtIndex:[[_tableHypervisorDestination selectedRowIndexes] firstIndex]],
        stanza                  = [TNStropheStanza iqWithType:@"set"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeVirtualMachineControl}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeVirtualMachineControlMigrate,
        "hypervisorjid": [destinationHypervisor fullJID]}];

    [virtualMachine sendStanza:stanza andRegisterSelector:@selector(_didMigrate:) ofObject:self];
}

/*! compute the migration result
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)_didMigrate:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        [_tableHypervisorDestination deselectAll];
        [_tableHypervisorVirtualMachines deselectAll];
        [_tableHypervisorOrigin deselectAll];

        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Migration" message:@"Migration has started. It can take a while"];
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
            var JID     = [[queryItems objectAtIndex:i] text],
                entry   = [_roster contactWithJID:JID];

            if (entry)
            {
               if ([[[entry vCard] firstChildWithName:@"TYPE"] text] == "virtualmachine")
               {
                   [_virtualMachinesDatasource addObject:entry]
               }
            }
        }
        [_tableHypervisorVirtualMachines reloadData];
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
    if ([aNotification object] == _tableHypervisorOrigin)
    {
        [buttonMigrate setEnabled:NO];
        [_hypervisorDestinationDatasource removeAllObjects];
        [_tableHypervisorDestination reloadData];
        if ([_tableHypervisorOrigin numberOfSelectedRows] == 0)
        {
            [_virtualMachinesDatasource removeAllObjects];
            [_tableHypervisorVirtualMachines reloadData];
            [_tableHypervisorVirtualMachines deselectAll];
            return;
        }
        var index               = [[_tableHypervisorOrigin selectedRowIndexes] firstIndex],
            currentHypervisor   = [_hypervisorOriginDatasource objectAtIndex:index];

        [self rosterOfHypervisor:currentHypervisor];
    }
    else if ([aNotification object] == _tableHypervisorVirtualMachines)
    {
        [buttonMigrate setEnabled:NO];
        if ([_tableHypervisorVirtualMachines numberOfSelectedRows] == 0)
        {
            [_hypervisorDestinationDatasource removeAllObjects];
            [_tableHypervisorDestination reloadData];
            [_tableHypervisorDestination deselectAll];
            return;
        }
        [self populateHypervisorDestinationTable];
    }
    else if ([aNotification object] == _tableHypervisorDestination)
    {
        if ([_tableHypervisorDestination numberOfSelectedRows] == 0)
            [buttonMigrate setEnabled:NO];
        else
            [buttonMigrate setEnabled:YES];
    }
}

@end



