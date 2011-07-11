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

@import <AppKit/CPButton.j>
@import <AppKit/CPButtonBar.j>
@import <AppKit/CPCollectionView.j>
@import <AppKit/CPSearchField.j>
@import <AppKit/CPTableView.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPView.j>

@import <TNKit/TNAlert.j>
@import <TNKit/TNTableViewDataSource.j>
@import <TNKit/TNUIKitScrollView.j>

@import "TNDHCPEntryObject.j"
@import "TNHypervisorNetworkObject.j"
@import "TNNetworkEditionController.j"
@import "TNNetworkDataView.j";


var TNArchipelPushNotificationNetworks          = @"archipel:push:network",
    TNArchipelTypeHypervisorNetwork             = @"archipel:hypervisor:network",
    TNArchipelTypeHypervisorNetworkGet          = @"get",
    TNArchipelTypeHypervisorNetworkDefine       = @"define",
    TNArchipelTypeHypervisorNetworkUndefine     = @"undefine",
    TNArchipelTypeHypervisorNetworkCreate       = @"create",
    TNArchipelTypeHypervisorNetworkDestroy      = @"destroy",
    TNArchipelTypeHypervisorNetworkGetNics      = @"getnics";


/*! @defgroup  hypervisornetworks Module Hypervisor Networks
    @desc This manages hypervisors' virtual networks
*/

/*! @ingroup hypervisornetworks
    The main module controller
*/
@implementation TNHypervisorNetworksController : TNModule
{
    @outlet CPButtonBar                 buttonBarControl;
    @outlet CPSearchField               fieldFilterNetworks;
    @outlet CPTableView                 tableViewNetworks;
    @outlet CPView                      viewTableContainer;
    @outlet TNNetworkDataView           networkDataViewPrototype;
    @outlet TNNetworkEditionController  networkController;

    CPButton                            _activateButton;
    CPButton                            _deactivateButton;
    CPButton                            _editButton;
    CPButton                            _minusButton;
    CPButton                            _plusButton;
    TNHypervisorNetwork                 _networkHolder;
    TNTableViewDataSource               _datasourceNetworks;

}

#pragma mark -
#pragma mark Initialization

