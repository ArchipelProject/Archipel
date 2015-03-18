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
@import <AppKit/CPSearchField.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPOutlineView.j>
@import <AppKit/CPWindow.j>
@import <AppKit/CPPopover.j>

@import <LPKit/LPMultiLineTextField.j>
@import <TNKit/TNAlert.j>

@import "../../Model/TNModule.j"
@import "TNSnapshot.j"
@import "TNSnapshotsDatasource.j"

@global CPLocalizedString
@global CPLocalizedStringFromTableInBundle


var TNArchipelSnapshotsOpenedSnapshots          = @"TNArchipelSnapshotsOpenedSnapshots_",
    TNArchipelPushNotificationSnapshoting       = @"archipel:push:snapshoting",
    TNArchipelTypeHypervisorSnapshot            = @"archipel:virtualmachine:snapshoting",
    TNArchipelTypeHypervisorSnapshotTake        = @"take",
    TNArchipelTypeHypervisorSnapshotGet         = @"get",
    TNArchipelTypeHypervisorSnapshotCurrent     = @"current",
    TNArchipelTypeHypervisorSnapshotDelete      = @"delete",
    TNArchipelTypeHypervisorSnapshotRevert      = @"revert";

var TNModuleControlForTakeSnapshot               = @"TakeSnapshot",
    TNModuleControlForRevertToSnapshot           = @"RevertToSnapshot",
    TNModuleControlForRemoveSnapshot             = @"RemoveSnapshot";


/*! @defgroup  virtualmachinesnapshoting Module VirtualMachine Snapshots
    @desc Module to handle Virtual Machine snapshoting
*/

