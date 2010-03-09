/*  
 * TNWindowDriveEdition.j
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

@import "TNDatasourceDrives.j"

trinityTypeVirtualMachineDisk       = @"trinity:vm:disk";

trinityTypeVirtualMachineDiskGet    = @"get";
trinityTypeVirtualMachineISOGet     = @"getiso";

@implementation TNWindowDriveEdition : CPWindow
{
    @outlet CPPopUpButton   buttonSource    @accessors;
    @outlet CPPopUpButton   buttonType      @accessors;
    @outlet CPPopUpButton   buttonTarget    @accessors;
    @outlet CPPopUpButton   buttonBus       @accessors;
    @outlet CPRadioGroup    radioDriveType  @accessors;

    TNNetworkDrive          drive           @accessors;
    CPTableView             table           @accessors;
    TNStropheContact        contact         @accessors;
}


- (void)awakeFromCib
{
    [[self buttonType] removeAllItems];
    [[self buttonTarget] removeAllItems];
    [[self buttonBus] removeAllItems];
    [[self buttonSource] removeAllItems];
    
    var types = ["file"];
    for (var i = 0; i < types.length; i++)
    {
        var item = [[CPMenuItem alloc] initWithTitle:types[i] action:nil keyEquivalent:nil];
        [[self buttonType] addItem:item];
    }
    
    var targets = ["hda", "hdb", "hdc", "hdd", "sda", "sdb", "sdc", "sdd"];
    for (var i = 0; i < targets.length; i++)
    {
        var item = [[CPMenuItem alloc] initWithTitle:targets[i] action:nil keyEquivalent:nil];
        [[self buttonTarget] addItem:item];
    }
    
    var buses = ["ide", "sata"];
    for (var i = 0; i < buses.length; i++)
    {
        var item = [[CPMenuItem alloc] initWithTitle:buses[i] action:nil keyEquivalent:nil];
        [[self buttonBus] addItem:item];
    }
}

- (void)orderFront:(id)sender
{   
    for (var i = 0; i < [[radioDriveType radios] count]; i++)
    {
        var radio = [[radioDriveType radios] objectAtIndex:i];

        if ([radio title] == [drive type])
        {
            [radio setState:CPOnState];
            [self performRadioDriveTypeChanged:radioDriveType];
            break;
        }
    }
       
    [[self buttonType] selectItemWithTitle:[drive type]];
    [[self buttonTarget] selectItemWithTitle:[drive target]];
    [[self buttonBus] selectItemWithTitle:[drive bus]];
    [self getDisksInfo];
    
    [super orderFront:sender];
}

- (IBAction)save:(id)sender
{
    [drive setSource:[[[self buttonSource] selectedItem] stringValue]];
    [drive setType:[[self buttonType] title]];
    
    var driveType = [[[self radioDriveType] selectedRadio] title];
    
    if (driveType == @"Hard drive")
        [drive setDevice:@"disk"];
    else
        [drive setDevice:@"cdrom"];
        
    
    [drive setTarget:[[self buttonTarget] title]];
    [drive setBus:[[self buttonBus] title]];
    
    [[self table] reloadData];
}

- (IBAction)performRadioDriveTypeChanged:(id)sender
{
    var driveType = [[sender selectedRadio] title];
    
    if (driveType == @"Hard drive")
    {
        [self getDisksInfo];
        if ([[self buttonBus] title] == @"ide")
            [[self buttonTarget] selectItemWithTitle:@"hda"];
        else
            [[self buttonTarget] selectItemWithTitle:@"sda"];
    }
    else
    {
        [self getISOsInfo];
        if ([[self buttonBus] title] == @"ide")
            [[self buttonTarget] selectItemWithTitle:@"hdc"];
        else
            [[self buttonTarget] selectItemWithTitle:@"sdc"];
    }
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
        var disks = [aStanza childrenWithName:@"disk"];
        [[self buttonSource] removeAllItems];

        for (var i = 0; i < [disks count]; i++)
        {
            var disk    = [disks objectAtIndex:i];
            var vSize   = [[[disk valueForAttribute:@"virtualSize"] componentsSeparatedByString:@" "] objectAtIndex:0];
            var label   = [[[disk valueForAttribute:@"name"] componentsSeparatedByString:@"."] objectAtIndex:0] + " - " + vSize  + " (" + [disk valueForAttribute:@"diskSize"] + ")";
            var item    = [[TNMenuItem alloc] initWithTitle:label action:nil keyEquivalent:nil];
            
            [item setStringValue:[disk valueForAttribute:@"path"]];
            [[self buttonSource] addItem:item];
        }
    }
    [self save:nil];
}

-(void)getISOsInfo
{
    var uid = [[[self contact] connection] getUniqueId];
    var infoStanza = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeVirtualMachineDisk, "to": [[self contact] fullJID], "id": uid}];
    var params = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];;

    [infoStanza addChildName:@"query" withAttributes:{"type" : trinityTypeVirtualMachineISOGet}];

    [[[self contact] connection] registerSelector:@selector(didReceiveISOsInfo:) ofObject:self withDict:params];
    [[[self contact] connection] send:infoStanza];
}

- (void)didReceiveISOsInfo:(id)aStanza 
{
    var responseType    = [aStanza getType];
    var responseFrom    = [aStanza getFrom];

    if (responseType == @"success")
    {
        var isos = [aStanza childrenWithName:@"iso"];
        [[self buttonSource] removeAllItems];

        for (var i = 0; i < [isos count]; i++)
        {
            var iso     = [isos objectAtIndex:i];
            var label   = [iso valueForAttribute:@"name"];
            var item    = [[TNMenuItem alloc] initWithTitle:label action:nil keyEquivalent:nil];
            
            [item setStringValue:[iso valueForAttribute:@"path"]];
            [[self buttonSource] addItem:item];
        }
    }
    [self save:nil];
}
@end