/*! called at cib awaking
*/
- (void)awakeFromCib
{
    [viewTableContainer setBorderedWithHexColor:@"#C0C7D2"];

    /* VM table view */
    _datasourceNetworks     = [[TNTableViewDataSource alloc] init];
    var prototype = [CPKeyedArchiver archivedDataWithRootObject:networkDataViewPrototype];
    [[tableViewNetworks tableColumnWithIdentifier:@"self"] setDataView:[CPKeyedUnarchiver unarchiveObjectWithData:prototype]];
    [tableViewNetworks setTarget:self];
    [tableViewNetworks setDoubleAction:@selector(editNetwork:)];
    [_datasourceNetworks setTable:tableViewNetworks];
    [tableViewNetworks setDataSource:_datasourceNetworks];
    [tableViewNetworks setDelegate:self];

    [networkController setDelegate:self];

    var menu = [[CPMenu alloc] init];
    [menu addItemWithTitle:CPBundleLocalizedString(@"Create new virtual network", @"Create new virtual network") action:@selector(addNetwork:) keyEquivalent:@""];
    [menu addItem:[CPMenuItem separatorItem]];
    [menu addItemWithTitle:CPBundleLocalizedString(@"Edit", @"Edit") action:@selector(editNetwork:) keyEquivalent:@""];
    [menu addItemWithTitle:CPBundleLocalizedString(@"Activate", @"Activate") action:@selector(activateNetwork:) keyEquivalent:@""];
    [menu addItemWithTitle:CPBundleLocalizedString(@"Deactivate", @"Deactivate") action:@selector(deactivateNetwork:) keyEquivalent:@""];
    [menu addItem:[CPMenuItem separatorItem]];
    [menu addItemWithTitle:CPBundleLocalizedString(@"Delete", @"Delete") action:@selector(delNetwork:) keyEquivalent:@""];
    [tableViewNetworks setMenu:menu];

    _plusButton = [CPButtonBar plusButton];
    [_plusButton setTarget:self];
    [_plusButton setAction:@selector(addNetwork:)];
    [_plusButton setToolTip:CPBundleLocalizedString(@"Create a new network", @"Create a new network")];

    _minusButton = [CPButtonBar minusButton];
    [_minusButton setTarget:self];
    [_minusButton setAction:@selector(delNetwork:)];
    [_minusButton setToolTip:CPBundleLocalizedString(@"Delete selected networks", @"Delete selected networks")];

    _activateButton = [CPButtonBar plusButton];
    [_activateButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/check.png"] size:CPSizeMake(16, 16)]];
    [_activateButton setTarget:self];
    [_activateButton setAction:@selector(activateNetwork:)];
    [_activateButton setToolTip:CPBundleLocalizedString(@"Activate selected networks", @"Activate selected networks")];

    _deactivateButton = [CPButtonBar plusButton];
    [_deactivateButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/cancel.png"] size:CPSizeMake(16, 16)]];
    [_deactivateButton setTarget:self];
    [_deactivateButton setAction:@selector(deactivateNetwork:)];
    [_deactivateButton setToolTip:CPBundleLocalizedString(@"Deactivate selected networks", @"Deactivate selected networks")];

    _editButton  = [CPButtonBar plusButton];
    [_editButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/edit.png"] size:CPSizeMake(16, 16)]];
    [_editButton setTarget:self];
    [_editButton setAction:@selector(editNetwork:)];
    [_editButton setToolTip:CPBundleLocalizedString(@"Open configuration panel for selected network", @"Open configuration panel for selected network")];

    [_minusButton setEnabled:NO];
    [_activateButton setEnabled:NO];
    [_deactivateButton setEnabled:NO];
    [_editButton setEnabled:NO];

    [buttonBarControl setButtons:[_plusButton, _minusButton, _editButton, _activateButton, _deactivateButton]];
}


#pragma mark -
#pragma mark TNModule overrides

/*! called when module is loaded
*/
- (void)willLoad
{
    [super willLoad];

    var center = [CPNotificationCenter defaultCenter];

    [center addObserver:self selector:@selector(_didTableSelectionChange:) name:CPTableViewSelectionDidChangeNotification object:tableViewNetworks];
    [center postNotificationName:TNArchipelModulesReadyNotification object:self];

    [tableViewNetworks setDelegate:nil];
    [tableViewNetworks setDelegate:self];

    [self registerSelector:@selector(_didReceivePush:) forPushNotificationType:TNArchipelPushNotificationNetworks];
    [self getHypervisorNetworks];
    [self getHypervisorNICS];
}

/*! called when the module hides
*/
- (void)willHide
{
    [networkController closeWindow:nil];

    [super willHide];
}

/*! called when MainMenu is ready
*/
- (void)menuReady
{
    [[_menu addItemWithTitle:CPBundleLocalizedString(@"Create new virtual network", @"Create new virtual network") action:@selector(addNetwork:) keyEquivalent:@""] setTarget:self];
    [[_menu addItemWithTitle:CPBundleLocalizedString(@"Edit selected network", @"Edit selected network") action:@selector(editNetwork:) keyEquivalent:@""] setTarget:self];
    [[_menu addItemWithTitle:CPBundleLocalizedString(@"Delete selected network", @"Delete selected network") action:@selector(delNetwork:) keyEquivalent:@""] setTarget:self];
    [_menu addItem:[CPMenuItem separatorItem]];
    [[_menu addItemWithTitle:CPBundleLocalizedString(@"Activate this network", @"Activate this network") action:@selector(activateNetwork:) keyEquivalent:@""] setTarget:self];
    [[_menu addItemWithTitle:CPBundleLocalizedString(@"Deactivate this network", @"Deactivate this network") action:@selector(deactivateNetwork:) keyEquivalent:@""] setTarget:self];
}

/*! called when permissions changes
*/
- (void)permissionsChanged
{
    [self setControl:_plusButton enabledAccordingToPermission:@"network_define"];
    [self setControl:_minusButton enabledAccordingToPermission:@"network_undefine"];
    [self setControl:_editButton enabledAccordingToPermission:@"network_define"];
    [self setControl:_activateButton enabledAccordingToPermission:@"network_create"];
    [self setControl:_deactivateButton enabledAccordingToPermission:@"network_destroy"];

    [self _didTableSelectionChange:nil];
}


#pragma mark -
#pragma mark Notification handlers

/*! called when an Archipel push is recieved
    @param somePushInfo CPDictionary containing push information
*/
- (BOOL)_didReceivePush:(CPDictionary)somePushInfo
{
    var sender  = [somePushInfo objectForKey:@"owner"],
        type    = [somePushInfo objectForKey:@"type"],
        change  = [somePushInfo objectForKey:@"change"],
        date    = [somePushInfo objectForKey:@"date"];

    CPLog.info(@"PUSH NOTIFICATION: from: " + sender + ", type: " + type + ", change: " + change);

    [self getHypervisorNetworks];
    return YES;
}

/*! triggered when the main table selection changes. it will update GUI
*/
- (void)_didTableSelectionChange:(CPNotification)aNotification
{
    var selectedIndex   = [[tableViewNetworks selectedRowIndexes] firstIndex];

    [_minusButton setEnabled:NO];
    [_editButton setEnabled:NO];
    [_activateButton setEnabled:NO];
    [_deactivateButton setEnabled:NO];

    if ([tableViewNetworks numberOfSelectedRows] == 0)
        return;

    var networkObject   = [_datasourceNetworks objectAtIndex:selectedIndex];

    if ([networkObject isNetworkEnabled])
    {
        [self setControl:_deactivateButton enabledAccordingToPermission:@"network_destroy"];
    }
    else
    {
        [self setControl:_minusButton enabledAccordingToPermission:@"network_undefine"];
        [self setControl:_editButton enabledAccordingToPermission:@"network_define"];
        [self setControl:_activateButton enabledAccordingToPermission:@"network_create"];
    }

    return YES;
}


#pragma mark -
#pragma mark Utilities

/*! Generate a stanza containing libvirt valid network description
    @param anUid the ID to use for the stanza
    @return ready to send generate stanza
*/
- (TNStropheStanza)generateXMLNetworkStanzaWithUniqueID:(id)anUid network:(TNHypervisorNetwork)aNetwork
{
    var stanza = [TNStropheStanza iqWithAttributes:{"type": "set", "id": anUid}];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorNetwork}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorNetworkDefine,
        "autostart": [aNetwork isAutostart] ? @"1" : @"0"}];

    [stanza addChildWithName:@"network"];

    [stanza addChildWithName:@"name"];
    [stanza addTextNode:[aNetwork networkName]];
    [stanza up];

    [stanza addChildWithName:@"uuid"];
    [stanza addTextNode:[aNetwork UUID]];
    [stanza up];

    if ([aNetwork bridgeForwardMode])
    {
        [stanza addChildWithName:@"forward" andAttributes:{"mode": [aNetwork bridgeForwardMode], "dev": [aNetwork bridgeForwardDevice]}];
        [stanza up];
    }

    [stanza addChildWithName:@"bridge" andAttributes:{"name": [aNetwork bridgeName], "stp": ([aNetwork isSTPEnabled]) ? "on" :"off", "delay": [aNetwork bridgeDelay]}];
    [stanza up];

    if ([aNetwork bridgeIP] != @"" && [aNetwork bridgeNetmask] != @"")
        [stanza addChildWithName:@"ip" andAttributes:{"address": [aNetwork bridgeIP], "netmask": [aNetwork bridgeNetmask]}];

    var dhcp = [aNetwork isDHCPEnabled];
    if (dhcp)
    {
        [stanza addChildWithName:@"dhcp"];

        var DHCPRangeEntries = [aNetwork DHCPEntriesRanges];

        for (var i = 0; i < [DHCPRangeEntries count]; i++)
        {
            var DHCPEntry = [DHCPRangeEntries objectAtIndex:i];

            [stanza addChildWithName:@"range" andAttributes:{"start" : [DHCPEntry start], "end": [DHCPEntry end]}];
            [stanza up];
        }

        var DHCPHostsEntries = [aNetwork DHCPEntriesHosts];

        for (var i = 0; i < [DHCPHostsEntries count]; i++)
        {
            var DHCPEntry = [DHCPHostsEntries objectAtIndex:i];

            [stanza addChildWithName:@"host" andAttributes:{"mac" : [DHCPEntry mac], "name": [DHCPEntry name], "ip": [DHCPEntry IP]}];
            [stanza up];
        }

        [stanza up];
    }

    [stanza up];

    return stanza;
}

