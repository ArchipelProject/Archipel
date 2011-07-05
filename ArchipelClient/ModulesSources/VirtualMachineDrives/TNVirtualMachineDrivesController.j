/*
 * TNViewHypervisorControl.j
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
@import <AppKit/CPTableView.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPView.j>

@import <TNKit/TNAlert.j>
@import <TNKit/TNTableViewDataSource.j>

@import "TNNewDriveController.j"
@import "TNEditDriveController.j"


var TNArchipelTypeVirtualMachineDisk        = @"archipel:vm:disk",
    TNArchipelTypeVirtualMachineDiskCreate  = @"create",
    TNArchipelTypeVirtualMachineDiskDelete  = @"delete",
    TNArchipelTypeVirtualMachineDiskGet     = @"get",
    TNArchipelPushNotificationDisk          = @"archipel:push:disk",
    TNArchipelPushNotificationAppliance     = @"archipel:push:vmcasting",
    TNArchipelPushNotificationDiskCreated   = @"created";

TNArchipelDrivesFormats = [@"qcow2", @"qcow", @"cow", @"raw", @"vmdk"];

/*! @defgroup  virtualmachinedrives Module VirtualMachine Drives
    @desc Allows to create and manage virtual drives
*/

/*! @ingroup virtualmachinedrives
    main class of the module
*/
@implementation TNVirtualMachineDrivesController : TNModule
{
    @outlet CPButtonBar             buttonBarControl;
    @outlet CPSearchField           fieldFilter;
    @outlet CPView                  viewTableContainer;
    @outlet TNEditDriveController   editDriveController;
    @outlet TNNewDriveController    newDriveController;
    @outlet CPTableView             tableMedias;
    BOOL                            _isEntityOnline               @accessors(getter=isEntityOnline);

    CPButton                        _editButton;
    CPButton                        _minusButton;
    CPButton                        _plusButton;

    id                              _registredDiskListeningId;
    TNTableViewDataSource           _mediasDatasource;
}


#pragma mark -
#pragma mark Initialization

