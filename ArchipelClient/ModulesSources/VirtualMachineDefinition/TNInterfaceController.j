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

@import <Foundation/Foundation.j>
@import <AppKit/CPButton.j>
@import <AppKit/CPPopUpButton.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPView.j>

var TNArchipelTypeHypervisorNetwork                 = @"archipel:hypervisor:network",
    TNArchipelTypeHypervisorNuageNetwork            = @"archipel:hypervisor:nuage:network",
    TNArchipelTypeHypervisorNetworkGetNames         = @"getnames",
    TNArchipelTypeHypervisorNetworkBridges          = @"bridges",
    TNArchipelTypeHypervisorNetworkNICs             = @"getnics",
    TNArchipelTypeHypervisorNetworkGetNWFilters     = @"getnwfilters",
    TNArchipelTypeHypervisorNuageNetworkGetNames    = @"getnames";

/*! @ingroup virtualmachinedefinition
    this is the virtual nic editor
*/
@implementation TNInterfaceController : CPObject
{
    @outlet CPButtonBar         buttonBarNetworkParameters;
    @outlet CPCheckBox          checkBoxBandwidthInbound;
    @outlet CPCheckBox          checkBoxBandwidthOutbound;
    @outlet CPPopover           mainPopover;
    @outlet CPPopUpButton       buttonModel;
    @outlet CPPopUpButton       buttonNetworkFilter;
    @outlet CPPopUpButton       buttonSource;
    @outlet CPPopUpButton       buttonType;
    @outlet CPTableView         tableViewNetworkFilterParameters;
    @outlet CPTextField         fieldBandwidthInboundAverage;
    @outlet CPTextField         fieldBandwidthInboundBurst;
    @outlet CPTextField         fieldBandwidthInboundPeak;
    @outlet CPTextField         fieldBandwidthOutboundAverage;
    @outlet CPTextField         fieldBandwidthOutboundBurst;
    @outlet CPTextField         fieldBandwidthOutboundPeak;
    @outlet CPTextField         fieldErrorMessage;
    @outlet CPTextField         fieldMac;
    @outlet CPTextField         fieldNuageInterfaceIP;
    @outlet CPTextField         labelNuageInterfaceIP;
    @outlet CPView              viewNWFilterParametersContainer;
    @outlet CPButton            buttonOK;

    id                          _delegate   @accessors(property=delegate);
    CPTableView                 _table      @accessors(property=table);
    TNLibvirtDeviceInterface    _nic        @accessors(property=nic);
    TNLibvirtDomainMetadata     _metadata   @accessors(property=metadata);
    TNStropheContact            _entity     @accessors(property=entity);

    TNTableViewDataSource       _datasourceNWFilterParameters;
}

#pragma mark -
#pragma mark Initilization

/*! called at cib awaking
*/
- (void)awakeFromCib
{
    [viewNWFilterParametersContainer setBorderedWithHexColor:@"#C0C7D2"];

    [buttonType removeAllItems];
    [buttonModel removeAllItems];
    [buttonSource removeAllItems];
    [buttonNetworkFilter removeAllItems];

    [buttonModel addItemsWithTitles:TNLibvirtDeviceInterfaceModels];
    [buttonType addItemsWithTitles: TNLibvirtDeviceInterfaceTypes];

    var addButton  = [CPButtonBar plusButton];
    [addButton setTarget:self];
    [addButton setAction:@selector(addNWFilterParameter:)];

    var removeButton  = [CPButtonBar minusButton];
    [removeButton setTarget:self];
    [removeButton setAction:@selector(removeNWFilterParameter:)];

    [buttonBarNetworkParameters setButtons:[addButton, removeButton]];
}


#pragma mark -
#pragma mark Utilities

/*! send this message to update GUI according to permissions
*/
- (void)updateAfterPermissionChanged
{
    [_delegate setControl:buttonType enabledAccordingToPermissions:[@"network_getnames", @"network_bridges"]]
}