/*! generate a random MAC Address
    @return CPString containing a random mac address
*/
- (CPString)generateIPForNewNetwork
{
    var dA      = Math.round(Math.random() * 255),
        dB      = Math.round(Math.random() * 255);

    return dA + "." + dB + ".0.1";
}


#pragma mark -
#pragma mark Action

/*! add a network
    @param sender the sender of the action
*/
- (IBAction)addNetwork:(id)aSender
{
    var uuid            = [CPString UUID],
        ip              = [self generateIPForNewNetwork],
        ipStart         = ip.split(".")[0] + "." + ip.split(".")[1] + ".0.2",
        ipEnd           = ip.split(".")[0] + "." + ip.split(".")[1] + ".0.254",
        baseDHCPEntry   = [TNDHCPEntry DHCPRangeWithStartAddress:ipStart  endAddress:ipEnd],
        newNetwork      = [TNHypervisorNetwork networkWithName:uuid
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
                                                   DHCPEnabled:YES
                                                     autostart:YES];

    [networkController setNetwork:newNetwork];
    [networkController openWindow:aSender];
}

/*! delete a network
    @param sender the sender of the action
*/
- (IBAction)delNetwork:(id)aSender
{
    var selectedIndexes = [tableViewNetworks selectedRowIndexes],
        networks = [_datasourceNetworks objectsAtIndexes:selectedIndexes],
        alert = [TNAlert alertWithMessage:CPBundleLocalizedString(@"Delete Network", @"Delete Network")
                              informative:CPBundleLocalizedString(@"Are you sure you want to destroy this network ? Virtual machines that are in this network will loose connectivity.", @"Are you sure you want to destroy this network ? Virtual machines that are in this network will loose connectivity.")
                                   target:self
                                  actions:[[CPBundleLocalizedString("Delete", "Delete"), @selector(_performDelNetwork:)], [CPBundleLocalizedString("Cancel", "Cancel"), nil]]];
    [alert setUserInfo:networks];
    [alert runModal];
}

