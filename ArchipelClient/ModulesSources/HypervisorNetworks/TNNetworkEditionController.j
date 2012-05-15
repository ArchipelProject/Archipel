/*
 * TNNetworkEditionController.j
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
@import <AppKit/CPButtonBar.j>
@import <AppKit/CPCheckBox.j>
@import <AppKit/CPPopUpButton.j>
@import <AppKit/CPTableView.j>
@import <AppKit/CPTabView.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPView.j>
@import <AppKit/CPWindow.j>

@import <TNKit/TNTableViewDataSource.j>

@import "Model/TNLibvirtNet.j"



/*! @ingroup hypervisornetworks
    The newtork window edition
*/
@implementation TNNetworkEditionController : CPObject
{
    @outlet CPButton            buttonOK;
    @outlet CPButtonBar         buttonBarControlDHCPHosts;
    @outlet CPButtonBar         buttonBarControlDHCPRanges;
    @outlet CPCheckBox          checkBoxAutostart;
    @outlet CPCheckBox          checkBoxBandwidthInbound;
    @outlet CPCheckBox          checkBoxBandwidthOutbound;
    @outlet CPCheckBox          checkBoxDHCPEnabled;
    @outlet CPCheckBox          checkBoxSTPEnabled;
    @outlet CPPopover           mainPopover;
    @outlet CPPopUpButton       buttonForwardDevice;
    @outlet CPPopUpButton       buttonForwardMode;
    @outlet CPTableView         tableViewHosts;
    @outlet CPTableView         tableViewRanges;
    @outlet CPTabView           tabViewDHCP;
    @outlet CPTextField         fieldBandwidthInboundAverage;
    @outlet CPTextField         fieldBandwidthInboundBurst;
    @outlet CPTextField         fieldBandwidthInboundPeak;
    @outlet CPTextField         fieldBandwidthOutboundAverage;
    @outlet CPTextField         fieldBandwidthOutboundBurst;
    @outlet CPTextField         fieldBandwidthOutboundPeak;
    @outlet CPTextField         fieldBridgeDelay;
    @outlet CPTextField         fieldBridgeIP;
    @outlet CPTextField         fieldBridgeName;
    @outlet CPTextField         fieldBridgeNetmask;
    @outlet CPTextField         fieldErrorMessage;
    @outlet CPTextField         fieldNetworkName;
    @outlet CPView              viewHostsConf;
    @outlet CPView              viewRangesConf;

    CPArray                     _currentNetworkInterfaces   @accessors(property=currentNetworkInterfaces);
    id                          _delegate                   @accessors(property=delegate);
    TNLibvirtNetwork            _network                    @accessors(property=network);

    CPButton                    _minusButtonDHCPHosts;
    CPButton                    _minusButtonDHCPRanges;
    CPButton                    _plusButtonDHCPHosts;
    CPButton                    _plusButtonDHCPRanges;
    TNTableViewDataSource       _datasourceDHCPHosts;
    TNTableViewDataSource       _datasourceDHCPRanges;
}

#pragma mark -
#pragma mark  Initialization

