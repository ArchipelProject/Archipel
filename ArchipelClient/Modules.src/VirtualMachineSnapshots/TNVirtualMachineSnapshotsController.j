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
@import <AppKit/AppKit.j>

@import "TNSnapshot.j";
@import "TNSnapshotsDatasource.j";


TNArchipelSnapshotsOpenedSnapshots          = @"TNArchipelSnapshotsOpenedSnapshots_";

TNArchipelPushNotificationSnapshoting       = @"archipel:push:snapshoting";
TNArchipelTypeHypervisorSnapshot            = @"archipel:virtualmachine:snapshoting";
TNArchipelTypeHypervisorSnapshotTake        = @"take";
TNArchipelTypeHypervisorSnapshotGet         = @"get";
TNArchipelTypeHypervisorSnapshotCurrent     = @"current";
TNArchipelTypeHypervisorSnapshotDelete      = @"delete";
TNArchipelTypeHypervisorSnapshotRevert      = @"revert";



/*! @defgroup  virtualmachinesnapshoting Module VirtualMachine Snapshots
    @desc Module to handle Virtual Machine snapshoting
*/

/*! @ingroup virtualmachinedrives
    main class of the module
*/
@implementation TNVirtualMachineSnapshotsController : TNModule
{
    @outlet CPButtonBar                 buttonBarControl;
    @outlet CPScrollView                scrollViewSnapshots;
    @outlet CPSearchField               fieldFilter;
    @outlet CPTextField                 fieldInfo;
    @outlet CPTextField                 fieldJID;
    @outlet CPTextField                 fieldName;
    @outlet CPTextField                 fieldNewSnapshotName;
    @outlet CPView                      maskingView;
    @outlet CPView                      viewTableContainer;
    @outlet CPWindow                    windowNewSnapshot;
    @outlet LPMultiLineTextField        fieldNewSnapshotDescription;

    CPButton                            _minusButton;
    CPButton                            _plusButton;
    CPButton                            _revertButton;
    CPOutlineView                       _outlineViewSnapshots;
    TNSnapshot                          _currentSnapshot;
    TNSnapshotsDatasource               _datasourceSnapshots;
}

#pragma mark -
#pragma mark  Initialization

