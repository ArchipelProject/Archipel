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
    
    var mediaColumName = [[CPTableColumn alloc] initWithIdentifier:@"name"];
    [mediaColumName setWidth:150];
    [[mediaColumName headerView] setStringValue:@"Name"];
    [mediaColumName setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
    
    var mediaColumFormat = [[CPTableColumn alloc] initWithIdentifier:@"format"];
    [mediaColumFormat setWidth:80];
    [[mediaColumFormat headerView] setStringValue:@"Format"];
    [mediaColumFormat setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"format" ascending:YES]];
    
    var mediaColumVirtualSize = [[CPTableColumn alloc] initWithIdentifier:@"virtualSize"];
    [mediaColumVirtualSize setWidth:80];
    [[mediaColumVirtualSize headerView] setStringValue:@"Virtual size"];
    [mediaColumVirtualSize setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"virtualSize" ascending:YES]];
    
    var mediaColumDiskSize = [[CPTableColumn alloc] initWithIdentifier:@"diskSize"];
    [mediaColumDiskSize setWidth:80];
    [[mediaColumDiskSize headerView] setStringValue:@"Real size"];
    [mediaColumDiskSize setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"diskSize" ascending:YES]];
    
    var mediaColumPath = [[CPTableColumn alloc] initWithIdentifier:@"path"];
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


- (void)willLoad
{
    [super willLoad];

    _registredDiskListeningId = nil;

    var params = [[CPDictionary alloc] init];
    
    [self registerSelector:@selector(didPushReceive:) forPushNotificationType:TNArchipelPushNotificationDisk]
    [self registerSelector:@selector(didPushReceive:) forPushNotificationType:TNArchipelPushNotificationAppliance]
    
    var center = [CPNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(didNickNameUpdated:) name:TNStropheContactNicknameUpdatedNotification object:_entity];
    [center addObserver:self selector:@selector(didPresenceUpdated:) name:TNStropheContactPresenceUpdatedNotification object:_entity];
    [center postNotificationName:TNArchipelModulesReadyNotification object:self];
    
    [_tableMedias setDelegate:nil];
    [_tableMedias setDelegate:self]; // hum....
    
    [self getDisksInfo];
}

- (void)willShow
{
    [super willShow];

    [fieldName setStringValue:[_entity nickname]];
    [fieldJID setStringValue:[_entity JID]];
    
    [self checkIfRunning];
}


- (void)didNickNameUpdated:(CPNotification)aNotification
{
    if ([aNotification object] == _entity)
    {
       [fieldName setStringValue:[_entity nickname]]
    }
}

- (void)didPresenceUpdated:(CPNotification)aNotification
{
    if ([aNotification object] == _entity)
    {
        [self checkIfRunning];
    }
}

- (BOOL)didPushReceive:(TNStropheStanza)aStanza
{
    var growl   = [TNGrowlCenter defaultCenter];
    var sender  = [aStanza getFromNode];
    var type    = [[aStanza firstChildWithName:@"x"] valueForAttribute:@"xmlns"];
    var change  = [[aStanza firstChildWithName:@"x"] valueForAttribute:@"change"];
    
    CPLog.info("PUSH NOTIFICATION: from: " + sender + ", type: " + type + ", change: " + change);
        
    [self getDisksInfo];
    
    if (type == TNArchipelPushNotificationDisk)
    {
        if (change == @"created")
            [growl pushNotificationWithTitle:@"Disk" message:@"Disk has been created"];
        else if (change == @"deleted")
            [growl pushNotificationWithTitle:@"Disk" message:@"Disk has been removed"];
    }
    
    return YES;
}

- (void)checkIfRunning
{
    var status = [_entity status];
    
    _isActive = ((status == TNStropheContactStatusOnline) || (status == TNStropheContactStatusAway));
    
    if (status == TNStropheContactStatusBusy)
    {
        [maskingView removeFromSuperview];
    }
    else
    {
        [maskingView setFrame:[[self view] bounds]];
        [[self view] addSubview:maskingView];
    }
}