- (void)awakeFromCib
{
    _plusButtonDHCPHosts = [CPButtonBar plusButton];
    [_plusButtonDHCPHosts setTarget:self];
    [_plusButtonDHCPHosts setAction:@selector(addDHCPHost:)];
    [_plusButtonDHCPHosts setToolTip:CPBundleLocalizedString(@"Create a new DHCP reservation", @"Create a new DHCP reservation")];

    _minusButtonDHCPHosts= [CPButtonBar minusButton];
    [_minusButtonDHCPHosts setTarget:self];
    [_minusButtonDHCPHosts setAction:@selector(removeDHCPHost:)];
    [_minusButtonDHCPHosts setToolTip:CPBundleLocalizedString(@"Remove selected DHCP reservation", @"Remove selected DHCP reservation")];

    [buttonBarControlDHCPHosts setButtons:[_plusButtonDHCPHosts, _minusButtonDHCPHosts]];

    _plusButtonDHCPRanges = [CPButtonBar plusButton];
    [_plusButtonDHCPRanges setTarget:self];
    [_plusButtonDHCPRanges setAction:@selector(addDHCPRange:)];
    [_plusButtonDHCPRanges setToolTip:CPBundleLocalizedString(@"Create a new DHCP range", @"Create a new DHCP range")];

    _minusButtonDHCPRanges = [CPButtonBar minusButton];
    [_minusButtonDHCPRanges setTarget:self];
    [_minusButtonDHCPRanges setAction:@selector(removeDHCPRange:)];
    [_minusButtonDHCPRanges setToolTip:CPBundleLocalizedString(@"Remove selected DHCP range", @"Remove selected DHCP range")];

    [buttonBarControlDHCPRanges setButtons:[_plusButtonDHCPRanges, _minusButtonDHCPRanges]];

    [buttonForwardMode removeAllItems];
    [buttonForwardMode addItemsWithTitles:TNLibvirtNetworkForwardModes];
    [buttonForwardMode setToolTip:CPBundleLocalizedString(@"Choose the forward mode for this virtual network", @"Choose the forward mode for this virtual network")];
    [buttonForwardMode setTarget:self];
    [buttonForwardMode setAction:@selector(forwardModeChanged:)];

    [buttonForwardDevice removeAllItems];
    [buttonForwardDevice setToolTip:CPBundleLocalizedString(@"Select the hypervisor network card you want to use for this virtual network", @"Select the hypervisor network card you want to use for this virtual network")];

    // TABLE FOR RANGES
    _datasourceDHCPRanges   = [[TNTableViewDataSource alloc] init];
    [tableViewRanges setDelegate:self];
    [tableViewRanges setDataSource:_datasourceDHCPRanges];
    [_datasourceDHCPRanges setTable:tableViewRanges];

    // TABLE FOR HOSTS
    _datasourceDHCPHosts = [[TNTableViewDataSource alloc] init];
    [tableViewHosts setDelegate:self];
    [tableViewHosts setDataSource:_datasourceDHCPHosts];
    [_datasourceDHCPHosts setTable:tableViewHosts];


    var menuRange = [[CPMenu alloc] init],
        menuHost = [[CPMenu alloc] init];

    [menuRange addItemWithTitle:CPBundleLocalizedString(@"Add new range", @"Add new range") action:@selector(addDHCPRange:) keyEquivalent:@""];
    [menuRange addItemWithTitle:CPBundleLocalizedString(@"Remove", @"Remove") action:@selector(removeDHCPRange:) keyEquivalent:@""];
    [tableViewRanges setMenu:menuRange];

    [menuHost addItemWithTitle:CPBundleLocalizedString(@"Add new host reservation", @"Add new host reservation") action:@selector(addDHCPHost:) keyEquivalent:@""];
    [menuHost addItemWithTitle:CPBundleLocalizedString(@"Remove", @"Remove") action:@selector(removeDHCPHost:) keyEquivalent:@""];
    [tableViewHosts setMenu:menuHost];

    var tabViewDHCPRangesItem = [[CPTabViewItem alloc] initWithIdentifier:@"id1"],
        tabViewDHCPHostsItem = [[CPTabViewItem alloc] initWithIdentifier:@"id2"];

    [tabViewDHCPRangesItem setView:viewRangesConf];
    [tabViewDHCPRangesItem setLabel:CPBundleLocalizedString(@"DHCP Ranges", @"DHCP Ranges")];
    [tabViewDHCP addTabViewItem:tabViewDHCPRangesItem];

    [tabViewDHCPHostsItem setView:viewHostsConf];
    [tabViewDHCPHostsItem setLabel:CPBundleLocalizedString(@"DHCP Hosts", @"DHCP Hosts")];
    [tabViewDHCP addTabViewItem:tabViewDHCPHostsItem];

    [fieldNetworkName setToolTip:CPBundleLocalizedString(@"Enter the name of the virtual network", @"Enter the name of the virtual network")];
    [fieldBridgeName setToolTip:CPBundleLocalizedString(@"Enter the name of the bridge to create when this network is activated", @"Enter the name of the bridge to create when this network is activated")];
    [fieldBridgeDelay setToolTip:CPBundleLocalizedString(@"Enter the value of delay for the bridge", @"Enter the value of delay for the bridge")];
    [fieldBridgeIP setToolTip:CPBundleLocalizedString(@"The IP address to assign to the bridge", @"The IP address to assign to the bridge")];
    [fieldBridgeNetmask setToolTip:CPBundleLocalizedString(@"The netmask to use for the bridge", @"The netmask to use for the bridge")];
    [checkBoxSTPEnabled setToolTip:CPBundleLocalizedString(@"Activate or deactivate Spanning Tree Protocol for the bridge", @"Activate or deactivate Spanning Tree Protocol for the bridge")];
    [checkBoxDHCPEnabled setToolTip:CPBundleLocalizedString(@"Enable DHCP for this virtual network", @"Enable DHCP for this virtual network")];
    [checkBoxAutostart setToolTip:CPLocalizedString(@"Define if network should start with host", @"Define if network should start with host")];
}