/*! update the editor according to the current nic to edit
*/
- (void)update
{
    [fieldErrorMessage setStringValue:@""];

    [buttonSource removeAllItems];
    [buttonNetworkFilter removeAllItems];

    [buttonType selectItemWithTitle:[_nic type]];

    [self performNicTypeChanged:nil];
    [self updateAfterPermissionChanged];

    [buttonModel selectItemWithTitle:[_nic model]];

    [fieldMac setStringValue:[_nic MAC]];

    _datasourceNWFilterParameters = [[TNTableViewDataSource alloc] init];
    [tableViewNetworkFilterParameters setDataSource:_datasourceNWFilterParameters];
    [_datasourceNWFilterParameters setTable:tableViewNetworkFilterParameters];
    [_datasourceNWFilterParameters removeAllObjects];

    if ([_nic filterref])
        [_datasourceNWFilterParameters setContent:[[_nic filterref] parameters]];
    [tableViewNetworkFilterParameters reloadData];

    // Bandwidth
    [checkBoxBandwidthInbound setState:[[_nic bandwidth] inbound] ? CPOnState : CPOffState];
    [self inboundLimitChange:nil];
    [checkBoxBandwidthOutbound setState:[[_nic bandwidth] outbound] ? CPOnState : CPOffState];
    [self outboundLimitChange:nil];

    [fieldBandwidthInboundAverage setStringValue:[[[_nic bandwidth] inbound] average] || @""];
    [fieldBandwidthInboundPeak setStringValue:[[[_nic bandwidth] inbound] peak] || @""];
    [fieldBandwidthInboundBurst setStringValue:[[[_nic bandwidth] inbound] burst] || @""];

    [fieldBandwidthOutboundAverage setStringValue:[[[_nic bandwidth] outbound] average] || @""];
    [fieldBandwidthOutboundPeak setStringValue:[[[_nic bandwidth] outbound] peak] || @""];
    [fieldBandwidthOutboundBurst setStringValue:[[[_nic bandwidth] outbound] burst] || @""];
}


#pragma mark -
#pragma mark Actions


/*! add a new entry in the network filter parameter
    @param aSender the sender of the action
*/
- (void)addNWFilterParameter:(id)aSender
{
    [_datasourceNWFilterParameters addObject:[CPDictionary dictionaryWithObjectsAndKeys:@"parameter", @"name", @"value", @"value"]];
    [tableViewNetworkFilterParameters reloadData];
}

/*! remove the selected network filter parameter entries.
    @param aSender the sender of the action
*/
- (void)removeNWFilterParameter:(id)aSender
{
    var index = [tableViewNetworkFilterParameters selectedRow];

    if (index != -1)
        [_datasourceNWFilterParameters removeObjectAtIndex:index];

    [tableViewNetworkFilterParameters reloadData];
}

