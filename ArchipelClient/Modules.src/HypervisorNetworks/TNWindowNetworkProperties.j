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

@import "TNDatasourceDHCPEntries.j";

@implementation TNWindowNetworkProperties : CPWindow
{
    @outlet CPTextField     fieldNetworkName            @accessors;
    @outlet CPTextField     fieldBridgeName             @accessors;
    @outlet CPTextField     fieldBridgeDelay            @accessors;
    @outlet CPPopUpButton   buttonForwardMode           @accessors;
    @outlet CPPopUpButton   buttonForwardDevice         @accessors;
    @outlet CPTextField     fieldBridgeIP               @accessors;
    @outlet CPTextField     fieldBridgeNetmask          @accessors;
    @outlet CPScrollView    scrollViewDHCPRanges        @accessors;
    @outlet CPScrollView    scrollViewDHCPHosts         @accessors;
    @outlet CPCheckBox      checkBoxSTPEnabled          @accessors;
    @outlet CPCheckBox      checkBoxDHCPEnabled         @accessors;

    TNNetwork               network                     @accessors;
    TNStropheContact        hypervisor                  @accessors;
    CPTableView             table                       @accessors;

    TNDatasourceDHCPEntries _datasourceDHCPRanges;
    TNDatasourceDHCPEntries _datasourceDHCPHosts;
    CPTableView             _tableViewRanges;
    CPTableView             _tableViewHosts;
}

