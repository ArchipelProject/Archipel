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

@import "TNDHCPEntryObject.j";
@import "TNNetworkObject.j"

@implementation TNWindowNetworkProperties : CPWindow
{
    @outlet CPTabView       tabViewDHCP;
    @outlet CPButtonBar     buttonBarControlDHCPHosts;
    @outlet CPButtonBar     buttonBarControlDHCPRanges;
    @outlet CPCheckBox      checkBoxDHCPEnabled;
    @outlet CPCheckBox      checkBoxSTPEnabled;
    @outlet CPPopUpButton   buttonForwardDevice;
    @outlet CPPopUpButton   buttonForwardMode;
    @outlet CPScrollView    scrollViewDHCPHosts;
    @outlet CPScrollView    scrollViewDHCPRanges;
    @outlet CPTextField     fieldBridgeDelay;
    @outlet CPTextField     fieldBridgeIP;
    @outlet CPTextField     fieldBridgeName;
    @outlet CPTextField     fieldBridgeNetmask;
    @outlet CPTextField     fieldNetworkName;
    @outlet CPView          viewTableHostsContainer;
    @outlet CPView          viewTableRangesContainer;
    
    @outlet CPView          viewHostsConf;
    @outlet CPView          viewRangesConf;

    CPTableView             _externalTable              @accessors(property=tableNetwork);
    TNNetwork               _network                    @accessors(property=network);
    
    CPButton                _plusButtonDHCPHosts;
    CPButton                _plusButtonDHCPRanges;
    CPButton                _minusButtonDHCPRanges;
    CPButton                _minusButtonDHCPHosts;
    
    CPTableView             _tableViewHosts;
    CPTableView             _tableViewRanges;
    TNTableViewDataSource   _datasourceDHCPHosts;
    TNTableViewDataSource   _datasourceDHCPRanges;
}

