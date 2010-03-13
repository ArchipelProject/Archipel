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
trinityTypeHypervisorNetworkUndefine    = @"undefine";
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
    
    [_tableViewNetworks addTableColumn:columNetworkEnabled];
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
    var uid             = [[self connection] getUniqueId];
    var networksStanza  = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeHypervisorNetwork, "to": [[self entity] fullJID], "id": uid}];
    var params          = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];
        
    [networksStanza addChildName:@"query" withAttributes:{"type" : trinityTypeHypervisorNetworkList}];
    
    [[self connection] registerSelector:@selector(didReceiveHypervisorNetworks:) ofObject:self withDict:params];
    [[self connection] send:networksStanza];
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
        var uuid                = [[network firstChildWithName:@"uuid"] text];
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
        for (var j = 0; DHCPEnabled && j < [DHCPRangeEntries count]; j++)
        {
            var DHCPEntry           = [DHCPRangeEntries objectAtIndex:j];
            var randgeStartAddr     = [DHCPEntry valueForAttribute:@"start"];
            var rangeEndAddr        = [DHCPEntry valueForAttribute:@"end"];
            
            var DHCPEntryObject     = [TNDHCPEntry DHCPRangeWithStartAddress:randgeStartAddr endAddress:rangeEndAddr];
            
            [DHCPRangeEntriesArray addObject:DHCPEntryObject]; 
        }
        
        var DHCPHostEntriesArray = [CPArray array];
        for (var j = 0; DHCPEnabled && j < [DHCPHostEntries count]; j++)
        {
            var DHCPEntry   = [DHCPHostEntries objectAtIndex:j];
            var hostsMac    = [DHCPEntry valueForAttribute:@"mac"];
            var hostName    = [DHCPEntry valueForAttribute:@"name"];
            var hostIP      = [DHCPEntry valueForAttribute:@"ip"];
            
            var DHCPEntryObject = [TNDHCPEntry DHCPHostWithMac:hostsMac name:hostName ip:hostIP];
            
            [DHCPHostEntriesArray addObject:DHCPEntryObject];
        }
        
        var newNetwork  = [TNNetwork networkWithName:name 
                                                UUID:uuid
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

- (TNStropheStanza)generateXMLNetworkStanzaWithUniqueID:(CPNumber)anUid
{
    var selectedIndex   = [[_tableViewNetworks selectedRowIndexes] firstIndex];
    
    if (selectedIndex == -1)
        return
    
    var networkObject   = [[_datasourceNetworks networks] objectAtIndex:selectedIndex];
    var stanza          = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeHypervisorNetwork, "to": [[self entity] fullJID], "id": anUid}];
    
    
    [stanza addChildName:@"query" withAttributes:{"type": trinityTypeHypervisorNetworkDefine}];
    [stanza addChildName:@"network"];
    
    [stanza addChildName:@"name"];
    [stanza addTextNode:[networkObject networkName]];
    [stanza up];
    
    [stanza addChildName:@"uuid"];
    [stanza addTextNode:[networkObject UUID]];
    [stanza up];
    
    [stanza addChildName:@"forward" withAttributes:{"mode": [networkObject bridgeForwardMode], "dev": [networkObject bridgeForwardDevice]}];
    [stanza up];
    
    [stanza addChildName:@"bridge" withAttributes:{"name": [networkObject bridgeName], "stp": ([networkObject isSTPEnabled]) ? "on" :"off", "delay": [networkObject bridgeDelay]}];
    [stanza up];
    
    [stanza addChildName:@"ip" withAttributes:{"address": [networkObject bridgeIP], "netmask": [networkObject bridgeNetmask]}];
    var dhcp = [networkObject isDHCPEnabled];
    if (dhcp)
    {
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
    
    return stanza;
}

- (IBAction)editNetwork:(id)sender
{
    var selectedIndex   = [[_tableViewNetworks selectedRowIndexes] firstIndex];
    
    if (selectedIndex != -1)
    {
        var networkObject = [[_datasourceNetworks networks] objectAtIndex:selectedIndex];
        
        if ([networkObject isNetworkEnabled])
        {
            [CPAlert alertWithTitle:@"Error" message:@"You can't edit a running network" style:CPCriticalAlertStyle];
            return
        }
        

        [[self windowProperties] setNetwork:networkObject];
        [[self windowProperties] setTable:_tableViewNetworks];
        [[self windowProperties] setHypervisor:[self entity]];
        [[self windowProperties] center];
        [[self windowProperties] orderFront:nil];
    }
}


- (IBAction)defineNetworkXML:(id)sender
{
    var selectedIndex   = [[_tableViewNetworks selectedRowIndexes] firstIndex];

    if (selectedIndex == -1)
        return

    var networkObject   = [[_datasourceNetworks networks] objectAtIndex:selectedIndex];
    
    if ([networkObject isNetworkEnabled])
    {
        [CPAlert alertWithTitle:@"Error" message:@"You can't update a running network" style:CPCriticalAlertStyle];
        return
    }
    var uid             = [[self connection] getUniqueId];
    var deleteStanza    = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeHypervisorNetwork, "to": [[self entity] fullJID], "id": uid}];
    var params          = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];

    [deleteStanza addChildName:@"query" withAttributes:{"type": trinityTypeHypervisorNetworkUndefine}]; 
    [deleteStanza addTextNode:[networkObject UUID]];
    
    [[self connection] registerSelector:@selector(didNetworkUndefinedBeforeDefining:) ofObject:self withDict:params];
    [[self connection] send:deleteStanza];
    
}

