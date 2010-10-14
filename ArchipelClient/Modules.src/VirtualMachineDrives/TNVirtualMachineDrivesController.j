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
@import <AppKit/AppKit.j>

@import "TNMediaObject.j";

TNArchipelTypeVirtualMachineDisk       = @"archipel:vm:disk";
TNArchipelTypeVirtualMachineDiskCreate  = @"create";
TNArchipelTypeVirtualMachineDiskDelete  = @"delete";
TNArchipelTypeVirtualMachineDiskGet     = @"get";
TNArchipelTypeVirtualMachineDiskConvert = @"convert";
TNArchipelTypeVirtualMachineDiskRename  = @"rename";

TNArchipelPushNotificationDisk           = @"archipel:push:disk";
TNArchipelPushNotificationAppliance      = @"archipel:push:vmcasting";
TNArchipelPushNotificationDiskCreated    = @"created";


/*! @defgroup  virtualmachinedrives Module VirtualMachine Drives
    @desc Allows to create and manage virtual drives
*/

/*! @ingroup virtualmachinedrives
    main class of the module
*/
@implementation TNVirtualMachineDrivesController : TNModule
{
    @outlet CPButton        buttonConvert;
    @outlet CPButtonBar     buttonBarControl;
    @outlet CPImageView     imageViewConverting;
    @outlet CPPopUpButton   buttonEditDiskFormat;
    @outlet CPPopUpButton   buttonNewDiskFormat;
    @outlet CPPopUpButton   buttonNewDiskSizeUnit;
    @outlet CPScrollView    scrollViewDisks;
    @outlet CPSearchField   fieldFilter;
    @outlet CPTextField     fieldEditDiskName;
    @outlet CPTextField     fieldJID;
    @outlet CPTextField     fieldName;
    @outlet CPTextField     fieldNewDiskName;
    @outlet CPTextField     fieldNewDiskSize;
    @outlet CPView          maskingView;
    @outlet CPView          viewTableContainer;
    @outlet CPWindow        windowDiskProperties;
    @outlet CPWindow        windowNewDisk;

    BOOL                    _isActive;
    CPButton                _editButton;
    CPButton                _minusButton;
    CPButton                _plusButton;
    CPTableView             _tableMedias;
    id                      _registredDiskListeningId;
    TNMedia                 _currentEditedDisk;
    TNTableViewDataSource   _mediasDatasource;
}

#pragma mark -
#pragma mark Initialization

