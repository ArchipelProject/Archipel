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

TNArchipelTypeVirtualMachineDisk       = @"archipel:vm:disk";

TNArchipelTypeVirtualMachineDiskGet    = @"get";
TNArchipelTypeVirtualMachineISOGet     = @"getiso";

TNXMLDescDiskType   = @"file";
TNXMLDescDiskTypes  = [TNXMLDescDiskType];

TNXMLDescDiskTargetHda  = @"hda";
TNXMLDescDiskTargetHdb  = @"hdb";
TNXMLDescDiskTargetHdc  = @"hdc";
TNXMLDescDiskTargetHdd  = @"hdd";
TNXMLDescDiskTargetSda  = @"sda";
TNXMLDescDiskTargetSdb  = @"sdb";
TNXMLDescDiskTargetSdc  = @"sdc";
TNXMLDescDiskTargetSdd  = @"sdd";
TNXMLDescDiskTargets        = [ TNXMLDescDiskTargetHda, TNXMLDescDiskTargetHdb,
                                TNXMLDescDiskTargetHdc, TNXMLDescDiskTargetHdd,
                                TNXMLDescDiskTargetSda, TNXMLDescDiskTargetSdb,
                                TNXMLDescDiskTargetSdc, TNXMLDescDiskTargetSdd];
TNXMLDescDiskTargetsIDE     = [ TNXMLDescDiskTargetHda, TNXMLDescDiskTargetHdb,
                                TNXMLDescDiskTargetHdc, TNXMLDescDiskTargetHdd];
TNXMLDescDiskTargetsSCSI    = [ TNXMLDescDiskTargetSda, TNXMLDescDiskTargetSdb,
                                TNXMLDescDiskTargetSdc, TNXMLDescDiskTargetSdd]

TNXMLDescDiskBusIDE     = @"ide";
TNXMLDescDiskBusSCSI    = @"scsi";
TNXMLDescDiskBusVIRTIO  = @"virtio";
TNXMLDescDiskBuses      = [TNXMLDescDiskBusIDE, TNXMLDescDiskBusSCSI, TNXMLDescDiskBusVIRTIO];

@implementation TNWindowDriveEdition : CPWindow
{
    @outlet CPPopUpButton   buttonSource    @accessors;
    @outlet CPPopUpButton   buttonType      @accessors;
    @outlet CPPopUpButton   buttonTarget    @accessors;
    @outlet CPPopUpButton   buttonBus       @accessors;
    @outlet CPRadioGroup    radioDriveType  @accessors;

    TNNetworkDrive          drive           @accessors;
    CPTableView             table           @accessors;
    TNStropheContact        entity          @accessors;
}


- (void)awakeFromCib
{
    [[self buttonType] removeAllItems];
    [[self buttonTarget] removeAllItems];
    [[self buttonBus] removeAllItems];
    [[self buttonSource] removeAllItems];
    
    for (var i = 0; i < TNXMLDescDiskTypes.length; i++)
    {
        var item = [[CPMenuItem alloc] initWithTitle:TNXMLDescDiskTypes[i] action:nil keyEquivalent:nil];
        [[self buttonType] addItem:item];
    }
    
    for (var i = 0; i < TNXMLDescDiskTargetsIDE.length; i++)
    {
        var item = [[CPMenuItem alloc] initWithTitle:TNXMLDescDiskTargetsIDE[i] action:nil keyEquivalent:nil];
        [[self buttonTarget] addItem:item];
    }
    
    for (var i = 0; i < TNXMLDescDiskBuses.length; i++)
    {
        var item = [[CPMenuItem alloc] initWithTitle:TNXMLDescDiskBuses[i] action:nil keyEquivalent:nil];
        [[self buttonBus] addItem:item];
    }
}

- (void)orderFront:(id)sender
{
    if (![self isVisible])
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
        
        if ([drive device] == @"disk")
            [[[[self radioDriveType] radios] objectAtIndex:0] setState:CPOnState];
        else if ([drive device] == @"cdrom")
            [[[[self radioDriveType] radios] objectAtIndex:1] setState:CPOnState];

        [self performRadioDriveTypeChanged:[self radioDriveType]];
        
        [self populateTargetButton];
    }
    
    [super orderFront:sender];
}


- (void)populateTargetButton
{
    [[self buttonTarget] removeAllItems];
    if ([[self buttonBus] title] == TNXMLDescDiskBusIDE)
    {
        for (var i = 0; i < TNXMLDescDiskTargetsIDE.length; i++)
        {
            var item = [[CPMenuItem alloc] initWithTitle:TNXMLDescDiskTargetsIDE[i] action:nil keyEquivalent:nil];
            [[self buttonTarget] addItem:item];
        }
    }
    else if ([[self buttonBus] title] == TNXMLDescDiskBusSCSI)
    {
        for (var i = 0; i < TNXMLDescDiskTargetsSCSI.length; i++)
        {
            var item = [[CPMenuItem alloc] initWithTitle:TNXMLDescDiskTargetsSCSI[i] action:nil keyEquivalent:nil];
            [[self buttonTarget] addItem:item];
        }
    }
    [[self buttonTarget] selectItemWithTitle:[drive target]];
}

- (IBAction)save:(id)sender
{
    if (sender == [self buttonBus])
    {
       [self populateTargetButton];
    }
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
        if ([[self buttonBus] title] == TNXMLDescDiskBusIDE)
            [[self buttonTarget] selectItemWithTitle:@"hda"];
        else
            [[self buttonTarget] selectItemWithTitle:@"sda"];
    }
    else
    {
        [self getISOsInfo];
        if ([[self buttonBus] title] == TNXMLDescDiskBusIDE)
            [[self buttonTarget] selectItemWithTitle:@"hdc"];
        else
            [[self buttonTarget] selectItemWithTitle:@"sdc"];
    }
}

-(void)getDisksInfo
{
    var infoStanza = [TNStropheStanza iqWithAttributes:{"type" : TNArchipelTypeVirtualMachineDisk}];

    [infoStanza addChildName:@"query" withAttributes:{"type" : TNArchipelTypeVirtualMachineDiskGet}];

    [[self entity] sendStanza:infoStanza andRegisterSelector:@selector(didReceiveDisksInfo:) ofObject:self];
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
        
        for (var i = 0; i < [[[self buttonSource] itemArray] count]; i++)
        {
            var item  = [[[self buttonSource] itemArray] objectAtIndex:i];
            console.log([item stringValue] + " == " + [drive source]);
            if ([item stringValue] == [drive source])
                [[self buttonSource] selectItem:item];
        }
    }
    [self save:nil];
}

-(void)getISOsInfo
{
    var infoStanza = [TNStropheStanza iqWithAttributes:{"type" : TNArchipelTypeVirtualMachineDisk}];
    
    [infoStanza addChildName:@"query" withAttributes:{"type" : TNArchipelTypeVirtualMachineISOGet}];
    
    [[self entity] sendStanza:infoStanza andRegisterSelector:@selector(didReceiveISOsInfo:) ofObject:self];
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
        
        for (var i = 0; i < [[[self buttonSource] itemArray] count]; i++)
        {
            var item  = [[[self buttonSource] itemArray] objectAtIndex:i];
            console.log([item stringValue] + " == " + [drive source]);
            if ([item stringValue] == [drive source])
                [[self buttonSource] selectItem:item];
        }
    }
    [self save:nil];
}
@end