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

@import "TNNetworkObject.j"
@import "TNDHCPEntryObject.j"
@import "TNWindowNetworkProperties.j"

TNArchipelPushNotificationNetworks          = @"archipel:push:network";
TNArchipelTypeHypervisorNetwork             = @"archipel:hypervisor:network";
TNArchipelTypeHypervisorNetworkGet          = @"get";
TNArchipelTypeHypervisorNetworkDefine       = @"define";
TNArchipelTypeHypervisorNetworkUndefine     = @"undefine";
TNArchipelTypeHypervisorNetworkCreate       = @"create";
TNArchipelTypeHypervisorNetworkDestroy      = @"destroy";


function generateIPForNewNetwork()
{
    var dA      = Math.round(Math.random() * 255)
    var dB      = Math.round(Math.random() * 255)
    var ipaddress  = dA + "." + dB + ".0.1";

    return ipaddress;
}

@implementation TNHypervisorNetworksController : TNModule
{
    @outlet CPButtonBar                 buttonBarControl;
    @outlet CPScrollView                scrollViewNetworks;
    @outlet CPSearchField               fieldFilterNetworks;
    @outlet CPTextField                 fieldJID;
    @outlet CPTextField                 fieldName;
    @outlet CPView                      viewTableContainer;
    @outlet TNWindowNetworkProperties   windowProperties;
    
    CPButton                            _activateButton;
    CPButton                            _deactivateButton;
    CPButton                            _editButton;
    CPButton                            _minusButton;
    CPButton                            _plusButton;
    CPTableView                         _tableViewNetworks;
    TNTableViewDataSource               _datasourceNetworks;
}