- (void)getDisksInfo
{
    var stanza = [TNStropheStanza iqWithType:@"get"];
    
    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeVirtualMachineDisk}];
    [stanza addChildName:@"archipel" withAttributes:{
        "action": TNArchipelTypeVirtualMachineDiskGet}];
        
    [_entity sendStanza:stanza andRegisterSelector:@selector(didReceiveDisksInfo:) ofObject:self];
}

- (void)didReceiveDisksInfo:(id)aStanza
{
    var responseType    = [aStanza getType];
    var responseFrom    = [aStanza getFrom];

    if (responseType == @"result")
    {
        [_mediasDatasource removeAllObjects];

        var disks = [aStanza childrenWithName:@"disk"];

        for (var i = 0; i < [disks count]; i++)
        {
            var disk    = [disks objectAtIndex:i];
            var vSize   = [[[disk valueForAttribute:@"virtualSize"] componentsSeparatedByString:@" "] objectAtIndex:0];
            var dSize   = [[[disk valueForAttribute:@"diskSize"] componentsSeparatedByString:@" "] objectAtIndex:0];
            var path    = [disk valueForAttribute:@"path"];
            var name    = [disk valueForAttribute:@"name"];
            var format  = [disk valueForAttribute:@"format"];

            var newMedia = [TNMedia mediaWithPath:path name:name format:format virtualSize:vSize diskSize:dSize];
            [_mediasDatasource addObject:newMedia];
        }
        [_tableMedias reloadData];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}



- (IBAction)openNewDiskWindow:(id)sender
{
    [fieldNewDiskName setStringValue:@""];
    [fieldNewDiskSize setStringValue:@""];
    [buttonNewDiskFormat selectItemWithTitle:@"qcow2"];
    [windowNewDisk makeFirstResponder:fieldNewDiskName];
    [windowNewDisk center];
    [windowNewDisk makeKeyAndOrderFront:nil];
}

- (IBAction)convertFormatChange:(id)sender
{
    if (([_tableMedias numberOfRows]) && ([_tableMedias numberOfSelectedRows] <= 0))
    {
         return;
    }
    
    var selectedIndex   = [[_tableMedias selectedRowIndexes] firstIndex];
    var diskObject      = [_mediasDatasource objectAtIndex:selectedIndex];
}

- (IBAction)openRenamePanel:(id)sender
{
    if (_isActive)
    {
        var growl   = [TNGrowlCenter defaultCenter];
        
        [growl pushNotificationWithTitle:@"Disk" message:@"You can't edit disks of a running virtual machine" icon:TNGrowlIconError];
    }
    else
    {
        if (([_tableMedias numberOfRows]) && ([_tableMedias numberOfSelectedRows] <= 0))
             return;
             
        if ([_tableMedias numberOfSelectedRows] > 1)
        {
            var growl   = [TNGrowlCenter defaultCenter];

            [growl pushNotificationWithTitle:@"Disk" message:@"You can't edit multiple disk" icon:TNGrowlIconError];
            
            return;
        }
        
        var selectedIndex   = [[_tableMedias selectedRowIndexes] firstIndex];
        var diskObject      = [_mediasDatasource objectAtIndex:selectedIndex];
        
        [windowDiskProperties center];
        [windowDiskProperties makeKeyAndOrderFront:nil];
        [fieldEditDiskName setStringValue:[diskObject name]];

        _currentEditedDisk = diskObject;
    }
}


- (IBAction)createDisk:(id)sender
{
    var dUnit;
    var dName       = [fieldNewDiskName stringValue];
    var dSize       = [fieldNewDiskSize stringValue];
    var format      = [buttonNewDiskFormat title];
    
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

    switch( [buttonNewDiskSizeUnit title])
    {
        case "Go":
            dUnit = "G";
            break;

        case "Mo":
            dUnit = "M";
            break;
    }

    
    var stanza  = [TNStropheStanza iqWithType:@"set"];
    
    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeVirtualMachineDisk}];
    [stanza addChildName:@"archipel" withAttributes:{
        "action": TNArchipelTypeVirtualMachineDiskCreate,
        "name": dName,
        "size": dSize,
        "unit": dUnit,
        "format": format}];
                    
    [_entity sendStanza:stanza andRegisterSelector:@selector(didCreateDisk:) ofObject:self];

    [windowNewDisk orderOut:nil];
    [fieldNewDiskName setStringValue:@""];
    [fieldNewDiskSize setStringValue:@""];
}

