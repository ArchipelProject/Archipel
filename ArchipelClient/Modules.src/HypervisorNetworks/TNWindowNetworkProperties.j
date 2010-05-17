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
    @outlet CPTextField     fieldNetworkName            @accessors;
    @outlet CPTextField     fieldBridgeName             @accessors;
    @outlet CPTextField     fieldBridgeDelay            @accessors;
    @outlet CPPopUpButton   buttonForwardMode           @accessors;
    @outlet CPPopUpButton   buttonForwardDevice         @accessors;
    @outlet CPTextField     fieldBridgeIP               @accessors;
    @outlet CPTextField     fieldBridgeNetmask          @accessors;
    @outlet CPCheckBox      checkBoxSTPEnabled          @accessors;
    @outlet CPCheckBox      checkBoxDHCPEnabled         @accessors;
    @outlet CPView          viewTableContainer;
    @outlet CPView          viewCurrentTable;
    @outlet CPButtonBar     buttonBar;
    @outlet CPButtonBar     buttonBarControl;
    @outlet CPScrollView    _scrollViewDHCPRanges;
    @outlet CPScrollView    _scrollViewDHCPHosts;

    TNNetwork               network                     @accessors;
    TNStropheContact        hypervisor                  @accessors;
    CPTableView             table                       @accessors;

    CPButton                _plusButton;
    CPButton                _minusButton;
    TNTableViewDataSource   _datasourceDHCPRanges;
    TNTableViewDataSource   _datasourceDHCPHosts;
    CPTableView             _tableViewRanges;
    CPTableView             _tableViewHosts;
    CPScrollView            _currentTableScrollView;
    CPColor                 _buttonBezelHighlighted;
    CPColor                 _buttonBezelSelected;
    CPColor                 _bezelColor;
}