/*! @ingroup virtualmachinedrives
    main class of the module
*/
@implementation TNVirtualMachineSnapshotsController : TNModule
{
    @outlet CPButton                    buttonSnapshotTake;
    @outlet CPButtonBar                 buttonBarControl;
    @outlet CPPopover                   popoverNewSnapshot;
    @outlet CPScrollView                scrollViewSnapshots;
    @outlet CPSearchField               fieldFilter;
    @outlet CPTextField                 fieldInfo;
    @outlet CPTextField                 fieldNewSnapshotName;
    @outlet CPView                      viewTableContainer;
    @outlet LPMultiLineTextField        fieldNewSnapshotDescription;

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
    [viewTableContainer setBorderedWithHexColor:@"#F2F2F2"];

    // VM table view
    _datasourceSnapshots    = [[TNSnapshotsDatasource alloc] init];
    _outlineViewSnapshots   = [[CPOutlineView alloc] initWithFrame:[scrollViewSnapshots bounds]];

    [_datasourceSnapshots setParentKeyPath:@"parent"];
    [_datasourceSnapshots setChildCompKeyPath:@"name"];

    [scrollViewSnapshots setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [scrollViewSnapshots setAutohidesScrollers:YES];
    [scrollViewSnapshots setDocumentView:_outlineViewSnapshots];

    [_outlineViewSnapshots setUsesAlternatingRowBackgroundColors:YES];
    [_outlineViewSnapshots setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [_outlineViewSnapshots setAllowsColumnResizing:YES];
    [_outlineViewSnapshots setAllowsEmptySelection:YES];
    [_outlineViewSnapshots setAllowsMultipleSelection:NO];
    [_outlineViewSnapshots setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [_outlineViewSnapshots setDataSource:_datasourceSnapshots];

    var outlineColumn = [[CPTableColumn alloc] initWithIdentifier:@"outline"],
        columnName = [[CPTableColumn alloc] initWithIdentifier:@"name"],
        columnDescription = [[CPTableColumn alloc] initWithIdentifier:@"description"],
        columnCreationTime = [[CPTableColumn alloc] initWithIdentifier:@"creationTime"],
        columnState     = [[CPTableColumn alloc] initWithIdentifier:@"isCurrent"],
        imgView         = [[CPImageView alloc] initWithFrame:CGRectMake(0,0,16,16)];

    [outlineColumn setWidth:16];

    [[columnName headerView] setStringValue:CPBundleLocalizedString(@"UUID", @"UUID")];
    [columnName setWidth:100];
    [columnName setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];

    [[columnDescription headerView] setStringValue:CPBundleLocalizedString(@"Description", @"Description")];
    [columnDescription setWidth:400];
    [columnDescription setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"description" ascending:YES]];

    [[columnCreationTime headerView] setStringValue:CPBundleLocalizedString(@"Creation date", @"Creation date")];
    [columnCreationTime setWidth:130];
    [columnCreationTime setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"creationTime" ascending:YES]];

    [imgView setImageScaling:CPScaleNone];
    [columnState setDataView:imgView];
    [columnState setResizingMask:CPTableColumnAutoresizingMask ];
    [columnState setWidth:16];
    [[columnState headerView] setStringValue:@""];

    [_outlineViewSnapshots addTableColumn:columnState];
    [_outlineViewSnapshots addTableColumn:columnDescription];
    [_outlineViewSnapshots addTableColumn:columnCreationTime];
    [_outlineViewSnapshots addTableColumn:columnName];
    [_outlineViewSnapshots setOutlineTableColumn:columnDescription];
    [_outlineViewSnapshots setDelegate:self];
    [_outlineViewSnapshots setTarget:self];
    [_outlineViewSnapshots setDoubleAction:@selector(revertSnapshot:)];

    [fieldFilter setSendsSearchStringImmediately:YES];
    [fieldFilter setTarget:self];
    [fieldFilter setAction:@selector(fieldFilterDidChange:)];


    [self addControlsWithIdentifier:TNModuleControlForTakeSnapshot
                              title:CPBundleLocalizedString(@"Create a new snapshot", @"Create a new snapshot")
                             target:self
                             action:@selector(openWindowNewSnapshot:)
                              image:CPImageInBundle(@"IconsButtons/photo-add.png",nil, [CPBundle mainBundle])];

    [self addControlsWithIdentifier:TNModuleControlForRemoveSnapshot
                              title:CPBundleLocalizedString(@"Remove selected snapshot", @"Remove selected snapshot")
                             target:self
                             action:@selector(deleteSnapshot:)
                              image:CPImageInBundle(@"IconsButtons/photo-remove.png",nil, [CPBundle mainBundle])];

    [self addControlsWithIdentifier:TNModuleControlForRevertToSnapshot
                              title:CPBundleLocalizedString(@"Revert state to selected snapshot", @"Revert state to selected snapshot")
                             target:self
                             action:@selector(revertSnapshot:)
                              image:CPImageInBundle(@"IconsButtons/subscription-add.png",nil, [CPBundle mainBundle])];

    [buttonBarControl setButtons:[
        [self buttonWithIdentifier:TNModuleControlForTakeSnapshot],
        [self buttonWithIdentifier:TNModuleControlForRemoveSnapshot],
        [self buttonWithIdentifier:TNModuleControlForRevertToSnapshot]]];
}


#pragma mark -
#pragma mark TNModule overrides

/*! called when module is loaded
*/
- (BOOL)willShow
{
    if (![super willShow])
        return NO;

    [self registerSelector:@selector(_didReceivePush:) forPushNotificationType:TNArchipelPushNotificationSnapshoting];

    _currentSnapshot = nil;

    [_outlineViewSnapshots setDelegate:nil];
    [_outlineViewSnapshots setDelegate:self];

    [self getSnapshots];

    return YES;
}

/*! called when module is unloaded
*/
- (void)willUnload
{
    [_datasourceSnapshots removeAllObjects];
    [_outlineViewSnapshots reloadData];
    [_outlineViewSnapshots deselectAll];
    [[self buttonWithIdentifier:TNModuleControlForRevertToSnapshot] setEnabled:NO];
    [[self buttonWithIdentifier:TNModuleControlForRemoveSnapshot] setEnabled:NO];
    [popoverNewSnapshot close];

    [super willUnload];
}

/*! called when user permissions changed
*/
- (void)permissionsChanged
{
    [super permissionsChanged];
}

/*! called when the UI needs to be updated according to the permissions
*/
- (void)setUIAccordingToPermissions
{
    [self setControl:[self buttonWithIdentifier:TNModuleControlForTakeSnapshot] enabledAccordingToPermission:@"snapshot_take"];
    [self setControl:[self buttonWithIdentifier:TNModuleControlForRemoveSnapshot] enabledAccordingToPermission:@"snapshot_delete" specialCondition:([_outlineViewSnapshots numberOfSelectedRows] > 0)];
    [self setControl:[self buttonWithIdentifier:TNModuleControlForRevertToSnapshot] enabledAccordingToPermission:@"snapshot_revert" specialCondition:([_outlineViewSnapshots numberOfSelectedRows] > 0)];

    if (![self currentEntityHasPermission:@"snapshot_take"])
        [popoverNewSnapshot close];
}

/*! this message is used to flush the UI
*/
- (void)flushUI
{
    [_datasourceSnapshots removeAllObjects];
    [_outlineViewSnapshots reloadData];
}


#pragma mark -
#pragma mark Notification

/*! called when an Archipel push is received
    @param somePushInfo CPDictionary containing the push information
*/
- (BOOL)_didReceivePush:(CPDictionary)somePushInfo
{
    var sender  = [somePushInfo objectForKey:@"owner"],
        type    = [somePushInfo objectForKey:@"type"],
        change  = [somePushInfo objectForKey:@"change"],
        date    = [somePushInfo objectForKey:@"date"];

    [self getSnapshots];

    return YES;
}


#pragma mark -
#pragma mark  Actions

/*! update filter
    @param sender the sender of the action
*/
- (IBAction)fieldFilterDidChange:(id)aSender
{
    [_datasourceSnapshots setFilter:[fieldFilter stringValue]];
    [_outlineViewSnapshots reloadData];
    [_outlineViewSnapshots recoverExpandedWithBaseKey:TNArchipelSnapshotsOpenedSnapshots itemKeyPath:@"name"];
}

/*! opens the new snapshot window
    @param aSender the sender of the action
*/
- (IBAction)openWindowNewSnapshot:(id)aSender
{
    [self requestVisible];
    if (![self isVisible])
        return;

    [fieldNewSnapshotName setStringValue:@""];
    [fieldNewSnapshotDescription setStringValue:@""];
    [fieldNewSnapshotName setStringValue:[CPString UUID]];

    [popoverNewSnapshot close];
    [popoverNewSnapshot showRelativeToRect:nil ofView:[self buttonWithIdentifier:TNModuleControlForTakeSnapshot] preferredEdge:nil];
    [popoverNewSnapshot makeFirstResponder:fieldNewSnapshotDescription];
    [popoverNewSnapshot setDefaultButton:buttonSnapshotTake];
}

/*! close the new snapshot window
    @param aSender the sender of the action
*/
- (IBAction)closeWindowNewSnapshot:(id)aSender
{
    [popoverNewSnapshot close];
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
    [self requestVisible];
    if (![self isVisible])
        return;

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

    [self setModuleStatus:TNArchipelModuleStatusWaiting];
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
        [self setModuleStatus:TNArchipelModuleStatusReady];
    }
    else if ([aStanza type] == @"ignore")
    {
        [fieldInfo setStringValue:CPBundleLocalizedString(@"There is no snapshot for this virtual machine", @"There is no snapshot for this virtual machine")];
        [self setModuleStatus:TNArchipelModuleStatusReady];
    }
    else if ([aStanza type] == @"error")
    {
        [self setModuleStatus:TNArchipelModuleStatusError];
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
    [stanza up];

    [self sendStanza:stanza andRegisterSelector:@selector(_didTakeSnapshot:)];

    [popoverNewSnapshot close];
    [fieldNewSnapshotName setStringValue:@""];
    [fieldNewSnapshotDescription setStringValue:@""];
}

/*! compute virtual machine answer about taking a snapshot
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)_didTakeSnapshot:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[_entity name]
                                                         message:CPBundleLocalizedString(@"Snapshoting sucessfull", @"Snapshoting sucessfull")];
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
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[_entity name]
                                                         message:CPBundleLocalizedString(@"You must select only one snapshot", @"You must select only one snapshot")
                                                            icon:TNGrowlIconError];

        return;
    }

    if ([_outlineViewSnapshots numberOfSelectedRows] == 0)
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[_entity name]
                                                         message:CPBundleLocalizedString(@"You must select one snapshot", @"You must select one snapshot")
                                                            icon:TNGrowlIconError];

        return;
    }

    var alert = [TNAlert alertWithMessage:CPBundleLocalizedString(@"Delete to snapshot", @"Delete to snapshot")
                                informative:CPBundleLocalizedString(@"Are you sure you want to destory this snapshot ? this is not reversible.", @"Are you sure you want to destory this snapshot ? this is not reversible.")
                                 target:self
                                 actions:[[CPBundleLocalizedString(@"Delete", @"Delete"), @selector(performDeleteSnapshot:)], [CPBundleLocalizedString(@"Cancel", @"Cancel"), nil]]];
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
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[_entity name]
                                                         message:CPBundleLocalizedString(@"Snapshot deleted", @"Snapshot deleted")];
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
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[_entity name]
                                                         message:CPBundleLocalizedString(@"You must select one snapshot", @"You must select one snapshot")
                                                            icon:TNGrowlIconError];

        return;
    }

    var alert = [TNAlert alertWithMessage:CPBundleLocalizedString(@"Revert to snapshot", @"Revert to snapshot")
                                informative:CPBundleLocalizedString(@"Are you sure you want to revert to this snasphot ? All unsnapshoted changes will be lost.", @"Are you sure you want to revert to this snasphot ? All unsnapshoted changes will be lost.")
                                 target:self
                                 actions:[[CPBundleLocalizedString(@"Revert", @"Revert"), @selector(performRevertSnapshot:)], [CPBundleLocalizedString(@"Cancel", @"Cancel"), nil]]];
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
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[_entity name]
                                                         message:CPBundleLocalizedString(@"You must select only one snapshot", @"You must select only one snapshot")
                                                            icon:TNGrowlIconError];

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
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[_entity name]
                                                         message:CPBundleLocalizedString(@"Snapshot sucessfully reverted", @"Snapshot sucessfully reverted")];
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
    [[self buttonWithIdentifier:TNModuleControlForRevertToSnapshot] setEnabled:NO];
    [[self buttonWithIdentifier:TNModuleControlForRemoveSnapshot] setEnabled:NO];

    if ([_outlineViewSnapshots numberOfSelectedRows] > 0)
    {
        [self setControl:[self buttonWithIdentifier:TNModuleControlForRemoveSnapshot] enabledAccordingToPermission:@"snapshot_delete"];
        [self setControl:[self buttonWithIdentifier:TNModuleControlForRevertToSnapshot] enabledAccordingToPermission:@"snapshot_revert"];
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

/*! Delegate of CPOutlineView for Menu
*/
- (CPMenu)outlineView:(CPOutlineView)anOutlineView menuForTableColumn:(CPTableColumn)aTableColumn item:(int)anItem
{
    if ((anOutlineView != _outlineViewSnapshots) && ([anOutlineView numberOfSelectedRows] > 1))
        return;

    var itemRow = [anOutlineView rowForItem:anItem];
    if ([anOutlineView selectedRow] != itemRow)
        if (itemRow >= 0)
            [anOutlineView selectRowIndexes:[CPIndexSet indexSetWithIndex:itemRow] byExtendingSelection:NO];
        else
            [anOutlineView deselectAll];

    [_contextualMenu removeAllItems];

    if ([anOutlineView numberOfSelectedRows] == 0)
        {
           [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForTakeSnapshot]];
        }
    else
        {
           [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForRemoveSnapshot]];
           [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForRevertToSnapshot]];
        }

    return _contextualMenu;
}

/* Delegate of CPOutlineView for delete key event
*/
- (void)outlineViewDeleteKeyPressed:(CPOutlineView)anOutlineView
{
    if ([anOutlineView numberOfSelectedRows] == 0)
        return;

    [self deleteSnapshot:anOutlineView];
}

@end



// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNVirtualMachineSnapshotsController], comment);
}

