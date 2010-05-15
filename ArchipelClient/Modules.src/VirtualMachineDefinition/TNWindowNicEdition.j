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

TNArchipelTypeHypervisorNetwork            = @"archipel:hypervisor:network";
TNArchipelTypeHypervisorNetworkList        = @"list";

TNArchipelNICModels = ["ne2k_isa", "i82551", "i82557b", "i82559er", "ne2k_pci", "pcnet", "rtl8139", "e1000", "virtio"];
TNArchipelNICTypes  = ["network", "bridge", "user"];

@implementation TNWindowNicEdition : CPWindow
{
    @outlet CPTextField     fieldMac            @accessors;
    @outlet CPPopUpButton   buttonType          @accessors;
    @outlet CPPopUpButton   buttonModel         @accessors;
    @outlet CPPopUpButton   buttonSource        @accessors;
    @outlet CPRadioGroup    radioNetworkType    @accessors;

    TNStropheContact        _entity      @accessors(getter=entity, setter=setEntity:);
    TNNetworkInterface      _nic         @accessors(getter=nic, setter=setNic:);
    CPTableView             _table       @accessors(getter=table, setter=setTable:);
}

- (void)awakeFromCib
{
    [buttonType removeAllItems];
    [buttonModel removeAllItems];
    [buttonSource removeAllItems];

    [buttonModel addItemsWithTitles:TNArchipelNICModels];
    [buttonType addItemsWithTitles: TNArchipelNICTypes];
}

- (void)orderFront:(id)sender
{
    if (![self isVisible])
    {
        if ([_nic mac] == "00:00:00:00:00:00")
            [fieldMac setStringValue:generateMacAddr()];
        else
            [fieldMac setStringValue:[_nic mac]];

        [buttonSource removeAllItems];

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
        [buttonType selectItemWithTitle:[_nic type]];
        [buttonModel selectItemWithTitle:[_nic model]];
    }
    [super orderFront:sender];
}

- (IBAction)save:(id)sender
{
    [_nic setMac:[fieldMac stringValue]];
    [_nic setModel:[buttonModel title]];
    [_nic setSource:[buttonSource title]];

    [_table reloadData];
}

- (void)getHypervisorNetworks
{
    var networksStanza  = [TNStropheStanza iqWithAttributes:{"type" : TNArchipelTypeHypervisorNetwork}];

    [networksStanza addChildName:@"query" withAttributes:{"type" : TNArchipelTypeHypervisorNetworkList}];

    [_entity sendStanza:networksStanza andRegisterSelector:@selector(didReceiveHypervisorNetworks:) ofObject:self];
}

- (void)didReceiveHypervisorNetworks:(id)aStanza
{
    if ([aStanza getType] == @"success")
    {
        var names = [aStanza childrenWithName:@"network"]
        for (var i = 0; i < [names count]; i++)
        {
            var name = [[names objectAtIndex:i] valueForAttribute:@"name"];
            [buttonSource addItemWithTitle:name];
        }
        [buttonSource selectItemWithTitle:[_nic source]];
    }
    else
    {
        CPLog.debug("ERROR");
    }
}

- (IBAction)performRadioNicTypeChanged:(id)sender
{
    var nicType = [[sender selectedRadio] title];

    if (nicType == @"Network")
    {
        [buttonSource removeAllItems];
        [_nic setType:@"network"];
        
        [self getHypervisorNetworks];
    }
    else if(nicType == @"Bridge")
    {
        var source = ["virbr0", "virbr1", "virbr2"];
        
        [_nic setType:@"bridge"];
        
        [buttonSource removeAllItems];
        [buttonSource addItemsWithTitles:source];
    }
    else if(nicType == @"User")
    {
        [_nic setType:@"user"];
        [buttonSource removeAllItems];
    }
}

@end