#pragma mark -
#pragma mark CPWindow override

/*! Set the GUI for isolated mode
*/
- (void)GUIForIsolatedMode
{
    [buttonForwardDevice setEnabled:NO];
    [fieldBridgeName setEnabled:YES];
    [fieldBridgeIP setEnabled:YES];
    [fieldBridgeNetmask setEnabled:YES];
    [fieldBridgeDelay setEnabled:YES];
    [checkBoxSTPEnabled setEnabled:YES];
    [checkBoxDHCPEnabled setEnabled:YES];

    [fieldBridgeName setStringValue:[[_network bridge] name]];
    [fieldBridgeIP setStringValue:[[_network IP] address]];
    [fieldBridgeNetmask setStringValue:[[_network IP] netmask]];
    [fieldBridgeDelay setStringValue:[[_network bridge] delay]];
    [checkBoxSTPEnabled setState:[[_network bridge] isSTPEnabled] ? CPOnState : CPOffState];
    [checkBoxDHCPEnabled setState:[[_network IP] DHCP] ? CPOnState : CPOffState];

    [buttonForwardDevice removeAllItems];

    [self DHCPChange:nil];
}

/*! Set the GUI for NAT or Route mode
*/
- (void)GUIForNATRouteMode
{
    [buttonForwardDevice setEnabled:YES];
    [fieldBridgeName setEnabled:YES];
    [fieldBridgeIP setEnabled:YES];
    [fieldBridgeNetmask setEnabled:YES];
    [fieldBridgeDelay setEnabled:YES];
    [checkBoxSTPEnabled setEnabled:YES];
    [checkBoxDHCPEnabled setEnabled:YES];

    [fieldBridgeName setStringValue:[[_network bridge] name]];
    [fieldBridgeIP setStringValue:[[_network IP] address]];
    [fieldBridgeNetmask setStringValue:[[_network IP] netmask]];
    [fieldBridgeDelay setStringValue:[[_network bridge] delay]];
    [checkBoxSTPEnabled setState:[[_network bridge] isSTPEnabled] ? CPOnState : CPOffState];
    [checkBoxDHCPEnabled setState:[[_network IP] DHCP] ? CPOnState : CPOffState];

    [buttonForwardDevice addItemsWithTitles:_currentNetworkInterfaces];
    if ([[buttonForwardDevice itemTitles] containsObject:[[_network forward] dev]])
        [buttonForwardDevice selectItemWithTitle:[[_network forward] dev]];
    else
        [buttonForwardDevice selectItemAtIndex:0];

    [self DHCPChange:nil];
}

/*! Set the GUI for bridged mode
*/
- (void)GUIForBridgeMode
{
    [buttonForwardDevice setEnabled:YES];
    [fieldBridgeName setEnabled:NO];
    [fieldBridgeIP setEnabled:NO];
    [fieldBridgeNetmask setEnabled:NO];
    [fieldBridgeDelay setEnabled:NO];
    [checkBoxSTPEnabled setEnabled:NO];
    [checkBoxDHCPEnabled setEnabled:NO];

    [fieldBridgeName setStringValue:@""];
    [fieldBridgeIP setStringValue:@""];
    [fieldBridgeNetmask setStringValue:@""];
    [fieldBridgeDelay setStringValue:@""];
    [checkBoxSTPEnabled setState:CPOffState];
    [checkBoxDHCPEnabled setState:CPOffState];

    [buttonForwardDevice addItemsWithTitles:_currentNetworkInterfaces];
    if ([[buttonForwardDevice itemTitles] containsObject:[[_network forward] dev]])
        [buttonForwardDevice selectItemWithTitle:[[_network forward] dev]];
    else
        [buttonForwardDevice selectItemAtIndex:0];

    [_datasourceDHCPRanges removeAllObjects];
    [_datasourceDHCPHosts removeAllObjects];
    [tableViewRanges reloadData];
    [tableViewHosts reloadData];
}

