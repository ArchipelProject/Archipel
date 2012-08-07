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
@import <AppKit/CPTextField.j>
@import <AppKit/CPView.j>

@import <LPKit/LPMultiLineTextField.j>
@import <TNKit/TNAlert.j>

@import "TNNuageEditionController.j"
@import "TNNuageDataView.j"
@import "TNCNACommunicator.j"

@import "Model/TNNuage.j"

var TNArchipelPushNotificationNuage             = @"archipel:push:nuagenetwork",
    TNArchipelTypeHypervisorNuage               = @"archipel:hypervisor:nuage:network",
    TNArchipelTypeHypervisorNuageGet            = @"get",
    TNArchipelTypeHypervisorNuageCreate         = @"create",
    TNArchipelTypeHypervisorNuageDelete         = @"delete",
    TNArchipelTypeHypervisorNuageUpate          = @"update";


/*! @defgroup  hypervisornetworks Module Hypervisor Networks
    @desc This manages hypervisors' virtual networks
*/

/*! @ingroup hypervisornetworks
    The main module controller
*/
@implementation TNHypervisorNuageController : TNModule
{
    @outlet CPButton                    buttonDefineXMLString;
    @outlet CPButtonBar                 buttonBarControl;
    @outlet CPPopover                   popoverXMLString;
    @outlet CPSearchField               fieldFilterNuage;
    @outlet CPTableView                 tableViewNuage;
    @outlet CPTextField                 fieldPreferencesBaseURL;
    @outlet CPTextField                 fieldPreferencesCompany;
    @outlet CPTextField                 fieldPreferencesToken;
    @outlet CPTextField                 fieldPreferencesUserName;
    @outlet CPView                      viewTableContainer;
    @outlet LPMultiLineTextField        fieldXMLString;
    @outlet TNNuageDataView             nuageDataViewPrototype;
    @outlet TNNuageEditionController    nuageController;

    CPButton                            _editButton;
    CPButton                            _editXMLButton;
    CPButton                            _minusButton;
    CPButton                            _plusButton;
    CPDictionary                        _nuagesRAW;
    TNCNACommunicator                   _CNACommunicator;
    TNTableViewDataSource               _datasourceNuages;
}

#pragma mark -
#pragma mark Initialization