- (void)didCreateDisk:(id)aStanza
{
    if ([aStanza getType] == @"error")
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}


- (IBAction)convert:(id)sender
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

    var selectedIndex   = [[_tableMedias selectedRowIndexes] firstIndex];
    var dName           = [_mediasDatasource objectAtIndex:selectedIndex];   
    var stanza          = [TNStropheStanza iqWithType:@"set"];
    
    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeVirtualMachineDisk}];
    [stanza addChildName:@"archipel" withAttributes:{
        "action": TNArchipelTypeVirtualMachineDiskConvert,
        "path": [dName path],
        "format": [buttonEditDiskFormat title]}];
    
    [windowDiskProperties orderOut:nil];
    
    [imageViewConverting setHidden:NO];
    [_entity sendStanza:stanza andRegisterSelector:@selector(didConvertDisk:) ofObject:self];
}

- (void)didConvertDisk:(id)aStanza
{
    [imageViewConverting setHidden:YES];
    
    if ([aStanza getType] == @"result")
    {
        var growl   = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Disk" message:@"Disk has been converted"];
    }
    else if ([aStanza getType] == @"error")
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}


- (IBAction)rename:(id)sender
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

        [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeVirtualMachineDisk}];
        [stanza addChildName:@"archipel" withAttributes:{
            "xmlns": TNArchipelTypeVirtualMachineDisk, 
            "action": TNArchipelTypeVirtualMachineDiskRename,
            "path": [_currentEditedDisk path],
            "newname": [_currentEditedDisk name]}];

        [_entity sendStanza:stanza andRegisterSelector:@selector(didRename:) ofObject:self];
    
        _currentEditedDisk = nil;
    }
}

- (void)didRename:(id)aStanza
{
    if ([aStanza getType] == @"result")
    {
        var growl   = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Disk" message:@"Disk has been renamed"];
    }
    else if ([aStanza getType] == @"error")
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}


- (IBAction)removeDisk:(id)sender
{
    if (([_tableMedias numberOfRows]) && ([_tableMedias numberOfSelectedRows] <= 0))
    {
         [CPAlert alertWithTitle:@"Error" message:@"You must select a media"];
         return;
    }
    
    var alert = [TNAlert alertWithTitle:@"Delete to drive"
                                message:@"Are you sure you want to destory this drive ? this is not reversible."
                                delegate:self
                                 actions:[["Delete", @selector(performRemoveDisk:)], ["Cancel", nil]]];
    [alert runModal];
}

- (void)performRemoveDisk:(id)someUserInfo
{
    var selectedIndexes = [_tableMedias selectedRowIndexes];
    var objects         = [_mediasDatasource objectsAtIndexes:selectedIndexes];
    
    for (var i = 0; i < [objects count]; i++)
    {
        var dName           = [objects objectAtIndex:i];
        var stanza      = [TNStropheStanza iqWithType:@"set"];
        
        [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeVirtualMachineDisk}];
        [stanza addChildName:@"archipel" withAttributes:{
            "xmlns": TNArchipelTypeVirtualMachineDisk, 
            "action": TNArchipelTypeVirtualMachineDiskDelete,
            "name": [dName path],
            "format": [buttonEditDiskFormat title],
            "undefine": "yes"}];
                    
        [_entity sendStanza:stanza andRegisterSelector:@selector(didRemoveDisk:) ofObject:self];
    }
}

- (void)didRemoveDisk:(id)aStanza
{
    if ([aStanza getType] == @"error")
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}



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
    
    var selectedIndex   = [[_tableMedias selectedRowIndexes] firstIndex];
    var diskObject      = [_mediasDatasource objectAtIndex:selectedIndex];
    
    [buttonEditDiskFormat selectItemWithTitle:[diskObject format]];
}

@end



