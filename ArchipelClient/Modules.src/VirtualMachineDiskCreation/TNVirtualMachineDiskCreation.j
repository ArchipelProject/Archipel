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

trinityTypeVirtualMachineDisk       = @"trinity:vm:disk";

trinityTypeVirtualMachineDiskCreate = @"create";
trinityTypeVirtualMachineDiskDelete = @"delete";
trinityTypeVirtualMachineDiskGet    = @"get";

@implementation TNVirtualMachineDiskCreation : TNModule 
{
    @outlet CPTextField     fieldNewDiskName        @accessors;
    @outlet CPTextField     fieldNewDiskSize        @accessors;
    @outlet CPPopUpButton   buttonNewDiskSizeUnit   @accessors;
    @outlet CPScrollView    scrollViewDisks         @accessors;
    
    CPTableView             tableMedias              @accessors;
    TNDatasourceMedias      mediasDatasource        @accessors;
}

- (void)awakeFromCib
{
    [[self buttonNewDiskSizeUnit] removeAllItems];
    
    var unitTypes = ["Go", "Mo", "Ko"];
    for (var i = 0; i < unitTypes.length; i++)
    {
        var item = [[TNMenuItem alloc] initWithTitle:unitTypes[i] action:nil keyEquivalent:nil];
        [[self buttonNewDiskSizeUnit] addItem:item];
    }
    
    // Media table view
    mediasDatasource    = [[TNDatasourceMedias alloc] init];
    tableMedias         = [[CPTableView alloc] initWithFrame:[[self scrollViewDisks] bounds]];
    
    [[self scrollViewDisks] setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [[self scrollViewDisks] setAutohidesScrollers:YES];
    [[self scrollViewDisks] setDocumentView:[self tableMedias]];
    [[self scrollViewDisks] setBorderedWithHexColor:@"#9e9e9e"];
    
    [[self tableMedias] setUsesAlternatingRowBackgroundColors:YES];
    [[self tableMedias] setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [[self tableMedias] setAllowsColumnReordering:YES];
    [[self tableMedias] setAllowsColumnResizing:YES];
    [[self tableMedias] setAllowsEmptySelection:YES];
    
    var mediaColumName = [[CPTableColumn alloc] initWithIdentifier:@"name"];
    [mediaColumName setWidth:150];
    [mediaColumName setResizingMask:CPTableColumnAutoresizingMask ];
    [[mediaColumName headerView] setStringValue:@"Name"];
        
    var mediaColumVirtualSize = [[CPTableColumn alloc] initWithIdentifier:@"virtualSize"];
    [mediaColumVirtualSize setWidth:80];
    [mediaColumVirtualSize setResizingMask:CPTableColumnAutoresizingMask ];
    [[mediaColumVirtualSize headerView] setStringValue:@"VirtualSize"];
    
    var mediaColumDiskSize = [[CPTableColumn alloc] initWithIdentifier:@"diskSize"];
    [mediaColumDiskSize setWidth:80];
    [mediaColumDiskSize setResizingMask:CPTableColumnAutoresizingMask ];
    [[mediaColumDiskSize headerView] setStringValue:@"RealSize"];
    
    var mediaColumPath = [[CPTableColumn alloc] initWithIdentifier:@"path"];
    [mediaColumPath setWidth:500];
    [mediaColumPath setResizingMask:CPTableColumnAutoresizingMask ];
    [[mediaColumPath headerView] setStringValue:@"HypervisorPath"];
    
    [[self tableMedias] addTableColumn:mediaColumName];
    [[self tableMedias] addTableColumn:mediaColumVirtualSize];
    [[self tableMedias] addTableColumn:mediaColumDiskSize];
    [[self tableMedias] addTableColumn:mediaColumPath];
    
    [[self tableMedias] setDataSource:[self mediasDatasource]];
}

- (void)willLoad
{
    // message sent when view will be added from superview;
    // MUST be declared
}

- (void)willUnload
{
   // message sent when view will be removed from superview;
   // MUST be declared
}

- (void)willShow 
{
    [self getDisksInfo];
}

- (void)willHide 
{
    // message sent when the tab is changed
}

-(void)getDisksInfo
{
    var uid = [[[self contact] connection] getUniqueId];
    var infoStanza = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeVirtualMachineDisk, "to": [[self contact] fullJID], "id": uid}];
    var params = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];;

    [infoStanza addChildName:@"query" withAttributes:{"type" : trinityTypeVirtualMachineDiskGet}];

    [[[self contact] connection] registerSelector:@selector(didReceiveDisksInfo:) ofObject:self withDict:params];
    [[[self contact] connection] send:infoStanza];
}

