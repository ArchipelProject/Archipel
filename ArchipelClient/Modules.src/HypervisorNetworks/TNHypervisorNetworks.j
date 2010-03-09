/*  
 * TNViewHypervisorControl.j
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
@import <AppKit/AppKit.j>
@import <AppKit/CPCollectionView.j>

@import "TNDatasourceNetworks.j"
@import "TNDatasourceDHCPEntries.j"
@import "TNWindowNetworkProperties.j"


trinityTypeHypervisorNetwork            = @"trinity:hypervisor:network";
trinityTypeHypervisorNetworkList        = @"list";
trinityTypeHypervisorNetworkDefine      = @"define";
trinityTypeHypervisorNetworkUndefine    = @"indefine";
trinityTypeHypervisorNetworkCreate      = @"create";
trinityTypeHypervisorNetworkDestroy     = @"destroy";




@implementation TNHypervisorNetworks : TNModule 
{
    @outlet CPScrollView                scrollViewNetworks      @accessors;
    @outlet TNWindowNetworkProperties   windowProperties        @accessors;
    
    CPTableView             _tableViewNetworks; 
    TNDatasourceNetworks    _datasourceNetworks;
}

- (void)awakeFromCib
{
    // VM table view
    _datasourceNetworks     = [[TNDatasourceNetworks alloc] init];
    _tableViewNetworks      = [[CPTableView alloc] initWithFrame:[[self scrollViewNetworks] bounds]];
    
    [[self scrollViewNetworks] setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [[self scrollViewNetworks] setAutohidesScrollers:YES];
    [[self scrollViewNetworks] setDocumentView:_tableViewNetworks];
    [[self scrollViewNetworks] setBorderedWithHexColor:@"#9e9e9e"];
    
    [_tableViewNetworks setUsesAlternatingRowBackgroundColors:YES];
    [_tableViewNetworks setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [_tableViewNetworks setAllowsColumnReordering:YES];
    [_tableViewNetworks setAllowsColumnResizing:YES];
    [_tableViewNetworks setAllowsEmptySelection:YES];
    [_tableViewNetworks setTarget:self];
    [_tableViewNetworks setDoubleAction:@selector(editNetwork:)];
    
    var columNetworkEnabled = [[CPTableColumn alloc] initWithIdentifier:@"isNetworkEnabled"];
    var imgView = [[CPImageView alloc] initWithFrame:CGRectMake(0,0,16,16)];
    [imgView setImageScaling:CPScaleNone];
    [columNetworkEnabled setDataView:imgView];
    [columNetworkEnabled setWidth:16];
    [[columNetworkEnabled headerView] setStringValue:@""];
    
    
    var columNetworkName = [[CPTableColumn alloc] initWithIdentifier:@"networkName"];
    [columNetworkName setResizingMask:CPTableColumnAutoresizingMask ];
    [[columNetworkName headerView] setStringValue:@"Network Name"];
    
    var columBridgeName = [[CPTableColumn alloc] initWithIdentifier:@"bridgeName"];
    [columBridgeName setResizingMask:CPTableColumnAutoresizingMask ];
    [[columBridgeName headerView] setStringValue:@"Bridge Name"];
    
    var columForwardMode = [[CPTableColumn alloc] initWithIdentifier:@"bridgeForwardMode"];
    [columForwardMode setResizingMask:CPTableColumnAutoresizingMask ];
    [[columForwardMode headerView] setStringValue:@"Forward Mode"];
    
    var columForwardDevice = [[CPTableColumn alloc] initWithIdentifier:@"bridgeForwardDevice"];
    [columForwardDevice setResizingMask:CPTableColumnAutoresizingMask ];
    [[columForwardDevice headerView] setStringValue:@"Forward Device"];
    
    var columBridgeIP = [[CPTableColumn alloc] initWithIdentifier:@"bridgeIP"];
    [columBridgeIP setResizingMask:CPTableColumnAutoresizingMask ];
    [[columBridgeIP headerView] setStringValue:@"Bridge IP"];
    
    var columBridgeNetmask = [[CPTableColumn alloc] initWithIdentifier:@"bridgeNetmask"];
    [columBridgeNetmask setResizingMask:CPTableColumnAutoresizingMask ];
    [[columBridgeNetmask headerView] setStringValue:@"Bridge Netmask"];
    
    [_tableViewNetworks addTableColumn:columNetworkName];
    [_tableViewNetworks addTableColumn:columBridgeName];
    [_tableViewNetworks addTableColumn:columForwardMode];
    [_tableViewNetworks addTableColumn:columForwardDevice];
    [_tableViewNetworks addTableColumn:columBridgeIP];
    [_tableViewNetworks addTableColumn:columBridgeNetmask];
    
    [_tableViewNetworks setDataSource:_datasourceNetworks];
    
    [[self windowProperties] setDelegate:self];
}

- (void)willLoad
{
    // message sent when view will be added from superview;
    // MUST be declared
}

- (void)willUnload
{
   // message sent when view will be removed from superview;
   // MUST be declared
}

- (void)willShow 
{
    [self getHypervisorNetworks];
}

- (void)willHide 
{
    // message sent when the tab is changed
}

- (void)getHypervisorNetworks
{
    var uid             = [[[self contact] connection] getUniqueId];
    var networksStanza  = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeHypervisorNetwork, "to": [[self contact] fullJID], "id": uid}];
    var params          = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];
        
    [networksStanza addChildName:@"query" withAttributes:{"type" : trinityTypeHypervisorNetworkList}];
    
    [[[self contact] connection] registerSelector:@selector(didReceiveHypervisorNetworks:) ofObject:self withDict:params];
    [[[self contact] connection] send:networksStanza];
}

- (void)didReceiveHypervisorNetworks:(id)aStanza 
{
    var activeNetworks      = [[[aStanza childrenWithName:@"activedNetworks"] objectAtIndex:0] children];
    var unactiveNetworks    = [[[aStanza childrenWithName:@"unactivedNetworks"] objectAtIndex:0] children];
    var allNetworks         = [CPArray array];
    
    [allNetworks addObjectsFromArray:activeNetworks];
    [allNetworks addObjectsFromArray:unactiveNetworks];
    
    [[_datasourceNetworks networks] removeAllObjects];
    
    for (var i = 0; i < [allNetworks count]; i++)
    {
        var network             = [allNetworks objectAtIndex:i];
        var name                = [[network firstChildWithName:@"name"] text];
        var bridge              = [network firstChildWithName:@"bridge"];
        var bridgeName          = [bridge valueForAttribute:@"name"];
        var bridgeSTP           = ([bridge valueForAttribute:@"stp"] == @"on") ? YES : NO;
        var bridgeDelay         = [bridge valueForAttribute:@"delay"];
        var forward             = [network firstChildWithName:@"forward"];
        var forwardMode         = [forward valueForAttribute:@"mode"];
        var forwardDev          = [forward valueForAttribute:@"dev"];
        var ip                  = [network firstChildWithName:@"ip"];
        var bridgeIP            = [ip valueForAttribute:@"address"];
        var bridgeNetmask       = [ip valueForAttribute:@"netmask"];
        var dhcp                = [ip firstChildWithName:@"dhcp"];
        var DHCPEnabled         = (dhcp) ? YES : NO;
        var DHCPRangeEntries    = [dhcp childrenWithName:@"range"]; 
        var DHCPHostEntries     = [dhcp childrenWithName:@"host"];
        var networkActive       = [activeNetworks containsObject:network];
        
        var DHCPRangeEntriesArray = [CPArray array];
        for (var i = 0; DHCPEnabled && i < [DHCPRangeEntries count]; i++)
        {
            var DHCPEntry           = [DHCPRangeEntries objectAtIndex:i];
            var randgeStartAddr     = [DHCPEntry valueForAttribute:@"start"];
            var rangeEndAddr        = [DHCPEntry valueForAttribute:@"end"];
            
            var DHCPEntryObject     = [TNDHCPEntry DHCPRangeWithStartAddress:randgeStartAddr endAddress:rangeEndAddr];
            
            [DHCPRangeEntriesArray addObject:DHCPEntryObject]; 
        }
        
        var DHCPHostEntriesArray = [CPArray array];
        for (var i = 0; DHCPEnabled && i < [DHCPHostEntries count]; i++)
        {
            var DHCPEntry   = [DHCPHostEntries objectAtIndex:i];
            var hostsMac    = [DHCPEntry valueForAttribute:@"mac"];
            var hostName    = [DHCPEntry valueForAttribute:@"name"];
            var hostIP      = [DHCPEntry valueForAttribute:@"ip"];
            
            var DHCPEntryObject = [TNDHCPEntry DHCPHostWithMac:hostsMac name:hostName ip:hostIP];
            
            [DHCPHostEntriesArray addObject:DHCPEntryObject];
        }
        
        console.log("bridgeSTP " + [bridge valueForAttribute:@"stp"]);
        
        var newNetwork  = [TNNetwork networkWithName:name 
                                          bridgeName:bridgeName 
                                         bridgeDelay:parseInt(bridgeDelay)
                                   bridgeForwardMode:forwardMode
                                 bridgeForwardDevice:forwardDev
                                            bridgeIP:bridgeIP
                                       bridgeNetmask:bridgeNetmask
                                   DHCPEntriesRanges:DHCPRangeEntriesArray
                                    DHCPEntriesHosts:DHCPHostEntriesArray
                                      networkEnabled:networkActive
                                          STPEnabled:bridgeSTP
                                         DHCPEnabled:DHCPEnabled]
        
        [[_datasourceNetworks networks] addObject:newNetwork];   
    }

    [_tableViewNetworks reloadData];
}

- (IBAction)editNetwork:(id)sender
{
    var selectedIndex   = [[_tableViewNetworks selectedRowIndexes] firstIndex];
    
    if (selectedIndex != -1)
    {
        var networkObject = [[_datasourceNetworks networks] objectAtIndex:selectedIndex];

        [[self windowProperties] setNetwork:networkObject];
        [[self windowProperties] setTable:_tableViewNetworks];
        [[self windowProperties] setHypervisor:[self contact]];
        [[self windowProperties] center];
        [[self windowProperties] orderFront:nil];
    }
}

- (IBAction)defineNetworkXML:(id)sender
{
    var uid             = [[[self contact] connection] getUniqueId];
    var defineStanza    = [self generateXMLNetworkStanzaWithUniqueID:uid];
    var params          = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];
    
    [[[self contact] connection] registerSelector:@selector(didDefineNetwork:) ofObject:self withDict:params];
    [[[self contact] connection] send:defineStanza];
}

- (TNStropheStanza)generateXMLNetworkStanzaWithUniqueID:(CPNumber)anUid
{
    var selectedIndex   = [[_tableViewNetworks selectedRowIndexes] firstIndex];
    
    if (selectedIndex == -1)
        return
    
    var networkObject   = [[_datasourceNetworks networks] objectAtIndex:selectedIndex];
    var stanza          = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeHypervisorNetwork, "to": [[self contact] fullJID], "id": anUid}];
    
    
    [stanza addChildName:@"query" withAttributes:{"type": trinityTypeHypervisorNetworkDefine}];
    [stanza addChildName:@"network"];
    
    [stanza addChildName:@"name"];
    [stanza addTextNode:[networkObject networkName]];
    [stanza up];
    
    [stanza addChildName:@"forward" withAttributes:{"mode": [networkObject bridgeForwardMode], "dev": [networkObject bridgeForwardDevice]}];
    [stanza up];
    
    [stanza addChildName:@"bridge" withAttributes:{"name": [networkObject bridgeName], "stp": ([networkObject isSTPEnabled]) ? "on" :"off", "delay": [networkObject bridgeDelay]}];
    [stanza up];
    
    [stanza addChildName:@"ip" withAttributes:{"address": [networkObject bridgeIP], "netmask": [networkObject bridgeNetmask]}];
    var dhcp = [networkObject isDHCPEnabled];
    if (dhcp)
    {
        console.log("HEEEREEE");
        [stanza addChildName:@"dhcp"];
        
        var DHCPRangeEntries = [networkObject DHCPEntriesRanges];
        for (var i = 0; i < [DHCPRangeEntries count]; i++)
        {
            var DHCPEntry = [DHCPRangeEntries objectAtIndex:i];
            
            [stanza addChildName:@"range" withAttributes:{"start" : [DHCPEntry start], "end": [DHCPEntry end]}];
            [stanza up];
        }
        
        var DHCPHostsEntries = [networkObject DHCPEntriesHosts];
        for (var i = 0; i < [DHCPHostsEntries count]; i++)
        {
            var DHCPEntry = [DHCPHostsEntries objectAtIndex:i];
            
            [stanza addChildName:@"host" withAttributes:{"mac" : [DHCPEntry mac], "name": [DHCPEntry name], "ip": [DHCPEntry IP]}];
            [stanza up];
        }
        
        [stanza up];
    }
    // ip up
    [stanza up];
    
    console.log([stanza stringValue]);
    return stanza;
}

- (void)didDefineNetwork:(TNStropheStanza)aStanza
{
    console.log([aStanza stringValue]);
}

-(BOOL)windowShouldClose:(id)window
{
    [self defineNetworkXML:nil];
    
    return YES;
}
@end