/*! saves the change
    @param aSender the sender of the action
*/
- (IBAction)save:(id)aSender
{
    [_nic setMAC:[fieldMac stringValue]];
    [_nic setModel:[buttonModel title]];
    [_nic setType:[buttonType title]];

    // source
    if (![_nic source])
    {
        var source = [[TNLibvirtDeviceInterfaceSource alloc] init];
        [_nic setSource:source]
    }

    // type
    switch ([_nic type])
    {
        case TNLibvirtDeviceInterfaceTypeNuage:
            [[_nic source] setNetwork:nil];
            [[_nic source] setBridge:@"auto"];
            [[_nic source] setDevice:nil];
            [[_nic source] setMode:nil];
            [_nic setNuageNetworkName:[buttonSource title]];
            [_nic setNuageNetworkInterfaceIP:[fieldNuageInterfaceIP stringValue]];
            break;

        case TNLibvirtDeviceInterfaceTypeNetwork:
            [[_nic source] setNetwork:[buttonSource title]];
            [[_nic source] setBridge:nil];
            [[_nic source] setDevice:nil];
            [[_nic source] setMode:nil];
            [_nic setTarget:nil];
            break;
        case TNLibvirtDeviceInterfaceTypeBridge:
            [[_nic source] setNetwork:nil];
            [[_nic source] setBridge:[buttonSource title]];
            [[_nic source] setDevice:nil];
            [[_nic source] setMode:nil];
            [_nic setTarget:nil];
            break;
        case TNLibvirtDeviceInterfaceTypeUser:
            [[_nic source] setNetwork:nil];
            [[_nic source] setBridge:nil];
            [[_nic source] setDevice:nil];
            [[_nic source] setMode:nil];
            [_nic setTarget:nil];
            break;
        case TNLibvirtDeviceInterfaceTypeDirect:
            [[_nic source] setNetwork:nil];
            [[_nic source] setBridge:nil];
            [[_nic source] setDevice:[buttonSource title]];
            [[_nic source] setMode:TNLibvirtDeviceInterfaceSourceModeBridge];
            [_nic setTarget:nil];
            break;
    }

    // Filter
    if ([buttonNetworkFilter title] != @"None")
    {
        var filter = [[TNLibvirtDeviceInterfaceFilterRef alloc] init];

        [filter setName:[buttonNetworkFilter title]];
        [filter setParameters:[_datasourceNWFilterParameters content]];

        [_nic setFilterref:filter];
    }
    else
    {
        [_nic setFilterref:nil];
    }

    // Bandwidth
    if ([checkBoxBandwidthInbound state] == CPOnState)
    {
        if (![_nic bandwidth])
            [_nic setBandwidth:[TNLibvirtDeviceInterfaceBandwidth defaultBandwidth]];

        if (![[_nic bandwidth] inbound])
            [[_nic bandwidth] setInbound:[[TNLibvirtDeviceInterfaceBandwidthInbound alloc] init]];

        if ([fieldBandwidthInboundAverage stringValue] == @"")
        {
            [fieldErrorMessage setStringValue:CPLocalizedString(@"You must set at least the \"average\" value for inbound limit", @"You must set at least the \"average\" value for inbound limit")];
            return;
        }
        [[[_nic bandwidth] inbound] setAverage:[fieldBandwidthInboundAverage intValue]];
        [[[_nic bandwidth] inbound] setPeak:[fieldBandwidthInboundPeak intValue]];
        [[[_nic bandwidth] inbound] setBurst:[fieldBandwidthInboundBurst intValue]];
    }
    else
    {
        [[_nic bandwidth] setInbound:nil];
    }

    if ([checkBoxBandwidthOutbound state] == CPOnState)
    {
        if (![_nic bandwidth])
            [_nic setBandwidth:[TNLibvirtDeviceInterfaceBandwidth defaultBandwidth]];

        if (![[_nic bandwidth] outbound])
            [[_nic bandwidth] setOutbound:[[TNLibvirtDeviceInterfaceBandwidthOutbound alloc] init]];

        if ([fieldBandwidthOutboundAverage stringValue] == @"")
        {
            [fieldErrorMessage setStringValue:CPLocalizedString(@"You must set at least the \"average\" value for outbound limit", @"You must set at least the \"average\" value for outbound limit")];
            return;
        }
        [[[_nic bandwidth] outbound] setAverage:[fieldBandwidthOutboundAverage intValue]];
        [[[_nic bandwidth] outbound] setPeak:[fieldBandwidthOutboundPeak intValue]];
        [[[_nic bandwidth] outbound] setBurst:[fieldBandwidthOutboundBurst intValue]];
    }
    else
    {
        [[_nic bandwidth] setOutbound:nil];
    }

    // final
    [_delegate handleDefinitionEdition:YES];

    if (![[_table dataSource] containsObject:_nic])
        [[_table dataSource] addObject:_nic];

    [_table reloadData];
    [mainPopover close];
}