/*! called at cib awaking
*/
- (void)awakeFromCib
{
    [fieldJID setSelectable:YES];
    [viewTableContainer setBorderedWithHexColor:@"#C0C7D2"];

    // this really sucks, but something have change in capp that made the textfield not take care of the Atlas defined values;
    [fieldNewSnapshotDescription setFrameSize:CPSizeMake(366, 120)];

    // VM table view
    _datasourceSnapshots    = [[TNSnapshotsDatasource alloc] init];
    _outlineViewSnapshots   = [[CPOutlineView alloc] initWithFrame:[scrollViewSnapshots bounds]];

    [scrollViewSnapshots setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [scrollViewSnapshots setAutohidesScrollers:YES];
    [scrollViewSnapshots setDocumentView:_outlineViewSnapshots];

    [_outlineViewSnapshots setUsesAlternatingRowBackgroundColors:YES];
    [_outlineViewSnapshots setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [_outlineViewSnapshots setAllowsColumnResizing:YES];
    [_outlineViewSnapshots setAllowsEmptySelection:YES];
    [_outlineViewSnapshots setAllowsMultipleSelection:NO];
    [_outlineViewSnapshots setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    // [_outlineViewSnapshots setRowHeight:50.0];

    var outlineColumn = [[CPTableColumn alloc] initWithIdentifier:@"outline"],
        columnName = [[CPTableColumn alloc] initWithIdentifier:@"name"],
        columnDescription = [[CPTableColumn alloc] initWithIdentifier:@"description"],
        columnCreationTime = [[CPTableColumn alloc] initWithIdentifier:@"creationTime"],
        columnState     = [[CPTableColumn alloc] initWithIdentifier:@"isCurrent"],
        imgView         = [[CPImageView alloc] initWithFrame:CGRectMake(0,0,16,16)];

    [outlineColumn setWidth:16];

    [[columnName headerView] setStringValue:@"UUID"];
    [columnName setWidth:100];
    [columnName setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];

    [[columnDescription headerView] setStringValue:@"Description"];
    [columnDescription setWidth:400];
    [columnDescription setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"description" ascending:YES]];

    [[columnCreationTime headerView] setStringValue:@"Creation date"];
    [columnCreationTime setWidth:130];
    [columnCreationTime setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"creationTime" ascending:YES]];

    [imgView setImageScaling:CPScaleNone];
    [columnState setDataView:imgView];
    [columnState setResizingMask:CPTableColumnAutoresizingMask ];
    [columnState setWidth:16];
    [[columnState headerView] setStringValue:@""];

    // [_outlineViewSnapshots addTableColumn:outlineColumn];
    [_outlineViewSnapshots addTableColumn:columnState];
    [_outlineViewSnapshots addTableColumn:columnDescription];
    [_outlineViewSnapshots addTableColumn:columnCreationTime];
    [_outlineViewSnapshots addTableColumn:columnName];
    [_outlineViewSnapshots setOutlineTableColumn:columnDescription];
    [_outlineViewSnapshots setDelegate:self];

    [_datasourceSnapshots setParentKeyPath:@"parent"];
    [_datasourceSnapshots setChildCompKeyPath:@"name"];
    [_datasourceSnapshots setSearchableKeyPaths:[@"name", @"description", @"creationTime"]];

    [fieldFilter setTarget:_datasourceSnapshots];
    [fieldFilter setAction:@selector(filterObjects:)];

    [_outlineViewSnapshots setDataSource:_datasourceSnapshots];

    var menu = [[CPMenu alloc] init];
    [menu addItemWithTitle:@"Create new snapshot" action:@selector(openWindowNewSnapshot:) keyEquivalent:@""];
    [menu addItemWithTitle:@"Delete" action:@selector(deleteSnapshot:) keyEquivalent:@""];
    [menu addItemWithTitle:@"Restore" action:@selector(restoreSnapshot:) keyEquivalent:@""];
    [_outlineViewSnapshots setMenu:menu];

    _plusButton = [CPButtonBar plusButton];
    [_plusButton setTarget:self];
    [_plusButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-photo-add.png"] size:CPSizeMake(16, 16)]];
    [_plusButton setAction:@selector(openWindowNewSnapshot:)];

    _minusButton = [CPButtonBar minusButton];
    [_minusButton setTarget:self];
    [_minusButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-photo-remove.png"] size:CPSizeMake(16, 16)]];
    [_minusButton setAction:@selector(deleteSnapshot:)];

    _revertButton = [CPButtonBar minusButton];
    [_revertButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-revert.png"] size:CPSizeMake(16, 16)]];
    [_revertButton setTarget:self];
    [_revertButton setAction:@selector(revertSnapshot:)];

    [_revertButton setEnabled:NO];
    [_minusButton setEnabled:NO];

    [buttonBarControl setButtons:[_plusButton, _minusButton, _revertButton]];
}


#pragma mark -
#pragma mark TNModule overrides

/*! called when module is loaded
*/
- (void)willLoad
{
    [super willLoad];

    [fieldName setStringValue:[_entity nickname]];
    [fieldJID setStringValue:[_entity JID]];

    var center = [CPNotificationCenter defaultCenter];

    [center addObserver:self selector:@selector(_didUpdateNickName:) name:TNStropheContactNicknameUpdatedNotification object:_entity];
    [center addObserver:self selector:@selector(_didUpdatePresence:) name:TNStropheContactPresenceUpdatedNotification object:_entity];
    [center postNotificationName:TNArchipelModulesReadyNotification object:self];

    [self registerSelector:@selector(_didReceivePush:) forPushNotificationType:TNArchipelPushNotificationSnapshoting];

    _currentSnapshot = nil;

    [_outlineViewSnapshots setDelegate:nil];
    [_outlineViewSnapshots setDelegate:self];

    [self checkIfRunning];
    [self getSnapshots];
}

/*! called when module is unloaded
*/
- (void)willUnload
{
    [super willUnload];

    [_datasourceSnapshots removeAllObjects];
    [_outlineViewSnapshots reloadData];
    [_outlineViewSnapshots deselectAll];
    [_revertButton setEnabled:NO];
    [_minusButton setEnabled:NO];
}

/*! called when module becomes visible
*/
- (void)willShow
{
    [super willShow];
    [self checkIfRunning];
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
    [[_menu addItemWithTitle:@"Take a snapshot" action:@selector(openWindowNewSnapshot:) keyEquivalent:@""] setTarget:self];
    [[_menu addItemWithTitle:@"Revert to selected drive" action:@selector(revertSnapshot:) keyEquivalent:@""] setTarget:self];
    [_menu addItem:[CPMenuItem separatorItem]];
    [[_menu addItemWithTitle:@"Delete selected snapshot" action:@selector(deleteSnapshot:) keyEquivalent:@""] setTarget:self];
}


#pragma mark -
#pragma mark Notification

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

    [self getSnapshots];

    return YES;
}


#pragma mark -
#pragma mark Utilities

/*! checks if virtual machine running. if yes displays the masking view
*/
- (void)checkIfRunning
{
    if ([_entity XMPPShow] == TNStropheContactStatusOnline || [_entity XMPPShow] == TNStropheContactStatusAway)
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
#pragma mark  Actions

/*! opens the new snapshot window
    @param aSender the sender of the action
*/
- (IBAction)openWindowNewSnapshot:(id)aSender
{
    [fieldNewSnapshotName setStringValue:@""];
    [fieldNewSnapshotDescription setStringValue:@""];
    [windowNewSnapshot center];
    [windowNewSnapshot makeFirstResponder:fieldNewSnapshotDescription];
    [fieldNewSnapshotName setStringValue:[CPString UUID]];
    [windowNewSnapshot makeKeyAndOrderFront:aSender];
}

/*! take a snaphot
    @param aSender the sender of the action
*/
- (IBAction)takeSnapshot:(id)aSender
{
    [self takeSnapshot];
}

/*! delete a snaphot
    @param aSender the sender of the action
*/
- (IBAction)deleteSnapshot:(id)aSender
{
    [self deleteSnapshot];
}

/*! revert to a snaphot
    @param aSender the sender of the action
*/
- (IBAction)revertSnapshot:(id)aSender
{
    [self revertSnapshot];
}


#pragma mark -
#pragma mark XMPP Controls

/*! asks virtual machine for its snapshot
*/
- (void)getSnapshots
{
    var stanza  = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorSnapshot}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorSnapshotGet}];

    [self sendStanza:stanza andRegisterSelector:@selector(_didGetSnapshots:)];
}

/*! compute virtual machine snapshots
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)_didGetSnapshots:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        var snapshots = [aStanza childrenWithName:@"domainsnapshot"];

        [_datasourceSnapshots removeAllObjects];

        for (var i = 0; i < [snapshots count]; i++)
        {
            var snapshot        = [snapshots objectAtIndex:i],
                snapshotObject  = [[TNSnapshot alloc] init],
                date            = [CPDate dateWithTimeIntervalSince1970:[[snapshot firstChildWithName:@"creationTime"] text]];

            CPLog.debug([[snapshot firstChildWithName:@"domainsnapshot"] text]);

            [snapshotObject setUUID:[[snapshot firstChildWithName:@"uuid"] text]];
            [snapshotObject setName:[[snapshot firstChildWithName:@"name"] text]];
            [snapshotObject setDescription:[[snapshot firstChildWithName:@"description"] text]];
            [snapshotObject setCreationTime:date.dateFormat(@"Y-m-d H:i:s")];
            [snapshotObject setState:[[snapshot firstChildWithName:@"state"] text]];
            [snapshotObject setParent:[[[snapshot firstChildWithName:@"parent"] firstChildWithName:@"name"] text]];
            [snapshotObject setDomain:[[snapshot firstChildWithName:@"domain"] text]];
            [snapshotObject setCurrent:NO];

            [_datasourceSnapshots addObject:snapshotObject];
        }

        [self getCurrentSnapshot];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}

/*! asks virtual machine for its current snapshot
*/
- (void)getCurrentSnapshot
{
    var stanza  = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorSnapshot}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorSnapshotCurrent}];

    [self sendStanza:stanza andRegisterSelector:@selector(_didGetCurrentSnapshot:)];
}