- (void)awakeFromCib
{
    var bundle                  = [CPBundle mainBundle];
    // var centerBezel             = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"TNButtonBar/buttonBarCenterBezel.png"] size:CGSizeMake(1, 26)];
    // var buttonBezel             = [CPColor colorWithPatternImage:centerBezel];
    // var centerBezelHighlighted  = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"TNButtonBar/buttonBarCenterBezelHighlighted.png"] size:CGSizeMake(1, 26)];
    // var centerBezelSelected     = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"TNButtonBar/buttonBarCenterBezelSelected.png"] size:CGSizeMake(1, 26)];
    // _bezelColor                 = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"TNButtonBar/buttonBarBackground.png"] size:CGSizeMake(1, 27)]];
    // _buttonBezelHighlighted     = [CPColor colorWithPatternImage:centerBezelHighlighted];
    // _buttonBezelSelected = [CPColor colorWithPatternImage:centerBezelSelected];
    

    // [buttonBar setValue:buttonBezel forThemeAttribute:"button-bezel-color"];
    // [buttonBar setValue:_buttonBezelHighlighted forThemeAttribute:"button-bezel-color" inState:CPThemeStateHighlighted];
    // 
    // var rangeButton = [[CPButton alloc] initWithFrame:CPRectMake(0,0,[buttonBar frame].size.width / 2 - 2,25)];
    // [rangeButton setValue:_buttonBezelHighlighted forThemeAttribute:"bezel-color" inState:CPThemeStateSelected];
    // [rangeButton setBordered:NO];
    // [rangeButton setTarget:self];
    // [rangeButton setAction:@selector(displayRangesTable:)];
    // [rangeButton setTitle:@"DHCP Ranges"];
    // 
    // var hostButton = [[CPButton alloc] initWithFrame:CPRectMake([buttonBar frame].size.width / 2 - 2,0,[buttonBar frame].size.width / 2,25)];
    // [hostButton setValue:_buttonBezelHighlighted forThemeAttribute:"bezel-color" inState:CPThemeStateSelected];
    // [hostButton setBordered:NO];
    // [hostButton setTarget:self];
    // [hostButton setAction:@selector(displayHostsTable:)];
    // [hostButton setTitle:@"DHCP Hosts"];
    // 
    // [buttonBar setButtons:[rangeButton, hostButton]];
    // [buttonBar layoutSubviews];
    
    _plusButtonDHCPHosts = [CPButtonBar plusButton];
    _minusButtonDHCPHosts= [CPButtonBar minusButton];
    [buttonBarControlDHCPHosts setButtons:[_plusButtonDHCPHosts, _minusButtonDHCPHosts]];
    [_plusButtonDHCPHosts setTarget:self];
    [_plusButtonDHCPHosts setAction:@selector(addDHCPHost:)];    
    [_minusButtonDHCPHosts setTarget:self];
    [_minusButtonDHCPHosts setAction:@selector(removeDHCPHost:)];
    
    _plusButtonDHCPRanges = [CPButtonBar plusButton];
    _minusButtonDHCPRanges = [CPButtonBar minusButton];
    [buttonBarControlDHCPRanges setButtons:[_plusButtonDHCPRanges, _minusButtonDHCPRanges]];
    [_plusButtonDHCPRanges setTarget:self];
    [_plusButtonDHCPRanges setAction:@selector(addDHCPRange:)];    
    [_minusButtonDHCPRanges setTarget:self];
    [_minusButtonDHCPRanges setAction:@selector(removeDHCPRange:)];
    
    
    [viewTableRangesContainer setBorderedWithHexColor:@"#C0C7D2"];
    [viewTableHostsContainer setBorderedWithHexColor:@"#C0C7D2"];
    
    [buttonForwardMode removeAllItems];
    [buttonForwardMode addItemsWithTitles:["route", "nat"]];
    
    [buttonForwardDevice removeAllItems];
    [buttonForwardDevice addItemsWithTitles:["nothing", "eth0", "eth1", "eth2", "eth3", "eth4", "eth5", "eth6"]];
    
    
    
    // TABLE FOR RANGES
    _datasourceDHCPRanges   = [[TNTableViewDataSource alloc] init];
    _tableViewRanges        = [[CPTableView alloc] initWithFrame:[scrollViewDHCPRanges bounds]];

    [scrollViewDHCPRanges setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [scrollViewDHCPRanges setAutohidesScrollers:YES];
    [scrollViewDHCPRanges setDocumentView:_tableViewRanges];

    [_tableViewRanges setUsesAlternatingRowBackgroundColors:YES];
    [_tableViewRanges setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [_tableViewRanges setAllowsColumnResizing:YES];
    [_tableViewRanges setAllowsEmptySelection:YES];

    var columRangeStart = [[CPTableColumn alloc] initWithIdentifier:@"start"];
    [[columRangeStart headerView] setStringValue:@"Start"];
    [columRangeStart setWidth:250];
    [columRangeStart setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"start" ascending:YES]];
    [columRangeStart setEditable:YES];

    var columRangeEnd = [[CPTableColumn alloc] initWithIdentifier:@"end"];
    [[columRangeEnd headerView] setStringValue:@"End"];
    [columRangeEnd setWidth:250];
    [columRangeEnd setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"end" ascending:YES]];
    [columRangeEnd setEditable:YES];

    [_tableViewRanges addTableColumn:columRangeStart];
    [_tableViewRanges addTableColumn:columRangeEnd];

    // TABLE FOR HOSTS
    _datasourceDHCPHosts     = [[TNTableViewDataSource alloc] init];
    _tableViewHosts          = [[CPTableView alloc] initWithFrame:[scrollViewDHCPHosts bounds]];

    [scrollViewDHCPHosts setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [scrollViewDHCPHosts setAutohidesScrollers:YES];
    [scrollViewDHCPHosts setDocumentView:_tableViewHosts];
    // [scrollViewDHCPHosts setBorderedWithHexColor:@"#C0C7D2"];

    [_tableViewHosts setUsesAlternatingRowBackgroundColors:YES];
    [_tableViewHosts setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [_tableViewHosts setAllowsColumnResizing:YES];
    [_tableViewHosts setAllowsEmptySelection:YES];
     
    var columHostMac = [[CPTableColumn alloc] initWithIdentifier:@"mac"];
    [[columHostMac headerView] setStringValue:@"MAC Address"];
    [columHostMac setWidth:150];
    [columHostMac setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"mac" ascending:YES]];
    [columHostMac setEditable:YES];

    var columHostName = [[CPTableColumn alloc] initWithIdentifier:@"name"];
    [[columHostName headerView] setStringValue:@"Name"];
    [columHostName setWidth:150];
    [columHostName setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
    [columHostName setEditable:YES];

    var columHostIP = [[CPTableColumn alloc] initWithIdentifier:@"IP"];
    [[columHostIP headerView] setStringValue:@"IP"];
    [columHostIP setWidth:150];
    [columHostIP setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"IP" ascending:YES]];
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
    
    // // setting the current selected table
    // // _currentTableScrollView = scrollViewDHCPRanges;
    // [viewCurrentTable addSubview:scrollViewDHCPRanges];
    // [rangeButton setValue:_buttonBezelSelected forThemeAttribute:"bezel-color"];
    
    var menuRange = [[CPMenu alloc] init];
    [menuRange addItemWithTitle:@"Add new range" action:@selector(addDHCPRange:) keyEquivalent:@""];
    [menuRange addItemWithTitle:@"Remove" action:@selector(removeDHCPRange:) keyEquivalent:@""];
    [_tableViewRanges setMenu:menuRange];
    
    var menuHost = [[CPMenu alloc] init];
    [menuHost addItemWithTitle:@"Add new host reservation" action:@selector(addDHCPHost:) keyEquivalent:@""];
    [menuHost addItemWithTitle:@"Remove" action:@selector(removeDHCPHost:) keyEquivalent:@""];
    [_tableViewHosts setMenu:menuHost];
    
    var tabViewDHCPRangesItem = [[CPTabViewItem alloc] initWithIdentifier:@"id1"];
    [tabViewDHCPRangesItem setView:viewRangesConf];
    [tabViewDHCPRangesItem setLabel:@"DHCP Ranges"];
    [tabViewDHCP addTabViewItem:tabViewDHCPRangesItem];
    
    var tabViewDHCPHostsItem = [[CPTabViewItem alloc] initWithIdentifier:@"id1"];
    [tabViewDHCPHostsItem setView:viewHostsConf];
    [tabViewDHCPHostsItem setLabel:@"DHCP Hosts"];
    [tabViewDHCP addTabViewItem:tabViewDHCPHostsItem];
}

- (void)makeKeyAndOrderFront:(id)sender
{
    if (![self isVisible])
    {
        [fieldNetworkName setStringValue:[_network networkName]];
        [fieldBridgeName setStringValue:[_network bridgeName]];
        [fieldBridgeDelay setStringValue:([_network bridgeDelay] == @"") ? [_network bridgeDelay] : @"0"];
        [fieldBridgeIP setStringValue:[_network bridgeIP]];
        [fieldBridgeNetmask setStringValue:[_network bridgeNetmask]];

        [buttonForwardMode selectItemWithTitle:[_network bridgeForwardMode]];
        [buttonForwardDevice selectItemWithTitle:[_network bridgeForwardDevice]];

        [checkBoxSTPEnabled setState:([_network isSTPEnabled]) ? CPOnState : CPOffState];
        [checkBoxDHCPEnabled setState:([_network isDHCPEnabled]) ? CPOnState : CPOffState];

        [_datasourceDHCPRanges setContent:[_network DHCPEntriesRanges]];
        [_datasourceDHCPHosts setContent:[_network DHCPEntriesHosts]];

        [_tableViewRanges reloadData];
        [_tableViewHosts reloadData];
        
        // [[[buttonBar buttons] objectAtIndex:0] setValue:_buttonBezelSelected forThemeAttribute:"bezel-color"];
        // _currentTableScrollView = scrollViewDHCPHosts;
        // [self displayRangesTable:nil];
    }
    
    [super makeKeyAndOrderFront:sender];
    
    // ouais, ben ouais, commentes, tu vas voir...
    var frame = [_tableViewHosts bounds];
    frame.size.width--;
    
    [_tableViewHosts setFrame:frame];
    [_tableViewRanges setFrame:frame];
}

// - (IBAction)displayRangesTable:(id)sender
// {
//     if (_currentTableScrollView != scrollViewDHCPRanges)
//     {
//         [_currentTableScrollView removeFromSuperview];
//         _currentTableScrollView = scrollViewDHCPRanges;
//         [scrollViewDHCPRanges setFrame:[viewCurrentTable bounds]];
//         [viewCurrentTable addSubview:scrollViewDHCPRanges];
//         
//         [[[buttonBar buttons] objectAtIndex:0] setValue:_buttonBezelSelected forThemeAttribute:"bezel-color"];
//         [[[buttonBar buttons] objectAtIndex:1] setValue:_bezelColor forThemeAttribute:"bezel-color"];
//         
//         [_plusButton setTarget:self];
//         [_plusButton setAction:@selector(addDHCPRange:)];
//         [_minusButton setTarget:self];
//         [_minusButton setAction:@selector(removeDHCPRange:)];
//     }
// }

// - (IBAction)displayHostsTable:(id)sender
// {
//     if (_currentTableScrollView != scrollViewDHCPHosts)
//     {
//         [_currentTableScrollView removeFromSuperview];
//         _currentTableScrollView = scrollViewDHCPHosts;
//         [scrollViewDHCPHosts setFrame:[viewCurrentTable bounds]];
//         [viewCurrentTable addSubview:scrollViewDHCPHosts];
// 
//         [[[buttonBar buttons] objectAtIndex:1] setValue:_buttonBezelSelected forThemeAttribute:"bezel-color"];
//         [[[buttonBar buttons] objectAtIndex:0] setValue:_bezelColor forThemeAttribute:"bezel-color"];
//         
//         [_plusButton setTarget:self];
//         [_plusButton setAction:@selector(addDHCPHost:)];
//         [_minusButton setTarget:self];
//         [_minusButton setAction:@selector(removeDHCPHost:)];
//     }
// }

- (IBAction)save:(id)sender
{
    [_network setNetworkName:[fieldNetworkName stringValue]];
    [_network setBridgeName:[fieldBridgeName stringValue]];
    [_network setBridgeDelay:[fieldBridgeDelay stringValue]];
    [_network setBridgeForwardMode:[buttonForwardMode title]];
    [_network setBridgeForwardDevice:[buttonForwardDevice title]];
    [_network setBridgeIP:[fieldBridgeIP stringValue]];
    [_network setBridgeNetmask:[fieldBridgeNetmask stringValue]];
    [_network setDHCPEntriesRanges:[_datasourceDHCPRanges content]];
    [_network setDHCPEntriesHosts:[_datasourceDHCPHosts content]];
    [_network setSTPEnabled:([checkBoxSTPEnabled state] == CPOnState) ? YES : NO];
    [_network setDHCPEnabled:([checkBoxDHCPEnabled state] == CPOnState) ? YES : NO];

    [_externalTable reloadData];
    
    [[self delegate] defineNetworkXML:nil];
    [self close];
}

- (IBAction)addDHCPRange:(id)sender
{
    var newRange = [TNDHCPEntry DHCPRangeWithStartAddress:@"0.0.0.0"  endAddress:@"0.0.0.0"];

    [checkBoxDHCPEnabled setState:CPOnState];
    [_datasourceDHCPRanges addObject:newRange];
    [_tableViewRanges reloadData];
}

- (IBAction)removeDHCPRange:(id)sender
{
    var selectedIndex   = [[_tableViewRanges selectedRowIndexes] firstIndex];
    var rangeObject     = [_datasourceDHCPRanges removeObjectAtIndex:selectedIndex];

    [_tableViewRanges reloadData];

    if (([_tableViewRanges numberOfRows] == 0) && ([_tableViewHosts numberOfRows] == 0))
      [checkBoxDHCPEnabled setState:CPOffState];

}

- (IBAction)addDHCPHost:(id)sender
{
    var newHost = [TNDHCPEntry DHCPHostWithMac:@"00:00:00:00:00:00"  name:"domain.com" ip:@"0.0.0.0"];

    [checkBoxDHCPEnabled setState:CPOnState];
    [_datasourceDHCPHosts addObject:newHost];
    [_tableViewHosts reloadData];
}

- (IBAction)removeDHCPHost:(id)sender
{
    var selectedIndex   = [[_tableViewHosts selectedRowIndexes] firstIndex];
    var hostsObject     = [_datasourceDHCPHosts removeObjectAtIndex:selectedIndex];

    [_tableViewHosts reloadData];

    if (([_tableViewRanges numberOfRows] == 0) && ([_tableViewHosts numberOfRows] == 0))
      [checkBoxDHCPEnabled setState:CPOffState];
}

@end
