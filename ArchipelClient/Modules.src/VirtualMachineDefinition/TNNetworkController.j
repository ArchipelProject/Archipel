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


/*! @ingroup virtualmachinedefinition
    this is the virtual nic editor
*/
@implementation TNNetworkController : CPObject
{
    @outlet CPWindow        mainWindow;
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

//#pragma mark -
//#pragma mark Initilization

/*! called at cib awaking
*/
- (void)awakeFromCib
{
    [buttonType removeAllItems];
    [buttonModel removeAllItems];
    [buttonSource removeAllItems];

    [buttonModel addItemsWithTitles:TNArchipelNICModels];
    [buttonType addItemsWithTitles: TNArchipelNICTypes];
}


//#pragma mark -
//#pragma mark Utilities

/*! update the editor according to the current nic to edit
*/
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


//#pragma mark -
//#pragma mark Actions

/*! saves the change
    @param sender the sender of the action
*/
- (IBAction)save:(id)aSender
{
    [_nic setMac:[fieldMac stringValue]];
    [_nic setModel:[buttonModel title]];
    [_nic setSource:[buttonSource title]];

    [_delegate defineXML:aSender];
    [_table reloadData];
    [mainWindow close];
}

/*! change the type of the network
    @param sender the sender of the action
*/
- (IBAction)performRadioNicTypeChanged:(id)aSender
{
    var nicType = [[aSender selectedRadio] title];

    switch (nicType)
    {
        case @"Network":
            [buttonSource setEnabled:YES];
            [buttonSource removeAllItems];
            [_nic setType:@"network"];
            [self getHypervisorNetworks];
            break;

        case @"Bridge":
            [buttonSource setEnabled:YES];
            [buttonSource removeAllItems];
            [_nic setType:@"bridge"];
            [self getBridges];
            break;

        case @"User":
            [_nic setType:@"user"];
            [buttonSource removeAllItems];
            [buttonSource setEnabled:NO];
            break;
    }
}

- (IBAction)showWindow:(id)aSender
{
    [mainWindow center];
    [mainWindow makeKeyAndOrderFront:aSender];

    [self update];
}


//#pragma mark -
//#pragma mark XMPP Controls

/*! ask hypervisor for its networks
*/
- (void)getHypervisorNetworks
{
    var stanza  = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorNetwork}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorNetworkGetNames}];

    [_entity sendStanza:stanza andRegisterSelector:@selector(_didReceiveHypervisorNetworks:) ofObject:self];
}

/*! compute hypervisor networks
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)_didReceiveHypervisorNetworks:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        var names = [aStanza childrenWithName:@"network"];

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
        CPLog.error("Stanza error received in VirtualMachineDefintion _didReceiveHypervisorNetworks: I cannot handle this error. I am sorry. Do you hate me ? please. don't hate me. I don't hate you. The cake is a lie.");

    return NO;
}

/*! ask hypervisor for its bridges
*/
- (void)getBridges
{
    var stanza  = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorNetwork}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorNetworkBridges}];
    [_entity sendStanza:stanza andRegisterSelector:@selector(_didReceiveBridges:) ofObject:self];
}

/*! compute hypervisor bridges
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)_didReceiveBridges:(id)aStanza
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
        CPLog.error("Stanza error received in VirtualMachineDefintion _didReceiveBridges: I cannot handle this error. I am sorry. Do you hate me ? please. don't hate me. I don't hate you. The cake is a lie.");

    return NO;
}

@end