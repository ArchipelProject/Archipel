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
    @outlet CPPopUpButton   buttonBus;
    @outlet CPPopUpButton   buttonSource;
    @outlet CPPopUpButton   buttonTarget;
    @outlet CPPopUpButton   buttonType;
    @outlet CPRadioGroup    radioDriveType;

    CPTableView             _table          @accessors(property=table);
    TNNetworkDrive          _drive          @accessors(property=drive);
    TNStropheContact        _entity         @accessors(property=entity);
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
        [buttonType selectItemWithTitle:[_drive type]];
        [buttonTarget selectItemWithTitle:[_drive target]];
        [buttonBus selectItemWithTitle:[_drive bus]];
        
        if ([_drive device] == @"disk")
            [[[radioDriveType radios] objectAtIndex:0] setState:CPOnState];
        else if ([_drive device] == @"cdrom")
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
    [buttonTarget selectItemWithTitle:[_drive target]];
}



- (IBAction)save:(id)sender
{
    if (sender == buttonBus)
    {
       [self populateTargetButton];
    }
    if ([buttonSource selectedItem])
        [_drive setSource:[[buttonSource selectedItem] stringValue]];
    else
        [_drive setSource:@"/tmp/nodisk"];
    
    [_drive setType:[buttonType title]];

    var driveType = [[radioDriveType selectedRadio] title];
    
    if (driveType == @"Hard drive")
        [_drive setDevice:@"disk"];
    else
        [_drive setDevice:@"cdrom"];


    [_drive setTarget:[buttonTarget title]];
    [_drive setBus:[buttonBus title]];

    [_table reloadData];
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
    var stanza = [TNStropheStanza iqWithType:@"get"];
    
    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeVirtualMachineDisk}];
    [stanza addChildName:@"archipel" withAttributes:{
        "xmlns": TNArchipelTypeVirtualMachineDisk, 
        "action": TNArchipelTypeVirtualMachineDiskGet}];

    [_entity sendStanza:stanza andRegisterSelector:@selector(didReceiveDisksInfo:) ofObject:self];
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

            if ([item stringValue] == [_drive source])
                [buttonSource selectItem:item];
        }
    }
    
    [self save:nil];
}

-(void)getISOsInfo
{
    var stanza = [TNStropheStanza iqWithType:@"get"];
    
    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeVirtualMachineDisk}];
    [stanza addChildName:@"archipel" withAttributes:{
        "xmlns": TNArchipelTypeVirtualMachineDisk, 
        "action": TNArchipelTypeVirtualMachineISOGet}];
        
    [_entity sendStanza:stanza andRegisterSelector:@selector(didReceiveISOsInfo:) ofObject:self];
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
            
            if ([item stringValue] == [_drive source])
                [buttonSource selectItem:item];
        }
    }
    [self save:nil];
}
@end