/*! compute virtual machine current snapshot
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)_didGetCurrentSnapshot:(TNStropheStanza)aStanza
{
    [fieldInfo setStringValue:@""];
    if ([aStanza type] == @"result")
    {
        var snapshots   = [aStanza firstChildWithName:@"domainsnapshot"],
            name        = [[snapshots firstChildWithName:@"name"] text];

        for (var i = 0; i < [_datasourceSnapshots count]; i++)
        {
            var obj = [_datasourceSnapshots objectAtIndex:i];

            if ([obj name] == name)
            {
                _currentSnapshot = obj;
                [obj setCurrent:YES];
                break;
            }

        }
    }
    else if ([aStanza type] == @"ignore")
    {
        [fieldInfo setStringValue:@"There is no snapshot for this virtual machine"];
    }
    else if ([aStanza type] == @"error")
    {
        [self handleIqErrorFromStanza:aStanza];
    }

    [_outlineViewSnapshots reloadData];
    [_outlineViewSnapshots recoverExpandedWithBaseKey:TNArchipelSnapshotsOpenedSnapshots itemKeyPath:@"name"];

    return NO;
}

/*! asks virtual machine to take a snapshot. but ask confirmation before
*/
- (void)takeSnapshot
{
    var stanza  = [TNStropheStanza iqWithType:@"set"],
        uuid    = [CPString UUID];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorSnapshot}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorSnapshotTake}];

    [stanza addChildWithName:@"domainsnapshot"];

    [stanza addChildWithName:@"name"];
    [stanza addTextNode:[fieldNewSnapshotName stringValue]];
    [stanza up];

    [stanza addChildWithName:@"description"];
    [stanza addTextNode:[[fieldNewSnapshotDescription stringValue] stringByReplacingOccurrencesOfString:@"\n" withString:@""]];
    //[stanza addTextNode:[fieldNewSnapshotDescription stringValue]];
    [stanza up];

    [self sendStanza:stanza andRegisterSelector:@selector(_didTakeSnapshot:)];

    [windowNewSnapshot orderOut:nil];
    [fieldNewSnapshotName setStringValue:nil];
    [fieldNewSnapshotDescription setStringValue:nil];
}