/*! called at cib awaking
*/
- (void)awakeFromCib
{
    [fieldJID setSelectable:YES];

    [viewTableContainer setBorderedWithHexColor:@"#C0C7D2"];

    [buttonNewDiskSizeUnit removeAllItems];
    [buttonNewDiskSizeUnit addItemsWithTitles:["Go", "Mo"]];

    var formats = [@"qcow2", @"qcow", @"cow", @"raw", @"vmdk"];
    [buttonNewDiskFormat removeAllItems];
    [buttonNewDiskFormat addItemsWithTitles:formats];

    [buttonEditDiskFormat removeAllItems];
    [buttonEditDiskFormat addItemsWithTitles:formats];

    var bundle = [CPBundle mainBundle];
    [imageViewConverting setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"spinner.gif"]]];
    [imageViewConverting setHidden:YES];

    // Media table view
    _mediasDatasource    = [[TNTableViewDataSource alloc] init];
    _tableMedias         = [[CPTableView alloc] initWithFrame:[scrollViewDisks bounds]];

    [scrollViewDisks setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [scrollViewDisks setAutohidesScrollers:YES];
    [scrollViewDisks setDocumentView:_tableMedias];

    [_tableMedias setUsesAlternatingRowBackgroundColors:YES];
    [_tableMedias setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [_tableMedias setAllowsColumnReordering:YES];
    [_tableMedias setAllowsColumnResizing:YES];
    [_tableMedias setAllowsEmptySelection:YES];
    [_tableMedias setAllowsMultipleSelection:YES];
    [_tableMedias setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];

    var mediaColumName = [[CPTableColumn alloc] initWithIdentifier:@"name"],
        mediaColumFormat = [[CPTableColumn alloc] initWithIdentifier:@"format"],
        mediaColumVirtualSize = [[CPTableColumn alloc] initWithIdentifier:@"virtualSize"],
        mediaColumDiskSize = [[CPTableColumn alloc] initWithIdentifier:@"diskSize"],
        mediaColumPath = [[CPTableColumn alloc] initWithIdentifier:@"path"];

    [mediaColumName setWidth:150];
    [[mediaColumName headerView] setStringValue:@"Name"];
    [mediaColumName setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];

    [mediaColumFormat setWidth:80];
    [[mediaColumFormat headerView] setStringValue:@"Format"];
    [mediaColumFormat setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"format" ascending:YES]];

    [mediaColumVirtualSize setWidth:80];
    [[mediaColumVirtualSize headerView] setStringValue:@"Virtual size"];
    [mediaColumVirtualSize setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"virtualSize" ascending:YES]];

    [mediaColumDiskSize setWidth:80];
    [[mediaColumDiskSize headerView] setStringValue:@"Real size"];
    [mediaColumDiskSize setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"diskSize" ascending:YES]];

    [mediaColumPath setWidth:300];
    [[mediaColumPath headerView] setStringValue:@"Path"];
    [mediaColumPath setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"path" ascending:YES]];

    [_tableMedias addTableColumn:mediaColumName];
    [_tableMedias addTableColumn:mediaColumFormat];
    [_tableMedias addTableColumn:mediaColumVirtualSize];
    [_tableMedias addTableColumn:mediaColumDiskSize];
    [_tableMedias addTableColumn:mediaColumPath];

    [_tableMedias setTarget:self];
    [_tableMedias setDoubleAction:@selector(openRenamePanel:)];
    [_tableMedias setDelegate:self];

    [_mediasDatasource setTable:_tableMedias];
    [_mediasDatasource setSearchableKeyPaths:[@"name", @"format", @"virtualSize", @"diskSize", @"path"]];

    [_tableMedias setDataSource:_mediasDatasource];

    [fieldNewDiskName setValue:[CPColor grayColor] forThemeAttribute:@"text-color" inState:CPTextFieldStatePlaceholder];
    [fieldNewDiskSize setValue:[CPColor grayColor] forThemeAttribute:@"text-color" inState:CPTextFieldStatePlaceholder];

    [fieldFilter setTarget:_mediasDatasource];
    [fieldFilter setAction:@selector(filterObjects:)];

    var menu = [[CPMenu alloc] init];
    [menu addItemWithTitle:@"Rename" action:@selector(openRenamePanel:) keyEquivalent:@""];
    [menu addItemWithTitle:@"Delete" action:@selector(removeDisk:) keyEquivalent:@""];
    [_tableMedias setMenu:menu];

    _plusButton  = [CPButtonBar plusButton];
    [_plusButton setTarget:self];
    [_plusButton setAction:@selector(openNewDiskWindow:)];

    _minusButton  = [CPButtonBar minusButton];
    [_minusButton setTarget:self];
    [_minusButton setAction:@selector(removeDisk:)];

    _editButton  = [CPButtonBar plusButton];
    [_editButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-edit.png"] size:CPSizeMake(16, 16)]];
    [_editButton setTarget:self];
    [_editButton setAction:@selector(openRenamePanel:)];

    [_editButton setEnabled:NO];
    [_minusButton setEnabled:NO];

    [buttonBarControl setButtons:[_plusButton, _minusButton, _editButton]];

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

    [center addObserver:self selector:@selector(_didUpdateNickName:) name:TNStropheContactNicknameUpdatedNotification object:_entity];
    [center addObserver:self selector:@selector(_didUpdatePresence:) name:TNStropheContactPresenceUpdatedNotification object:_entity];
    [center postNotificationName:TNArchipelModulesReadyNotification object:self];

    [_tableMedias setDelegate:nil];
    [_tableMedias setDelegate:self]; // hum....

    [self getDisksInfo];
}

/*! called when module becomes visible
*/
- (void)willShow
{
    [super willShow];

    [fieldName setStringValue:[_entity nickname]];
    [fieldJID setStringValue:[_entity JID]];

    [self checkIfRunning];
    [self getDisksInfo];
}