/*! called at cib awaking
*/
- (void)awakeFromCib
{
    _nuagesRAW = [CPDictionary dictionary];

    [viewTableContainer setBorderedWithHexColor:@"#C0C7D2"];

    /* Preferences */

    var bundle = [CPBundle bundleForClass:[self class]],
        defaults = [CPUserDefaults standardUserDefaults];

    // register defaults
    [defaults registerDefaults:[CPDictionary dictionaryWithObjectsAndKeys:
            [bundle objectForInfoDictionaryKey:@"TNArchipelNuageURL"], @"TNArchipelNuageURL",
            [bundle objectForInfoDictionaryKey:@"TNArchipelNuageUserName"], @"TNArchipelNuageUserName",
            [bundle objectForInfoDictionaryKey:@"TNArchipelNuageCompany"], @"TNArchipelNuageCompany",
            [bundle objectForInfoDictionaryKey:@"TNArchipelNuagePassword"], @"TNArchipelNuagePassword"
    ]];

    /* VM table view */
    _datasourceNuages     = [[TNTableViewDataSource alloc] init];
    var prototype = [CPKeyedArchiver archivedDataWithRootObject:nuageDataViewPrototype];
    [[tableViewNuage tableColumnWithIdentifier:@"self"] setDataView:[CPKeyedUnarchiver unarchiveObjectWithData:prototype]];
    [tableViewNuage setTarget:self];
    [tableViewNuage setDoubleAction:@selector(editNuage:)];
    [tableViewNuage setSelectionHighlightStyle:CPTableViewSelectionHighlightStyleNone];
    [tableViewNuage setBackgroundColor:[CPColor colorWithHexString:@"F7F7F7"]];

    [_datasourceNuages setTable:tableViewNuage];
    [_datasourceNuages setSearchableKeyPaths:[@"name", @"type", @"IP.address", @"IP.netmask", @"IP.gateway"]];
    [tableViewNuage setDataSource:_datasourceNuages];
    [tableViewNuage setDelegate:self];
    [nuageController setDelegate:self];

    [fieldFilterNuage setTarget:_datasourceNuages];
    [fieldFilterNuage setAction:@selector(filterObjects:)];

    _plusButton = [CPButtonBar plusButton];
    [_plusButton setTarget:self];
    [_plusButton setAction:@selector(addNuage:)];
    [_plusButton setToolTip:CPBundleLocalizedString(@"Create a new Nuage network", @"Create a new Nuage network")];

    _minusButton = [CPButtonBar minusButton];
    [_minusButton setTarget:self];
    [_minusButton setAction:@selector(delNuage:)];
    [_minusButton setToolTip:CPBundleLocalizedString(@"Delete selected Nuage networks", @"Delete selected Nuage networks")];

    _editButton  = [CPButtonBar plusButton];
    [_editButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/edit.png"] size:CPSizeMake(16, 16)]];
    [_editButton setTarget:self];
    [_editButton setAction:@selector(editNuage:)];
    [_editButton setToolTip:CPBundleLocalizedString(@"Open configuration panel for selected Nuage network", @"Open configuration panel for selected Nuage network")];

    _editXMLButton = [CPButtonBar plusButton];
    [_editXMLButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/editxml.png"] size:CPSizeMake(16, 16)]];
    [_editXMLButton setTarget:self];
    [_editXMLButton setAction:@selector(openXMLEditor:)];
    [_editXMLButton setToolTip:CPLocalizedString(@"Open the manual XML editor", @"Open the manual XML editor")];

    [_minusButton setEnabled:NO];
    [_editButton setEnabled:NO];
    [_editXMLButton setEnabled:NO];

    [buttonBarControl setButtons:[_plusButton, _minusButton, _editButton, _editXMLButton]];

    [fieldXMLString setTextColor:[CPColor blackColor]];
    [fieldXMLString setFont:[CPFont fontWithName:@"Andale Mono, Courier New" size:12]];

    // CNA Communicator
    var URLString = [defaults objectForKey:@"TNArchipelNuageURL"];
    [self _initCNACommunicatorWithURLString:URLString];
}


#pragma mark -
#pragma mark TNModule overrides

/*! Called when all modules are ready
*/
- (void)allModulesLoaded
{
    [[CPNotificationCenter defaultCenter] postNotificationName:TNVirtualMachineVMCreationAddFieldDelegateNotification
                                                        object:self];
}

/*! called when module is loaded
*/
- (BOOL)willLoad
{
    if (![super willLoad])
        return NO;

    [tableViewNuage setDelegate:nil];
    [tableViewNuage setDelegate:self];

    [self registerSelector:@selector(_didReceivePush:) forPushNotificationType:TNArchipelPushNotificationNuage];

    if ([self currentEntityHasPermission:@"nuagenetwork_get"])
        [self getHypervisorNuages];
    return YES;
}

/*! called when the module hides
*/
- (void)willHide
{
    [nuageController closeWindow:nil];
    [popoverXMLString close];

    [super willHide];
}

/*! called when MainMenu is ready
*/
- (void)menuReady
{
    [[_menu addItemWithTitle:CPBundleLocalizedString(@"Create new Nuage network", @"Create new Nuage network") action:@selector(addNuage:) keyEquivalent:@""] setTarget:self];
    [[_menu addItemWithTitle:CPBundleLocalizedString(@"Edit selected Nuage network", @"Edit selected Nuage network") action:@selector(editNuage:) keyEquivalent:@""] setTarget:self];
    [[_menu addItemWithTitle:CPBundleLocalizedString(@"Delete selected Nuage network", @"Delete selected Nuage network") action:@selector(delNuage:) keyEquivalent:@""] setTarget:self];
}

/*! called when permissions changes
*/
- (void)permissionsChanged
{
    [super permissionsChanged];
    // Right, this is useless to reimplement it
    // but this is just to explain that we don't
    // reload anything else, because the permissions
    // system of TNModule will replay _beforeWillLoad,
    // and so refetch the data.
}

/*! called when the UI needs to be updated according to the permissions
*/
- (void)setUIAccordingToPermissions
{
    var selectedIndex = [[tableViewNuage selectedRowIndexes] firstIndex],
        conditionTableSelectedRow = ([tableViewNuage numberOfSelectedRows] != 0),
        nuageObject = conditionTableSelectedRow ? [_datasourceNuages objectAtIndex:selectedIndex] : nil,
        conditionTableSelectedOnlyOnRow = ([tableViewNuage numberOfSelectedRows] == 1);

    [self setControl:_plusButton enabledAccordingToPermission:@"nuagenetwork_create"];

    [self setControl:_editXMLButton enabledAccordingToPermission:@"nuagenetwork_create" specialCondition:conditionTableSelectedOnlyOnRow];
    [self setControl:_minusButton enabledAccordingToPermission:@"nuagenetwork_delete" specialCondition:conditionTableSelectedRow];
    [self setControl:_editButton enabledAccordingToPermission:@"nuagenetwork_create" specialCondition:conditionTableSelectedOnlyOnRow];
    [self setControl:buttonDefineXMLString enabledAccordingToPermission:@"nuagenetwork_create" specialCondition:conditionTableSelectedOnlyOnRow];
    [self setControl:_editXMLButton enabledAccordingToPermission:@"nuagenetwork_create" specialCondition:conditionTableSelectedOnlyOnRow];
}

/*! this message is used to flush the UI
*/
- (void)flushUI
{
    [_nuagesRAW removeAllObjects];
    [_datasourceNuages removeAllObjects];
    [tableViewNuage reloadData];
}

/*! called when user saves preferences
*/
- (void)savePreferences
{
    var defaults = [CPUserDefaults standardUserDefaults];

    [defaults setObject:[fieldPreferencesCompany stringValue] forKey:@"TNArchipelNuageCompany"];
    [defaults setObject:[fieldPreferencesUserName stringValue] forKey:@"TNArchipelNuageUserName"];
    [defaults setObject:[fieldPreferencesToken stringValue] forKey:@"TNArchipelNuagePassword"];
    [defaults setObject:[fieldPreferencesBaseURL stringValue] forKey:@"TNArchipelNuageURL"];

    [self _initCNACommunicatorWithURLString:[fieldPreferencesBaseURL stringValue]];
}

/*! called when user gets preferences
*/
- (void)loadPreferences
{
    var defaults = [CPUserDefaults standardUserDefaults];

    [fieldPreferencesCompany setStringValue:[defaults objectForKey:@"TNArchipelNuageCompany"]];
    [fieldPreferencesUserName setStringValue:[defaults objectForKey:@"TNArchipelNuageUserName"]];
    [fieldPreferencesToken setStringValue:[defaults objectForKey:@"TNArchipelNuagePassword"]];
    [fieldPreferencesBaseURL setStringValue:[defaults objectForKey:@"TNArchipelNuageURL"]];
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

    [self getHypervisorNuages];
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

    return [dA + "." + dB + ".0.0", dA + "." + dB + ".0.1"] ;
}


- (void)_initCNACommunicatorWithURLString:(CPString)anURL
{
    if (anURL)
    {
        var anURL = [CPURL URLWithString:anURL];

        _CNACommunicator = [[TNCNACommunicator alloc] initWithBaseURL:anURL];
    }
    else
        _CNACommunicator = nil;
}

#pragma mark -
#pragma mark Action

/*! add a network
    @param sender the sender of the action
*/
- (IBAction)addNuage:(id)aSender
{
    [self requestVisible];
    if (![self isVisible])
        return;

    var ip = [self generateIPForNewNetwork],
        newNuage = [TNNuageNetwork defaultNetworkWithName:@"" type:TNNuageNetworkTypeIPV4];

    [newNuage setIP:[[TNNuageNetworkIP alloc] init]];
    [[newNuage IP] setAddress:ip[0]];
    [[newNuage IP] setNetmask:@"255.255.0.0"];
    [[newNuage IP] setGateway:ip[1]];

    [nuageController setIsNewNuage:YES];
    [nuageController setNuage:newNuage];
    [nuageController openWindow:_plusButton];
}

/*! delete a network
    @param sender the sender of the action
*/
- (IBAction)delNuage:(id)aSender
{
    [self requestVisible];
    if (![self isVisible])
        return;

    if ([tableViewNuage numberOfSelectedRows] < 1)
        return;

    var selectedIndexes = [tableViewNuage selectedRowIndexes],
        nuages = [_datasourceNuages objectsAtIndexes:selectedIndexes],
        alert = [TNAlert alertWithMessage:CPBundleLocalizedString(@"Delete Nuage Network", @"Delete Nuage Network")
                              informative:CPBundleLocalizedString(@"Are you sure you want to destroy this Nuage network ?", @"Are you sure you want to destroy this Nuage network ?")
                                   target:self
                                  actions:[[CPBundleLocalizedString("Delete", "Delete"), @selector(_performDelNuage:)], [CPBundleLocalizedString("Cancel", "Cancel"), nil]]];
    [alert setUserInfo:nuages];
    [alert runModal];
}

/*! @ignore
*/
- (void)_performDelNuage:(id)someUserInfo
{
    [self deleteNuages:someUserInfo];
}

/*! open network edition panel
    @param sender the sender of the action
*/
- (IBAction)editNuage:(id)aSender
{
    if (![self currentEntityHasPermission:@"nuagenetwork_create"])
        return;

    [self requestVisible];
    if (![self isVisible])
        return;

    var selectedIndex   = [[tableViewNuage selectedRowIndexes] firstIndex];

    if (selectedIndex != -1)
    {
        var nuageObject = [_datasourceNuages objectAtIndex:selectedIndex];

        [nuageController setIsNewNuage:NO];
        [nuageController setNuage:nuageObject];

        if ([aSender isKindOfClass:CPMenuItem])
            aSender = _editButton;
        [popoverXMLString close];
        [nuageController openWindow:aSender];
    }
}

/*! define a network
    @param sender the sender of the action
*/
- (IBAction)createNuageXML:(id)aSender
{
    var selectedIndex = [[tableViewNuage selectedRowIndexes] firstIndex];

    if (selectedIndex == -1)
        return

    var nuageObject = [_datasourceNuages objectAtIndex:selectedIndex];

    [self createNuage:nuageObject];
}

/*! open the XML editor
    @param aSender the sender of the action
*/
- (IBAction)openXMLEditor:(id)aSender
{
    [self requestVisible];
    if (![self isVisible])
        return;

    if ([tableViewNuage numberOfSelectedRows] != 1)
        return;

    var nuage = [_datasourceNuages objectAtIndex:[tableViewNuage selectedRow]],
        XMLString = [_nuagesRAW objectForKey:[nuage name]];

    XMLString  = XMLString.replace("\n  \n", "\n");
    XMLString  = XMLString.replace(" xmlns='http://www.gajim.org/xmlns/undeclared'", "");
    [fieldXMLString setStringValue:XMLString];
    [nuageController closeWindow:nil];
    [popoverXMLString close];
    [popoverXMLString showRelativeToRect:nil ofView:_editXMLButton preferredEdge:nil]
    [popoverXMLString setDefaultButton:buttonDefineXMLString];
    [fieldXMLString setNeedsDisplay:YES];
}

/*! Save the current XML string description
    @param aSender the sender of the action
*/
- (IBAction)defineXMLString:(id)aSender
{
    var desc;
    try
    {
        desc = (new DOMParser()).parseFromString(unescape(""+[fieldXMLString stringValue]+""), "text/xml").getElementsByTagName("nuage_network")[0];
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

    var nuage = [[TNNuageNetwork alloc] initWithXMLNode:[TNXMLNode nodeWithXMLNode:desc]];
    [self updateNuage:nuage];
    [popoverXMLString close];
}


#pragma mark -
#pragma mark XMPP Controls

/*! asks networks to the hypervisor
*/
- (void)getHypervisorNuages
{
    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorNuage}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorNuageGet}];

    [self setModuleStatus:TNArchipelModuleStatusWaiting];
    [self sendStanza:stanza andRegisterSelector:@selector(_didReceiveHypervisorNuages:)];
}

