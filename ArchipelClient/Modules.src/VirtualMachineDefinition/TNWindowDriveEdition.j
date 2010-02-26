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

@implementation TNWindowDriveEdition : CPWindow
{
    @outlet CPTextField     fieldSource     @accessors;
    @outlet CPPopUpButton   buttonType      @accessors;
    @outlet CPPopUpButton   buttonDevice    @accessors;
    @outlet CPPopUpButton   buttonTarget    @accessors;
    @outlet CPPopUpButton   buttonBus       @accessors;

    TNNetworkDrive          drive           @accessors;
    CPTableView             table           @accessors;
}


- (void)awakeFromCib
{
    [[self buttonType] removeAllItems];
    [[self buttonDevice] removeAllItems];
    [[self buttonTarget] removeAllItems];
    [[self buttonBus] removeAllItems];
    
    var types = ["file"];
    for (var i = 0; i < types.length; i++)
    {
        var item = [[CPMenuItem alloc] initWithTitle:types[i] action:nil keyEquivalent:nil];
        [[self buttonType] addItem:item];
    }
    
    var devices = ["disk", "cdrom"];
    for (var i = 0; i < devices.length; i++)
    {
        var item = [[CPMenuItem alloc] initWithTitle:devices[i] action:nil keyEquivalent:nil];
        [[self buttonDevice] addItem:item];
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
    [[self fieldSource] setStringValue:[drive source]];
    
    [[self buttonType] selectItemWithTitle:[drive type]];
    [[self buttonDevice] selectItemWithTitle:[drive device]];
    [[self buttonTarget] selectItemWithTitle:[drive target]];
    [[self buttonBus] selectItemWithTitle:[drive bus]];
    
    [super orderFront:sender];
}

- (IBAction)save:(id)sender
{
    [drive setSource:[[self fieldSource] stringValue]];
    [drive setType:[[self buttonType] title]];
    [drive setDevice:[[self buttonDevice] title]];
    [drive setTarget:[[self buttonTarget] title]];
    [drive setBus:[[self buttonBus] title]];
    
    [[self table] reloadData];
}
@end