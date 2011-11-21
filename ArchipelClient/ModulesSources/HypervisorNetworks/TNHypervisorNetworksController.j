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

@import <LPKit/LPMultiLineTextField.j>
@import <TNKit/TNAlert.j>
@import <TNKit/TNTableViewDataSource.j>

@import "TNNetworkEditionController.j"
@import "TNNetworkDataView.j"

@import "Model/TNLibvirtNet.j"

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
    @outlet CPButton                    buttonDefineXMLString;
    @outlet CPButtonBar                 buttonBarControl;
    @outlet CPSearchField               fieldFilterNetworks;
    @outlet CPTableView                 tableViewNetworks;
    @outlet CPView                      viewTableContainer;
    @outlet LPMultiLineTextField        fieldXMLString;
    @outlet TNNetworkDataView           networkDataViewPrototype;
    @outlet TNNetworkEditionController  networkController;
    @outlet CPPopover                   popoverXMLString;

    CPButton                            _activateButton;
    CPButton                            _deactivateButton;
    CPButton                            _editButton;
    CPButton                            _minusButton;
    CPButton                            _plusButton;
    CPButton                            _editXMLButton;
    TNLibvirtNetwork                    _networkHolder;
    TNTableViewDataSource               _datasourceNetworks;
    CPDictionary                        _networksRAW;

}

#pragma mark -
#pragma mark Initialization

/*! called at cib awaking
*/
- (void)awakeFromCib
{
    _networksRAW = [CPDictionary dictionary];

    [viewTableContainer setBorderedWithHexColor:@"#C0C7D2"];

    /* VM table view */
    _datasourceNetworks     = [[TNTableViewDataSource alloc] init];
    var prototype = [CPKeyedArchiver archivedDataWithRootObject:networkDataViewPrototype];
    [[tableViewNetworks tableColumnWithIdentifier:@"self"] setDataView:[CPKeyedUnarchiver unarchiveObjectWithData:prototype]];
    [tableViewNetworks setTarget:self];
    [tableViewNetworks setDoubleAction:@selector(editNetwork:)];
    [tableViewNetworks setSelectionHighlightStyle:CPTableViewSelectionHighlightStyleNone];
    [tableViewNetworks setBackgroundColor:[CPColor colorWithHexString:@"F7F7F7"]];

    [_datasourceNetworks setTable:tableViewNetworks];
    [_datasourceNetworks setSearchableKeyPaths:[@"networkName", @"UUID", @"bridgeName"]];
    [tableViewNetworks setDataSource:_datasourceNetworks];
    [tableViewNetworks setDelegate:self];
    [networkController setDelegate:self];

    [fieldFilterNetworks setTarget:_datasourceNetworks];
    [fieldFilterNetworks setAction:@selector(filterObjects:)];

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

    _editXMLButton = [CPButtonBar plusButton];
    [_editXMLButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/editxml.png"] size:CPSizeMake(16, 16)]];
    [_editXMLButton setTarget:self];
    [_editXMLButton setAction:@selector(openXMLEditor:)];
    [_editXMLButton setToolTip:CPLocalizedString(@"Open the manual XML editor", @"Open the manual XML editor")];

    [_minusButton setEnabled:NO];
    [_activateButton setEnabled:NO];
    [_deactivateButton setEnabled:NO];
    [_editButton setEnabled:NO];
    [_editXMLButton setEnabled:NO];

    [buttonBarControl setButtons:[_plusButton, _minusButton, _editButton, _activateButton, _deactivateButton, _editXMLButton]];

    [fieldXMLString setTextColor:[CPColor blackColor]];
    [fieldXMLString setFont:[CPFont fontWithName:@"Andale Mono, Courier New" size:12]];
}


#pragma mark -
#pragma mark TNModule overrides

/*! called when module is loaded
*/
- (BOOL)willLoad
{
    if (![super willLoad])
        return NO;

    [[CPNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_didTableSelectionChange:)
                                                 name:CPTableViewSelectionDidChangeNotification
                                               object:tableViewNetworks];

    [tableViewNetworks setDelegate:nil];
    [tableViewNetworks setDelegate:self];

    [self registerSelector:@selector(_didReceivePush:) forPushNotificationType:TNArchipelPushNotificationNetworks];
    [self getHypervisorNetworks];
    [self getHypervisorNICS];

    return YES;
}

/*! called when the module hides
*/
- (void)willHide
{
    [networkController closeWindow:nil];
    [popoverXMLString close];

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
    [super permissionsChanged];
    if ([self currentEntityHasPermission:@"network_get"])
        [self getHypervisorNetworks];
    if ([self currentEntityHasPermission:@"network_getnics"])
        [self getHypervisorNICS];

    [self _didTableSelectionChange:nil];
}

/*! called when the UI needs to be updated according to the permissions
*/
- (void)setUIAccordingToPermissions
{
    [self setControl:_plusButton enabledAccordingToPermission:@"network_define"];
    [self setControl:_minusButton enabledAccordingToPermission:@"network_undefine"];
    [self setControl:_editButton enabledAccordingToPermission:@"network_define"];
    [self setControl:_activateButton enabledAccordingToPermission:@"network_create"];
    [self setControl:_deactivateButton enabledAccordingToPermission:@"network_destroy"];
    [self setControl:buttonDefineXMLString enabledAccordingToPermission:@"network_define"];
}

/*! this message is used to flush the UI
*/
- (void)flushUI
{
    [_networksRAW removeAllObjects];
    [_datasourceNetworks removeAllObjects];
    [tableViewNetworks reloadData];
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

    [self getHypervisorNetworks];
    return YES;
}

/*! triggered when the main table selection changes. it will update GUI
*/
- (void)_didTableSelectionChange:(CPNotification)aNotification
{
    var selectedIndex   = [[tableViewNetworks selectedRowIndexes] firstIndex];

    [popoverXMLString close];

    [_minusButton setEnabled:NO];
    [_editButton setEnabled:NO];
    [_activateButton setEnabled:NO];
    [_deactivateButton setEnabled:NO];
    [buttonDefineXMLString setEnabled:NO];
    [_editXMLButton setEnabled:NO];

    if ([tableViewNetworks numberOfSelectedRows] == 0)
        return;

    var networkObject = [_datasourceNetworks objectAtIndex:selectedIndex];

    if ([networkObject isActive])
    {
        [self setControl:_deactivateButton enabledAccordingToPermission:@"network_destroy"];
        if ([tableViewNetworks numberOfSelectedRows] == 1)
            [self setControl:_editXMLButton enabledAccordingToPermission:@"network_define"];
    }
    else
    {
        [self setControl:_minusButton enabledAccordingToPermission:@"network_undefine"];
        [self setControl:_editButton enabledAccordingToPermission:@"network_define"];
        [self setControl:_activateButton enabledAccordingToPermission:@"network_create"];
        if ([tableViewNetworks numberOfSelectedRows] == 1)
        {
            [self setControl:buttonDefineXMLString enabledAccordingToPermission:@"network_define"];
            [self setControl:_editXMLButton enabledAccordingToPermission:@"network_define"];
        }
    }

    return YES;
}


#pragma mark -
#pragma mark Utilities

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
    [self requestVisible];
    if (![self isVisible])
        return;

    var uuid            = [CPString UUID],
        ip              = [self generateIPForNewNetwork],
        newNetwork      = [TNLibvirtNetwork defaultNetworkWithName:uuid UUID:uuid];

    [newNetwork setIP:[[TNLibvirtNetworkIP alloc] init]];
    [[newNetwork IP] setAddress:ip];
    [[newNetwork IP] setNetmask:@"255.255.0.0"];

    [networkController setNetwork:newNetwork];
    [networkController openWindow:_plusButton];
}

