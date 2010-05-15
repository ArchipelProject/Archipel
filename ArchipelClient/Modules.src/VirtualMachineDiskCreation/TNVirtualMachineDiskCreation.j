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

@import "TNDatasourceMedias.j";

TNArchipelTypeVirtualMachineDisk       = @"archipel:vm:disk";

TNArchipelTypeVirtualMachineDiskCreate  = @"create";
TNArchipelTypeVirtualMachineDiskDelete  = @"delete";
TNArchipelTypeVirtualMachineDiskGet     = @"get";
TNArchipelTypeVirtualMachineDiskConvert = @"convert";
TNArchipelTypeVirtualMachineDiskRename  = @"rename";

TNArchipelPushNotificationDisk           = @"archipel:push:disk";
TNArchipelPushNotificationDiskCreated    = @"created";

@implementation TNVirtualMachineDiskCreation : TNModule
{
    @outlet CPTextField     fieldJID;
    @outlet CPTextField     fieldName;
    @outlet CPTextField     fieldNewDiskName;
    @outlet CPTextField     fieldNewDiskSize;
    @outlet CPPopUpButton   buttonNewDiskSizeUnit;
    @outlet CPPopUpButton   buttonFormatCreate;
    @outlet CPPopUpButton   buttonFormatConvert;
    @outlet CPScrollView    scrollViewDisks;
    @outlet CPWindow        windowDiskProperties;
    @outlet CPTextField     fieldDiskNewName;
    @outlet CPTextField     fieldPropertyPath;
    @outlet CPTextField     fieldPropertyRealSize;
    @outlet CPTextField     fieldPropertyVirtualSize;
    @outlet CPImageView     imageViewConverting;
    @outlet CPButton        buttonConvert;

    CPTableView             _tableMedias;
    TNDatasourceMedias      _mediasDatasource;
    TNMedia                 _currentEditedDisk;
    id                      _registredDiskListeningId;
}