/*! @ignore
*/
- (void)_performDelNetwork:(id)someUserInfo
{
    [self deleteNetworks:someUserInfo];
}

/*! open network edition panel
    @param sender the sender of the action
*/
- (IBAction)editNetwork:(id)aSender
{
    if (![self currentEntityHasPermission:@"network_define"])
        return;

    var selectedIndex   = [[tableViewNetworks selectedRowIndexes] firstIndex];

    if (selectedIndex != -1)
    {
        var networkObject = [_datasourceNetworks objectAtIndex:selectedIndex];

        if ([networkObject isNetworkEnabled])
        {
            [TNAlert showAlertWithMessage:CPBundleLocalizedString(@"Error", @"Error") informative:CPBundleLocalizedString(@"You can't edit a running network", @"You can't edit a running network")];
            return;
        }

        [networkController setNetwork:networkObject];
        [networkController openWindow:aSender];
    }
}

/*! define a network
    @param sender the sender of the action
*/
- (IBAction)defineNetworkXML:(id)aSender
{
    var selectedIndex = [[tableViewNetworks selectedRowIndexes] firstIndex];

    if (selectedIndex == -1)
        return

    var networkObject = [_datasourceNetworks objectAtIndex:selectedIndex];

    [self defineNetwork:networkObject];
}