- (void)awakeFromCib
{
    [buttonForwardMode removeAllItems];
    [buttonForwardDevice removeAllItems];

    var forwardMode = ["route", "nat"];
    for (var i = 0; i < forwardMode.length; i++)
    {
        var item = [[CPMenuItem alloc] initWithTitle:forwardMode[i] action:nil keyEquivalent:nil];
        [buttonForwardMode addItem:item];
    }

    var forwardDev = ["nothing", "eth0", "eth1", "eth2", "eth3", "eth4", "eth5", "eth6"]; //TODO obvious..
    for (var i = 0; i < forwardDev.length; i++)
    {
        var item = [[CPMenuItem alloc] initWithTitle:forwardDev[i] action:nil keyEquivalent:nil];
        [buttonForwardDevice addItem:item];
    }

    // TABLE FOR RANGES
    _datasourceDHCPRanges   = [[TNDatasourceDHCPEntries alloc] init];
    _tableViewRanges        = [[CPTableView alloc] initWithFrame:[[self scrollViewDHCPRanges] bounds]];

    [[self scrollViewDHCPRanges] setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [[self scrollViewDHCPRanges] setAutohidesScrollers:YES];
    [[self scrollViewDHCPRanges] setDocumentView:_tableViewRanges];
    [[self scrollViewDHCPRanges] setBorderedWithHexColor:@"#9e9e9e"];

    [_tableViewRanges setUsesAlternatingRowBackgroundColors:YES];
    [_tableViewRanges setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [_tableViewRanges setAllowsColumnReordering:YES];
    [_tableViewRanges setAllowsColumnResizing:YES];
    [_tableViewRanges setAllowsEmptySelection:YES];

    var columRangeStart = [[CPTableColumn alloc] initWithIdentifier:@"start"];
    [[columRangeStart headerView] setStringValue:@"Start"];
    [columRangeStart setEditable:YES];

    var columRangeEnd = [[CPTableColumn alloc] initWithIdentifier:@"end"];
    [[columRangeEnd headerView] setStringValue:@"End"];
    [columRangeEnd setEditable:YES];

    [_tableViewRanges addTableColumn:columRangeStart];
    [_tableViewRanges addTableColumn:columRangeEnd];

    // TABLE FOR HOSTS
    _datasourceDHCPHosts     = [[TNDatasourceDHCPEntries alloc] init];
    _tableViewHosts          = [[CPTableView alloc] initWithFrame:[[self scrollViewDHCPHosts] bounds]];

    [[self scrollViewDHCPHosts] setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [[self scrollViewDHCPHosts] setAutohidesScrollers:YES];
    [[self scrollViewDHCPHosts] setDocumentView:_tableViewHosts];
    [[self scrollViewDHCPHosts] setBorderedWithHexColor:@"#9e9e9e"];

    [_tableViewHosts setUsesAlternatingRowBackgroundColors:YES];
    [_tableViewHosts setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [_tableViewHosts setAllowsColumnReordering:YES];
    [_tableViewHosts setAllowsColumnResizing:YES];
    [_tableViewHosts setAllowsEmptySelection:YES];

    var columHostMac = [[CPTableColumn alloc] initWithIdentifier:@"mac"];
    [[columHostMac headerView] setStringValue:@"MAC Address"];
    [columHostMac setEditable:YES];

    var columHostName = [[CPTableColumn alloc] initWithIdentifier:@"name"];
    [[columHostName headerView] setStringValue:@"Name"];
    [columHostName setEditable:YES];

    var columHostIP = [[CPTableColumn alloc] initWithIdentifier:@"IP"];
    [[columHostIP headerView] setStringValue:@"IP"];
    [columHostIP setEditable:YES];

    [_tableViewHosts addTableColumn:columHostMac];
    [_tableViewHosts addTableColumn:columHostName];
    [_tableViewHosts addTableColumn:columHostIP];

    //setting datasources
    [_tableViewRanges setDataSource:_datasourceDHCPRanges];
    [_tableViewHosts setDataSource:_datasourceDHCPHosts];

    // setting delegate
    [_tableViewHosts setDelegate:self];
    [_tableViewRanges setDelegate:self];
}

- (void)orderFront:(id)sender
{
    [_tableViewRanges setNeedsDisplay:YES];
    [_tableViewHosts setNeedsDisplay:YES];

    [fieldNetworkName setStringValue:[network networkName]];
    [fieldBridgeName setStringValue:[network bridgeName]];
    [fieldBridgeDelay setStringValue:[network bridgeDelay]];
    [fieldBridgeIP setStringValue:[network bridgeIP]];
    [fieldBridgeNetmask setStringValue:[network bridgeNetmask]];

    [buttonForwardMode selectItemWithTitle:[network bridgeForwardMode]];
    [buttonForwardDevice selectItemWithTitle:[network bridgeForwardDevice]];

    [checkBoxSTPEnabled setState:([network isSTPEnabled]) ? CPOnState : CPOffState];
    [checkBoxDHCPEnabled setState:([network isDHCPEnabled]) ? CPOnState : CPOffState];

    [_datasourceDHCPRanges setEntries:[network DHCPEntriesRanges]];
    [_datasourceDHCPHosts setEntries:[network DHCPEntriesHosts]];

    [_tableViewRanges reloadData];
    [_tableViewHosts reloadData];

    [super orderFront:sender];
}

- (IBAction)save:(id)sender
{
    [network setNetworkName:[fieldNetworkName stringValue]];
    [network setBridgeName:[fieldBridgeName stringValue]];
    [network setBridgeDelay:[fieldBridgeDelay intValue]];
    [network setBridgeForwardMode:[buttonForwardMode title]];
    [network setBridgeForwardDevice:[buttonForwardDevice title]];
    [network setBridgeIP:[fieldBridgeIP stringValue]];
    [network setBridgeNetmask:[fieldBridgeNetmask stringValue]];
    [network setDHCPEntriesRanges:[_datasourceDHCPRanges entries]];
    [network setDHCPEntriesHosts:[_datasourceDHCPHosts entries]];
    [network setSTPEnabled:([checkBoxSTPEnabled state] == CPOnState) ? YES : NO];
    [network setDHCPEnabled:([checkBoxDHCPEnabled state] == CPOnState) ? YES : NO];

    [[self table] reloadData];
}

- (IBAction)addDHCPRange:(id)sender
{
    var newRange = [TNDHCPEntry DHCPRangeWithStartAddress:@"0.0.0.0"  endAddress:@"0.0.0.0"];

    [checkBoxDHCPEnabled setState:CPOnState];
    [[_datasourceDHCPRanges entries] addObject:newRange];
    [_tableViewRanges reloadData];
    [self save:nil];
}

- (IBAction)removeDHCPRange:(id)sender
{
    var selectedIndex   = [[_tableViewRanges selectedRowIndexes] firstIndex];
    var rangeObject     = [[_datasourceDHCPRanges entries] removeObjectAtIndex:selectedIndex];

    [_tableViewRanges reloadData];

    if (([_tableViewRanges numberOfRows] == 0) && ([_tableViewHosts numberOfRows] == 0))
      [checkBoxDHCPEnabled setState:CPOffState];

    [self save:nil];
}

- (IBAction)addDHCPHost:(id)sender
{
    var newHost = [TNDHCPEntry DHCPHostWithMac:@"00:00:00:00:00:00"  name:"domain.com" ip:@"0.0.0.0"];

    [checkBoxDHCPEnabled setState:CPOnState];
    [[_datasourceDHCPHosts entries] addObject:newHost];
    [_tableViewHosts reloadData];
    [self save:nil];
}

- (IBAction)removeDHCPHost:(id)sender
{
    var selectedIndex   = [[_tableViewHosts selectedRowIndexes] firstIndex];
    var hostsObject     = [[_datasourceDHCPHosts entries] removeObjectAtIndex:selectedIndex];

    [_tableViewHosts reloadData];

    if (([_tableViewRanges numberOfRows] == 0) && ([_tableViewHosts numberOfRows] == 0))
      [checkBoxDHCPEnabled setState:CPOffState];

    [self save:nil];
}

@end