/*! delete a network
    @param sender the sender of the action
*/
- (IBAction)delNetwork:(id)aSender
{
    [self requestVisible];
    if (![self isVisible])
        return;

    if ([tableViewNetworks numberOfSelectedRows] < 1)
        return;

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

    [self requestVisible];
    if (![self isVisible])
        return;

    var selectedIndex   = [[tableViewNetworks selectedRowIndexes] firstIndex];

    if (selectedIndex != -1)
    {
        var networkObject = [_datasourceNetworks objectAtIndex:selectedIndex];

        if ([networkObject isActive])
        {
            [TNAlert showAlertWithMessage:CPBundleLocalizedString(@"Error", @"Error") informative:CPBundleLocalizedString(@"You can't edit a running network", @"You can't edit a running network")];
            return;
        }

        [networkController setNetwork:networkObject];

        if ([aSender isKindOfClass:CPMenuItem])
            aSender = _editButton;
        [popoverXMLString close];
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
    [self requestVisible];
    if (![self isVisible])
        return;

    if ([tableViewNetworks numberOfSelectedRows] < 1)
        return;

    var selectedIndexes = [tableViewNetworks selectedRowIndexes],
        networks = [_datasourceNetworks objectsAtIndexes:selectedIndexes];

    [self activateNetworks:networks];
}

/*! deactivate a network
    @param sender the sender of the action
*/
- (IBAction)deactivateNetwork:(id)aSender
{
    [self requestVisible];
    if (![self isVisible])
        return;

    if ([tableViewNetworks numberOfSelectedRows] < 1)
        return;

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


/*! open the XML editor
    @param aSender the sender of the action
*/
- (IBAction)openXMLEditor:(id)aSender
{
    [self requestVisible];
    if (![self isVisible])
        return;

    if ([tableViewNetworks numberOfSelectedRows] != 1)
        return;

    var network = [_datasourceNetworks objectAtIndex:[tableViewNetworks selectedRow]],
        XMLString = [_networksRAW objectForKey:[network UUID]];


    if ([network isActive])
        [fieldXMLString setEnabled:NO];
    else
        [fieldXMLString setEnabled:YES];

    XMLString  = XMLString.replace("\n  \n", "\n");
    XMLString  = XMLString.replace(" xmlns='http://www.gajim.org/xmlns/undeclared'", "");
    [fieldXMLString setStringValue:XMLString];
    [networkController closeWindow:nil];
    [popoverXMLString close];
    [popoverXMLString showRelativeToRect:nil ofView:_editXMLButton preferredEdge:nil]
    [popoverXMLString setDefaultButton:buttonDefineXMLString];
}

/*! Save the current XML string description
    @param aSender the sender of the action
*/
- (IBAction)defineXMLString:(id)aSender
{
    var desc;
    try
    {
        desc = (new DOMParser()).parseFromString(unescape(""+[fieldXMLString stringValue]+""), "text/xml").getElementsByTagName("network")[0];
        if (!desc || typeof(desc) == "undefined")
            [CPException raise:CPInternalInconsistencyException reason:@"Not valid XML"];
    }
    catch (e)
    {
        [TNAlert showAlertWithMessage:CPLocalizedString(@"Error", @"Error")
                          informative:CPLocalizedString(@"Unable to parse the given XML", @"Unable to parse the given XML")
                          style:CPCriticalAlertStyle];
        [popoverXMLString close];
        return;
    }

    var network = [[TNLibvirtNetwork alloc] initWithXMLNode:[TNXMLNode nodeWithXMLNode:desc]];
    [self defineNetwork:network];
    [popoverXMLString close];
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

        [self flushUI];

        for (var i = 0; i < [allNetworks count]; i++)
        {
            var networkNode      = [allNetworks objectAtIndex:i],
                autostart        = ([networkNode valueForAttribute:@"autostart"] == @"1") ? YES : NO,
                active           = [activeNetworks containsObject:networkNode],
                network          = [[TNLibvirtNetwork alloc] initWithXMLNode:networkNode];

            [network setAutostart:autostart];
            [network setActive:active];
            [_datasourceNetworks addObject:network];
            [_networksRAW setObject:[networkNode stringValue].replace(" autostart='0'","").replace(" autostart='1'","")
                             forKey:[network UUID]];
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
- (void)defineNetwork:(TNLibvirtNetwork)aNetwork
{
    if ([aNetwork isActive])
    {
        [TNAlert showAlertWithTitle:CPBundleLocalizedString(@"Error", @"Error") message:CPBundleLocalizedString(@"You can't update a running network", @"You can't update a running network") style:CPCriticalAlertStyle];
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
    var stanza = [TNStropheStanza iqWithAttributes:{"type": "set"}];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorNetwork}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorNetworkDefine,
        "autostart": [_networkHolder isAutostart] ? @"1" : @"0"}];

    [stanza addNode:[_networkHolder XMLNode]];

    _networkHolder = nil;

    [self sendStanza:stanza andRegisterSelector:@selector(_didDefineNetwork:)];

    return NO;
}

/*! compute if hypervisor has defined the network
    @param aStanza TNStropheStanza containing the answer
    @return NO to unregister selector
*/
- (BOOL)_didDefineNetwork:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[_entity nickname] message:CPBundleLocalizedString(@"Network has been defined", @"Network has been defined")];
    else
        [self handleIqErrorFromStanza:aStanza];

    return NO;
}

