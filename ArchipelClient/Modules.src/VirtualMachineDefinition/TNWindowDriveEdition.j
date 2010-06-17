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

@import "TNDriveObject.j"

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
    [buttonType removeAllItems];
    [buttonTarget removeAllItems];
    [buttonBus removeAllItems];
    [buttonSource removeAllItems];

    [buttonType addItemsWithTitles:TNXMLDescDiskTypes];
    [buttonTarget addItemsWithTitles:TNXMLDescDiskTargetsIDE];
    [buttonBus addItemsWithTitles:TNXMLDescDiskBuses];
}

- (void)orderFront:(id)sender
{
    if (![self isVisible])
    {
        [buttonType selectItemWithTitle:[drive type]];
        [buttonTarget selectItemWithTitle:[drive target]];
        [buttonBus selectItemWithTitle:[drive bus]];
        
        if ([drive device] == @"disk")
            [[[radioDriveType radios] objectAtIndex:0] setState:CPOnState];
        else if ([drive device] == @"cdrom")
            [[[radioDriveType radios] objectAtIndex:1] setState:CPOnState];
        
        [self performRadioDriveTypeChanged:radioDriveType];
        
        [self populateTargetButton];
    }

    [super orderFront:sender];
}

- (void)populateTargetButton
{
    [buttonTarget removeAllItems];
    if ([buttonBus title] == TNXMLDescDiskBusIDE)
    {
        [buttonTarget addItemsWithTitles:TNXMLDescDiskTargetsIDE];
    }
    else if ([buttonBus title] == TNXMLDescDiskBusSCSI)
    {
        [buttonTarget addItemsWithTitles:TNXMLDescDiskTargetsSCSI];
    }
    [buttonTarget selectItemWithTitle:[drive target]];
}



- (IBAction)save:(id)sender
{
    if (sender == buttonBus)
    {
       [self populateTargetButton];
    }
    if ([buttonSource selectedItem])
        [drive setSource:[[buttonSource selectedItem] stringValue]];
    else
        [drive setSource:@"/tmp/nodisk"];
    
    [drive setType:[buttonType title]];

    var driveType = [[radioDriveType selectedRadio] title];
    
    if (driveType == @"Hard drive")
        [drive setDevice:@"disk"];
    else
        [drive setDevice:@"cdrom"];


    [drive setTarget:[buttonTarget title]];
    [drive setBus:[buttonBus title]];

    [[self table] reloadData];
}

- (IBAction)performRadioDriveTypeChanged:(id)sender
{
    console.log("PERFORMING performRadioDriveTypeChanged");
    var driveType = [[sender selectedRadio] title];
    
    if (driveType == @"Hard drive")
    {
        [self getDisksInfo];
        if ([buttonBus title] == TNXMLDescDiskBusIDE)
            [buttonTarget selectItemWithTitle:@"hda"];
        else
            [buttonTarget selectItemWithTitle:@"sda"];
    }
    else
    {
        [self getISOsInfo];
        if ([buttonBus title] == TNXMLDescDiskBusIDE)
            [buttonTarget selectItemWithTitle:@"hdc"];
        else
            [buttonTarget selectItemWithTitle:@"sdc"];
    }
}



-(void)getDisksInfo
{
    var infoStanza = [TNStropheStanza iq];
    
    [infoStanza addChildName:@"query" withAttributes:{
        "xmlns": TNArchipelTypeVirtualMachineDisk, 
        "type": "get", 
        "action" : TNArchipelTypeVirtualMachineDiskGet}];

    [[self entity] sendStanza:infoStanza andRegisterSelector:@selector(didReceiveDisksInfo:) ofObject:self];
}

- (void)didReceiveDisksInfo:(id)aStanza
{
    var responseType    = [aStanza getType];
    var responseFrom    = [aStanza getFrom];

    if (responseType == @"result")
    {
        var disks = [aStanza childrenWithName:@"disk"];
        [buttonSource removeAllItems];

        for (var i = 0; i < [disks count]; i++)
        {
            var disk    = [disks objectAtIndex:i];
            var vSize   = [[[disk valueForAttribute:@"virtualSize"] componentsSeparatedByString:@" "] objectAtIndex:0];
            var label   = [[[disk valueForAttribute:@"name"] componentsSeparatedByString:@"."] objectAtIndex:0] + " - " + vSize  + " (" + [disk valueForAttribute:@"diskSize"] + ")";
            var item    = [[TNMenuItem alloc] initWithTitle:label action:nil keyEquivalent:nil];

            [item setStringValue:[disk valueForAttribute:@"path"]];
            [buttonSource addItem:item];
        }

        for (var i = 0; i < [[buttonSource itemArray] count]; i++)
        {
            var item  = [[buttonSource itemArray] objectAtIndex:i];

            if ([item stringValue] == [drive source])
                [buttonSource selectItem:item];
        }
    }
    
    [self save:nil];
}

-(void)getISOsInfo
{
    var infoStanza = [TNStropheStanza iq];
    
    [infoStanza addChildName:@"query" withAttributes:{
        "xmlns": TNArchipelTypeVirtualMachineDisk, 
        "type": "get", 
        "action" : TNArchipelTypeVirtualMachineISOGet}];

    [[self entity] sendStanza:infoStanza andRegisterSelector:@selector(didReceiveISOsInfo:) ofObject:self];
}

- (void)didReceiveISOsInfo:(id)aStanza
{
    var responseType    = [aStanza getType];
    var responseFrom    = [aStanza getFrom];

    if (responseType == @"result")
    {
        var isos = [aStanza childrenWithName:@"iso"];
        [buttonSource removeAllItems];

        for (var i = 0; i < [isos count]; i++)
        {
            var iso     = [isos objectAtIndex:i];
            var label   = [iso valueForAttribute:@"name"];
            var item    = [[TNMenuItem alloc] initWithTitle:label action:nil keyEquivalent:nil];

            [item setStringValue:[iso valueForAttribute:@"path"]];
            [buttonSource addItem:item];
        }

        for (var i = 0; i < [[buttonSource itemArray] count]; i++)
        {
            var item  = [[buttonSource itemArray] objectAtIndex:i];
            
            if ([item stringValue] == [drive source])
                [buttonSource selectItem:item];
        }
    }
    [self save:nil];
}
@end