/*! compute the answer containing the network information
*/
- (void)_didReceiveHypervisorNuages:(id)aStanza
{
    if ([aStanza type] == @"result")
    {
        [self flushUI];

        var nuages = [aStanza childrenWithName:@"nuage"]

        for (var i = 0; i < [nuages count]; i++)
        {
            var nuageNode = [nuages objectAtIndex:i],
                nuage = [[TNNuageNetwork alloc] initWithXMLNode:[nuageNode firstChildWithName:@"nuage_network"]];
            [_datasourceNuages addObject:nuage];
            [_nuagesRAW setObject:[[nuageNode firstChildWithName:@"nuage_network"] stringValue] forKey:[nuage name]];
        }

        [tableViewNuage reloadData];
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
- (void)createNuage:(TNuageNetwork)aNuage
{
    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorNuage}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorNuageCreate}];

    [stanza addNode:[aNuage XMLNode]];

    [self sendStanza:stanza andRegisterSelector:@selector(_didCreateNuage:)];
}

/*! compute if hypervisor has defined the network
    @param aStanza TNStropheStanza containing the answer
    @return NO to unregister selector
*/
- (BOOL)_didCreateNuage:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[_entity nickname] message:CPBundleLocalizedString(@"Nuage Network has been defined", @"Nuage Network has been defined")];
    else
        [self handleIqErrorFromStanza:aStanza];

    return NO;
}