/*! activate a network
    @param sender the sender of the action
*/
- (IBAction)activateNetwork:(id)aSender
{
    var selectedIndexes = [tableViewNetworks selectedRowIndexes],
        networks = [_datasourceNetworks objectsAtIndexes:selectedIndexes];

    [self activateNetworks:networks];
}

/*! deactivate a network
    @param sender the sender of the action
*/
- (IBAction)deactivateNetwork:(id)aSender
{
    var selectedIndexes = [tableViewNetworks selectedRowIndexes],
        networks = [_datasourceNetworks objectsAtIndexes:selectedIndexes],
        alert = [TNAlert alertWithMessage:CPBundleLocalizedString(@"Deactivate Network", @"Deactivate Network")
                              informative:CPBundleLocalizedString(@"Are you sure you want to deactivate this network ? Virtual machines that are in this network will loose connectivity.", @"Are you sure you want to deactivate this network ? Virtual machines that are in this network will loose connectivity.")
                                   target:self
                                  actions:[[CPBundleLocalizedString(@"Deactivate", @"Deactivate"), @selector(_performDeactivateNetwork:)], [CPBundleLocalizedString(@"Cancel", @"Cancel"), nil]]];
    [alert setUserInfo:networks];
    [alert runModal];
}

/*! @ignore
*/
- (void)_performDeactivateNetwork:(id)someUserInfo
{
    [self deactivateNetworks:someUserInfo];
}


#pragma mark -
#pragma mark XMPP Controls

/*! asks networks to the hypervisor
*/
- (void)getHypervisorNetworks
{
    var stanza  = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorNetwork}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorNetworkGet}];

    [self setModuleStatus:TNArchipelModuleStatusWaiting];
    [self sendStanza:stanza andRegisterSelector:@selector(_didReceiveHypervisorNetworks:)];
}

/*! compute the answer containing the network information
*/
- (void)_didReceiveHypervisorNetworks:(id)aStanza
{
    if ([aStanza type] == @"result")
    {
        var activeNetworks      = [[aStanza firstChildWithName:@"activedNetworks"] children],
            unactiveNetworks    = [[aStanza firstChildWithName:@"unactivedNetworks"] children],
            allNetworks         = [CPArray array];

        [allNetworks addObjectsFromArray:activeNetworks];
        [allNetworks addObjectsFromArray:unactiveNetworks];

        [_datasourceNetworks removeAllObjects];

        for (var i = 0; i < [allNetworks count]; i++)
        {
            var network                 = [allNetworks objectAtIndex:i],
                autostart               = ([network valueForAttribute:@"autostart"] == @"1") ? YES : NO,
                name                    = [[network firstChildWithName:@"name"] text],
                uuid                    = [[network firstChildWithName:@"uuid"] text],
                bridge                  = [network firstChildWithName:@"bridge"],
                bridgeName              = [bridge valueForAttribute:@"name"],
                bridgeSTP               = ([bridge valueForAttribute:@"stp"] == @"on") ? YES : NO,
                bridgeDelay             = [bridge valueForAttribute:@"forwardDelay"],
                forward                 = [network firstChildWithName:@"forward"],
                forwardMode             = [forward valueForAttribute:@"mode"],
                forwardDev              = [forward valueForAttribute:@"dev"],
                ip                      = [network firstChildWithName:@"ip"],
                bridgeIP                = [ip valueForAttribute:@"address"],
                bridgeNetmask           = [ip valueForAttribute:@"netmask"],
                dhcp                    = [ip firstChildWithName:@"dhcp"],
                DHCPEnabled             = (dhcp) ? YES : NO,
                DHCPRangeEntries        = [dhcp childrenWithName:@"range"],
                DHCPHostEntries         = [dhcp childrenWithName:@"host"],
                networkActive           = [activeNetworks containsObject:network],
                DHCPRangeEntriesArray   = [CPArray array],
                DHCPHostEntriesArray    = [CPArray array];

            for (var j = 0; DHCPEnabled && j < [DHCPRangeEntries count]; j++)
            {
                var DHCPEntry           = [DHCPRangeEntries objectAtIndex:j],
                    randgeStartAddr     = [DHCPEntry valueForAttribute:@"start"],
                    rangeEndAddr        = [DHCPEntry valueForAttribute:@"end"],
                    DHCPEntryObject     = [TNDHCPEntry DHCPRangeWithStartAddress:randgeStartAddr endAddress:rangeEndAddr];

                [DHCPRangeEntriesArray addObject:DHCPEntryObject];
            }

            for (var j = 0; DHCPEnabled && j < [DHCPHostEntries count]; j++)
            {
                var DHCPEntry       = [DHCPHostEntries objectAtIndex:j],
                    hostsMac        = [DHCPEntry valueForAttribute:@"mac"],
                    hostName        = [DHCPEntry valueForAttribute:@"name"],
                    hostIP          = [DHCPEntry valueForAttribute:@"ip"],
                    DHCPEntryObject = [TNDHCPEntry DHCPHostWithMac:hostsMac name:hostName ip:hostIP];

                [DHCPHostEntriesArray addObject:DHCPEntryObject];
            }

            var newNetwork  = [TNHypervisorNetwork networkWithName:name
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
                                             DHCPEnabled:DHCPEnabled
                                               autostart:autostart];

            [_datasourceNetworks addObject:newNetwork];
        }

        [tableViewNetworks reloadData];
        [self setModuleStatus:TNArchipelModuleStatusReady];
    }
    else
    {
        [self setModuleStatus:TNArchipelModuleStatusError];
        [self handleIqErrorFromStanza:aStanza];
    }
}

