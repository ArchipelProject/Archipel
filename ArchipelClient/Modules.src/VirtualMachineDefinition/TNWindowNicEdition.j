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

@import "TNDatasourceNetworkInterfaces.j"

TNArchipelTypeHypervisorNetwork            = @"archipel:hypervisor:network";
TNArchipelTypeHypervisorNetworkList        = @"list";

@implementation TNWindowNicEdition : CPWindow
{
    @outlet CPTextField     fieldMac            @accessors;
    @outlet CPPopUpButton   buttonType          @accessors;
    @outlet CPPopUpButton   buttonModel         @accessors;
    @outlet CPPopUpButton   buttonSource        @accessors;
    @outlet CPRadioGroup    radioNetworkType    @accessors;

    TNStropheContact        entity      @accessors;
    TNNetworkInterface      nic         @accessors;
    CPTableView             table       @accessors;
}

- (void)awakeFromCib
{
    [[self buttonType] removeAllItems];
    [[self buttonModel] removeAllItems];
    [[self buttonSource] removeAllItems];

    var models = ["ne2k_isa", "i82551", "i82557b", "i82559er", "ne2k_pci", "pcnet", "rtl8139", "e1000", "virtio"];
    for (var i = 0; i < models.length; i++)
    {
        var item = [[CPMenuItem alloc] initWithTitle:models[i] action:nil keyEquivalent:nil];
        [[self buttonModel] addItem:item];
    }

    var types = ["network", "bridge", "user"];
    for (var i = 0; i < types.length; i++)
    {
        var item = [[CPMenuItem alloc] initWithTitle:types[i] action:nil keyEquivalent:nil];
        [[self buttonType] addItem:item];
    }
}

- (void)orderFront:(id)sender
{
    if (![self isVisible])
    {
        if ([nic mac] == "00:00:00:00:00:00")
            [[self fieldMac] setStringValue:generateMacAddr()];
        else
            [[self fieldMac] setStringValue:[nic mac]];

        [[self buttonSource] removeAllItems];

        for (var i = 0; i < [[radioNetworkType radios] count]; i++)
        {
            var radio = [[radioNetworkType radios] objectAtIndex:i];

            if ([[radio title] lowercaseString] == [nic type])
            {
                [radio setState:CPOnState];
                [self performRadioNicTypeChanged:radioNetworkType];
                break;
            }
        }
        [[self buttonType] selectItemWithTitle:[nic type]];
        [[self buttonModel] selectItemWithTitle:[nic model]];
    }
    [super orderFront:sender];
}

- (IBAction)save:(id)sender
{
    [nic setMac:[[self fieldMac] stringValue]];
    [nic setModel:[[self buttonModel] title]];
    [nic setSource:[[self buttonSource] title]];

    [[self table] reloadData];
}

- (void)getHypervisorNetworks
{
    var networksStanza  = [TNStropheStanza iqWithAttributes:{"type" : TNArchipelTypeHypervisorNetwork}];

    [networksStanza addChildName:@"query" withAttributes:{"type" : TNArchipelTypeHypervisorNetworkList}];

    [[self entity] sendStanza:networksStanza andRegisterSelector:@selector(didReceiveHypervisorNetworks:) ofObject:self];
}

- (void)didReceiveHypervisorNetworks:(id)aStanza
{
    if ([aStanza getType] == @"success")
    {
        var names = [aStanza childrenWithName:@"network"]
        for (var i = 0; i < [names count]; i++)
        {
            var name = [[names objectAtIndex:i] valueForAttribute:@"name"];
            var item = [[CPMenuItem alloc] initWithTitle:name action:nil keyEquivalent:nil];
            [[self buttonSource] addItem:item];
        }
        [[self buttonSource] selectItemWithTitle:[nic source]];
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
        [[self buttonSource] removeAllItems];
        [self getHypervisorNetworks];
        [[self nic] setType:@"network"];
    }
    else if(nicType == @"Bridge")
    {
        [[self buttonSource] removeAllItems];
        [[self nic] setType:@"bridge"];
        var source = ["virbr0", "virbr1", "virbr2"];

        for (var i = 0; i < source.length; i++)
        {
            var item = [[CPMenuItem alloc] initWithTitle:source[i] action:nil keyEquivalent:nil];
            [[self buttonSource] addItem:item];
        }
    }
    else if(nicType == @"User")
    {
        [[self buttonSource] removeAllItems];
        [[self nic] setType:@"user"];
    }
}

@end