/*! called at cib awaking
*/
- (void)awakeFromCib
{
    [viewTableContainer setBorderedWithHexColor:@"#C0C7D2"];

    var bundle = [CPBundle mainBundle];

    // Media table view
    _mediasDatasource    = [[TNTableViewDataSource alloc] init];
    [tableMedias setTarget:self];
    [tableMedias setDoubleAction:@selector(openEditWindow:)];
    [tableMedias setDelegate:self];

    [_mediasDatasource setTable:tableMedias];
    [_mediasDatasource setSearchableKeyPaths:[@"name", @"format", @"virtualSize", @"diskSize", @"path", @"backingFile"]];

    [tableMedias setDataSource:_mediasDatasource];

    [fieldFilter setTarget:_mediasDatasource];
    [fieldFilter setAction:@selector(filterObjects:)];

    var menu = [[CPMenu alloc] init];
    [menu addItemWithTitle:CPBundleLocalizedString(@"Rename", @"Rename") action:@selector(openEditWindow:) keyEquivalent:@""];
    [menu addItemWithTitle:CPBundleLocalizedString(@"Delete", @"Delete") action:@selector(removeDisk:) keyEquivalent:@""];
    [tableMedias setMenu:menu];

    _plusButton  = [CPButtonBar plusButton];
    [_plusButton setTarget:self];
    [_plusButton setAction:@selector(openNewDiskWindow:)];
    [_plusButton setToolTip:CPBundleLocalizedString(@"Create a new virtual drive", @"Create a new virtual drive")];

    _minusButton  = [CPButtonBar minusButton];
    [_minusButton setTarget:self];
    [_minusButton setAction:@selector(removeDisk:)];
    [_minusButton setEnabled:NO];
    [_minusButton setToolTip:CPBundleLocalizedString(@"Delete selected virtual drives", @"Delete selected virtual drives")];

    _editButton  = [CPButtonBar plusButton];
    [_editButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/edit.png"] size:CPSizeMake(16, 16)]];
    [_editButton setTarget:self];
    [_editButton setAction:@selector(openEditWindow:)];
    [_editButton setEnabled:NO];
    [_editButton setToolTip:CPBundleLocalizedString(@"Edit selected virtual drive", @"Edit selected virtual drive")];

    [buttonBarControl setButtons:[_plusButton, _minusButton, _editButton]];

    [newDriveController setDelegate:self];
    [editDriveController setDelegate:self];
}


#pragma mark -
#pragma mark TNModule overrides

/*! called when module is loaded
*/
- (void)willLoad
{
    [super willLoad];

    _registredDiskListeningId = nil;

    var params = [[CPDictionary alloc] init],
        center = [CPNotificationCenter defaultCenter];

    [self registerSelector:@selector(_didReceivePush:) forPushNotificationType:TNArchipelPushNotificationDisk]
    [self registerSelector:@selector(_didReceivePush:) forPushNotificationType:TNArchipelPushNotificationAppliance]

    [center addObserver:self selector:@selector(_didUpdatePresence:) name:TNStropheContactPresenceUpdatedNotification object:_entity];
    [center postNotificationName:TNArchipelModulesReadyNotification object:self];

    [tableMedias setDelegate:nil];
    [tableMedias setDelegate:self];

    [self getDisksInfo];
}

/*! called when module becomes visible
*/
- (BOOL)willShow
{
    if (![super willShow])
        return NO;

    [self checkIfRunning];
    [self getDisksInfo];

    return YES;
}

/*! called when MainMenu is ready
*/
- (void)menuReady
{
    [[_menu addItemWithTitle:CPBundleLocalizedString(@"Create a drive", @"Create a drive") action:@selector(openNewDiskWindow:) keyEquivalent:@""] setTarget:self];
    [[_menu addItemWithTitle:CPBundleLocalizedString(@"Edit selected drive", @"Edit selected drive") action:@selector(openEditWindow:) keyEquivalent:@""] setTarget:self];
    [_menu addItem:[CPMenuItem separatorItem]];
    [[_menu addItemWithTitle:CPBundleLocalizedString(@"Delete selected drive", @"Delete selected drive") action:@selector(removeDisk:) keyEquivalent:@""] setTarget:self];
}

/*! called when permissions changes
*/
- (void)permissionsChanged
{
    if (![self currentEntityHasPermission:@"drives_create"])
        [newDriveController closeMainWindow];

    if (![self currentEntityHasPermissions:[@"drives_convert", @"drives_rename"]])
        [editDriveController closeMainWindow];

    [self tableViewSelectionDidChange:nil];
}


#pragma mark -
#pragma mark Notification handlers

/*! called if entity changes it presence and call checkIfRunning
    @param aNotification the notification
*/
- (void)_didUpdatePresence:(CPNotification)aNotification
{
    if ([aNotification object] == _entity)
    {
        [self checkIfRunning];
    }
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

    if (type == TNArchipelPushNotificationDisk)
    {
        if (change == @"created")
            [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:CPBundleLocalizedString(@"Disk", @"Disk")
                                                             message:CPBundleLocalizedString(@"Disk has been created", @"Disk has been created")];
        else if (change == @"deleted")
            [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:CPBundleLocalizedString(@"Disk", @"Disk")
                                                             message:CPBundleLocalizedString(@"Disk has been removed", @"Disk has been removed")];
    }

    [self getDisksInfo];

    return YES;
}


#pragma mark -
#pragma mark  Utilities

/*! checks if virtual machine is running. if yes, display ythe masking view
*/
- (void)checkIfRunning
{
    var XMPPShow = [_entity XMPPShow];

    _isEntityOnline = ((XMPPShow == TNStropheContactStatusOnline) || (XMPPShow == TNStropheContactStatusAway));

    if (XMPPShow == TNStropheContactStatusBusy)
        [self showMaskView:NO];
    else
        [self showMaskView:YES];
}


#pragma mark -
#pragma mark Actions

/*! opens the new disk window
    @param aSender the sender of the action
*/
- (IBAction)openNewDiskWindow:(id)aSender
{
    [newDriveController openMainWindow];
}

/*! opens the rename window
    @param aSender the sender of the action
*/
- (IBAction)openEditWindow:(id)aSender
{
    if (![self currentEntityHasPermissions:[@"drives_convert", @"drives_rename"]])
        return;

    if (_isEntityOnline)
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:CPBundleLocalizedString(@"Disk", @"Disk")
                                                         message:CPBundleLocalizedString(@"You can't edit disks of a running virtual machine", @"You can't edit disks of a running virtual machine")
                                                            icon:TNGrowlIconError];
    }
    else
    {
        if (([tableMedias numberOfRows]) && ([tableMedias numberOfSelectedRows] <= 0))
             return;

        if ([tableMedias numberOfSelectedRows] > 1)
        {
            [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:CPBundleLocalizedString(@"Disk", @"Disk")
                                                             message:CPBundleLocalizedString(@"You can't edit multiple disk", @"You can't edit multiple disk")
                                                                icon:TNGrowlIconError];
            return;
        }

        var selectedIndex   = [[tableMedias selectedRowIndexes] firstIndex],
            diskObject      = [_mediasDatasource objectAtIndex:selectedIndex];

        [editDriveController setCurrentEditedDisk:diskObject];
        [editDriveController openMainWindow];
    }
}