/*! called when MainMenu is ready
*/
- (void)menuReady
{
    [[_menu addItemWithTitle:@"Create a drive" action:@selector(openNewDiskWindow:) keyEquivalent:@""] setTarget:self];
    [[_menu addItemWithTitle:@"Edit selected drive" action:@selector(openRenamePanel:) keyEquivalent:@""] setTarget:self];
    [_menu addItem:[CPMenuItem separatorItem]];
    [[_menu addItemWithTitle:@"Delete selected drive" action:@selector(removeDisk:) keyEquivalent:@""] setTarget:self];
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
            [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Disk" message:@"Disk has been created"];
        else if (change == @"deleted")
            [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Disk" message:@"Disk has been removed"];
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

    _isActive = ((XMPPShow == TNStropheContactStatusOnline) || (XMPPShow == TNStropheContactStatusAway));

    if (XMPPShow == TNStropheContactStatusBusy)
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

/*! opens the new disk window
    @param aSender the sender of the action
*/
- (IBAction)openNewDiskWindow:(id)aSender
{
    [fieldNewDiskName setStringValue:@""];
    [fieldNewDiskSize setStringValue:@""];
    [buttonNewDiskFormat selectItemWithTitle:@"qcow2"];
    [windowNewDisk makeFirstResponder:fieldNewDiskName];
    [windowNewDisk center];
    [windowNewDisk makeKeyAndOrderFront:nil];
}

/*! opens the rename window
    @param aSender the sender of the action
*/
- (IBAction)openRenamePanel:(id)aSender
{
    if (_isActive)
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Disk" message:@"You can't edit disks of a running virtual machine" icon:TNGrowlIconError];
    else
    {
        if (([_tableMedias numberOfRows]) && ([_tableMedias numberOfSelectedRows] <= 0))
             return;

        if ([_tableMedias numberOfSelectedRows] > 1)
        {
            [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Disk" message:@"You can't edit multiple disk" icon:TNGrowlIconError];
            return;
        }

        var selectedIndex   = [[_tableMedias selectedRowIndexes] firstIndex],
            diskObject      = [_mediasDatasource objectAtIndex:selectedIndex];

        [windowDiskProperties center];
        [windowDiskProperties makeKeyAndOrderFront:nil];
        [fieldEditDiskName setStringValue:[diskObject name]];

        _currentEditedDisk = diskObject;
    }
}

/*! creates a disk
    @param aSender the sender of the action
*/
- (IBAction)createDisk:(id)aSender
{
    [self createDisk];
}

/*! converts a disk
    @param aSender the sender of the action
*/
- (IBAction)convert:(id)aSender
{
    [self convert];
}

/*! rename a disk
    @param aSender the sender of the action
*/
- (IBAction)rename:(id)aSender
{
    [self rename];
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
            var disk    = [disks objectAtIndex:i],
                vSize   = [[[disk valueForAttribute:@"virtualSize"] componentsSeparatedByString:@" "] objectAtIndex:0],
                dSize   = [[[disk valueForAttribute:@"diskSize"] componentsSeparatedByString:@" "] objectAtIndex:0],
                path    = [disk valueForAttribute:@"path"],
                name    = [disk valueForAttribute:@"name"],
                format  = [disk valueForAttribute:@"format"],
                newMedia = [TNMedia mediaWithPath:path name:name format:format virtualSize:vSize diskSize:dSize];

            [_mediasDatasource addObject:newMedia];
        }
        [_tableMedias reloadData];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}

/*! asks virtual machine to create a new disk
*/
- (void)createDisk
{
    var dUnit,
        dName       = [fieldNewDiskName stringValue],
        dSize       = [fieldNewDiskSize stringValue],
        format      = [buttonNewDiskFormat title];

    if (dSize == @"" || isNaN(dSize))
    {
        [CPAlert alertWithTitle:@"Error" message:@"You must enter a numeric value" style:CPCriticalAlertStyle];
        return;
    }

    if (dName == @"")
    {
        [CPAlert alertWithTitle:@"Error" message:@"You must enter a valid name" style:CPCriticalAlertStyle];
        return;
    }

    switch ([buttonNewDiskSizeUnit title])
    {
        case "Go":
            dUnit = "G";
            break;

        case "Mo":
            dUnit = "M";
            break;
    }


    var stanza  = [TNStropheStanza iqWithType:@"set"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeVirtualMachineDisk}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeVirtualMachineDiskCreate,
        "name": dName,
        "size": dSize,
        "unit": dUnit,
        "format": format}];

    [_entity sendStanza:stanza andRegisterSelector:@selector(_didCreateDisk:) ofObject:self];

    [windowNewDisk orderOut:nil];
    [fieldNewDiskName setStringValue:@""];
    [fieldNewDiskSize setStringValue:@""];
}

/*! compute virtual machine disk creation results
    @param aStanza TNStropheStanza that contains the answer
*/
- (BOOL)_didCreateDisk:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"error")
    {
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}

