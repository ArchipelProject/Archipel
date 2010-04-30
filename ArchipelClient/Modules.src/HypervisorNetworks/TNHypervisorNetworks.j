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

TNArchipelTypeHypervisorNetwork            = @"archipel:hypervisor:network";
TNArchipelTypeHypervisorNetworkList        = @"list";
TNArchipelTypeHypervisorNetworkDefine      = @"define";
TNArchipelTypeHypervisorNetworkUndefine    = @"undefine";
TNArchipelTypeHypervisorNetworkCreate      = @"create";
TNArchipelTypeHypervisorNetworkDestroy     = @"destroy";

@implementation TNHypervisorNetworks : TNModule
{
    @outlet CPTextField                 fieldJID                @accessors;
    @outlet CPTextField                 fieldName               @accessors;
    @outlet CPScrollView                scrollViewNetworks      @accessors;
    @outlet TNWindowNetworkProperties   windowProperties        @accessors;
    @outlet CPButton                    buttonActivation;
    @outlet CPButton                    buttonDeactivation;
    @outlet CPButton                    buttonDelete;
    
    CPTableView             _tableViewNetworks;
    TNDatasourceNetworks    _datasourceNetworks;
}

- (void)awakeFromCib
{
    /* VM table view */
    _datasourceNetworks     = [[TNDatasourceNetworks alloc] init];
    _tableViewNetworks      = [[CPTableView alloc] initWithFrame:[scrollViewNetworks bounds]];

    [scrollViewNetworks setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [scrollViewNetworks setAutohidesScrollers:YES];
    [scrollViewNetworks setDocumentView:_tableViewNetworks];
    [scrollViewNetworks setBorderedWithHexColor:@"#9e9e9e"];

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
    
    var center = [CPNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(didTableSelectionChange:) name:CPTableViewSelectionDidChangeNotification object:_tableViewNetworks];
    
    [windowProperties setDelegate:self];
    
    [buttonActivation setEnabled:NO];
    [buttonDeactivation setEnabled:NO];
    [buttonDelete setEnabled:NO];

}

- (void)willLoad
{
    [super willLoad];

    var center = [CPNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(didNickNameUpdated:) name:TNStropheContactNicknameUpdatedNotification object:[self entity]];
}

- (void)willShow
{
    [super willShow];

    [fieldName setStringValue:[[self entity] nickname]];
    [fieldJID setStringValue:[[self entity] jid]];
    
    [self getHypervisorNetworks];
}

- (void)didNickNameUpdated:(CPNotification)aNotification
{
    if ([aNotification object] == [self entity])
    {
       [fieldName setStringValue:[[self entity] nickname]]
    }
}

- (void)getHypervisorNetworks
{
    var networksStanza  = [TNStropheStanza iqWithAttributes:{"type": TNArchipelTypeHypervisorNetwork}];

    [networksStanza addChildName:@"query" withAttributes:{"type": TNArchipelTypeHypervisorNetworkList}];

    [self sendStanza:networksStanza andRegisterSelector:@selector(didReceiveHypervisorNetworks:)];
}

- (void)didReceiveHypervisorNetworks:(id)aStanza
{
    if ([aStanza getType] == @"success")
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
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}

- (TNStropheStanza)generateXMLNetworkStanzaWithUniqueID:(CPNumber)anUid
{
    var selectedIndex   = [[_tableViewNetworks selectedRowIndexes] firstIndex];

    if (selectedIndex == -1)
        return

    var networkObject   = [[_datasourceNetworks networks] objectAtIndex:selectedIndex];
    var stanza          = [TNStropheStanza iqWithAttributes:{"type" : TNArchipelTypeHypervisorNetwork, "to": [[self entity] fullJID], "id": anUid}];


    [stanza addChildName:@"query" withAttributes:{"type": TNArchipelTypeHypervisorNetworkDefine}];
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

        [windowProperties setNetwork:networkObject];
        [windowProperties setTable:_tableViewNetworks];
        [windowProperties setHypervisor:[self entity]];
        [windowProperties center];
        [windowProperties orderFront:nil];
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

    var deleteStanza = [TNStropheStanza iqWithAttributes:{"type" : TNArchipelTypeHypervisorNetwork}];

    [deleteStanza addChildName:@"query" withAttributes:{"type": TNArchipelTypeHypervisorNetworkUndefine}];
    [deleteStanza addTextNode:[networkObject UUID]];

    [self sendStanza:deleteStanza andRegisterSelector:@selector(didNetworkUndefinedBeforeDefining:)];
}

- (void)didNetworkUndefinedBeforeDefining:(TNStropheStanza)aStanza
{
    var uid             = [_connection getUniqueId];
    var defineStanza    = [self generateXMLNetworkStanzaWithUniqueID:uid];

    [self sendStanza:defineStanza andRegisterSelector:@selector(didDefineNetwork:) withSpecificID:uid];
}

- (void)didDefineNetwork:(TNStropheStanza)aStanza
{
    if ([aStanza getType] == @"success")
    {
        [self getHypervisorNetworks];
        
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Network" message:@"Network has been defined"];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}

- (IBAction)activateNetwork:(id)sender
{
    var selectedIndex   = [[_tableViewNetworks selectedRowIndexes] firstIndex];

    if (selectedIndex == -1)
        return

    var networkObject   = [[_datasourceNetworks networks] objectAtIndex:selectedIndex];
    var stanza          = [TNStropheStanza iqWithAttributes:{"type" : TNArchipelTypeHypervisorNetwork}]

    if (![networkObject isNetworkEnabled])
    {
        [stanza addChildName:@"query" withAttributes:{"type": TNArchipelTypeHypervisorNetworkCreate}];
        [stanza addTextNode:[networkObject UUID]];

        [self sendStanza:stanza andRegisterSelector:@selector(didNetworkStatusChange:)];
        [_tableViewNetworks deselectAll];
    }
}

- (IBAction)deactivateNetwork:(id)sender
{
    var selectedIndex   = [[_tableViewNetworks selectedRowIndexes] firstIndex];

    if (selectedIndex == -1)
        return

    var networkObject   = [[_datasourceNetworks networks] objectAtIndex:selectedIndex];
    var stanza          = [TNStropheStanza iqWithAttributes:{"type" : TNArchipelTypeHypervisorNetwork}]

    if ([networkObject isNetworkEnabled])
    {
        [stanza addChildName:@"query" withAttributes:{"type": TNArchipelTypeHypervisorNetworkDestroy}];
        [stanza addTextNode:[networkObject UUID]];

        [self sendStanza:stanza andRegisterSelector:@selector(didNetworkStatusChange:)];
        [_tableViewNetworks deselectAll];
    }
}


- (void)didNetworkStatusChange:(TNStropheStanza)aStanza
{
    if ([aStanza getType] == @"success")
    {
        [self getHypervisorNetworks];
        
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Network" message:@"Network status has changed"];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
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
    
    var growl = [TNGrowlCenter defaultCenter];
    [growl pushNotificationWithTitle:@"Network" message:@"Network has been added"];
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

    var deleteStanza    = [TNStropheStanza iqWithAttributes:{"type": TNArchipelTypeHypervisorNetwork}];

    [deleteStanza addChildName:@"query" withAttributes:{"type": TNArchipelTypeHypervisorNetworkUndefine}];
    [deleteStanza addTextNode:[networkObject UUID]];

    [self sendStanza:deleteStanza andRegisterSelector:@selector(didDelNetwork:)];
}

- (void)didDelNetwork:(TNStropheStanza)aStanza
{
    if ([aStanza getType] == @"success")
    {
        [self getHypervisorNetworks];
        
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Network" message:@"Network has been removed"];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}

-(BOOL)windowShouldClose:(id)window
{
    [self defineNetworkXML:nil];

    return YES;
}

- (BOOL)didTableSelectionChange:(CPNotification)aNotification
{
    var selectedIndex   = [[_tableViewNetworks selectedRowIndexes] firstIndex];
    
    if (selectedIndex == -1)
    {
        [buttonActivation setEnabled:NO];
        [buttonDeactivation setEnabled:NO];
        [buttonDelete setEnabled:NO];
        return YES;
    }
           
    [buttonDelete setEnabled:YES];
    
    var networkObject   = [[_datasourceNetworks networks] objectAtIndex:selectedIndex];
    
    if ([networkObject isNetworkEnabled])
    {
        [buttonActivation setEnabled:NO];
        [buttonDeactivation setEnabled:YES];
    }
    else
    {
        [buttonActivation setEnabled:YES];
        [buttonDeactivation setEnabled:NO];
    }
    
    return YES;
}

@end



