/*
 * TNWindowNetworkProperties.j
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

@import "TNDHCPEntryObject.j";
@import "TNHypervisorNetworkObject.j";



/*! @ingroup hypervisornetworks
    The newtork window edition
*/
@implementation TNWindowNetworkController : CPObject
{
    @outlet CPButton            buttonOK;
    @outlet CPButtonBar         buttonBarControlDHCPHosts;
    @outlet CPButtonBar         buttonBarControlDHCPRanges;
    @outlet CPCheckBox          checkBoxDHCPEnabled;
    @outlet CPCheckBox          checkBoxSTPEnabled;
    @outlet CPPopUpButton       buttonForwardDevice;
    @outlet CPPopUpButton       buttonForwardMode;
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
    @outlet CPWindow            mainWindow;
    @outlet CPTableView         tableViewHosts;
    @outlet CPTableView         tableViewRanges;

    CPArray                     _currentNetworkInterfaces   @accessors(property=currentNetworkInterfaces);
    id                          _delegate                   @accessors(property=delegate);
    TNHypervisorNetwork         _network                    @accessors(property=network);

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
    [mainWindow setDefaultButton:buttonOK];

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
    [buttonForwardMode addItemsWithTitles:[@"isolated", @"route", @"nat"]];
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
}


#pragma mark -
#pragma mark CPWindow override

- (void)update
{
    [buttonForwardDevice removeAllItems];
    [fieldNetworkName setStringValue:[_network networkName]];
    [fieldBridgeName setStringValue:[_network bridgeName]];
    [fieldBridgeDelay setStringValue:([_network bridgeDelay] == @"") ? [_network bridgeDelay] : @"0"];
    [fieldBridgeIP setStringValue:[_network bridgeIP]];
    [fieldBridgeNetmask setStringValue:[_network bridgeNetmask]];

    if (![_network bridgeForwardMode])
    {
        [buttonForwardDevice setEnabled:NO];
        [buttonForwardMode selectItemWithTitle:@"isolated"];
    }
    else
    {
        [buttonForwardDevice setEnabled:YES];
        [buttonForwardDevice addItemsWithTitles:_currentNetworkInterfaces];
        [buttonForwardDevice selectItemWithTitle:[_network bridgeForwardDevice]];
    }

    [checkBoxSTPEnabled setState:([_network isSTPEnabled]) ? CPOnState : CPOffState];
    [checkBoxDHCPEnabled setState:([_network isDHCPEnabled]) ? CPOnState : CPOffState];

    [_datasourceDHCPRanges setContent:[_network DHCPEntriesRanges]];
    [_datasourceDHCPHosts setContent:[_network DHCPEntriesHosts]];

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
    [_network setNetworkName:[fieldNetworkName stringValue]];
    [_network setBridgeName:[fieldBridgeName stringValue]];
    [_network setBridgeDelay:[fieldBridgeDelay stringValue]];
    if ([buttonForwardMode title] != @"isolated")
    {
        [_network setBridgeForwardMode:[buttonForwardMode title]];
        [_network setBridgeForwardDevice:[buttonForwardDevice title]];
    }
    else
    {
        [_network setBridgeForwardMode:nil];
        [_network setBridgeForwardDevice:nil];
    }

    [_network setBridgeIP:[fieldBridgeIP stringValue]];
    [_network setBridgeNetmask:[fieldBridgeNetmask stringValue]];
    [_network setDHCPEntriesRanges:[_datasourceDHCPRanges content]];
    [_network setDHCPEntriesHosts:[_datasourceDHCPHosts content]];
    [_network setSTPEnabled:([checkBoxSTPEnabled state] == CPOnState) ? YES : NO];
    [_network setDHCPEnabled:([checkBoxDHCPEnabled state] == CPOnState) ? YES : NO];

    [_delegate defineNetwork:_network];
    [mainWindow close];
}

/*! add a new DCHP range
    @param sender the sender of the action
*/
- (IBAction)addDHCPRange:(id)sender
{
    var newRange = [TNDHCPEntry DHCPRangeWithStartAddress:@"0.0.0.0"  endAddress:@"0.0.0.0"];

    [checkBoxDHCPEnabled setState:CPOnState];
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
    var newHost = [TNDHCPEntry DHCPHostWithMac:@"00:00:00:00:00:00"  name:CPBundleLocalizedString("domain.com", "domain.com") ip:@"0.0.0.0"];

    [checkBoxDHCPEnabled setState:CPOnState];
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
- (IBAction)showWindow:(id)aSender
{
    [self update];
    [mainWindow center];
    [mainWindow makeKeyAndOrderFront:aSender];
}

/*! hide the main window
    @param aSender the sender of the action
*/
- (IBAction)hideWindow:(id)sender
{
    [mainWindow close];
}

/*! called when changing the forward mode
    @param aSender the sender of the action
*/
- (IBAction)forwardModeChanged:(id)sender
{
    if ([buttonForwardMode title] == @"isolated")
    {
        [buttonForwardDevice removeAllItems];
        [buttonForwardDevice setEnabled:NO];
    }
    else
    {
        [buttonForwardDevice removeAllItems];
        [buttonForwardDevice addItemsWithTitles:_currentNetworkInterfaces];
        [buttonForwardDevice setEnabled:YES];
    }
}

@end


// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNWindowNetworkController], comment);
}