- (void)awakeFromCib
{
    var bundle                  = [CPBundle mainBundle];
    var centerBezel             = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"TNButtonBar/buttonBarCenterBezel.png"] size:CGSizeMake(1, 26)];
    var buttonBezel             = [CPColor colorWithPatternImage:centerBezel];
    var centerBezelHighlighted  = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"TNButtonBar/buttonBarCenterBezelHighlighted.png"] size:CGSizeMake(1, 26)];
    var centerBezelSelected     = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"TNButtonBar/buttonBarCenterBezelSelected.png"] size:CGSizeMake(1, 26)];

    _bezelColor                 = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"TNButtonBar/buttonBarBackground.png"] size:CGSizeMake(1, 27)]];
    _buttonBezelHighlighted     = [CPColor colorWithPatternImage:centerBezelHighlighted];
    _buttonBezelSelected = [CPColor colorWithPatternImage:centerBezelSelected];
    
    [buttonBar setValue:_bezelColor forThemeAttribute:"bezel-color"];
    [buttonBar setValue:buttonBezel forThemeAttribute:"button-bezel-color"];
    [buttonBar setValue:_buttonBezelHighlighted forThemeAttribute:"button-bezel-color" inState:CPThemeStateHighlighted];
    
    var rangeButton = [[CPButton alloc] initWithFrame:CPRectMake(0,0,[buttonBar frame].size.width / 2 - 2,25)];
    [rangeButton setValue:_buttonBezelHighlighted forThemeAttribute:"bezel-color" inState:CPThemeStateSelected];
    [rangeButton setBordered:NO];
    [rangeButton setTarget:self];
    [rangeButton setAction:@selector(displayRangesTable:)];
    [rangeButton setTitle:@"DHCP Ranges"];
    
    var hostButton = [[CPButton alloc] initWithFrame:CPRectMake([buttonBar frame].size.width / 2 - 2,0,[buttonBar frame].size.width / 2,25)];
    [hostButton setValue:_buttonBezelHighlighted forThemeAttribute:"bezel-color" inState:CPThemeStateSelected];
    [hostButton setBordered:NO];
    [hostButton setTarget:self];
    [hostButton setAction:@selector(displayHostsTable:)];
    [hostButton setTitle:@"DHCP Hosts"];
    
    [buttonBar setButtons:[rangeButton, hostButton]];
    [buttonBar layoutSubviews];
    
    _plusButton = [CPButtonBar plusButton];
    _minusButton = [CPButtonBar minusButton];
    [buttonBarControl setButtons:[_plusButton, _minusButton]];
    
    [viewTableContainer setBorderedWithHexColor:@"#9e9e9e"];
    
    [buttonForwardMode removeAllItems];
    [buttonForwardMode addItemsWithTitles:["route", "nat"]];
    
    [buttonForwardDevice removeAllItems];
    [buttonForwardDevice addItemsWithTitles:["nothing", "eth0", "eth1", "eth2", "eth3", "eth4", "eth5", "eth6"]];
    
    
    
    // TABLE FOR RANGES
    _scrollViewDHCPRanges    = [[CPScrollView alloc] initWithFrame:[viewCurrentTable bounds]];
    _datasourceDHCPRanges   = [[TNTableViewDataSource alloc] init];
    _tableViewRanges        = [[CPTableView alloc] initWithFrame:[_scrollViewDHCPRanges bounds]];

    [_scrollViewDHCPRanges setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [_scrollViewDHCPRanges setAutohidesScrollers:YES];
    [_scrollViewDHCPRanges setDocumentView:_tableViewRanges];
    // [_scrollViewDHCPRanges setBorderedWithHexColor:@"#9e9e9e"];

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
    _scrollViewDHCPHosts     = [[CPScrollView alloc] initWithFrame:[viewCurrentTable bounds]];
    _datasourceDHCPHosts     = [[TNTableViewDataSource alloc] init];
    _tableViewHosts          = [[CPTableView alloc] initWithFrame:[_scrollViewDHCPHosts bounds]];

    [_scrollViewDHCPHosts setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [_scrollViewDHCPHosts setAutohidesScrollers:YES];
    [_scrollViewDHCPHosts setDocumentView:_tableViewHosts];
    // [_scrollViewDHCPHosts setBorderedWithHexColor:@"#9e9e9e"];

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
    
    // setting the current selected table
    _currentTableScrollView = _scrollViewDHCPRanges;
    [viewCurrentTable addSubview:_scrollViewDHCPRanges];
    [rangeButton setValue:_buttonBezelSelected forThemeAttribute:"bezel-color"];
    
    var menuRange = [[CPMenu alloc] init];
    [menuRange addItemWithTitle:@"Add new range" action:@selector(addDHCPRange:) keyEquivalent:@""];
    [menuRange addItemWithTitle:@"Remove" action:@selector(removeDHCPRange:) keyEquivalent:@""];
    [_tableViewRanges setMenu:menuRange];
    
    var menuHost = [[CPMenu alloc] init];
    [menuHost addItemWithTitle:@"Add new host reservation" action:@selector(addDHCPHost:) keyEquivalent:@""];
    [menuHost addItemWithTitle:@"Remove" action:@selector(removeDHCPHost:) keyEquivalent:@""];
    [_tableViewHosts setMenu:menuHost];
}

- (void)orderFront:(id)sender
{
    if (![self isVisible])
    {
        [fieldNetworkName setStringValue:[network networkName]];
        [fieldBridgeName setStringValue:[network bridgeName]];
        [fieldBridgeDelay setStringValue:([network bridgeDelay] != @"") ? [network bridgeDelay] : @"0"];
        [fieldBridgeIP setStringValue:[network bridgeIP]];
        [fieldBridgeNetmask setStringValue:[network bridgeNetmask]];

        [buttonForwardMode selectItemWithTitle:[network bridgeForwardMode]];
        [buttonForwardDevice selectItemWithTitle:[network bridgeForwardDevice]];

        [checkBoxSTPEnabled setState:([network isSTPEnabled]) ? CPOnState : CPOffState];
        [checkBoxDHCPEnabled setState:([network isDHCPEnabled]) ? CPOnState : CPOffState];

        [_datasourceDHCPRanges setContent:[network DHCPEntriesRanges]];
        [_datasourceDHCPHosts setContent:[network DHCPEntriesHosts]];

        [_tableViewRanges reloadData];
        [_tableViewHosts reloadData];
        
        [[[buttonBar buttons] objectAtIndex:0] setValue:_buttonBezelSelected forThemeAttribute:"bezel-color"];
        _currentTableScrollView = _scrollViewDHCPHosts;
        [self displayRangesTable:nil];
    }
    
    [super orderFront:sender];
    
    // ouais, ben ouais, commentes, tu vas voir...
    var frame = [_tableViewHosts bounds];
    frame.size.width--;
    
    [_tableViewHosts setFrame:frame];
    [_tableViewRanges setFrame:frame];
}

- (IBAction)displayRangesTable:(id)sender
{
    if (_currentTableScrollView != _scrollViewDHCPRanges)
    {
        [_currentTableScrollView removeFromSuperview];
        _currentTableScrollView = _scrollViewDHCPRanges;
        [_scrollViewDHCPRanges setFrame:[viewCurrentTable bounds]];
        [viewCurrentTable addSubview:_scrollViewDHCPRanges];
        
        [[[buttonBar buttons] objectAtIndex:0] setValue:_buttonBezelSelected forThemeAttribute:"bezel-color"];
        [[[buttonBar buttons] objectAtIndex:1] setValue:_bezelColor forThemeAttribute:"bezel-color"];
        
        [_plusButton setTarget:self];
        [_plusButton setAction:@selector(addDHCPRange:)];
        [_minusButton setTarget:self];
        [_minusButton setAction:@selector(removeDHCPRange:)];
    }
}

- (IBAction)displayHostsTable:(id)sender
{
    if (_currentTableScrollView != _scrollViewDHCPHosts)
    {
        [_currentTableScrollView removeFromSuperview];
        _currentTableScrollView = _scrollViewDHCPHosts;
        [_scrollViewDHCPHosts setFrame:[viewCurrentTable bounds]];
        [viewCurrentTable addSubview:_scrollViewDHCPHosts];

        [[[buttonBar buttons] objectAtIndex:1] setValue:_buttonBezelSelected forThemeAttribute:"bezel-color"];
        [[[buttonBar buttons] objectAtIndex:0] setValue:_bezelColor forThemeAttribute:"bezel-color"];
        
        [_plusButton setTarget:self];
        [_plusButton setAction:@selector(addDHCPHost:)];
        [_minusButton setTarget:self];
        [_minusButton setAction:@selector(removeDHCPHost:)];
    }
}

- (IBAction)save:(id)sender
{
    [network setNetworkName:[fieldNetworkName stringValue]];
    [network setBridgeName:[fieldBridgeName stringValue]];
    [network setBridgeDelay:[fieldBridgeDelay stringValue]];
    [network setBridgeForwardMode:[buttonForwardMode title]];
    [network setBridgeForwardDevice:[buttonForwardDevice title]];
    [network setBridgeIP:[fieldBridgeIP stringValue]];
    [network setBridgeNetmask:[fieldBridgeNetmask stringValue]];
    [network setDHCPEntriesRanges:[_datasourceDHCPRanges content]];
    [network setDHCPEntriesHosts:[_datasourceDHCPHosts content]];
    [network setSTPEnabled:([checkBoxSTPEnabled state] == CPOnState) ? YES : NO];
    [network setDHCPEnabled:([checkBoxDHCPEnabled state] == CPOnState) ? YES : NO];

    [[self table] reloadData];
}

- (IBAction)addDHCPRange:(id)sender
{
    var newRange = [TNDHCPEntry DHCPRangeWithStartAddress:@"0.0.0.0"  endAddress:@"0.0.0.0"];

    [checkBoxDHCPEnabled setState:CPOnState];
    [_datasourceDHCPRanges addObject:newRange];
    [_tableViewRanges reloadData];
    [self save:nil];
}

- (IBAction)removeDHCPRange:(id)sender
{
    var selectedIndex   = [[_tableViewRanges selectedRowIndexes] firstIndex];
    var rangeObject     = [_datasourceDHCPRanges removeObjectAtIndex:selectedIndex];

    [_tableViewRanges reloadData];

    if (([_tableViewRanges numberOfRows] == 0) && ([_tableViewHosts numberOfRows] == 0))
      [checkBoxDHCPEnabled setState:CPOffState];

    [self save:nil];
}

- (IBAction)addDHCPHost:(id)sender
{
    var newHost = [TNDHCPEntry DHCPHostWithMac:@"00:00:00:00:00:00"  name:"domain.com" ip:@"0.0.0.0"];

    [checkBoxDHCPEnabled setState:CPOnState];
    [_datasourceDHCPHosts addObject:newHost];
    [_tableViewHosts reloadData];
    [self save:nil];
}

- (IBAction)removeDHCPHost:(id)sender
{
    var selectedIndex   = [[_tableViewHosts selectedRowIndexes] firstIndex];
    var hostsObject     = [_datasourceDHCPHosts removeObjectAtIndex:selectedIndex];

    [_tableViewHosts reloadData];

    if (([_tableViewRanges numberOfRows] == 0) && ([_tableViewHosts numberOfRows] == 0))
      [checkBoxDHCPEnabled setState:CPOffState];

    [self save:nil];
}

@end