/*! change the type of the network
    @param aSender the sender of the action
*/
- (IBAction)performNicTypeChanged:(id)aSender
{
    var nicType = [buttonType title];

    switch (nicType)
    {
        case TNLibvirtDeviceInterfaceTypeNuage:
            [buttonSource removeAllItems];
            [self getHypervisorNuageNetworks];
            [buttonSource setEnabled:YES];
            [fieldNuageInterfaceIP setStringValue:@""];
            [fieldNuageInterfaceIP setHidden:NO];
            [labelNuageInterfaceIP setHidden:NO];
            break;

        case TNLibvirtDeviceInterfaceTypeNetwork:
            [fieldNuageInterfaceIP setHidden:YES];
            [buttonSource removeAllItems];
            if ([_delegate currentEntityHasPermission:@"network_getnames"])
            {
                [_delegate setControl:buttonSource enabledAccordingToPermission:@"network_getnames"];
                [self getHypervisorNetworks];
            }
            else
                [buttonSource setEnabled:NO];
            break;

        case TNLibvirtDeviceInterfaceTypeBridge:
            [fieldNuageInterfaceIP setHidden:YES];
            [labelNuageInterfaceIP setHidden:YES];
            if ([_delegate currentEntityHasPermission:@"network_bridges"])
            {
                [_delegate setControl:buttonSource enabledAccordingToPermission:@"network_bridges"];
                [buttonSource removeAllItems];
                [self getBridges];
            }
            else
                [buttonSource setEnabled:NO]
            break;

        case TNLibvirtDeviceInterfaceTypeDirect:
            [fieldNuageInterfaceIP setHidden:YES];
            [labelNuageInterfaceIP setHidden:YES];
            [buttonSource removeAllItems];
            if ([_delegate currentEntityHasPermission:@"network_getnics"])
            {
                [_delegate setControl:buttonSource enabledAccordingToPermission:@"network_getnics"];
                [self getNics];
            }
            else
                [buttonSource setEnabled:NO];
            break;

        case TNLibvirtDeviceInterfaceTypeUser:
            [fieldNuageInterfaceIP setHidden:YES];
            [labelNuageInterfaceIP setHidden:YES];
            [buttonSource removeAllItems];
            [buttonSource setEnabled:NO];
            break;
    }

    [self getHypervisorNWFilters];
}

/*! show the main window
    @param aSender the sender of the action
*/
- (IBAction)openWindow:(id)aSender
{
    [mainPopover close];
    [self update];

    if ([aSender isKindOfClass:CPTableView])
    {
        var rect = [aSender rectOfRow:[aSender selectedRow]];
        rect.origin.y += rect.size.height / 2;
        rect.origin.x += rect.size.width / 2;
        [mainPopover showRelativeToRect:CPRectMake(rect.origin.x, rect.origin.y, 10, 10) ofView:aSender preferredEdge:nil];
    }
    else
        [mainPopover showRelativeToRect:nil ofView:aSender preferredEdge:nil];

    [mainPopover setDefaultButton:buttonOK];
}

/*! hide the main window
    @param aSender the sender of the action
*/
- (IBAction)closeWindow:(id)aSender
{
    [mainPopover close];
}

/*! Called when checkbox for inbound changed
    @param aSender the sender of the action
*/
- (IBAction)inboundLimitChange:(id)aSender
{
    if ([checkBoxBandwidthInbound state] == CPOnState)
    {
        [fieldBandwidthInboundAverage setEnabled:YES];
        [fieldBandwidthInboundPeak setEnabled:YES];
        [fieldBandwidthInboundBurst setEnabled:YES];
        if (![_nic bandwidth])
            [_nic setBandwidth:[TNLibvirtDeviceInterfaceBandwidth defaultBandwidth]];
    }
    else
    {
        [fieldBandwidthInboundAverage setEnabled:NO];
        [fieldBandwidthInboundPeak setEnabled:NO];
        [fieldBandwidthInboundBurst setEnabled:NO];
        [fieldBandwidthInboundAverage setStringValue:@""];
        [fieldBandwidthInboundPeak setStringValue:@""];
        [fieldBandwidthInboundBurst setStringValue:@""];

        if (![_nic bandwidth])
            [[_nic bandwidth] setInbound:nil];
    }
}

/*! Called when checkbox for outbound changed
    @param aSender the sender of the action
*/
- (IBAction)outboundLimitChange:(id)aSender
{
    if ([checkBoxBandwidthOutbound state] == CPOnState)
    {
        [fieldBandwidthOutboundAverage setEnabled:YES];
        [fieldBandwidthOutboundPeak setEnabled:YES];
        [fieldBandwidthOutboundBurst setEnabled:YES];
        if (![_nic bandwidth])
            [_nic setBandwidth:[TNLibvirtDeviceInterfaceBandwidth defaultBandwidth]];
    }
    else
    {
        [fieldBandwidthOutboundAverage setEnabled:NO];
        [fieldBandwidthOutboundPeak setEnabled:NO];
        [fieldBandwidthOutboundBurst setEnabled:NO];
        [fieldBandwidthOutboundAverage setStringValue:@""];
        [fieldBandwidthOutboundPeak setStringValue:@""];
        [fieldBandwidthOutboundBurst setStringValue:@""];

        if (![_nic bandwidth])
            [[_nic bandwidth] setOutbound:nil];
    }
}


