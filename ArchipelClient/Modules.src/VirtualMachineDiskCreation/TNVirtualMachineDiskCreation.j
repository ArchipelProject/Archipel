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

TNArchipelTypeVirtualMachineDiskCreate = @"create";
TNArchipelTypeVirtualMachineDiskDelete = @"delete";
TNArchipelTypeVirtualMachineDiskGet    = @"get";

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

    CPTableView             _tableMedias;
    TNDatasourceMedias      _mediasDatasource;

    id  _registredDiskListeningId;
}

- (void)awakeFromCib
{
    [buttonNewDiskSizeUnit removeAllItems];
    [buttonNewDiskSizeUnit addItemsWithTitles:["Go", "Mo"]];

    var formats = [@"qcow2", @"qcow (not implemented)", @"cow (not implemented)", @"raw (not implemented)", @"vmdk (not implemented)", @"cloop (not implemented)"];
    [buttonFormatCreate removeAllItems];
    [buttonFormatCreate addItemsWithTitles:formats];
    
    [buttonFormatConvert removeAllItems];
    [buttonFormatConvert addItemsWithTitles:formats];
    
    
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

    var mediaColumVirtualSize = [[CPTableColumn alloc] initWithIdentifier:@"virtualSize"];
    [mediaColumVirtualSize setWidth:80];
    [[mediaColumVirtualSize headerView] setStringValue:@"VirtualSize"];

    var mediaColumDiskSize = [[CPTableColumn alloc] initWithIdentifier:@"diskSize"];
    [mediaColumDiskSize setWidth:80];
    [[mediaColumDiskSize headerView] setStringValue:@"RealSize"];

    var mediaColumPath = [[CPTableColumn alloc] initWithIdentifier:@"path"];
    [mediaColumPath setWidth:500];
    [[mediaColumPath headerView] setStringValue:@"HypervisorPath"];

    [_tableMedias addTableColumn:mediaColumName];
    [_tableMedias addTableColumn:mediaColumVirtualSize];
    [_tableMedias addTableColumn:mediaColumDiskSize];
    [_tableMedias addTableColumn:mediaColumPath];

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
    [fieldJID setStringValue:[_entity jid]];
    
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

            var newMedia = [TNMedia mediaWithPath:path name:name virtualSize:vSize diskSize:dSize];
            [_mediasDatasource addMedia:newMedia];
        }
        [_tableMedias reloadData];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}

- (IBAction)createDisk:(id)sender
{
    var dUnit;
    var dName       = [fieldNewDiskName stringValue];
    var dSize       = [fieldNewDiskSize stringValue];

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

    [_entity sendStanza:diskStanza andRegisterSelector:@selector(didCreateDisk:) ofObject:self];

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

- (void)didRemoveDisk:(id)aStanza
{
    if ([aStanza getType] == @"error")
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}

- (IBAction)convert:(id)sender
{
    var growl   = [TNGrowlCenter defaultCenter];
    
    [growl pushNotificationWithTitle:@"Not implemented" message:@"This function is not implemented"];
}
@end



