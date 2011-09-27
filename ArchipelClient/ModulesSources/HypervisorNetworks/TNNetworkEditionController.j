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
    @outlet CPCheckBox          checkBoxDHCPEnabled;
    @outlet CPCheckBox          checkBoxSTPEnabled;
    @outlet CPPopover           mainPopover;
    @outlet CPPopUpButton       buttonForwardDevice;
    @outlet CPPopUpButton       buttonForwardMode;
    @outlet CPTableView         tableViewHosts;
    @outlet CPTableView         tableViewRanges;
    @outlet CPTabView           tabViewDHCP;
    @outlet CPTextField         fieldBridgeDelay;
    @outlet CPTextField         fieldBridgeIP;
    @outlet CPTextField         fieldBridgeName;
    @outlet CPTextField         fieldBridgeNetmask;
    @outlet CPTextField         fieldNetworkName;
    @outlet CPView              viewHostsConf;
    @outlet CPView              viewRangesConf;
    @outlet CPView              viewTableHostsContainer;
    @outlet CPView              viewTableRangesContainer;

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

    [viewTableRangesContainer setBorderedWithHexColor:@"#C0C7D2"];
    [viewTableHostsContainer setBorderedWithHexColor:@"#C0C7D2"];

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

- (void)update
{
    [buttonForwardDevice removeAllItems];
    [fieldNetworkName setStringValue:[_network name]];
    [fieldBridgeName setStringValue:[[_network bridge] name] || @""];
    [fieldBridgeDelay setStringValue:[[_network bridge] delay] || @""];
    [fieldBridgeIP setStringValue:[[_network IP] address] || @""];
    [fieldBridgeNetmask setStringValue:[[_network IP] netmask] || @""];

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

    [checkBoxSTPEnabled setState:([[_network bridge] isSTPEnabled]) ? CPOnState : CPOffState];
    [checkBoxDHCPEnabled setState:([[_network IP] DHCP]) ? CPOnState : CPOffState];
    [checkBoxAutostart setState:([_network isAutostart]) ? CPOnState : CPOffState];

    [_datasourceDHCPRanges setContent:[[[_network IP] DHCP] ranges]];
    [_datasourceDHCPHosts setContent:[[[_network IP] DHCP] hosts]];

    [tableViewRanges reloadData];
    [tableViewHosts reloadData];
}


#pragma mark -
#pragma mark Actions

/*! save the changes
    @param sender the sender of the action
*/
- (IBAction)save:(id)sender
{
    [_network setName:[fieldNetworkName stringValue]];
    [[_network bridge] setName:[fieldBridgeName stringValue]];
    [[_network bridge] setDelay:[fieldBridgeDelay stringValue]];

    if ([buttonForwardMode title] != @"isolated")
    {
        if (![_network forward])
            [_network setForward:[[TNLibvirtNetworkForward alloc] init]];

        [[_network forward] setMode:[buttonForwardMode title]];

        // @ TODO : this is just a test
        [[_network forward] setDev:[buttonForwardDevice title]];
        // [[[_network forward] interfaces] addObject:[TNLibvirtNetworkForwardInterface defaultNetworkForwardInterfaceWithDev:[buttonForwardDevice title]]];
    }
    else
    {
        if ([_network forward])
            [_network setForward:nil];
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

    if ([checkBoxSTPEnabled state] == CPOnState)
    {
        if (![_network bridge])
            [_network setBridge:[[TNLibvirtNetworkBridge alloc] init]]
        [[_network bridge] setEnableSTP:([checkBoxSTPEnabled state] == CPOnState) ? YES : NO];
    }

    if ([checkBoxDHCPEnabled state] == CPOffState)
    {
        [[_network IP] setDHCP:nil];
    }

    [_network setAutostart:([checkBoxAutostart state] == CPOnState) ? YES : NO];
    [_delegate defineNetwork:_network];
    [mainPopover close];
}

/*! add a new DHCP range
    @param sender the sender of the action
*/
- (IBAction)addDHCPRange:(id)sender
{
    var newRange = [TNLibvirtNetworkIPDHCPRange defaultNetworkIPDHCPRangeWithStart:@"0.0.0.0"  end:@"0.0.0.0"];

    [checkBoxDHCPEnabled setState:CPOnState];
    if (![_network IP])
        [_network setIP:[[TNLibvirtNetworkIP alloc] init]];
    if (![[_network IP] DHCP])
    {
        [[_network IP] setDHCP:[[TNLibvirtNetworkIPDHCP alloc] init]];
        [_datasourceDHCPHosts setContent:[[[_network IP] DHCP] hosts]];
        [_datasourceDHCPRanges setContent:[[[_network IP] DHCP] ranges]];
    }

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

    if (([tableViewRanges numberOfRows] == 0) && ([tableViewHosts numberOfRows] == 0))
      [checkBoxDHCPEnabled setState:CPOffState];

}

/*! add a new DHCP host
    @param sender the sender of the action
*/
- (IBAction)addDHCPHost:(id)sender
{
    var newHost = [TNLibvirtNetworkIPDHCPHost defaultNetworkDHCPHostWithName:CPBundleLocalizedString("domain.com", "domain.com")
                                                                         MAC:@"00:00:00:00:00:00"
                                                                          IP:@"0.0.0.0"]

    [checkBoxDHCPEnabled setState:CPOnState];
    if (![_network IP])
        [_network setIP:[[TNLibvirtNetworkIP alloc] init]];
    if (![[_network IP] DHCP])
    {
        [[_network IP] setDHCP:[[TNLibvirtNetworkIPDHCP alloc] init]];
        [_datasourceDHCPHosts setContent:[[[_network IP] DHCP] hosts]];
        [_datasourceDHCPRanges setContent:[[[_network IP] DHCP] ranges]];
    }

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

    if (([tableViewRanges numberOfRows] == 0) && ([tableViewHosts numberOfRows] == 0))
      [checkBoxDHCPEnabled setState:CPOffState];
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
        rect.origin.y += rect.size.height
        rect.origin.x += rect.size.width / 2;
        var point = [[aSender superview] convertPoint:rect.origin toView:nil];
        [mainPopover showRelativeToRect:CPRectMake(point.x, point.y, 10, 10) ofView:nil preferredEdge:nil];
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
    switch ([buttonForwardMode title])
    {
        case @"isolated":
            [buttonForwardDevice removeAllItems];
            [buttonForwardDevice setEnabled:NO];
            break;

        default:
            [buttonForwardDevice removeAllItems];
            [buttonForwardDevice addItemsWithTitles:_currentNetworkInterfaces];
            [buttonForwardDevice setEnabled:YES];
            if ([[buttonForwardDevice itemTitles] containsObject:[[_network forward] dev]])
                [buttonForwardDevice selectItemWithTitle:[[_network forward] dev]];
            else
                [buttonForwardDevice selectItemAtIndex:0];

    }
}

@end


// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNWindowNetworkController], comment);
}
