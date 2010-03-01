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
 
@import "../../TNModule.j";

trinityTypeVirtualMachineDisk       = @"trinity:vm:disk";

trinityTypeVirtualMachineDiskCreate = @"create";
trinityTypeVirtualMachineDiskDelete = @"delete";
trinityTypeVirtualMachineDiskGet    = @"get";

@implementation TNVirtualMachineDiskCreation : TNModule 
{
    @outlet CPTextField     fieldNewDiskName        @accessors;
    @outlet CPTextField     fieldNewDiskSize        @accessors;
    @outlet CPPopUpButton   buttonNewDiskSizeUnit   @accessors;
    @outlet CPPopUpButton   buttonDelDiskName       @accessors;
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
    var infoStanza = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeVirtualMachineDiskGet, "to": [[self contact] fullJID], "id": uid}];
    var params = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];;

    [infoStanza addChildName:@"query" withAttributes:{"xmlns" : trinityTypeVirtualMachineDisk}];

    [[[self contact] connection] registerSelector:@selector(didReceiveDisksInfo:) ofObject:self withDict:params];
    [[[self contact] connection] send:infoStanza];
}

- (void)didReceiveDisksInfo:(id)aStanza 
{
    var stanza          = [TNStropheStanza stanzaWithStanza:aStanza];
    var responseType    = [stanza getType];
    var responseFrom    = [stanza getFrom];

    if (responseType == @"success")
    {
        var disks = [stanza getChildrenWithName:@"disk"];
        [[self buttonDelDiskName] removeAllItems];
        for (var i = 0; i < [disks count]; i++)
        {
            var disk    = [disks objectAtIndex:i];
            var vSize   = [[[disk getValueForAttribute:@"virtualSize"] componentsSeparatedByString:@" "] objectAtIndex:0];
            var label   = [[[disk getValueForAttribute:@"name"] componentsSeparatedByString:@"."] objectAtIndex:0] + " - " + vSize  + " (" + [disk getValueForAttribute:@"diskSize"] + ")";
            var item    = [[TNMenuItem alloc] initWithTitle:label action:nil keyEquivalent:nil];
            
            [item setStringValue:[disk getValueForAttribute:@"path"]];
            [[self buttonDelDiskName] addItem:item];
        }
    }   
}

- (IBAction)createDisk:(id)sender
{
    var dUnit;
    var dName       = [[self fieldNewDiskName] stringValue];
    var dSize       = [[self fieldNewDiskSize] stringValue];

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
    var diskStanza  = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeVirtualMachineDiskCreate, "to": [[self contact] fullJID], "id": uid}];
    var params      = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];
    
    [diskStanza addChildName:@"query" withAttributes:{"xmlns" : trinityTypeVirtualMachineDisk}];
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
    var dName       = [[[self buttonDelDiskName] selectedItem] stringValue];
    var uid         = [[[self contact] connection] getUniqueId];
    var diskStanza  = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeVirtualMachineDiskDelete, "to": [[self contact] fullJID], "id": uid}];
    var params      = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];
    
    [diskStanza addChildName:@"query" withAttributes:{"xmlns" : trinityTypeVirtualMachineDisk}];
    [diskStanza addChildName:@"name"];
    [diskStanza addTextNode:dName];
     
    [[[self contact] connection] registerSelector:@selector(didCreateDisk:) ofObject:self withDict:params];
    [[[self contact] connection] send:diskStanza];
}

@end