/*! Update the controller with a new network object
*/
- (void)update
{
    [fieldErrorMessage setStringValue:@""];

    [buttonForwardDevice removeAllItems];
    [fieldNetworkName setStringValue:[_network name]];
    [fieldBridgeName setStringValue:[[_network bridge] name] || @""];
    [fieldBridgeDelay setStringValue:[[_network bridge] delay] || @""];
    [fieldBridgeIP setStringValue:[[_network IP] address] || @""];
    [fieldBridgeNetmask setStringValue:[[_network IP] netmask] || @""];

    // Forward mode
    if (![[_network forward] mode])
    {
        [buttonForwardDevice setEnabled:NO];
        [buttonForwardMode selectItemWithTitle:@"isolated"];
    }
    else
    {
        [buttonForwardDevice setEnabled:YES];
        [buttonForwardDevice addItemsWithTitles:_currentNetworkInterfaces];
        [buttonForwardDevice selectItemWithTitle:[[_network forward] dev]];
        [buttonForwardMode selectItemWithTitle:[[_network forward] mode]];
    }
    [self forwardModeChanged:nil];

    // DHCP
    [checkBoxSTPEnabled setState:([[_network bridge] isSTPEnabled]) ? CPOnState : CPOffState];
    [checkBoxAutostart setState:([_network isAutostart]) ? CPOnState : CPOffState];
    [checkBoxDHCPEnabled setState:[[_network IP] DHCP] ? CPOnState : CPOffState];
    [self DHCPChange:nil];
    [_datasourceDHCPRanges setContent:[[[_network IP] DHCP] ranges]];
    [_datasourceDHCPHosts setContent:[[[_network IP] DHCP] hosts]];

    [tableViewRanges reloadData];
    [tableViewHosts reloadData];

    // Bandwidth
    [checkBoxBandwidthInbound setState:[[_network bandwidth] inbound] ? CPOnState : CPOffState];
    [self inboundLimitChange:nil];
    [checkBoxBandwidthOutbound setState:[[_network bandwidth] outbound] ? CPOnState : CPOffState];
    [self outboundLimitChange:nil];

    [fieldBandwidthInboundAverage setStringValue:[[[_network bandwidth] inbound] average] || @""];
    [fieldBandwidthInboundPeak setStringValue:[[[_network bandwidth] inbound] peak] || @""];
    [fieldBandwidthInboundBurst setStringValue:[[[_network bandwidth] inbound] burst] || @""];

    [fieldBandwidthOutboundAverage setStringValue:[[[_network bandwidth] outbound] average] || @""];
    [fieldBandwidthOutboundPeak setStringValue:[[[_network bandwidth] outbound] peak] || @""];
    [fieldBandwidthOutboundBurst setStringValue:[[[_network bandwidth] outbound] burst] || @""];
}

