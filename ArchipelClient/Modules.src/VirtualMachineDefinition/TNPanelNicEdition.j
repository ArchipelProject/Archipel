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

@implementation TNPanelNicEdition : CPPanel
{
    @outlet CPTextField     fieldName       @accessors;
    @outlet CPTextField     fieldMac        @accessors;
    @outlet CPPopUpButton   buttonType      @accessors;
    @outlet CPPopUpButton   buttonModel     @accessors;
    @outlet CPPopUpButton   buttonSource    @accessors;


    TNNetworkInterface              nic         @accessors;
    CPTableView                     table       @accessors;
}

- (id)initWithContentRect:(CGRect)aRect styleMask:(CPNumber)aStyle
{
    if (self = [super initWithContentRect:aRect styleMask:aStyle])
    {
        [self setFloatingPanel:NO];
    }
    
    return self;
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
    
    var types = ["bridge", "user"];
    for (var i = 0; i < types.length; i++)
    {
        var item = [[CPMenuItem alloc] initWithTitle:types[i] action:nil keyEquivalent:nil];
        [[self buttonType] addItem:item];
    }
    
    var source = ["virbr0", "virbr1", "virbr2"];
    for (var i = 0; i < source.length; i++)
    {
        var item = [[CPMenuItem alloc] initWithTitle:source[i] action:nil keyEquivalent:nil];
        [[self buttonSource] addItem:item];
    }
}

- (void)orderFront:(id)sender
{
    [[self fieldName] setStringValue:[nic name]];
    [[self fieldMac] setStringValue:[nic mac]];

    [[self buttonSource] selectItemWithTitle:[nic source]];
    [[self buttonType] selectItemWithTitle:[nic type]];
    [[self buttonModel] selectItemWithTitle:[nic model]];
    
    
    [super orderFront:sender];
}

- (IBAction)save:(id)sender
{
    [nic setName:[[self fieldName] stringValue]];
    [nic setMac:[[self fieldMac] stringValue]];
    [nic setType:[[self buttonType] title]];
    [nic setModel:[[self buttonModel] title]];
    [nic setSource:[[self buttonSource] title]];
    
    [[self table] reloadData];
}
@end