/*! get existing nics on the hypervisor
*/
- (void)getHypervisorNICS
{
    var stanza  = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorNetwork}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorNetworkGetNics}];

    [self setModuleStatus:TNArchipelModuleStatusWaiting];
    [self sendStanza:stanza andRegisterSelector:@selector(_didReceiveHypervisorNics:)];
}

/*! compute the answer containing the nics information
*/
- (void)_didReceiveHypervisorNics:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        var nics    = [aStanza childrenWithName:@"nic"],
            names   = [CPArray array];

        for (var i = 0; i < [nics count]; i++)
        {
            var nic = [nics objectAtIndex:i],
                name = [nic valueForAttribute:@"name"];

            if (name.indexOf("vnet") == -1)
                [names addObject:name];
        }
        [networkController setCurrentNetworkInterfaces:names];
        [self setModuleStatus:TNArchipelModuleStatusReady];
    }
    else
    {
        [self setModuleStatus:TNArchipelModuleStatusError];
        [self handleIqErrorFromStanza:aStanza];
    }
}


/*! define the given network
    @param aNetwork the network to define
*/
- (void)defineNetwork:(TNHypervisorNetwork)aNetwork
{
    if ([aNetwork isNetworkEnabled])
    {
        [CPAlert alertWithTitle:CPBundleLocalizedString(@"Error", @"Error") message:CPBundleLocalizedString(@"You can't update a running network", @"You can't update a running network") style:CPCriticalAlertStyle];
        return
    }

    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorNetwork}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorNetworkUndefine,
        "uuid": [aNetwork UUID]}];

    _networkHolder = aNetwork;
    [self sendStanza:stanza andRegisterSelector:@selector(_didNetworkUndefinBeforeDefining:)];

}

/*! if hypervisor sucessfullty deactivate the network. it will then define it
    @param aStanza TNStropheStanza containing the answer
    @return NO to unregister selector
*/
- (BOOL)_didNetworkUndefinBeforeDefining:(TNStropheStanza)aStanza
{
    var uid             = [[[TNStropheIMClient defaultClient] connection] getUniqueId],
        defineStanza    = [self generateXMLNetworkStanzaWithUniqueID:uid network:_networkHolder];

    _networkHolder = nil;

    [self sendStanza:defineStanza andRegisterSelector:@selector(_didDefineNetwork:) withSpecificID:uid];

    return NO;
}