/*! Update the network object with value and
    send defineNetwork delegate method
*/
- (void)save
{
    if (![fieldNetworkName stringValue] || [fieldNetworkName stringValue] == @"")
    {
        [fieldErrorMessage setStringValue:CPLocalizedString(@"You must enter a valid network name", @"You must enter a valid network name")];
        return;
    }

    [_network setAutostart:([checkBoxAutostart state] == CPOnState) ? YES : NO];
    [_network setName:[fieldNetworkName stringValue]];

    switch ([buttonForwardMode title])
    {
        case TNLibvirtNetworkForwardModeIsolated:
            [_network setForward:nil];
            break;

        case TNLibvirtNetworkForwardModeNAT:
        case TNLibvirtNetworkForwardModeRoute:
            [_network setForward:[[TNLibvirtNetworkForward alloc] init]];
            [[_network forward] setDev:[buttonForwardDevice title]];
            [[_network forward] setMode:[buttonForwardMode title]];
            break;

        case TNLibvirtNetworkForwardModePrivate:
        case TNLibvirtNetworkForwardModeBridge:
            [_network setForward:[[TNLibvirtNetworkForward alloc] init]];
            [[_network forward] setDev:nil];
            [[_network forward] setMode:[buttonForwardMode title]];
            [_network setBridge:nil];
            [[[_network forward] interfaces] addObject:[TNLibvirtNetworkForwardInterface defaultNetworkForwardInterfaceWithDev:[buttonForwardDevice title]]];
            break;
    }

    if ([fieldBridgeIP stringValue] != @"")
    {
        if (![_network IP])
            [_network setIP:[[TNLibvirtNetworkIP alloc] init]];

        [[_network IP] setAddress:[fieldBridgeIP stringValue]];
        [[_network IP] setNetmask:[fieldBridgeNetmask stringValue]];
    }
    else
        [_network setIP:nil];

    if ([fieldBridgeName stringValue] != @"")
    {
        if (![_network bridge])
            [_network setBridge:[[TNLibvirtNetworkBridge alloc] init]];
        [[_network bridge] setName:[fieldBridgeName stringValue]];
    }
    else
        [_network setBridge:nil];

    if ([checkBoxSTPEnabled state] == CPOnState)
    {
        if (![_network bridge])
            [_network setBridge:[[TNLibvirtNetworkBridge alloc] init]]
        [[_network bridge] setEnableSTP:([checkBoxSTPEnabled state] == CPOnState) ? YES : NO];
    }

    if ([checkBoxBandwidthInbound state] == CPOnState)
    {
        if (![_network bandwidth])
            [_network setBandwidth:[TNLibvirtNetworkBandwidth defaultNetworkBandwidth]];

        if (![[_network bandwidth] inbound])
            [[_network bandwidth] setInbound:[[TNLibvirtNetworkBandwidthInbound alloc] init]];

        if ([fieldBandwidthInboundAverage stringValue] == @"")
        {
            [fieldErrorMessage setStringValue:CPLocalizedString(@"You must set at least the \"average\" value for inbound limit", @"You must set at least the \"average\" value for inbound limit")];
            return;
        }
        [[[_network bandwidth] inbound] setAverage:[fieldBandwidthInboundAverage intValue]];
        [[[_network bandwidth] inbound] setPeak:[fieldBandwidthInboundPeak intValue]];
        [[[_network bandwidth] inbound] setBurst:[fieldBandwidthInboundBurst intValue]];
    }
    else
    {
        [[_network bandwidth] setInbound:nil];
    }

    if ([checkBoxBandwidthOutbound state] == CPOnState)
    {
        if (![_network bandwidth])
            [_network setBandwidth:[TNLibvirtNetworkBandwidth defaultNetworkBandwidth]];

        if (![[_network bandwidth] outbound])
            [[_network bandwidth] setOutbound:[[TNLibvirtNetworkBandwidthOutbound alloc] init]];

        if ([fieldBandwidthOutboundAverage stringValue] == @"")
        {
            [fieldErrorMessage setStringValue:CPLocalizedString(@"You must set at least the \"average\" value for outbound limit", @"You must set at least the \"average\" value for outbound limit")];
            return;
        }
        [[[_network bandwidth] outbound] setAverage:[fieldBandwidthOutboundAverage intValue]];
        [[[_network bandwidth] outbound] setPeak:[fieldBandwidthOutboundPeak intValue]];
        [[[_network bandwidth] outbound] setBurst:[fieldBandwidthOutboundBurst intValue]];
    }
    else
    {
        [[_network bandwidth] setOutbound:nil];
    }

    CPLog.info("Network information is :" + _network);
    [_delegate defineNetwork:_network];
    [mainPopover close];
}


#pragma mark -
#pragma mark Actions

/*! save the changes
    @param sender the sender of the action
*/
- (IBAction)save:(id)sender
{
    [self save];
}

/*! add a new DHCP range
    @param sender the sender of the action
*/
- (IBAction)addDHCPRange:(id)sender
{
    var newRange = [TNLibvirtNetworkIPDHCPRange defaultNetworkIPDHCPRangeWithStart:@"0.0.0.0"  end:@"0.0.0.0"];

    [_datasourceDHCPRanges addObject:newRange];
    [tableViewRanges reloadData];
}

/*! remove a DHCP range
    @param sender the sender of the action
*/
- (IBAction)removeDHCPRange:(id)sender
{
    var selectedIndex   = [[tableViewRanges selectedRowIndexes] firstIndex],
        rangeObject     = [_datasourceDHCPRanges removeObjectAtIndex:selectedIndex];

    [tableViewRanges reloadData];
}

/*! add a new DHCP host
    @param sender the sender of the action
*/
- (IBAction)addDHCPHost:(id)sender
{
    var newHost = [TNLibvirtNetworkIPDHCPHost defaultNetworkDHCPHostWithName:CPBundleLocalizedString("domain.com", "domain.com")
                                                                         MAC:@"00:00:00:00:00:00"
                                                                          IP:@"0.0.0.0"];

    [_datasourceDHCPHosts addObject:newHost];
    [tableViewHosts reloadData];
}