/*! Update the given network
    @param aNetwork the network to define
*/
- (void)updateNuage:(TNuageNetwork)aNuage
{
    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorNuage}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorNuageUpate,
        "name": [aNuage name]}];

    [stanza addNode:[aNuage XMLNode]];

    [self sendStanza:stanza andRegisterSelector:@selector(_didUpdateNuage:)];
}

/*! compute if hypervisor has update the network
    @param aStanza TNStropheStanza containing the answer
    @return NO to unregister selector
*/
- (BOOL)_didUpdateNuage:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[_entity nickname] message:CPBundleLocalizedString(@"Nuage Network has been updated", @"Nuage Network has been updated")];
    else
        [self handleIqErrorFromStanza:aStanza];

    return NO;
}

/*! delete given networks
    @param someNetworks CPArray of TNLibvirtNetwork
*/
- (void)deleteNuages:(CPArray)someNuages
{
    for (var i = 0; i < [someNuages count]; i++)
    {
        var nuageObject = [someNuages objectAtIndex:i],
            stanza = [TNStropheStanza iqWithType:@"get"];

        [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorNuage}];
        [stanza addChildWithName:@"archipel" andAttributes:{
            "xmlns": TNArchipelTypeHypervisorNuage,
            "action": TNArchipelTypeHypervisorNuageDelete,
            "name": [nuageObject name]}];

        [self sendStanza:stanza andRegisterSelector:@selector(_didDeleteNuage:)];
    }
}