- (void)didNetworkUndefinedBeforeDefining:(TNStropheStanza)aStanza
{
    var uid             = [[self connection] getUniqueId];
    var defineStanza    = [self generateXMLNetworkStanzaWithUniqueID:uid];
    var params          = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];
    
    [[self connection] registerSelector:@selector(didDefineNetwork:) ofObject:self withDict:params];
    [[self connection] send:defineStanza];
}

- (void)didDefineNetwork:(TNStropheStanza)aStanza
{
    if ([aStanza getType] != @"success")
    {
        [self onLibvirtError:aStanza];
    }
}


- (IBAction)activateNetworkSwitch:(id)sender
{
    var selectedIndex   = [[_tableViewNetworks selectedRowIndexes] firstIndex];
    
    if (selectedIndex == -1)
        return
    
    var networkObject   = [[_datasourceNetworks networks] objectAtIndex:selectedIndex];
    var uid             = [[self connection] getUniqueId];
    var activeStanza    = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeHypervisorNetwork, "to": [[self entity] fullJID], "id": uid}];
    var params          = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];

    if ([networkObject isNetworkEnabled])
    {
        [activeStanza addChildName:@"query" withAttributes:{"type": trinityTypeHypervisorNetworkDestroy}];
    }
    else
    {
        [activeStanza addChildName:@"query" withAttributes:{"type": trinityTypeHypervisorNetworkCreate}];
    }
        
    [activeStanza addTextNode:[networkObject UUID]];
    
    [[self connection] registerSelector:@selector(didNetworkStatusChange:) ofObject:self withDict:params];
    [[self connection] send:activeStanza];
}

- (void)didNetworkStatusChange:(TNStropheStanza)aStanza
{
    if ([aStanza getType] == @"success")
    {
        [self getHypervisorNetworks];
    }
    else
    {
        [self onLibvirtError:aStanza];
    }
}

- (IBAction)addNetwork:(id)sender
{
   var newNetwork = [TNNetwork networkWithName:@"New Network"
                                            UUID:[CPString UUID]
                                      bridgeName:@"virbr0"
                                     bridgeDelay:0
                               bridgeForwardMode:@"route"
                             bridgeForwardDevice:@"eth0"
                                        bridgeIP:@"10.0.0.1"
                                   bridgeNetmask:@"255.255.0.0"
                               DHCPEntriesRanges:[CPArray array]
                                DHCPEntriesHosts:[CPArray array]
                                  networkEnabled:NO
                                      STPEnabled:NO
                                     DHCPEnabled:NO];

    [[_datasourceNetworks networks] addObject:newNetwork];
    [_tableViewNetworks reloadData];
}

- (IBAction)delNetwork:(id)sender
{
    var selectedIndex   = [[_tableViewNetworks selectedRowIndexes] firstIndex];

    if (selectedIndex == -1)
        return

    var networkObject   = [[_datasourceNetworks networks] objectAtIndex:selectedIndex];
    
    if ([networkObject isNetworkEnabled])
    {
        [CPAlert alertWithTitle:@"Error" message:@"You can't update a running network" style:CPCriticalAlertStyle];
        return
    }
    
    var uid             = [[self connection] getUniqueId];
    var deleteStanza    = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeHypervisorNetwork, "to": [[self entity] fullJID], "id": uid}];
    var params          = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];

    [deleteStanza addChildName:@"query" withAttributes:{"type": trinityTypeHypervisorNetworkUndefine}]; 
    [deleteStanza addTextNode:[networkObject UUID]];
    
    [[self connection] registerSelector:@selector(didDelNetwork:) ofObject:self withDict:params];
    [[self connection] send:deleteStanza];

}

- (void)didDelNetwork:(TNStropheStanza)aStanza
{
    if ([aStanza getType] == @"success")
    {
        [self getHypervisorNetworks];
    }
    else
    {
        [self onLibvirtError:aStanza];
    }
}

-(BOOL)windowShouldClose:(id)window
{
    [self defineNetworkXML:nil];
    
    return YES;
}

- (void)onLibvirtError:(TNStropheStanza)errorStanza
{
    var errorNode               = [errorStanza firstChildWithName:@"error"];
    var libvirtErrorCode        = [errorNode valueForAttribute:@"code"];
    var libvirtErrorMessage     = [errorNode text];   
    var title                   = @"Error " + libvirtErrorCode;
    
    [CPAlert alertWithTitle:title message:libvirtErrorMessage style:CPCriticalAlertStyle]
    
    [[TNViewLog sharedLogger] log:@"Error code :" + libvirtErrorCode + ". " + libvirtErrorMessage];
}

@end



