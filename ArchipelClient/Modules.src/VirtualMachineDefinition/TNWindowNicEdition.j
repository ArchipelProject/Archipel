/*
 * TNWindowNICEdition.j
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

@import "TNNetworkInterfaceObject.j"

TNArchipelTypeHypervisorNetwork             = @"archipel:hypervisor:network";
TNArchipelTypeHypervisorNetworkGetNames     = @"getnames";
TNArchipelTypeHypervisorNetworkBridges      = @"bridges";

TNArchipelNICModels = ["ne2k_isa", "i82551", "i82557b", "i82559er", "ne2k_pci", "pcnet", "rtl8139", "e1000", "virtio"];
TNArchipelNICTypes  = ["network", "bridge", "user"];

@implementation TNWindowNicEdition : CPWindow
{
    @outlet CPPopUpButton   buttonModel;
    @outlet CPPopUpButton   buttonSource;
    @outlet CPPopUpButton   buttonType;
    @outlet CPRadioGroup    radioNetworkType;
    @outlet CPTextField     fieldMac;

    id                      _delegate   @accessors(property=delegate);
    CPTableView             _table      @accessors(property=table);
    TNNetworkInterface      _nic        @accessors(property=nic);
    TNStropheContact        _entity     @accessors(property=entity);
}

- (void)awakeFromCib
{
    [buttonType removeAllItems];
    [buttonModel removeAllItems];
    [buttonSource removeAllItems];

    [buttonModel addItemsWithTitles:TNArchipelNICModels];
    [buttonType addItemsWithTitles: TNArchipelNICTypes];
}

- (void)update
{
    if ([_nic mac] == "00:00:00:00:00:00")
        [fieldMac setStringValue:generateMacAddr()];
    else
        [fieldMac setStringValue:[_nic mac]];

    [buttonSource removeAllItems];
    
    [radioNetworkType setTarget:nil];
    for (var i = 0; i < [[radioNetworkType radios] count]; i++)
    {
        var radio = [[radioNetworkType radios] objectAtIndex:i];

        if ([[radio title] lowercaseString] == [_nic type])
        {
            [radio setState:CPOnState];
            [self performRadioNicTypeChanged:radioNetworkType];
            break;
        }
    }
    [radioNetworkType setTarget:self];
    
    [buttonType selectItemWithTitle:[_nic type]];
    [buttonModel selectItemWithTitle:[_nic model]];
    [buttonSource selectItemWithTitle:[_nic source]];
}

- (IBAction)save:(id)sender
{
    [_nic setMac:[fieldMac stringValue]];
    [_nic setModel:[buttonModel title]];
    [_nic setSource:[buttonSource title]];
    
    [_delegate defineXML:sender];
    [_table reloadData];
    [self close];
}

- (void)getHypervisorNetworks
{
    var stanza  = [TNStropheStanza iqWithType:@"get"];
    
    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeHypervisorNetwork}];
    [stanza addChildName:@"archipel" withAttributes:{
        "action": TNArchipelTypeHypervisorNetworkGetNames}];

    [_entity sendStanza:stanza andRegisterSelector:@selector(didReceiveHypervisorNetworks:) ofObject:self];
}

- (void)didReceiveHypervisorNetworks:(id)aStanza
{
    if ([aStanza type] == @"result")
    {
        var names = [aStanza childrenWithName:@"network"]
        for (var i = 0; i < [names count]; i++)
        {
            var name = [[names objectAtIndex:i] valueForAttribute:@"name"];
            [buttonSource addItemWithTitle:name];
        }
        [buttonSource selectItemWithTitle:[_nic source]];

        if (![buttonSource selectedItem])
        {
            [buttonSource selectItemAtIndex:0];
        }
    }
    else
        CPLog.error("Stanza error received in VirtualMachineDefintion didReceiveHypervisorNetworks: I cannot handle this error. I am sorry. Do you hate me ? please. don't hate me. I don't hate you. The cake is a lie.")
}

- (void)getBridges
{
    var stanza  = [TNStropheStanza iqWithType:@"get"];
    
    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeHypervisorNetwork}];
    [stanza addChildName:@"archipel" withAttributes:{
        "action": TNArchipelTypeHypervisorNetworkBridges}];
    [_entity sendStanza:stanza andRegisterSelector:@selector(didReceiveBridges:) ofObject:self];
}

- (void)didReceiveBridges:(id)aStanza
{
    if ([aStanza type] == @"result")
    {
        var bridges = [aStanza childrenWithName:@"bridge"];
        
        [buttonSource removeAllItems];
        for (var i = 0; i < [bridges count]; i++)
        {
            var bridge = [[bridges objectAtIndex:i] valueForAttribute:@"name"];
            [buttonSource addItemWithTitle:bridge];
        }
        [buttonSource selectItemWithTitle:[_nic source]];

        if (![buttonSource selectedItem])
        {
            [buttonSource selectItemAtIndex:0];
        }
    }
    else
        CPLog.error("Stanza error received in VirtualMachineDefintion didReceiveHypervisorNetworks: I cannot handle this error. I am sorry. Do you hate me ? please. don't hate me. I don't hate you. The cake is a lie.")
}

- (IBAction)performRadioNicTypeChanged:(id)sender
{
    var nicType = [[sender selectedRadio] title];

    if (nicType == @"Network")
    {
        [buttonSource setEnabled:YES];
        [buttonSource removeAllItems];
        [_nic setType:@"network"];
        
        [self getHypervisorNetworks];
    }
    else if(nicType == @"Bridge")
    {
        [buttonSource setEnabled:YES];
        [buttonSource removeAllItems];
        [_nic setType:@"bridge"];        
        [self getBridges];
    }
    else if(nicType == @"User")
    {
        [_nic setType:@"user"];
        [buttonSource removeAllItems];
        [buttonSource setEnabled:NO];
    }
}

@end