- (void)awakeFromCib
{
    [fieldJID setSelectable:YES];
    
    [viewTableContainer setBorderedWithHexColor:@"#C0C7D2"];
    
    /* VM table view */
    _datasourceNetworks     = [[TNTableViewDataSource alloc] init];
    _tableViewNetworks      = [[CPTableView alloc] initWithFrame:[scrollViewNetworks bounds]];

    [scrollViewNetworks setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [scrollViewNetworks setAutohidesScrollers:YES];
    [scrollViewNetworks setDocumentView:_tableViewNetworks];
    

    [_tableViewNetworks setUsesAlternatingRowBackgroundColors:YES];
    [_tableViewNetworks setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [_tableViewNetworks setAllowsColumnResizing:YES];
    [_tableViewNetworks setAllowsEmptySelection:YES];
    [_tableViewNetworks setAllowsMultipleSelection:YES];
    [_tableViewNetworks setTarget:self];
    [_tableViewNetworks setDelegate:self];
    [_tableViewNetworks setDoubleAction:@selector(editNetwork:)];
    
    var columNetworkEnabled = [[CPTableColumn alloc] initWithIdentifier:@"icon"];
    var imgView = [[CPImageView alloc] initWithFrame:CGRectMake(0,0,16,16)];
    [imgView setImageScaling:CPScaleNone];
    [columNetworkEnabled setDataView:imgView];
    [columNetworkEnabled setWidth:16];
    [[columNetworkEnabled headerView] setStringValue:@""];
    
    var columNetworkName = [[CPTableColumn alloc] initWithIdentifier:@"networkName"];
    [[columNetworkName headerView] setStringValue:@"Name"];
    [columNetworkName setWidth:250];
    [columNetworkName setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"networkName" ascending:YES]];

    var columBridgeName = [[CPTableColumn alloc] initWithIdentifier:@"bridgeName"];
    [[columBridgeName headerView] setStringValue:@"Bridge"];
    [columBridgeName setWidth:80];
    [columBridgeName setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"bridgeName" ascending:YES]];

    var columForwardMode = [[CPTableColumn alloc] initWithIdentifier:@"bridgeForwardMode"];
    [[columForwardMode headerView] setStringValue:@"Forward Mode"];
    [columForwardMode setWidth:120];
    [columForwardMode setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"bridgeForwardMode" ascending:YES]];

    var columForwardDevice = [[CPTableColumn alloc] initWithIdentifier:@"bridgeForwardDevice"];
    [[columForwardDevice headerView] setStringValue:@"Forward Device"];
    [columForwardDevice setWidth:120];
    [columForwardDevice setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"bridgeForwardDevice" ascending:YES]];

    var columBridgeIP = [[CPTableColumn alloc] initWithIdentifier:@"bridgeIP"];
    [[columBridgeIP headerView] setStringValue:@"Bridge IP"];
    [columBridgeIP setWidth:90];
    [columBridgeIP setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"bridgeIP" ascending:YES]];

    var columBridgeNetmask = [[CPTableColumn alloc] initWithIdentifier:@"bridgeNetmask"];
    [[columBridgeNetmask headerView] setStringValue:@"Bridge Netmask"];
    [columBridgeNetmask setWidth:150];
    [columBridgeNetmask setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"bridgeNetmask" ascending:YES]];

    [_tableViewNetworks addTableColumn:columNetworkEnabled];
    [_tableViewNetworks addTableColumn:columNetworkName];
    [_tableViewNetworks addTableColumn:columBridgeName];
    [_tableViewNetworks addTableColumn:columForwardMode];
    [_tableViewNetworks addTableColumn:columForwardDevice];
    [_tableViewNetworks addTableColumn:columBridgeIP];
    [_tableViewNetworks addTableColumn:columBridgeNetmask];

    [_datasourceNetworks setTable:_tableViewNetworks];
    [_datasourceNetworks setSearchableKeyPaths:[@"bridgeNetmask", @"bridgeIP", @"bridgeForwardDevice", @"bridgeForwardMode", @"bridgeName", @"networkName"]];
    
    [fieldFilterNetworks setTarget:_datasourceNetworks];
    [fieldFilterNetworks setAction:@selector(filterObjects:)];
    
    [_tableViewNetworks setDataSource:_datasourceNetworks];
    [_tableViewNetworks setDelegate:self];
    
    [windowProperties setDelegate:self];
        
    var menu = [[CPMenu alloc] init];
    [menu addItemWithTitle:@"Create new virtual network" action:@selector(addNetwork:) keyEquivalent:@""];
    [menu addItem:[CPMenuItem separatorItem]];
    [menu addItemWithTitle:@"Edit" action:@selector(editNetwork:) keyEquivalent:@""];
    [menu addItemWithTitle:@"Activate" action:@selector(activateNetwork:) keyEquivalent:@""];
    [menu addItemWithTitle:@"Deactivate" action:@selector(deactivateNetwork:) keyEquivalent:@""];
    [menu addItem:[CPMenuItem separatorItem]];
    [menu addItemWithTitle:@"Delete" action:@selector(delNetwork:) keyEquivalent:@""];
    [_tableViewNetworks setMenu:menu];
    
    _plusButton = [CPButtonBar plusButton];
    [_plusButton setTarget:self];
    [_plusButton setAction:@selector(addNetwork:)];
    
    _minusButton = [CPButtonBar minusButton];
    [_minusButton setTarget:self];
    [_minusButton setAction:@selector(delNetwork:)];
    
    _activateButton = [CPButtonBar plusButton];
    [_activateButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-check.png"] size:CPSizeMake(16, 16)]];
    [_activateButton setTarget:self];
    [_activateButton setAction:@selector(activateNetwork:)];
    
    _deactivateButton = [CPButtonBar plusButton];
    [_deactivateButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-cancel.png"] size:CPSizeMake(16, 16)]];
    [_deactivateButton setTarget:self];
    [_deactivateButton setAction:@selector(deactivateNetwork:)];
    
    _editButton  = [CPButtonBar plusButton];
    [_editButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-edit.png"] size:CPSizeMake(16, 16)]];
    [_editButton setTarget:self];
    [_editButton setAction:@selector(editNetwork:)];
    
    [_minusButton setEnabled:NO];
    [_activateButton setEnabled:NO];
    [_deactivateButton setEnabled:NO];
    [_editButton setEnabled:NO];
    
    
    [buttonBarControl setButtons:[_plusButton, _minusButton, _editButton, _activateButton, _deactivateButton]];

}

- (void)willLoad
{
    [super willLoad];

    var center = [CPNotificationCenter defaultCenter];
    
    [center addObserver:self selector:@selector(didNickNameUpdated:) name:TNStropheContactNicknameUpdatedNotification object:[self entity]];
    [center addObserver:self selector:@selector(didTableSelectionChange:) name:CPTableViewSelectionDidChangeNotification object:_tableViewNetworks];
    [center postNotificationName:TNArchipelModulesReadyNotification object:self];
    
    [_tableViewNetworks setDelegate:nil];
    [_tableViewNetworks setDelegate:self]; // hum....
    
    [self registerSelector:@selector(didPushReceive:) forPushNotificationType:TNArchipelPushNotificationNetworks];
    [self getHypervisorNetworks];
}

- (void)willShow
{
    [super willShow];

    [fieldName setStringValue:[[self entity] nickname]];
    [fieldJID setStringValue:[[self entity] JID]];
}

- (void)menuReady
{
    [[_menu addItemWithTitle:@"Create new virtual network" action:@selector(addNetwork:) keyEquivalent:@""] setTarget:self];
    [[_menu addItemWithTitle:@"Edit selected network" action:@selector(editNetwork:) keyEquivalent:@""] setTarget:self];
    [[_menu addItemWithTitle:@"Delete selected network" action:@selector(delNetwork:) keyEquivalent:@""] setTarget:self];
    [_menu addItem:[CPMenuItem separatorItem]];
    [[_menu addItemWithTitle:@"Activate this network" action:@selector(activateNetwork:) keyEquivalent:@""] setTarget:self];
    [[_menu addItemWithTitle:@"Deactivate this network" action:@selector(deactivateNetwork:) keyEquivalent:@""] setTarget:self];
}


- (void)didNickNameUpdated:(CPNotification)aNotification
{
    if ([aNotification object] == [self entity])
    {
       [fieldName setStringValue:[[self entity] nickname]]
    }
}

- (BOOL)didPushReceive:(CPDictionary)somePushInfo
{
    var sender  = [somePushInfo objectForKey:@"owner"];
    var type    = [somePushInfo objectForKey:@"type"];
    var change  = [somePushInfo objectForKey:@"change"];
    var date    = [somePushInfo objectForKey:@"date"];
    CPLog.info(@"PUSH NOTIFICATION: from: " + sender + ", type: " + type + ", change: " + change);
    
    [self getHypervisorNetworks];
    return YES;
}


- (void)getHypervisorNetworks
{
    var stanza  = [TNStropheStanza iqWithType:@"get"];
    
    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeHypervisorNetwork}];
    [stanza addChildName:@"archipel" withAttributes:{
        "action": TNArchipelTypeHypervisorNetworkGet}];
    
    [self sendStanza:stanza andRegisterSelector:@selector(didReceiveHypervisorNetworks:)];
}

