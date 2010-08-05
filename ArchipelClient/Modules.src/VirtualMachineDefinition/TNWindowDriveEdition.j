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

TNXMLDescDriveTypeFile      = @"file";
TNXMLDescDriveTypeBlock     = @"block";
TNXMLDescDriveTypes         = [TNXMLDescDriveTypeFile, TNXMLDescDriveTypeBlock];

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
    @outlet CPTextField     fieldDevicePath;

    id                      _delegate       @accessors(property=delegate);
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

    [buttonType addItemsWithTitles:TNXMLDescDriveTypes];
    [buttonTarget addItemsWithTitles:TNXMLDescDiskTargetsIDE];
    [buttonBus addItemsWithTitles:TNXMLDescDiskBuses];
}

- (void)update
{
    [radioDriveType setTarget:nil];
    for (var i = 0; i < [[radioDriveType radios] count]; i++)
    {
        var radio = [[radioDriveType radios] objectAtIndex:i];
        if ((([radio title] == @"Hard drive") && ([_drive device] == @"disk"))
            ||  (([radio title] == @"CD/DVD") && ([_drive device] == @"cdrom")) )
        {
            [radio setState:CPOnState];
            break;
        }
    }
    [radioDriveType setTarget:self];
    
    if ([_drive device] == @"disk")
        [self getDisksInfo];
    else if ([_drive device] == @"cdrom")
        [self getISOsInfo];
    
    [self populateTargetButton:nil];
    
    [buttonType selectItemWithTitle:[_drive type]];
    
    [buttonType selectItemWithTitle:[_drive type]]
    [self driveTypeDidChange:nil];
    
    [buttonTarget selectItemWithTitle:[_drive target]];
    [buttonBus selectItemWithTitle:[_drive bus]];
}


- (IBAction)populateTargetButton:(id)sender
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
    else if ([buttonBus title] == TNXMLDescDiskBusVIRTIO)
    {
        [buttonTarget addItemsWithTitles:TNXMLDescDiskTargets];
    }
    
    [buttonTarget selectItemWithTitle:[_drive target]];
}

- (IBAction)save:(id)sender
{
    if ([buttonSource isEnabled] && [buttonSource selectedItem])
    {
        [_drive setSource:[[buttonSource selectedItem] stringValue]];
    }
    else if ([buttonType title] == TNXMLDescDriveTypeBlock)
    {
        [_drive setSource:[fieldDevicePath stringValue]];
    }
    else if ([buttonType title] == TNXMLDescDriveTypeFile)
    {
        [_drive setSource:([_drive device] == @"cdrom") ? @"" : @"/tmp/nodisk"];
    }
    
    [_drive setType:[buttonType title]];

    var driveType = [[radioDriveType selectedRadio] title];
    
    if (driveType == @"Hard drive")
        [_drive setDevice:@"disk"];
    else
        [_drive setDevice:@"cdrom"];


    [_drive setTarget:[buttonTarget title]];
    [_drive setBus:[buttonBus title]];

    [_table reloadData];
    
    [_delegate defineXML:sender];
    [self close];
}

- (IBAction)performRadioDriveTypeChanged:(id)sender
{
    var driveType = [[radioDriveType selectedRadio] title];
    
    if (driveType == @"Hard drive")
    {
        if ([buttonBus title] == TNXMLDescDiskBusIDE)
            [buttonTarget selectItemWithTitle:@"hda"];
        else if ([buttonBus title] == TNXMLDescDiskBusSCSI)
            [buttonTarget selectItemWithTitle:@"sda"];
        else if ([buttonBus title] == TNXMLDescDiskBusVIRTIO)
            [buttonTarget selectItemWithTitle:@"hda"];
            
        [self getDisksInfo];
    }
    else
    {
        if ([buttonBus title] == TNXMLDescDiskBusIDE)
            [buttonTarget selectItemWithTitle:@"hdc"];
        else if ([buttonBus title] == TNXMLDescDiskBusSCSI)
            [buttonTarget selectItemWithTitle:@"sdc"];
        else if ([buttonBus title] == TNXMLDescDiskBusVIRTIO)
            [buttonTarget selectItemWithTitle:@"sdc"];
            
        [self getISOsInfo];
    }
}

- (IBAction)driveTypeDidChange:(id)sender
{
    if ([buttonType title] == TNXMLDescDriveTypeBlock)
    {
        [fieldDevicePath setHidden:NO];
        [buttonSource setHidden:YES];
        
        [fieldDevicePath setEnabled:YES];
        [buttonSource setEnabled:NO];
        
        if (sender)
            [fieldDevicePath setStringValue:@"/dev/cdrom"];
        else
            [fieldDevicePath setStringValue:[_drive source]];
    }
    else if ([buttonType title] == TNXMLDescDriveTypeFile)
    {
        [fieldDevicePath setHidden:YES];
        [buttonSource setHidden:NO];
        
        [fieldDevicePath setEnabled:NO];
        [buttonSource setEnabled:YES];
        
        [fieldDevicePath setStringValue:@""];
    }
}

-(void)getDisksInfo
{
    var stanza = [TNStropheStanza iqWithType:@"get"];
    
    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeVirtualMachineDisk}];
    [stanza addChildName:@"archipel" withAttributes:{
        "action": TNArchipelTypeVirtualMachineDiskGet}];

    [_entity sendStanza:stanza andRegisterSelector:@selector(didReceiveDisksInfo:) ofObject:self];
}

- (void)didReceiveDisksInfo:(id)aStanza
{
    var responseType    = [aStanza type];
    var responseFrom    = [aStanza from];

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
            {
                [buttonSource selectItem:item];
                break;
            }
        }
    }
}



-(void)getISOsInfo
{
    var stanza = [TNStropheStanza iqWithType:@"get"];
    
    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeVirtualMachineDisk}];
    [stanza addChildName:@"archipel" withAttributes:{"action": TNArchipelTypeVirtualMachineISOGet}];
    
    [_entity sendStanza:stanza andRegisterSelector:@selector(didReceiveISOsInfo:) ofObject:self];
}


- (void)didReceiveISOsInfo:(id)aStanza
{
    var responseType    = [aStanza type];
    var responseFrom    = [aStanza from];
    
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
            {
                [buttonSource selectItem:item];
                break;
            }
                
        }
    }
}


@end