/*! compute virtual machine answer about taking a snapshot
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)_didTakeSnapshot:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Snapshot" message:@"Snapshoting sucessfull"];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}

/*! asks virtual machine to delete a snapshot
*/
- (void)deleteSnapshot
{
    var selectedIndexes = [_outlineViewSnapshots selectedRowIndexes];

    if ([selectedIndexes count] > 1)
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Snapshot" message:@"You must select only one snapshot" icon:TNGrowlIconError];

        return;
    }

    if ([_outlineViewSnapshots numberOfSelectedRows] == 0)
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Snapshot" message:@"You must select one snapshot" icon:TNGrowlIconError];

        return;
    }

    var alert = [TNAlert alertWithMessage:@"Delete to snapshot"
                                informative:@"Are you sure you want to destory this snapshot ? this is not reversible."
                                 target:self
                                 actions:[["Delete", @selector(performDeleteSnapshot:)], ["Cancel", nil]]];
    [alert runModal];
}

/*! asks virtual machine to take a snapshot
*/
- (void)performDeleteSnapshot:(id)someUserInfo
{
    var selectedIndexes = [_outlineViewSnapshots selectedRowIndexes],
        stanza          = [TNStropheStanza iqWithType:@"set"],
        object          = [_outlineViewSnapshots itemAtRow:[selectedIndexes firstIndex]],
        name            = [object name];


    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorSnapshot}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorSnapshotDelete,
        "name": name}];

    [self sendStanza:stanza andRegisterSelector:@selector(_didDeleteSnapshot:)];

}

/*! compute virtual machine answer about deleting a snapshot
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)_didDeleteSnapshot:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Snapshot" message:@"Snapshot deleted"];
    }
    else if ([aStanza type] == @"error")
    {
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}

/*! asks virtual machine to revert to a snapshot. but ask confirmation before
*/
- (void)revertSnapshot
{
    if ([_outlineViewSnapshots numberOfSelectedRows] == 0)
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Snapshot" message:@"You must select one snapshot" icon:TNGrowlIconError];

        return;
    }

    var alert = [TNAlert alertWithMessage:@"Revert to snapshot"
                                informative:@"Are you sure you want to revert to this snasphot ? All unsnapshoted changes will be lost."
                                 target:self
                                 actions:[["Revert", @selector(performRevertSnapshot:)], ["Cancel", nil]]];
    [alert runModal];
}

/*! asks virtual machine to revert to a snapshot
*/
- (void)performRevertSnapshot:(id)someUserInfo
{
    var stanza          = [TNStropheStanza iqWithType:@"set"],
        selectedIndexes   = [_outlineViewSnapshots selectedRowIndexes];

    if ([selectedIndexes count] > 1)
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Snapshot" message:@"You must select only one snapshot" icon:TNGrowlIconError];

        return;
    }

    var object  = [_outlineViewSnapshots itemAtRow:[selectedIndexes firstIndex]],
        name    = [object name];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorSnapshot}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorSnapshotRevert,
        "name": name}];

    [self sendStanza:stanza andRegisterSelector:@selector(_didRevertSnapshot:)];
}

/*! compute virtual machine answer about reverting to a snapshot
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)_didRevertSnapshot:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Snapshot" message:@"Snapshot sucessfully reverted"];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}


#pragma mark -
#pragma mark Delegates

- (void)outlineViewSelectionDidChange:(CPNotification)aNotification
{
    [_revertButton setEnabled:NO];
    [_minusButton setEnabled:NO];

    if ([_outlineViewSnapshots numberOfSelectedRows] > 0)
    {
        [_minusButton setEnabled:YES];
        [_revertButton setEnabled:YES];
    }
}

- (void)outlineViewItemWillExpand:(CPNotification)aNotification
{
    var item        = [[aNotification userInfo] valueForKey:@"CPObject"],
        defaults    = [CPUserDefaults standardUserDefaults],
        key         = TNArchipelSnapshotsOpenedSnapshots + [item name];

    [defaults setObject:"expanded" forKey:key];
}

- (void)outlineViewItemWillCollapse:(CPNotification)aNotification
{
    var item        = [[aNotification userInfo] valueForKey:@"CPObject"],
        defaults    = [CPUserDefaults standardUserDefaults],
        key         = TNArchipelSnapshotsOpenedSnapshots + [item name];

    [defaults setObject:"collapsed" forKey:key];
}

- (int)tableView:(CPTableView)aTableView heightOfRow:(int)aRow
{
    // FIXME : wait for Cappuccino to implement this.
    return 10.0;
}

@end