/*! activate given networks
    @param someNetworks CPArray of TNLibvirtNetwork
*/
- (void)activateNetworks:(CPArray)someNetworks
{
    for (var i = 0; i < [someNetworks count]; i++)
    {
        var networkObject   = [someNetworks objectAtIndex:i],
            stanza          = [TNStropheStanza iqWithType:@"set"];

        if (![networkObject isActive])
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
    @param someNetworks CPArray of TNLibvirtNetwork
*/
- (void)deactivateNetworks:(CPArray)someNetworks
{
    for (var i = 0; i < [someNetworks count]; i++)
    {
        var networkObject   = [someNetworks objectAtIndex:i],
            stanza          = [TNStropheStanza iqWithType:@"set"];

        if ([networkObject isActive])
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
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[_entity nickname] message:CPBundleLocalizedString(@"Network status has changed", @"Network status has changed")];
    else
        [self handleIqErrorFromStanza:aStanza];

    return NO;
}

/*! delete given networks
    @param someNetworks CPArray of TNLibvirtNetwork
*/
- (void)deleteNetworks:(CPArray)someNetworks
{
    for (var i = 0; i < [someNetworks count]; i++)
    {
        var networkObject   = [someNetworks objectAtIndex:i];

        if ([networkObject isActive])
        {
            [TNAlert showAlertWithMessage:CPBundleLocalizedString(@"Error", @"Error") informative:CPBundleLocalizedString(@"You can't update a running network", @"You can't update a running network") style:CPCriticalAlertStyle];
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
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[_entity nickname] message:CPBundleLocalizedString(@"Network has been removed", @"Network has been removed")];
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