- (void)didReceiveHypervisorNetworks:(id)aStanza
{
    if ([aStanza type] == @"result")
    {
        var activeNetworks      = [[[aStanza childrenWithName:@"activedNetworks"] objectAtIndex:0] children];
        var unactiveNetworks    = [[[aStanza childrenWithName:@"unactivedNetworks"] objectAtIndex:0] children];
        var allNetworks         = [CPArray array];

        [allNetworks addObjectsFromArray:activeNetworks];
        [allNetworks addObjectsFromArray:unactiveNetworks];

        [_datasourceNetworks removeAllObjects];

        for (var i = 0; i < [allNetworks count]; i++)
        {
            var network             = [allNetworks objectAtIndex:i];
            var name                = [[network firstChildWithName:@"name"] text];
            var uuid                = [[network firstChildWithName:@"uuid"] text];
            var bridge              = [network firstChildWithName:@"bridge"];
            var bridgeName          = [bridge valueForAttribute:@"name"];
            var bridgeSTP           = ([bridge valueForAttribute:@"stp"] == @"on") ? YES : NO;
            var bridgeDelay         = [bridge valueForAttribute:@"forwardDelay"];
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
                                             bridgeDelay:bridgeDelay
                                       bridgeForwardMode:forwardMode
                                     bridgeForwardDevice:forwardDev
                                                bridgeIP:bridgeIP
                                           bridgeNetmask:bridgeNetmask
                                       DHCPEntriesRanges:DHCPRangeEntriesArray
                                        DHCPEntriesHosts:DHCPHostEntriesArray
                                          networkEnabled:networkActive
                                              STPEnabled:bridgeSTP
                                             DHCPEnabled:DHCPEnabled]

            [_datasourceNetworks addObject:newNetwork];
        }

        [_tableViewNetworks reloadData];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}