#pragma mark -
#pragma mark XMPP Controls

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

        [buttonSource selectItemWithTitle:[[_nic source] network]];

        if (![buttonSource selectedItem])
            [buttonSource selectItemAtIndex:0];
    }
    else
    {
        [_delegate handleIqErrorFromStanza:aStanza];
    }

    return NO;
}



/*! ask hypervisor for its nuage networks
*/
- (void)getHypervisorNuageNetworks
{
    var stanza  = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorNuageNetwork}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorNuageNetworkGetNames}];

    [_entity sendStanza:stanza andRegisterSelector:@selector(_didReceiveHypervisorNuageNetworks:) ofObject:self];
}

/*! compute hypervisor nuage networks
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)_didReceiveHypervisorNuageNetworks:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        var names = [aStanza childrenWithName:@"network"];

        for (var i = 0; i < [names count]; i++)
        {
            var name = [[names objectAtIndex:i] valueForAttribute:@"name"];

            [buttonSource addItemWithTitle:name];
        }

        [buttonSource selectItemWithTitle:[_nic nuageNetworkName]];
        [fieldNuageInterfaceIP setStringValue:[_nic nuageNetworkInterfaceIP]];

        if (![buttonSource selectedItem])
            [buttonSource selectItemAtIndex:0];
    }
    else
    {
        [_delegate handleIqErrorFromStanza:aStanza];
    }

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
        [buttonSource selectItemWithTitle:[[_nic source] bridge]];

        if (![buttonSource selectedItem])
            [buttonSource selectItemAtIndex:0];
    }
    else
        [_delegate handleIqErrorFromStanza:aStanza];

    return NO;
}

/*! ask hypervisor for its bridges
*/
- (void)getNics
{
    var stanza  = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorNetwork}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorNetworkNICs}];
    [_entity sendStanza:stanza andRegisterSelector:@selector(_didReceiveNics:) ofObject:self];
}

/*! compute hypervisor bridges
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)_didReceiveNics:(id)aStanza
{
    if ([aStanza type] == @"result")
    {
        var hypervisorNics = [aStanza childrenWithName:@"nic"];

        [buttonSource removeAllItems];
        for (var i = 0; i < [hypervisorNics count]; i++)
        {
            var hypervisorNic = [[hypervisorNics objectAtIndex:i] valueForAttribute:@"name"];

            [buttonSource addItemWithTitle:hypervisorNic];
        }
        [buttonSource selectItemWithTitle:[[_nic source] device]];

        if (![buttonSource selectedItem])
            [buttonSource selectItemAtIndex:0];
    }
    else
        [_delegate handleIqErrorFromStanza:aStanza];

    return NO;
}


/*! get existing nics on the hypervisor
*/
- (void)getHypervisorNWFilters
{
    var stanza  = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorNetwork}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorNetworkGetNWFilters}];

    [_entity sendStanza:stanza andRegisterSelector:@selector(_didReceiveHypervisorNWFilters:) ofObject:self];
}

/*! compute the answer containing the nics information
*/
- (void)_didReceiveHypervisorNWFilters:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        var filters = [aStanza childrenWithName:@"filter"];

        [buttonNetworkFilter removeAllItems];
        [buttonNetworkFilter addItemWithTitle:@"None"]
        for (var i = 0; i < [filters count]; i++)
        {
            var filter = [filters objectAtIndex:i],
                name = [filter valueForAttribute:@"name"];
            [buttonNetworkFilter addItemWithTitle:name];
        }

        if ([[_nic filterref] name])
            [buttonNetworkFilter selectItemWithTitle:[[_nic filterref] name]];
        else
            [buttonNetworkFilter selectItemWithTitle:@"None"];
    }
    else
    {
        [buttonNetworkFilter addItemWithTitle:@"None"];
        [_delegate handleIqErrorFromStanza:aStanza];
    }
}

@end


// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNInterfaceController], comment);
}