- (void)didReceiveDisksInfo:(id)aStanza 
{
    var responseType    = [aStanza getType];
    var responseFrom    = [aStanza getFrom];

    if (responseType == @"success")
    {
        [[[self mediasDatasource] medias] removeAllObjects];
        
        var disks = [aStanza childrenWithName:@"disk"];
        
        for (var i = 0; i < [disks count]; i++)
        {
            var disk    = [disks objectAtIndex:i];
            var vSize   = [[[disk valueForAttribute:@"virtualSize"] componentsSeparatedByString:@" "] objectAtIndex:0];
            var dSize   = [[[disk valueForAttribute:@"diskSize"] componentsSeparatedByString:@" "] objectAtIndex:0];
            var path    = [disk valueForAttribute:@"path"];
            var name    = [disk valueForAttribute:@"name"];
            
            var newMedia = [TNMedia mediaWithPath:path name:name virtualSize:vSize diskSize:dSize];
            [[self mediasDatasource] addMedia:newMedia];
        }
        [[self tableMedias] reloadData];
    }   
}

- (IBAction)createDisk:(id)sender
{
    var dUnit;
    var dName       = [[self fieldNewDiskName] stringValue];
    var dSize       = [[self fieldNewDiskSize] stringValue];
    
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
    
    switch( [[self buttonNewDiskSizeUnit] title])
    {
        case "Go":
            dUnit = "G";
            break;
            
        case "Mo":
            dUnit = "M";
            break;
            
        case "Ko":
            dUnit = "M";
            break;
    }
    
    var uid         = [[[self contact] connection] getUniqueId];
    var diskStanza  = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeVirtualMachineDisk, "to": [[self contact] fullJID], "id": uid}];
    var params      = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];
    
    [diskStanza addChildName:@"query" withAttributes:{"type" : trinityTypeVirtualMachineDiskCreate}];
    [diskStanza addChildName:@"name"];
    [diskStanza addTextNode:dName];
    [diskStanza up];
    [diskStanza addChildName:@"size"];
    [diskStanza addTextNode:dSize];
    [diskStanza up];
    [diskStanza addChildName:@"unit"];
    [diskStanza addTextNode:dUnit];
    [diskStanza up];
     
    [[[self contact] connection] registerSelector:@selector(didCreateDisk:) ofObject:self withDict:params];
    [[[self contact] connection] send:diskStanza];
  
    [[self fieldNewDiskName] setStringValue:@""];
    [[self fieldNewDiskSize] setStringValue:@""];
}

- (void)didCreateDisk:(id)aStanza
{
    [self getDisksInfo];
}

- (IBAction)removeDisk:(id)sender
{
    if (([[self tableMedias] numberOfRows]) && ([[self tableMedias] numberOfSelectedRows] <= 0))
    {
         [CPAlert alertWithTitle:@"Error" message:@"You must select a media"];
         return;
    }
    
    var selectedIndex   = [[[self tableMedias] selectedRowIndexes] firstIndex];
    var dName           = [[[self mediasDatasource] medias] objectAtIndex:selectedIndex];
    var uid             = [[[self contact] connection] getUniqueId];
    var diskStanza      = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeVirtualMachineDisk, "to": [[self contact] fullJID], "id": uid}];
    var params          = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];
    
    [diskStanza addChildName:@"query" withAttributes:{"type" : trinityTypeVirtualMachineDiskDelete}];
    [diskStanza addChildName:@"name"];
    [diskStanza addTextNode:[dName path]];
     
    [[[self contact] connection] registerSelector:@selector(didRemoveDisk:) ofObject:self withDict:params];
    [[[self contact] connection] send:diskStanza];
}

- (void)didRemoveDisk:(id)aStanza
{
    [self getDisksInfo];
}

@end