- (void)awakeFromCib
{
    [buttonConvert setEnabled:NO];
    
    [buttonNewDiskSizeUnit removeAllItems];
    [buttonNewDiskSizeUnit addItemsWithTitles:["Go", "Mo"]];

    var formats = [@"qcow2", @"qcow", @"cow", @"raw", @"vmdk"];
    [buttonFormatCreate removeAllItems];
    [buttonFormatCreate addItemsWithTitles:formats];
    
    [buttonFormatConvert removeAllItems];
    [buttonFormatConvert addItemsWithTitles:formats];
    
    
    var bundle = [CPBundle mainBundle];
    [imageViewConverting setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"spinner.gif"]]];
    [imageViewConverting setHidden:YES];
    
    // Media table view
    _mediasDatasource    = [[TNDatasourceMedias alloc] init];
    _tableMedias         = [[CPTableView alloc] initWithFrame:[scrollViewDisks bounds]];

    [scrollViewDisks setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [scrollViewDisks setAutohidesScrollers:YES];
    [scrollViewDisks setDocumentView:_tableMedias];
    [scrollViewDisks setBorderedWithHexColor:@"#9e9e9e"];

    [_tableMedias setUsesAlternatingRowBackgroundColors:YES];
    [_tableMedias setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [_tableMedias setAllowsColumnReordering:YES];
    [_tableMedias setAllowsColumnResizing:YES];
    [_tableMedias setAllowsEmptySelection:YES];

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
    [_tableMedias setDoubleAction:@selector(tableViewAction:)];
    [_tableMedias setDelegate:self];
    
    [_mediasDatasource setTable:_tableMedias];
    [_tableMedias setDataSource:_mediasDatasource];
    
    [fieldNewDiskName setValue:[CPColor grayColor] forThemeAttribute:@"text-color" inState:CPTextFieldStatePlaceholder];
    [fieldNewDiskSize setValue:[CPColor grayColor] forThemeAttribute:@"text-color" inState:CPTextFieldStatePlaceholder];
    
}


- (void)willLoad
{
    [super willLoad];

    _registredDiskListeningId = nil;

    var params = [[CPDictionary alloc] init];
    
    [self registerSelector:@selector(didReceivedDiskPushNotification:) forPushNotificationType:TNArchipelPushNotificationDisk]
    
    var center = [CPNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(didNickNameUpdated:) name:TNStropheContactNicknameUpdatedNotification object:_entity];
}

- (void)willShow
{
    [super willShow];

    [fieldName setStringValue:[_entity nickname]];
    [fieldJID setStringValue:[_entity JID]];
    
    [self getDisksInfo];
}


- (void)didNickNameUpdated:(CPNotification)aNotification
{
    if ([aNotification object] == _entity)
    {
       [fieldName setStringValue:[_entity nickname]]
    }
}

- (BOOL)didReceivedDiskPushNotification:(TNStropheStanza)aStanza
{
    var growl   = [TNGrowlCenter defaultCenter];
    var change  = [aStanza valueForAttribute:@"change"];
    
    if (change == @"created")
        [growl pushNotificationWithTitle:@"Disk" message:@"Disk has been created"];
    else if (change == @"deleted")
        [growl pushNotificationWithTitle:@"Disk" message:@"Disk has been removed"];
    
    [self getDisksInfo];
    
    return YES;
}

- (void)getDisksInfo
{
    var infoStanza = [TNStropheStanza iqWithAttributes:{"type" : TNArchipelTypeVirtualMachineDisk}];

    [infoStanza addChildName:@"query" withAttributes:{"type" : TNArchipelTypeVirtualMachineDiskGet}];

    [_entity sendStanza:infoStanza andRegisterSelector:@selector(didReceiveDisksInfo:) ofObject:self];
}

- (void)didReceiveDisksInfo:(id)aStanza
{
    var responseType    = [aStanza getType];
    var responseFrom    = [aStanza getFrom];

    if (responseType == @"success")
    {
        [[_mediasDatasource medias] removeAllObjects];

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
            [_mediasDatasource addMedia:newMedia];
        }
        [_tableMedias reloadData];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}


- (IBAction)convertFormatChange:(id)sender
{
    if (([_tableMedias numberOfRows]) && ([_tableMedias numberOfSelectedRows] <= 0))
    {
         return;
    }
    
    var selectedIndex   = [[_tableMedias selectedRowIndexes] firstIndex];
    var diskObject      = [[_mediasDatasource medias] objectAtIndex:selectedIndex];
    
    if ([diskObject format] == [buttonFormatConvert title])
        [buttonConvert setEnabled:NO];
    else
        [buttonConvert setEnabled:YES];
}

- (IBAction)tableViewAction:(id)sender
{
    if (([_tableMedias numberOfRows]) && ([_tableMedias numberOfSelectedRows] <= 0))
    {
         return;
    }
    
    var selectedIndex   = [[_tableMedias selectedRowIndexes] firstIndex];
    var diskObject      = [[_mediasDatasource medias] objectAtIndex:selectedIndex];
    
    [windowDiskProperties orderFront:nil];
    [fieldDiskNewName setStringValue:[diskObject name]];
    [fieldPropertyVirtualSize setStringValue:[diskObject virtualSize]];
    [fieldPropertyRealSize setStringValue:[diskObject diskSize]];
    [fieldPropertyPath setStringValue:[diskObject path]];
    
    _currentEditedDisk = diskObject;
}

- (IBAction)createDisk:(id)sender
{
    var dUnit;
    var dName       = [fieldNewDiskName stringValue];
    var dSize       = [fieldNewDiskSize stringValue];
    var format      = [buttonFormatCreate title];
    
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

    // TODO : control disk size.

    var diskStanza  = [TNStropheStanza iqWithAttributes:{"type" : TNArchipelTypeVirtualMachineDisk}];

    [diskStanza addChildName:@"query" withAttributes:{"type" : TNArchipelTypeVirtualMachineDiskCreate}];
    [diskStanza addChildName:@"name"];
    [diskStanza addTextNode:dName];
    [diskStanza up];
    [diskStanza addChildName:@"size"];
    [diskStanza addTextNode:dSize];
    [diskStanza up];
    [diskStanza addChildName:@"unit"];
    [diskStanza addTextNode:dUnit];
    [diskStanza up];
    [diskStanza addChildName:@"format"];
    [diskStanza addTextNode:format];
    [diskStanza up];

    [_entity sendStanza:diskStanza andRegisterSelector:@selector(didCreateDisk:) ofObject:self];

    [fieldNewDiskName setStringValue:@""];
    [fieldNewDiskSize setStringValue:@""];
}

- (IBAction)convert:(id)sender
{
    if (([_tableMedias numberOfRows]) && ([_tableMedias numberOfSelectedRows] <= 0))
    {
         [CPAlert alertWithTitle:@"Error" message:@"You must select a media"];
         return;
    }

    var selectedIndex   = [[_tableMedias selectedRowIndexes] firstIndex];
    var dName           = [[_mediasDatasource medias] objectAtIndex:selectedIndex];   
    var diskStanza      = [TNStropheStanza iqWithAttributes:{"type" : TNArchipelTypeVirtualMachineDisk}];
    
    [diskStanza addChildName:@"query" withAttributes:{"type" : TNArchipelTypeVirtualMachineDiskConvert}];
    [diskStanza addChildName:@"path"];
    [diskStanza addTextNode:[dName path]];
    [diskStanza up];
    [diskStanza addChildName:@"format"];
    [diskStanza addTextNode:[buttonFormatConvert title]];
    [diskStanza up];
    
    [imageViewConverting setHidden:NO];
    [_entity sendStanza:diskStanza andRegisterSelector:@selector(didConvertDisk:) ofObject:self];
}

- (IBAction)rename:(id)sender
{
    if ([fieldDiskNewName stringValue] != [_currentEditedDisk name])
    {
        [_currentEditedDisk setName:[fieldDiskNewName stringValue]];
        [self rename:_currentEditedDisk];
    }
    
    var diskStanza      = [TNStropheStanza iqWithAttributes:{"type" : TNArchipelTypeVirtualMachineDisk}];
    
    [diskStanza addChildName:@"query" withAttributes:{"type" : TNArchipelTypeVirtualMachineDiskRename}];
    [diskStanza addChildName:@"path"];
    [diskStanza addTextNode:[_currentEditedDisk path]];
    [diskStanza up];
    [diskStanza addChildName:@"newname"];
    [diskStanza addTextNode:[_currentEditedDisk name]];
    [diskStanza up];

    [_entity sendStanza:diskStanza andRegisterSelector:@selector(didRename:) ofObject:self];
    
    _currentEditedDisk = nil;
    [windowDiskProperties orderOut:nil];
}

- (IBAction)removeDisk:(id)sender
{
    if (([_tableMedias numberOfRows]) && ([_tableMedias numberOfSelectedRows] <= 0))
    {
         [CPAlert alertWithTitle:@"Error" message:@"You must select a media"];
         return;
    }

    var selectedIndex   = [[_tableMedias selectedRowIndexes] firstIndex];
    var dName           = [[_mediasDatasource medias] objectAtIndex:selectedIndex];
    var diskStanza      = [TNStropheStanza iqWithAttributes:{"type" : TNArchipelTypeVirtualMachineDisk}];

    [diskStanza addChildName:@"query" withAttributes:{"type" : TNArchipelTypeVirtualMachineDiskDelete}];
    [diskStanza addChildName:@"name"];
    [diskStanza addTextNode:[dName path]];

    [_entity sendStanza:diskStanza andRegisterSelector:@selector(didRemoveDisk:) ofObject:self];
}


- (void)didCreateDisk:(id)aStanza
{
    if ([aStanza getType] == @"error")
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}

- (void)didConvertDisk:(id)aStanza
{
    [imageViewConverting setHidden:YES];
    
    if ([aStanza getType] == @"success")
    {
        var growl   = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Disk" message:@"Disk has been converted"];
    }
    else if ([aStanza getType] == @"error")
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}

- (void)didRename:(id)aStanza
{
    if ([aStanza getType] == @"success")
    {
        var growl   = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Disk" message:@"Disk has been renamed"];
    }
    else if ([aStanza getType] == @"error")
    {
        [self handleIqErrorFromStanza:aStanza];
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
    [buttonConvert setEnabled:NO];
    
    if (([_tableMedias numberOfRows]) && ([_tableMedias numberOfSelectedRows] <= 0))
    {
         return;
    }
    
    var selectedIndex   = [[_tableMedias selectedRowIndexes] firstIndex];
    var diskObject      = [[_mediasDatasource medias] objectAtIndex:selectedIndex];
    
    [buttonFormatConvert selectItemWithTitle:[diskObject format]];
}

@end