- (TNStropheStanza)generateXMLNetworkStanzaWithUniqueID:(id)anUid
{
    var selectedIndex   = [[_tableViewNetworks selectedRowIndexes] firstIndex];

    if (selectedIndex == -1)
        return

    var networkObject   = [_datasourceNetworks objectAtIndex:selectedIndex];
    var stanza          = [TNStropheStanza iqWithAttributes:{"type": "set", "id": anUid}];
    
    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeHypervisorNetwork}];
    [stanza addChildName:@"archipel" withAttributes:{
        "action": TNArchipelTypeHypervisorNetworkDefine}];

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
        var networkObject = [_datasourceNetworks objectAtIndex:selectedIndex];

        if ([networkObject isNetworkEnabled])
        {
            [CPAlert alertWithTitle:@"Error" message:@"You can't edit a running network" style:CPCriticalAlertStyle];
            return
        }

        [windowProperties setNetwork:networkObject];
        [windowProperties setTableNetwork:_tableViewNetworks];
        
        [windowProperties center];
        [windowProperties makeKeyAndOrderFront:nil];
    }
}

- (IBAction)defineNetworkXML:(id)sender
{
    var selectedIndex   = [[_tableViewNetworks selectedRowIndexes] firstIndex];

    if (selectedIndex == -1)
        return

    var networkObject   = [_datasourceNetworks objectAtIndex:selectedIndex];

    if ([networkObject isNetworkEnabled])
    {
        [CPAlert alertWithTitle:@"Error" message:@"You can't update a running network" style:CPCriticalAlertStyle];
        return
    }

    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeHypervisorNetwork}];
    [stanza addChildName:@"archipel" withAttributes:{
        "action": TNArchipelTypeHypervisorNetworkUndefine, 
        "uuid": [networkObject UUID]}];

    [self sendStanza:stanza andRegisterSelector:@selector(didNetworkUndefinedBeforeDefining:)];
}

- (void)didNetworkUndefinedBeforeDefining:(TNStropheStanza)aStanza
{
    var uid             = [_connection getUniqueId];
    var defineStanza    = [self generateXMLNetworkStanzaWithUniqueID:uid];

    [self sendStanza:defineStanza andRegisterSelector:@selector(didDefineNetwork:) withSpecificID:uid];
}

- (void)didDefineNetwork:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
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
    var selectedIndexes = [_tableViewNetworks selectedRowIndexes];
    var objects         = [_datasourceNetworks objectsAtIndexes:selectedIndexes];
    
    for (var i = 0; i < [objects count]; i++)
    {
        var networkObject   = [objects objectAtIndex:i];
        var stanza          = [TNStropheStanza iqWithType:@"set"];

        if (![networkObject isNetworkEnabled])
        {
            [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeHypervisorNetwork}];
            [stanza addChildName:@"archipel" withAttributes:{
                "xmlns": TNArchipelTypeHypervisorNetwork, 
                "action": TNArchipelTypeHypervisorNetworkCreate, 
                "uuid": [networkObject UUID]}];
            
            [self sendStanza:stanza andRegisterSelector:@selector(didNetworkStatusChange:)];
            [_tableViewNetworks deselectAll];
        }
    }
}


- (IBAction)deactivateNetwork:(id)sender
{
    var alert = [TNAlert alertWithTitle:@"Deactivate Network"
                                message:@"Are you sure you want to deactivate this network ? Virtual machines that are in this network will loose connectivity."
                                delegate:self
                                 actions:[["Deactivate", @selector(performDeactivateNetwork:)], ["Cancel", nil]]];

    [alert runModal];
}

- (void)performDeactivateNetwork:(id)someUserInfo
{
    var selectedIndexes = [_tableViewNetworks selectedRowIndexes];
    var objects         = [_datasourceNetworks objectsAtIndexes:selectedIndexes];
    
    for (var i = 0; i < [objects count]; i++)
    {
        var networkObject   = [objects objectAtIndex:i];
        var stanza          = [TNStropheStanza iqWithType:@"set"];

        if ([networkObject isNetworkEnabled])
        {
            [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeHypervisorNetwork}];
            [stanza addChildName:@"archipel" withAttributes:{
                "xmlns": TNArchipelTypeHypervisorNetwork, 
                "action": TNArchipelTypeHypervisorNetworkDestroy,
                "uuid" : [networkObject UUID]}];

            [self sendStanza:stanza andRegisterSelector:@selector(didNetworkStatusChange:)];
            [_tableViewNetworks deselectAll];
        }
    }
}