/*! asks virtual machine to connvert a disk
*/
- (void)convert
{
    if (([_tableMedias numberOfRows]) && ([_tableMedias numberOfSelectedRows] <= 0))
    {
         [CPAlert alertWithTitle:@"Error" message:@"You must select a media"];
         return;
    }

    if (_currentEditedDisk && [_currentEditedDisk format] == [buttonEditDiskFormat title])
    {
        [CPAlert alertWithTitle:@"Error" message:@"You must choose a different format"];
        return;

    }

    var selectedIndex   = [[_tableMedias selectedRowIndexes] firstIndex],
        dName           = [_mediasDatasource objectAtIndex:selectedIndex],
        stanza          = [TNStropheStanza iqWithType:@"set"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeVirtualMachineDisk}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeVirtualMachineDiskConvert,
        "path": [dName path],
        "format": [buttonEditDiskFormat title]}];

    [windowDiskProperties orderOut:nil];

    [imageViewConverting setHidden:NO];
    [_entity sendStanza:stanza andRegisterSelector:@selector(_didConvertDisk:) ofObject:self];
}

/*! compute virtual machine disk conversion results
    @param aStanza TNStropheStanza that contains the answer
*/
- (BOOL)_didConvertDisk:(TNStropheStanza)aStanza
{
    [imageViewConverting setHidden:YES];

    if ([aStanza type] == @"result")
    {
        var growl   = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Disk" message:@"Disk has been converted"];
    }
    else if ([aStanza type] == @"error")
    {
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}

/*! asks virtual machine to rename a disk
*/
- (void)rename
{
    [windowDiskProperties orderOut:nil];

    if (_isActive)
    {
        var growl   = [TNGrowlCenter defaultCenter];

        [growl pushNotificationWithTitle:@"Disk" message:@"You can't edit disks of a running virtual machine" icon:TNGrowlIconError];

        return;
    }

    if ([fieldEditDiskName stringValue] != [_currentEditedDisk name])
    {
        [_currentEditedDisk setName:[fieldEditDiskName stringValue]];
        [self rename:_currentEditedDisk];

        var stanza      = [TNStropheStanza iqWithType:@"set"];

        [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeVirtualMachineDisk}];
        [stanza addChildWithName:@"archipel" andAttributes:{
            "xmlns": TNArchipelTypeVirtualMachineDisk,
            "action": TNArchipelTypeVirtualMachineDiskRename,
            "path": [_currentEditedDisk path],
            "newname": [_currentEditedDisk name]}];

        [_entity sendStanza:stanza andRegisterSelector:@selector(_didRename:) ofObject:self];

        _currentEditedDisk = nil;
    }
}

/*! compute virtual machine disk renaming results
    @param aStanza TNStropheStanza that contains the answer
*/
- (BOOL)_didRename:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        var growl   = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Disk" message:@"Disk has been renamed"];
    }
    else if ([aStanza type] == @"error")
    {
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}

/*! asks virtual machine to remove a disk. but before ask a confirmation
*/
- (void)removeDisk
{
    if (([_tableMedias numberOfRows]) && ([_tableMedias numberOfSelectedRows] <= 0))
    {
         [CPAlert alertWithTitle:@"Error" message:@"You must select a media"];
         return;
    }

    var alert = [TNAlert alertWithTitle:@"Delete to drive"
                                message:@"Are you sure you want to destroy this drive ? this is not reversible."
                                delegate:self
                                 actions:[["Delete", @selector(performRemoveDisk:)], ["Cancel", nil]]];
    [alert runModal];
}

/*! asks virtual machine to remove a disk
*/
- (void)performRemoveDisk:(id)someUserInfo
{
    var selectedIndexes = [_tableMedias selectedRowIndexes],
        objects         = [_mediasDatasource objectsAtIndexes:selectedIndexes];

    for (var i = 0; i < [objects count]; i++)
    {
        var dName   = [objects objectAtIndex:i],
            stanza  = [TNStropheStanza iqWithType:@"set"];

        [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeVirtualMachineDisk}];
        [stanza addChildWithName:@"archipel" andAttributes:{
            "xmlns": TNArchipelTypeVirtualMachineDisk,
            "action": TNArchipelTypeVirtualMachineDiskDelete,
            "name": [dName path],
            "format": [buttonEditDiskFormat title],
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
    if ([_tableMedias numberOfSelectedRows] <= 0)
    {
        [_minusButton setEnabled:NO];
        [_editButton setEnabled:NO];
        return;
    }

    [_minusButton setEnabled:YES];
    [_editButton setEnabled:YES];

    var selectedIndex   = [[_tableMedias selectedRowIndexes] firstIndex],
        diskObject      = [_mediasDatasource objectAtIndex:selectedIndex];

    [buttonEditDiskFormat selectItemWithTitle:[diskObject format]];
}

@end