/*! remove a DHCP host
    @param sender the sender of the action
*/
- (IBAction)removeDHCPHost:(id)sender
{
    var selectedIndex   = [[tableViewHosts selectedRowIndexes] firstIndex],
        hostsObject     = [_datasourceDHCPHosts removeObjectAtIndex:selectedIndex];

    [tableViewHosts reloadData];
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
        [mainPopover showRelativeToRect:nil ofView:aSender preferredEdge:nil]

    [mainPopover makeFirstResponder:fieldNetworkName];
    [mainPopover setDefaultButton:buttonOK];
}

/*! hide the main window
    @param aSender the sender of the action
*/
- (IBAction)closeWindow:(id)sender
{
    [mainPopover close];
}

/*! called when changing the forward mode
    @param aSender the sender of the action
*/
- (IBAction)forwardModeChanged:(id)sender
{
    [buttonForwardDevice removeAllItems];

    switch ([buttonForwardMode title])
    {
        case TNLibvirtNetworkForwardModeIsolated:
            [self GUIForIsolatedMode];
            break;

        case TNLibvirtNetworkForwardModeRoute:
        case TNLibvirtNetworkForwardModeNAT:
            [self GUIForNATRouteMode];
            break;

        case TNLibvirtNetworkForwardModePrivate:
        case TNLibvirtNetworkForwardModeBridge:
            [self GUIForBridgeMode];
            break;
    }
}

/*! Called when user activate or deactivate DHCP
    @param aSender the sender of the action
*/
- (IBAction)DHCPChange:(id)aSender
{
    if ([checkBoxDHCPEnabled state] == CPOnState)
    {
        if (![_network IP])
            [_network setIP:[[TNLibvirtNetworkIP alloc] init]];

        if (![[_network IP] DHCP])
            [[_network IP] setDHCP:[[TNLibvirtNetworkIPDHCP alloc] init]];

        [_datasourceDHCPHosts setContent:[[[_network IP] DHCP] hosts]];
        [_datasourceDHCPRanges setContent:[[[_network IP] DHCP] ranges]];
        [tableViewRanges setEnabled:YES];
        [tableViewHosts setEnabled:YES];
        [[buttonBarControlDHCPRanges buttons] makeObjectsPerformSelector:@selector(setEnabled:) withObject:YES];
    }
    else
    {
        [_datasourceDHCPRanges removeAllObjects];
        [_datasourceDHCPHosts removeAllObjects];
        [tableViewHosts reloadData];
        [tableViewRanges reloadData];
        [[_network IP] setDHCP:nil];
        [tableViewRanges setEnabled:NO];
        [tableViewHosts setEnabled:NO];
        [[buttonBarControlDHCPRanges buttons] makeObjectsPerformSelector:@selector(setEnabled:) withObject:NO];
    }
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
        if (![_network bandwidth])
            [_network setBandwidth:[TNLibvirtNetworkBandwidth defaultNetworkBandwidth]];
    }
    else
    {
        [fieldBandwidthInboundAverage setEnabled:NO];
        [fieldBandwidthInboundPeak setEnabled:NO];
        [fieldBandwidthInboundBurst setEnabled:NO];
        [fieldBandwidthInboundAverage setStringValue:@""];
        [fieldBandwidthInboundPeak setStringValue:@""];
        [fieldBandwidthInboundBurst setStringValue:@""];

        if (![_network bandwidth])
            [[_network bandwidth] setInbound:nil];
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
        if (![_network bandwidth])
            [_network setBandwidth:[TNLibvirtNetworkBandwidth defaultNetworkBandwidth]];
    }
    else
    {
        [fieldBandwidthOutboundAverage setEnabled:NO];
        [fieldBandwidthOutboundPeak setEnabled:NO];
        [fieldBandwidthOutboundBurst setEnabled:NO];
        [fieldBandwidthOutboundAverage setStringValue:@""];
        [fieldBandwidthOutboundPeak setStringValue:@""];
        [fieldBandwidthOutboundBurst setStringValue:@""];

        if (![_network bandwidth])
            [[_network bandwidth] setOutbound:nil];
    }
}

@end


// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNWindowNetworkController], comment);
}