/*! compute if hypervisor has defined the network
    @param aStanza TNStropheStanza containing the answer
    @return NO to unregister selector
*/
- (BOOL)_didDefineNetwork:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:CPBundleLocalizedString(@"Network", @"Network") message:CPBundleLocalizedString(@"Network has been defined", @"Network has been defined")];
    else
        [self handleIqErrorFromStanza:aStanza];

    return NO;
}

/*! activate given networks
    @param someNetworks CPArray of TNHypervisorNetwork
*/
- (void)activateNetworks:(CPArray)someNetworks
{
    for (var i = 0; i < [someNetworks count]; i++)
    {
        var networkObject   = [someNetworks objectAtIndex:i],
            stanza          = [TNStropheStanza iqWithType:@"set"];

        if (![networkObject isNetworkEnabled])
        {
            [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorNetwork}];
            [stanza addChildWithName:@"archipel" andAttributes:{
                "xmlns": TNArchipelTypeHypervisorNetwork,
                "action": TNArchipelTypeHypervisorNetworkCreate,
                "uuid": [networkObject UUID]}];

            [self sendStanza:stanza andRegisterSelector:@selector(_didNetworkStatusChange:)];
            [tableViewNetworks deselectAll];
        }
    }
}

/*! deactivate given networks
    @param someNetworks CPArray of TNHypervisorNetwork
*/
- (void)deactivateNetworks:(CPArray)someNetworks
{
    for (var i = 0; i < [someNetworks count]; i++)
    {
        var networkObject   = [someNetworks objectAtIndex:i],
            stanza          = [TNStropheStanza iqWithType:@"set"];

        if ([networkObject isNetworkEnabled])
        {
            [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorNetwork}];
            [stanza addChildWithName:@"archipel" andAttributes:{
                "xmlns": TNArchipelTypeHypervisorNetwork,
                "action": TNArchipelTypeHypervisorNetworkDestroy,
                "uuid" : [networkObject UUID]}];

            [self sendStanza:stanza andRegisterSelector:@selector(_didNetworkStatusChange:)];
            [tableViewNetworks deselectAll];
        }
    }
}

/*! compute the answer of hypervisor after activating or deactivating a network
    @param aStanza TNStropheStanza containing the answer
    @return NO to unregister selector
*/
- (BOOL)_didNetworkStatusChange:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:CPBundleLocalizedString(@"Network", @"Network") message:CPBundleLocalizedString(@"Network status has changed", @"Network status has changed")];
    else
        [self handleIqErrorFromStanza:aStanza];

    return NO;
}

/*! delete given networks
    @param someNetworks CPArray of TNHypervisorNetwork
*/
- (void)deleteNetworks:(CPArray)someNetworks
{
    for (var i = 0; i < [someNetworks count]; i++)
    {
        var networkObject   = [someNetworks objectAtIndex:i];

        if ([networkObject isNetworkEnabled])
        {
            [CPAlert alertWithTitle:CPBundleLocalizedString(@"Error", @"Error") message:CPBundleLocalizedString(@"You can't update a running network", @"You can't update a running network") style:CPCriticalAlertStyle];
            return;
        }

        var stanza = [TNStropheStanza iqWithType:@"get"];

        [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorNetwork}];
        [stanza addChildWithName:@"archipel" andAttributes:{
            "xmlns": TNArchipelTypeHypervisorNetwork,
            "action": TNArchipelTypeHypervisorNetworkUndefine,
            "uuid": [networkObject UUID]}];

        [self sendStanza:stanza andRegisterSelector:@selector(_didDelNetwork:)];
    }
}

/*! compute if hypervisor has undefined the network
    @param aStanza TNStropheStanza containing the answer
    @return NO to unregister selector
*/
- (BOOL)_didDelNetwork:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:CPBundleLocalizedString(@"Network", @"Network") message:CPBundleLocalizedString(@"Network has been removed", @"Network has been removed")];
    else
        [self handleIqErrorFromStanza:aStanza];

    return NO;
}


@end

// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNHypervisorNetworksController], comment);
}