/*! remove a disk
    @param aSender the sender of the action
*/
- (IBAction)removeDisk:(id)aSender
{
    [self removeDisk];
}


#pragma mark -
#pragma mark XMPP Controls

/*! ask virtual machine for its disks
*/
- (void)getDisksInfo
{
    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeVirtualMachineDisk}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeVirtualMachineDiskGet}];

    [self setModuleStatus:TNArchipelModuleStatusWaiting];
    [_entity sendStanza:stanza andRegisterSelector:@selector(_didReceiveDisksInfo:) ofObject:self];
}

/*! compute virtual machine disk
    @param aStanza TNStropheStanza that contains the answer
*/
- (BOOL)_didReceiveDisksInfo:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        [_mediasDatasource removeAllObjects];
        var disks = [aStanza childrenWithName:@"disk"];

        for (var i = 0; i < [disks count]; i++)
        {
            var disk        = [disks objectAtIndex:i],
                vSize       = [[[disk valueForAttribute:@"virtualSize"] componentsSeparatedByString:@" "] objectAtIndex:0],
                dSize       = [[[disk valueForAttribute:@"diskSize"] componentsSeparatedByString:@" "] objectAtIndex:0],
                path        = [disk valueForAttribute:@"path"],
                name        = [disk valueForAttribute:@"name"],
                format      = [disk valueForAttribute:@"format"],
                backingFile = [disk valueForAttribute:@"backingFile"];

            [_mediasDatasource addObject:[CPDictionary dictionaryWithObjectsAndKeys:path, @"path",
                                                                                    name, @"name",
                                                                                    format, @"format",
                                                                                    vSize, @"virtualSize",
                                                                                    dSize, @"diskSize",
                                                                                    backingFile, @"backingFile"]];
        }
        [tableMedias reloadData];
        [self setModuleStatus:TNArchipelModuleStatusReady];
    }
    else
    {
        [self setModuleStatus:TNArchipelModuleStatusError];
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}

/*! asks virtual machine to remove a disk. but before ask a confirmation
*/
- (void)removeDisk
{
    if (([tableMedias numberOfRows]) && ([tableMedias numberOfSelectedRows] <= 0))
    {
         [TNAlert showAlertWithMessage:CPBundleLocalizedString(@"Error", @"Error")
                           informative:CPBundleLocalizedString(@"You must select a media", @"You must select a media")];
         return;
    }

    var alert = [TNAlert alertWithMessage:CPBundleLocalizedString(@"Delete to drive", @"Delete to drive")
                                informative:CPBundleLocalizedString(@"Are you sure you want to destroy this drive ? this is not reversible.", @"Are you sure you want to destroy this drive ? this is not reversible.")
                                 target:self
                                 actions:[[CPBundleLocalizedString(@"Delete", @"Delete"), @selector(performRemoveDisk:)], [CPBundleLocalizedString(@"Cancel", @"Cancel"), nil]]];
    [alert runModal];
}

/*! asks virtual machine to remove a disk
*/
- (void)performRemoveDisk:(id)someUserInfo
{
    var selectedIndexes = [tableMedias selectedRowIndexes],
        objects         = [_mediasDatasource objectsAtIndexes:selectedIndexes];

    for (var i = 0; i < [objects count]; i++)
    {
        var dName   = [objects objectAtIndex:i],
            stanza  = [TNStropheStanza iqWithType:@"set"];

        [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeVirtualMachineDisk}];
        [stanza addChildWithName:@"archipel" andAttributes:{
            "xmlns": TNArchipelTypeVirtualMachineDisk,
            "action": TNArchipelTypeVirtualMachineDiskDelete,
            "name": [dName objectForKey:@"path"],
            "undefine": "yes"}];

        [_entity sendStanza:stanza andRegisterSelector:@selector(_didRemoveDisk:) ofObject:self];
    }
}

/*! compute virtual machine disk removing results
    @param aStanza TNStropheStanza that contains the answer
*/
- (BOOL)_didRemoveDisk:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"error")
    {
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}


#pragma mark -
#pragma mark Delegates

- (void)tableViewSelectionDidChange:(CPTableView)aTableView
{
    [self setControl:_plusButton enabledAccordingToPermission:@"drives_create"];
    [self setControl:_minusButton enabledAccordingToPermission:@"drives_delete" specialCondition:([tableMedias numberOfSelectedRows] > 0)];
    [self setControl:_editButton enabledAccordingToPermissions:[@"drives_convert", @"drives_rename"] specialCondition:([tableMedias numberOfSelectedRows] <= 0)];
}


@end


// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNVirtualMachineDrivesController], comment);
}