- (IBAction)addNetwork:(id)sender
{
    var uuid            = [CPString UUID];
    var ip              = generateIPForNewNetwork();
    var ipStart         = ip.split(".")[0] + "." + ip.split(".")[1] + ".0.2";
    var ipEnd           = ip.split(".")[0] + "." + ip.split(".")[1] + ".0.254";
    
    var baseDHCPEntry   = [TNDHCPEntry DHCPRangeWithStartAddress:ipStart  endAddress:ipEnd];
    
    var newNetwork = [TNNetwork networkWithName:uuid
                                            UUID:uuid
                                      bridgeName:@"br" + Math.round((Math.random() * 42000))
                                     bridgeDelay:@"0"
                               bridgeForwardMode:@"nat"
                             bridgeForwardDevice:@"eth0"
                                        bridgeIP:ip
                                   bridgeNetmask:@"255.255.0.0"
                               DHCPEntriesRanges:[baseDHCPEntry]
                                DHCPEntriesHosts:[CPArray array]
                                  networkEnabled:NO
                                      STPEnabled:NO
                                     DHCPEnabled:YES];

    [_datasourceNetworks addObject:newNetwork];
    [_tableViewNetworks reloadData];
    
    var index = [_datasourceNetworks indexOfObject:newNetwork];
    [_tableViewNetworks selectRowIndexes:[CPIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
    
    [self defineNetworkXML:sender];
    [self editNetwork:nil];
}



- (IBAction)delNetwork:(id)sender
{
    var alert = [TNAlert alertWithTitle:@"Delete Network"
                                message:@"Are you sure you want to destroy this network ? Virtual machines that are in this network will loose connectivity."
                                delegate:self
                                 actions:[["Delete", @selector(performDelNetwork:)], ["Cancel", nil]]];

    [alert runModal];
}

- (void)performDelNetwork:(id)someUserInfo
{
    var selectedIndexes = [_tableViewNetworks selectedRowIndexes];
    var objects         = [_datasourceNetworks objectsAtIndexes:selectedIndexes];

    for (var i = 0; i < [objects count]; i++)
    {
        var networkObject   = [objects objectAtIndex:i];
        if ([networkObject isNetworkEnabled])
        {
            [CPAlert alertWithTitle:@"Error" message:@"You can't update a running network" style:CPCriticalAlertStyle];
            return
        }

        var stanza    = [TNStropheStanza iqWithType:@"get"];
        
        [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeHypervisorNetwork}];
        [stanza addChildName:@"archipel" withAttributes:{
            "xmlns": TNArchipelTypeHypervisorNetwork, 
            "action": TNArchipelTypeHypervisorNetworkUndefine,
            "uuid": [networkObject UUID]}];
        
        [self sendStanza:stanza andRegisterSelector:@selector(didDelNetwork:)];
    }
}

- (void)didDelNetwork:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Network" message:@"Network has been removed"];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}


- (void)didNetworkStatusChange:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Network" message:@"Network status has changed"];
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

- (void)didTableSelectionChange:(CPNotification)aNotification
{
    var selectedIndex   = [[_tableViewNetworks selectedRowIndexes] firstIndex];
    
    [_minusButton setEnabled:NO];
    [_editButton setEnabled:NO];
    [_activateButton setEnabled:NO];
    [_deactivateButton setEnabled:NO];
    
    if ([_tableViewNetworks numberOfSelectedRows] == 0)
        return;
        
    var networkObject   = [_datasourceNetworks objectAtIndex:selectedIndex];
    
    if ([networkObject isNetworkEnabled])
    {
        [_deactivateButton setEnabled:YES];
    }
    else
    {
        [_minusButton setEnabled:YES];
        [_editButton setEnabled:YES];
        [_activateButton setEnabled:YES];
    }
    
    return YES;
}

@end