/*! compute if hypervisor has undefined the network
    @param aStanza TNStropheStanza containing the answer
    @return NO to unregister selector
*/
- (BOOL)_didDeleteNuage:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[_entity nickname] message:CPBundleLocalizedString(@"Nuage Network has been removed", @"Nuage Network has been removed")];
    else
        [self handleIqErrorFromStanza:aStanza];

    return NO;
}


#pragma mark -
#pragma mark Delegate

/*! TableView delegate
*/
- (void)tableViewSelectionDidChange:(CPNotification)aNotification
{
    [popoverXMLString close];
    [nuageController closeWindow:nil];
    [self setUIAccordingToPermissions];
}

/*! Virtual Machine Creation Delegate
*/
- (CPArray)completionForField:(CPComboBox)aComboBox value:(id)aValue
{
    if (!_CNACommunicator)
        return;

    switch ([aComboBox tag])
    {
        case @"organization":
            [_CNACommunicator fetchOrganizationsAndSetCompletionForComboBox:aComboBox];
            break;
        case @"unit":
            [_CNACommunicator fetchGroupsAndSetCompletionForComboBox:aComboBox];
            break;
        case @"owner":
            [_CNACommunicator fetchUsersAndSetCompletionForComboBox:aComboBox];
            break;
        case @"category":
            [_CNACommunicator fetchApplicationsAndSetCompletionForComboBox:aComboBox];
            break;
    }
}

@end

// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNHypervisorNuageController], comment);
}
