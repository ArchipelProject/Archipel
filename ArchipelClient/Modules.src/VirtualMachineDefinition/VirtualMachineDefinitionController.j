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

@import "TNNetworkInterfaceObject.j"
@import "TNDriveObject.j";
@import "TNWindowNicEdition.j";
@import "TNWindowDriveEdition.j";

TNArchipelTypeVirtualMachineControl                 = @"archipel:vm:control";
TNArchipelTypeVirtualMachineDefinition              = @"archipel:vm:definition";

TNArchipelTypeVirtualMachineControlXMLDesc          = @"xmldesc";
TNArchipelTypeVirtualMachineControlInfo             = @"info";
TNArchipelTypeVirtualMachineDefinitionDefine        = @"define";
TNArchipelTypeVirtualMachineDefinitionUndefine      = @"undefine";
TNArchipelTypeVirtualMachineDefinitionCapabilities  = @"capabilities";

TNArchipelPushNotificationDefinitition              = @"archipel:push:virtualmachine:definition";

VIR_DOMAIN_NOSTATE	        =	0;
VIR_DOMAIN_RUNNING	        =	1;
VIR_DOMAIN_BLOCKED	        =	2;
VIR_DOMAIN_PAUSED	        =	3;
VIR_DOMAIN_SHUTDOWN	        =	4;
VIR_DOMAIN_SHUTOFF	        =	5;
VIR_DOMAIN_CRASHED	        =	6;

TNXMLDescBootHardDrive      = @"hd";
TNXMLDescBootCDROM          = @"cdrom";
TNXMLDescBootNetwork        = @"network";
TNXMLDescBootFileDescriptor = @"fd";
TNXMLDescBoots              = [ TNXMLDescBootHardDrive, TNXMLDescBootCDROM,
                                TNXMLDescBootNetwork, TNXMLDescBootFileDescriptor];


TNXMLDescHypervisorKVM          = @"kvm";
TNXMLDescHypervisorXen          = @"xen";
TNXMLDescHypervisorOpenVZ       = @"openvz";
TNXMLDescHypervisorQemu         = @"qemu";
TNXMLDescHypervisorKQemu        = @"kqemu";
TNXMLDescHypervisorLXC          = @"lxc";
TNXMLDescHypervisorUML          = @"uml";
TNXMLDescHypervisorVBox         = @"vbox";
TNXMLDescHypervisorVMWare       = @"vmware";
TNXMLDescHypervisorOpenNebula   = @"one";
// TNXMLDescHypervisors            = [ TNXMLDescHypervisorKVM, TNXMLDescHypervisorXen,
//                                     TNXMLDescHypervisorOpenVZ, TNXMLDescHypervisorQemu,
//                                     TNXMLDescHypervisorKQemu, TNXMLDescHypervisorLXC,
//                                     TNXMLDescHypervisorUML, TNXMLDescHypervisorVBox,
//                                     TNXMLDescHypervisorVMWare, TNXMLDescHypervisorOpenNebula];

TNXMLDescVNCKeymapFR            = @"fr";
TNXMLDescVNCKeymapEN_US         = @"en-us";
TNXMLDescVNCKeymaps             = [TNXMLDescVNCKeymapEN_US, TNXMLDescVNCKeymapFR];


TNXMLDescLifeCycleDestroy           = @"destroy";
TNXMLDescLifeCycleRestart           = @"restart";
TNXMLDescLifeCyclePreserve          = @"preserve";
TNXMLDescLifeCycleRenameRestart     = @"rename-restart";
TNXMLDescLifeCycles                 = [TNXMLDescLifeCycleDestroy, TNXMLDescLifeCycleRestart, 
                                        TNXMLDescLifeCyclePreserve, TNXMLDescLifeCycleRenameRestart];

TNXMLDescFeaturePAE                 = @"pae";
TNXMLDescFeatureACPI                = @"acpi";
TNXMLDescFeatureAPIC                = @"apic";

TNXMLDescClockUTC       = @"utc";
TNXMLDescClockLocalTime = @"localtime";
TNXMLDescClockTimezone  = @"timezone";
TNXMLDescClockVariable  = @"variable";
TNXMLDescClocks         = [TNXMLDescClockUTC, TNXMLDescClockLocalTime];

function generateMacAddr()
{
    var hexTab      = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"];
    var dA          = "DE";
    var dB          = "AD";
    var dC          = hexTab[Math.round(Math.random() * 15)] + hexTab[Math.round(Math.random() * 15)];
    var dD          = hexTab[Math.round(Math.random() * 15)] + hexTab[Math.round(Math.random() * 15)];
    var dE          = hexTab[Math.round(Math.random() * 15)] + hexTab[Math.round(Math.random() * 15)];
    var dF          = hexTab[Math.round(Math.random() * 15)] + hexTab[Math.round(Math.random() * 15)];
    var macaddress  = dA + ":" + dB + ":" + dC + ":" + dD + ":" + dE + ":" + dF;

    return macaddress
}

@implementation VirtualMachineDefinitionController : TNModule
{
    @outlet CPButton                buttonAddNic;
    @outlet CPButton                buttonArchitecture;
    @outlet CPButton                buttonClocks;
    @outlet CPButton                buttonDelNic;
    @outlet CPButton                buttonHypervisor;
    @outlet CPButton                buttonOnCrash;
    @outlet CPButton                buttonOnPowerOff;
    @outlet CPButton                buttonOnReboot;
    @outlet CPButtonBar             buttonBarControlDrives;
    @outlet CPButtonBar             buttonBarControlNics;
    @outlet CPCheckBox              checkboxACPI;
    @outlet CPCheckBox              checkboxAPIC;
    @outlet CPCheckBox              checkboxPAE;
    @outlet CPCheckBox              checkboxHugePages;
    @outlet CPPopUpButton           buttonBoot;
    @outlet CPPopUpButton           buttonNumberCPUs;
    @outlet CPPopUpButton           buttonVNCKeymap;
    @outlet CPPopUpButton           buttonMachines;
    @outlet CPScrollView            scrollViewForDrives;
    @outlet CPScrollView            scrollViewForNics;
    @outlet CPSearchField           fieldFilterDrives;
    @outlet CPSearchField           fieldFilterNics;
    @outlet CPTextField             fieldJID;
    @outlet CPTextField             fieldMemory;
    @outlet CPTextField             fieldVNCPassword;
    @outlet CPTextField             fieldName;
    @outlet CPView                  maskingView;
    @outlet CPView                  viewDrivesContainer;
    @outlet CPView                  viewNicsContainer;
    @outlet TNWindowDriveEdition    windowDriveEdition;
    @outlet TNWindowNicEdition      windowNicEdition;
    @outlet LPMultiLineTextField    fieldStringXMLDesc;
    @outlet CPWindow                windowXMLEditor;
    
    CPButton                        _editButtonDrives;
    CPButton                        _editButtonNics;
    CPButton                        _minusButtonDrives;
    CPButton                        _minusButtonNics;
    CPButton                        _plusButtonDrives;
    CPButton                        _plusButtonNics;
    CPColor                         _bezelColor;
    CPColor                         _buttonBezelHighlighted;
    CPColor                         _buttonBezelSelected;
    CPTableView                     _tableDrives;
    CPTableView                     _tableNetworkNics;
    TNTableViewDataSource           _drivesDatasource;
    TNTableViewDataSource           _nicsDatasource;
    CPString                        _stringXMLDesc;
    CPDictionary                    _supportedCapabilities;
}

- (void)awakeFromCib
{
    [fieldJID setSelectable:YES];
    [fieldStringXMLDesc setFont:[CPFont fontWithName:@"Andale Mono, Courier New" size:12]];
    
    _stringXMLDesc = @"";
    
    var bundle                  = [CPBundle mainBundle];
    var centerBezel             = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"TNButtonBar/buttonBarCenterBezel.png"] size:CGSizeMake(1, 26)];
    var buttonBezel             = [CPColor colorWithPatternImage:centerBezel];
    var centerBezelHighlighted  = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"TNButtonBar/buttonBarCenterBezelHighlighted.png"] size:CGSizeMake(1, 26)];
    var centerBezelSelected     = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"TNButtonBar/buttonBarCenterBezelSelected.png"] size:CGSizeMake(1, 26)];

    _bezelColor                 = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"TNButtonBar/buttonBarBackground.png"] size:CGSizeMake(1, 27)]];
    _buttonBezelHighlighted     = [CPColor colorWithPatternImage:centerBezelHighlighted];
    _buttonBezelSelected        = [CPColor colorWithPatternImage:centerBezelSelected];

    _plusButtonDrives   = [CPButtonBar plusButton];
    _minusButtonDrives  = [CPButtonBar minusButton];
    _editButtonDrives   = [CPButtonBar plusButton];

    [_plusButtonDrives setTarget:self];
    [_plusButtonDrives setAction:@selector(addDrive:)];
    [_minusButtonDrives setTarget:self];
    [_minusButtonDrives setAction:@selector(deleteDrive:)];
    [_editButtonDrives setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-edit.png"] size:CPSizeMake(16, 16)]];
    [_editButtonDrives setTarget:self];
    [_editButtonDrives setAction:@selector(editDrive:)];
    [_minusButtonDrives setEnabled:NO];
    [_editButtonDrives setEnabled:NO];
    [buttonBarControlDrives setButtons:[_plusButtonDrives, _minusButtonDrives, _editButtonDrives]];


    _plusButtonNics     = [CPButtonBar plusButton];
    _minusButtonNics    = [CPButtonBar minusButton];
    _editButtonNics     = [CPButtonBar plusButton];
    
    [_plusButtonNics setTarget:self];
    [_plusButtonNics setAction:@selector(addNetworkCard:)];
    [_minusButtonNics setTarget:self];
    [_minusButtonNics setAction:@selector(deleteNetworkCard:)];
    [_editButtonNics setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-edit.png"] size:CPSizeMake(16, 16)]];
    [_editButtonNics setTarget:self];
    [_editButtonNics setAction:@selector(editNetworkCard:)];    
    [_minusButtonNics setEnabled:NO];
    [_editButtonNics setEnabled:NO];
    [buttonBarControlNics setButtons:[_plusButtonNics, _minusButtonNics, _editButtonNics]];
    
    
    [viewDrivesContainer setBorderedWithHexColor:@"#C0C7D2"];
    [viewNicsContainer setBorderedWithHexColor:@"#C0C7D2"];
    
    [windowNicEdition setDelegate:self];
    [windowDriveEdition setDelegate:self];    
    
    //drives
    _drivesDatasource       = [[TNTableViewDataSource alloc] init];
    _tableDrives            = [[CPTableView alloc] initWithFrame:[scrollViewForDrives bounds]];
    
    [scrollViewForDrives setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [scrollViewForDrives setAutohidesScrollers:YES];
    [scrollViewForDrives setDocumentView:_tableDrives];
    
    [_tableDrives setUsesAlternatingRowBackgroundColors:YES];
    [_tableDrives setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [_tableDrives setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [_tableDrives setAllowsColumnResizing:YES];
    [_tableDrives setAllowsEmptySelection:YES];
    [_tableDrives setAllowsMultipleSelection:YES];
    [_tableDrives setTarget:self];
    [_tableDrives setDelegate:self];
    [_tableDrives setDoubleAction:@selector(editDrive:)];
    
    var driveColumnType = [[CPTableColumn alloc] initWithIdentifier:@"type"];
    [[driveColumnType headerView] setStringValue:@"Type"];
    [driveColumnType setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"type" ascending:YES]];
    
    var driveColumnDevice = [[CPTableColumn alloc] initWithIdentifier:@"device"];
    [[driveColumnDevice headerView] setStringValue:@"Device"];
    [driveColumnDevice setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"device" ascending:YES]];
    
    var driveColumnTarget = [[CPTableColumn alloc] initWithIdentifier:@"target"];
    [[driveColumnTarget headerView] setStringValue:@"Target"];
    [driveColumnTarget setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"target" ascending:YES]];
    
    var driveColumnSource = [[CPTableColumn alloc] initWithIdentifier:@"source"];
    [driveColumnSource setWidth:300];
    [[driveColumnSource headerView] setStringValue:@"Source"];
    [driveColumnSource setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"source" ascending:YES]];
    
    var driveColumnBus = [[CPTableColumn alloc] initWithIdentifier:@"bus"];
    [[driveColumnBus headerView] setStringValue:@"Bus"];
    [driveColumnBus setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"bus" ascending:YES]];
    
    [_tableDrives addTableColumn:driveColumnType];
    [_tableDrives addTableColumn:driveColumnDevice];
    [_tableDrives addTableColumn:driveColumnTarget];
    [_tableDrives addTableColumn:driveColumnBus];
    [_tableDrives addTableColumn:driveColumnSource];
    
    [_drivesDatasource setTable:_tableDrives];
    [_drivesDatasource setSearchableKeyPaths:[@"type", @"device", @"target", @"source", @"bus"]];
    
    [_tableDrives setDataSource:_drivesDatasource];


    // NICs
    _nicsDatasource      = [[TNTableViewDataSource alloc] init];
    _tableNetworkNics   = [[CPTableView alloc] initWithFrame:[scrollViewForNics bounds]];

    [scrollViewForNics setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [scrollViewForNics setDocumentView:_tableNetworkNics];
    [scrollViewForNics setAutohidesScrollers:YES];

    [_tableNetworkNics setUsesAlternatingRowBackgroundColors:YES];
    [_tableNetworkNics setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [_tableNetworkNics setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [_tableNetworkNics setAllowsColumnResizing:YES];
    [_tableNetworkNics setAllowsEmptySelection:YES];
    [_tableNetworkNics setAllowsEmptySelection:YES];
    [_tableNetworkNics setAllowsMultipleSelection:YES];
    [_tableNetworkNics setTarget:self];
    [_tableNetworkNics setDelegate:self];
    [_tableNetworkNics setDoubleAction:@selector(editNetworkCard:)];
    [_tableNetworkNics setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    
    var columnType = [[CPTableColumn alloc] initWithIdentifier:@"type"];
    [[columnType headerView] setStringValue:@"Type"];
    [columnType setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"type" ascending:YES]];
    
    var columnModel = [[CPTableColumn alloc] initWithIdentifier:@"model"];
    [[columnModel headerView] setStringValue:@"Model"];
    [columnModel setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"model" ascending:YES]];

    var columnMac = [[CPTableColumn alloc] initWithIdentifier:@"mac"];
    [columnMac setWidth:150];
    [[columnMac headerView] setStringValue:@"MAC"];
    [columnMac setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"mac" ascending:YES]];

    var columnSource = [[CPTableColumn alloc] initWithIdentifier:@"source"];
    [[columnSource headerView] setStringValue:@"Source"];
    [columnSource setWidth:250];
    [columnSource setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"source" ascending:YES]];

    [_tableNetworkNics addTableColumn:columnSource];
    [_tableNetworkNics addTableColumn:columnType];
    [_tableNetworkNics addTableColumn:columnModel];
    [_tableNetworkNics addTableColumn:columnMac];

    [_nicsDatasource setTable:_tableNetworkNics];
    [_nicsDatasource setSearchableKeyPaths:[@"type", @"model", @"mac", @"source"]];
    
    [_tableNetworkNics setDataSource:_nicsDatasource];
    
    [fieldFilterDrives setTarget:_drivesDatasource];
    [fieldFilterDrives setAction:@selector(filterObjects:)];
    [fieldFilterNics setTarget:_nicsDatasource];
    [fieldFilterNics setAction:@selector(filterObjects:)];

    // others..
    [buttonBoot removeAllItems];
    [buttonNumberCPUs removeAllItems];
    [buttonArchitecture removeAllItems];
    [buttonHypervisor removeAllItems];
    [buttonVNCKeymap removeAllItems];
    [buttonMachines removeAllItems];
    [buttonOnPowerOff removeAllItems];
    [buttonOnReboot removeAllItems];
    [buttonOnCrash removeAllItems];
    [buttonClocks removeAllItems];

    [buttonBoot addItemsWithTitles:TNXMLDescBoots];
    [buttonNumberCPUs addItemsWithTitles:[@"1", @"2", @"3", @"4"]];
    //[buttonHypervisor addItemsWithTitles:TNXMLDescHypervisors];
    [buttonVNCKeymap addItemsWithTitles:TNXMLDescVNCKeymaps];
    [buttonOnPowerOff addItemsWithTitles:TNXMLDescLifeCycles];
    [buttonOnReboot addItemsWithTitles:TNXMLDescLifeCycles];
    [buttonOnCrash addItemsWithTitles:TNXMLDescLifeCycles];
    [buttonClocks addItemsWithTitles:TNXMLDescClocks];
    
    [checkboxPAE setState:CPOffState];
    [checkboxACPI setState:CPOffState];
    [checkboxAPIC setState:CPOffState];
    
    
    var menuNet = [[CPMenu alloc] init];
    [menuNet addItemWithTitle:@"Create new network interface" action:@selector(addNetworkCard:) keyEquivalent:@""];
    [menuNet addItem:[CPMenuItem separatorItem]];
    [menuNet addItemWithTitle:@"Edit" action:@selector(editNetworkCard:) keyEquivalent:@""];
    [menuNet addItemWithTitle:@"Delete" action:@selector(deleteNetworkCard:) keyEquivalent:@""];
    [_tableNetworkNics setMenu:menuNet];
    
    var menuDrive = [[CPMenu alloc] init];
    [menuDrive addItemWithTitle:@"Create new drive" action:@selector(addDrive:) keyEquivalent:@""];
    [menuDrive addItem:[CPMenuItem separatorItem]];
    [menuDrive addItemWithTitle:@"Edit" action:@selector(editDrive:) keyEquivalent:@""];
    [menuDrive addItemWithTitle:@"Delete" action:@selector(deleteDrive:) keyEquivalent:@""];
    [_tableDrives setMenu:menuDrive];
    
    [fieldVNCPassword setSecure:YES];
    
    _supportedCapabilities = [CPDictionary dictionary];
    
    [windowDriveEdition setTable:_tableDrives];
    [windowNicEdition setTable:_tableNetworkNics];
}


// TNModule impl.

- (void)willLoad
{
    [super willLoad];
    
    var center = [CPNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(didNickNameUpdated:) name:TNStropheContactNicknameUpdatedNotification object:_entity];
    [center addObserver:self selector:@selector(didPresenceUpdated:) name:TNStropheContactPresenceUpdatedNotification object:_entity];
    
    [self registerSelector:@selector(didPushReceive:) forPushNotificationType:TNArchipelPushNotificationDefinitition];
    
    [center postNotificationName:TNArchipelModulesReadyNotification object:self];
    
    [_tableDrives setDelegate:nil];
    [_tableDrives setDelegate:self];
    [_tableNetworkNics setDelegate:nil];
    [_tableNetworkNics setDelegate:self];

    [windowDriveEdition setDelegate:nil];
    [windowDriveEdition setDelegate:self];
    [windowDriveEdition setEntity:_entity];
    
    [windowNicEdition setDelegate:nil];
    [windowNicEdition setDelegate:self];
    [windowNicEdition setEntity:_entity];
    
    [self setDefaultValues];
    
    [fieldStringXMLDesc setStringValue:@""];
    
    [self getCapabilities];
    
}

- (void)willShow
{
    [super willShow];
    [fieldName setStringValue:[_entity nickname]];
    [fieldJID setStringValue:[_entity JID]];
    
    [self checkIfRunning];
}

- (void)willHide
{
    [super willHide];
}

- (void)willUnload
{
    [super willUnload];
    
    [self setDefaultValues];
}

- (void)menuReady
{
    [[_menu addItemWithTitle:@"Undefine" action:@selector(undefineXML:) keyEquivalent:@""] setTarget:self];
    [_menu addItem:[CPMenuItem separatorItem]];
    [[_menu addItemWithTitle:@"Add drive" action:@selector(addDrive:) keyEquivalent:@""] setTarget:self];
    [[_menu addItemWithTitle:@"Edit selected drive" action:@selector(editDrive:) keyEquivalent:@""] setTarget:self];
    [_menu addItem:[CPMenuItem separatorItem]];
    [[_menu addItemWithTitle:@"Add network card" action:@selector(addNetworkCard:) keyEquivalent:@""] setTarget:self];
    [[_menu addItemWithTitle:@"Edit selected network card" action:@selector(editNetworkCard:) keyEquivalent:@""] setTarget:self];
    [_menu addItem:[CPMenuItem separatorItem]];
    [[_menu addItemWithTitle:@"Open XML editor" action:@selector(openXMLEditor:) keyEquivalent:@""] setTarget:self];
}



- (void)didNickNameUpdated:(CPNotification)aNotification
{
    if ([aNotification object] == _entity)
    {
       [fieldName setStringValue:[_entity nickname]]
    }
}

- (BOOL)didPushReceive:(CPDictionary)somePushInfo
{
    var sender  = [somePushInfo objectForKey:@"owner"];
    var type    = [somePushInfo objectForKey:@"type"];
    var change  = [somePushInfo objectForKey:@"change"];
    var date    = [somePushInfo objectForKey:@"date"];
    CPLog.info(@"PUSH NOTIFICATION: from: " + sender + ", type: " + type + ", change: " + change);
    
    [self getXMLDesc];
    return YES;
}

- (void)didPresenceUpdated:(CPNotification)aNotification
{
    [self checkIfRunning];
}

- (void)setDefaultValues
{
    var bundle  = [CPBundle bundleForClass:[self class]];
    var cpu     = [bundle objectForInfoDictionaryKey:@"TNDescDefaultNumberCPU"];
    var mem     = [bundle objectForInfoDictionaryKey:@"TNDescDefaultMemory"];
    var arch    = [bundle objectForInfoDictionaryKey:@"TNDescDefaultArchitecture"];
    var vnck    = [bundle objectForInfoDictionaryKey:@"TNDescDefaultVNCKeymap"];
    var opo     = [bundle objectForInfoDictionaryKey:@"TNDescDefaultOnPowerOff"];
    var or      = [bundle objectForInfoDictionaryKey:@"TNDescDefaultOnReboot"];
    var oc      = [bundle objectForInfoDictionaryKey:@"TNDescDefaultOnCrash"];
    var hp      = [bundle objectForInfoDictionaryKey:@"TNDescDefaultHugePages"];
    var clock   = [bundle objectForInfoDictionaryKey:@"TNDescDefaultClockOffset"];
    var pae     = [bundle objectForInfoDictionaryKey:@"TNDescDefaultPAE"];
    var acpi    = [bundle objectForInfoDictionaryKey:@"TNDescDefaultACPI"];
    var apic    = [bundle objectForInfoDictionaryKey:@"TNDescDefaultAPIC"];
    
    _supportedCapabilities = [CPDictionary dictionary];
    
    [buttonNumberCPUs selectItemWithTitle:cpu];
    [fieldMemory setStringValue:@""];
    [fieldVNCPassword setStringValue:@""];
    [buttonVNCKeymap selectItemWithTitle:vnck];
    [buttonOnPowerOff selectItemWithTitle:opo];
    [buttonOnReboot selectItemWithTitle:or];
    [buttonOnCrash selectItemWithTitle:oc];
    [buttonClocks selectItemWithTitle:clock];
    [checkboxPAE setState:(pae == 1) ? CPOnState : CPOffState];
    [checkboxACPI setState:(acpi == 1) ? CPOnState : CPOffState];
    [checkboxAPIC setState:(apic == 1) ? CPOnState : CPOffState];
    [checkboxHugePages setState:(hp == 1) ? CPOnState : CPOffState];
    
    [buttonMachines removeAllItems];
    [buttonHypervisor removeAllItems];
    [buttonArchitecture removeAllItems];
    
    [_nicsDatasource removeAllObjects];
    [_drivesDatasource removeAllObjects];
    [_tableNetworkNics reloadData];
    [_tableDrives reloadData];
    
}

- (void)checkIfRunning
{
    var XMPPShow = [_entity XMPPShow];
    
    if (XMPPShow != TNStropheContactStatusBusy)
    {
        if (![maskingView superview])
        {
            [maskingView setFrame:[[self view] bounds]];
            [[self view] addSubview:maskingView];
        }
    }
    else
        [maskingView removeFromSuperview];
}


- (TNStropheStanza)generateXMLDescStanzaWithUniqueID:(CPNumber)anUid
{
    var memory          = "" + [fieldMemory intValue] * 1024 + ""; //put it into kb and make a string like a pig
    var arch            = [buttonArchitecture title];
    var machine         = [buttonMachines title];
    var hypervisor      = [buttonHypervisor title];
    var nCPUs           = [buttonNumberCPUs title];
    var boot            = [buttonBoot title];
    var nics            = [_nicsDatasource content];
    var drives          = [_drivesDatasource content];
    
    var capabilities    = [_supportedCapabilities objectForKey:arch];
    var stanza          = [TNStropheStanza iqWithAttributes:{"to": [_entity fullJID], "id": anUid, "type": "set"}];
    
    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeVirtualMachineDefinition}];
    [stanza addChildName:@"archipel" withAttributes:{
        "action": TNArchipelTypeVirtualMachineDefinitionDefine}];
        
    [stanza addChildName:@"domain" withAttributes:{"type": hypervisor}];

    [stanza addChildName:@"name"];
    [stanza addTextNode:[_entity nodeName]];
    [stanza up];

    [stanza addChildName:@"uuid"];
    [stanza addTextNode:[_entity nodeName]];
    [stanza up];

    [stanza addChildName:@"memory"];
    [stanza addTextNode:memory];
    [stanza up];

    [stanza addChildName:@"currentMemory"];
    [stanza addTextNode:memory];
    [stanza up];
    
    if ([checkboxHugePages state] == CPOnState)
    {
        [stanza addChildName:@"memoryBacking"]
        [stanza addChildName:@"hugepages"];
        [stanza up];
        [stanza up];
    }
    

    [stanza addChildName:@"vcpu"];
    [stanza addTextNode:nCPUs];
    [stanza up];

    [stanza addChildName:@"os"];
    [stanza addChildName:@"type" withAttributes:{"machine": machine, "arch": arch}]
    [stanza addTextNode:@"hvm"];
    [stanza up];
    [stanza addChildName:@"boot" withAttributes:{"dev": boot}]
    [stanza up];
    [stanza up];
    
    [stanza addChildName:@"on_poweroff"];
    [stanza addTextNode:[buttonOnPowerOff title]];
    [stanza up];

    [stanza addChildName:@"on_reboot"];
    [stanza addTextNode:[buttonOnReboot title]];
    [stanza up];

    [stanza addChildName:@"on_crash"];
    [stanza addTextNode:[buttonOnCrash title]];
    [stanza up];
    
    // FEATURES
    [stanza addChildName:@"features"];
    
    if ([checkboxPAE state] == CPOnState)
    {
        [stanza addChildName:TNXMLDescFeaturePAE];
        [stanza up];
    }
    
    if ([checkboxACPI state] == CPOnState)
    {
        [stanza addChildName:TNXMLDescFeatureACPI];
        [stanza up];
    }
    
    if ([checkboxAPIC state] == CPOnState)
    {
        [stanza addChildName:TNXMLDescFeatureAPIC];
        [stanza up];
    }
    
    [stanza up];

    //Clock
    if ((hypervisor == TNXMLDescHypervisorKVM) || (hypervisor == TNXMLDescHypervisorQemu) || (hypervisor == TNXMLDescHypervisorKQemu))
    {
        [stanza addChildName:@"clock" withAttributes:{"offset": [buttonClocks title]}];
        [stanza up];
    }
    
    
    // Devices
    [stanza addChildName:@"devices"];

    // emulator
    if ([[[capabilities objectForKey:@"domains"] objectForKey:hypervisor] containsKey:@"emulator"])
    {
        var emulator = [[[capabilities objectForKey:@"domains"] objectForKey:hypervisor] objectForKey:@"emulator"];
        
        [stanza addChildName:@"emulator"];
        [stanza addTextNode:emulator];
        [stanza up];
    }
    
    // drives
    for (var i = 0; i < [drives count]; i++)
    {
        var drive = [drives objectAtIndex:i];
        
        [stanza addChildName:@"disk" withAttributes:{"device": [drive device], "type": [drive type]}];
        if ([[drive source] uppercaseString].indexOf("QCOW2") != -1) // !!!!!! Argh! FIXME!
        {
            [stanza addChildName:@"driver" withAttributes:{"type": "qcow2"}];
            [stanza up];
        }
        if ([drive type] == @"file")
            [stanza addChildName:@"source" withAttributes:{"file": [drive source]}];
        else if ([drive type] == @"block")
            [stanza addChildName:@"source" withAttributes:{"dev": [drive source]}];
        
        [stanza up];
        [stanza addChildName:@"target" withAttributes:{"bus": [drive bus], "dev": [drive target]}];
        [stanza up];
        [stanza up];
    }
    
    // nics
    for (var i = 0; i < [nics count]; i++)
    {
        var nic     = [nics objectAtIndex:i];
        var nicType = [nic type];

        [stanza addChildName:@"interface" withAttributes:{"type": nicType}];
        [stanza addChildName:@"mac" withAttributes:{"address": [nic mac]}];
        [stanza up];
        
        [stanza addChildName:@"model" withAttributes:{"type": [nic model]}];
        [stanza up];
        
        if (nicType == @"bridge")
            [stanza addChildName:@"source" withAttributes:{"bridge": [nic source]}];
        else
            [stanza addChildName:@"source" withAttributes:{"network": [nic source]}];

        [stanza up];
        [stanza up];
    }

    [stanza addChildName:@"input" withAttributes:{"bus": "ps2", "type": "mouse"}];
    [stanza up];

    if (hypervisor == TNXMLDescHypervisorKVM || hypervisor == TNXMLDescHypervisorQemu
        || hypervisor == TNXMLDescHypervisorKQemu || hypervisor == TNXMLDescHypervisorXen)
    {
        if ([fieldVNCPassword stringValue] != @"")
        {
            [stanza addChildName:@"graphics" withAttributes:{
                "autoport": "yes", 
                "type": "vnc", 
                "port": "-1", 
                "keymap": [buttonVNCKeymap title],
                "passwd": [fieldVNCPassword stringValue]}];
        }
        else
        {
            [stanza addChildName:@"graphics" withAttributes:{
                "autoport": "yes", 
                "type": "vnc", 
                "port": "-1", 
                "keymap": [buttonVNCKeymap title]}];
        }
        [stanza up];
    }

    //devices up
    [stanza up];

    return stanza;
}

// XML Capabilities
- (void)getCapabilities
{
    var stanza   = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeVirtualMachineDefinition}];
    [stanza addChildName:@"archipel" withAttributes:{
        "action": TNArchipelTypeVirtualMachineDefinitionCapabilities}];
        
    [_entity sendStanza:stanza andRegisterSelector:@selector(didReceiveXMLCapabilities:) ofObject:self];
}

- (void)didReceiveXMLCapabilities:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        var guests = [aStanza childrenWithName:@"guest"];
        _supportedCapabilities = [CPDictionary dictionary];
        
        for (var i = 0; i < [guests count]; i++)
        {
            var guest               = [guests objectAtIndex:i];
            var osType              = [[guest firstChildWithName:@"os_type"] text];
            var arch                = [[guest firstChildWithName:@"arch"] valueForAttribute:@"name"];
            var features            = [guest firstChildWithName:@"features"];
            var supportNonPAE       = NO;
            var supportPAE          = NO;
            var supportACPI         = NO;
            var supportAPIC         = NO;
            var domains             = [guest childrenWithName:@"domain"];
            var domainsDict         = [CPDictionary dictionary];
            var defaultMachines     = [CPArray array];
            var defaultEmulator     = [[[guest firstChildWithName:@"arch"] firstChildWithName:@"emulator"] text];
            var defaultMachinesNode = [[guest firstChildWithName:@"arch"] ownChildrenWithName:@"machine"];
            
            for (var j = 0; j < [defaultMachinesNode count]; j++)
            {
                var machine = [defaultMachinesNode objectAtIndex:j];
                if (![defaultMachinesNode containsObject:[machine text]])
                    [defaultMachines addObject:[machine text]];
            }
            
            if (domains)
            {
                for (var j = 0; j < [domains count]; j++)
                {
                    var domain          = [domains objectAtIndex:j];
                    var machines        = [CPArray array];
                    var machinesNode    = [domain childrenWithName:@"machine"];
                    var domEmulator     = nil;
                    var dict            = [CPDictionary dictionary];
                    
                    if ([domain containsChildrenWithName:@"emulator"])
                        domEmulator = [[domain firstChildWithName:@"emulator"] text];
                    else
                        domEmulator = defaultEmulator;
                    
                    if ([machinesNode count] == 0)
                        machines = defaultMachines;
                    else
                        for (var k = 0; k < [machinesNode count]; k++)
                        {
                            var machine = [machinesNode objectAtIndex:k];
                            [machines addObject:[machine text]];
                        }
                    
                    [dict setObject:domEmulator forKey:@"emulator"];
                    [dict setObject:machines forKey:@"machines"];
                    
                    [domainsDict setObject:dict forKey:[domain valueForAttribute:@"type"]]
                }
            }
            
            if (features)
            {
                supportNonPAE   = [features containsChildrenWithName:@"pae"];
                supportPAE      = [features containsChildrenWithName:@"nonpae"];
                supportACPI     = [features containsChildrenWithName:@"acpi"];
                supportAPIC     = [features containsChildrenWithName:@"apic"];
            }
            
            var cap = [CPDictionary dictionaryWithObjectsAndKeys:   supportPAE,         @"PAE", 
                                                                    supportNonPAE,      @"NONPAE",
                                                                    supportAPIC,        @"APIC",
                                                                    supportACPI,        @"ACPI",
                                                                    domainsDict,        @"domains"];
            
            [_supportedCapabilities setObject:cap forKey:arch];
        }
        CPLog.trace(_supportedCapabilities);
        [self getXMLDesc];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
    
}


//  XML Desc
- (void)getXMLDesc
{
    var stanza   = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeVirtualMachineControl}];
    [stanza addChildName:@"archipel" withAttributes:{
        "action": TNArchipelTypeVirtualMachineControlXMLDesc}];
        
    [_entity sendStanza:stanza andRegisterSelector:@selector(didReceiveXMLDesc:) ofObject:self];
}

- (void)didReceiveXMLDesc:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        var domain          = [aStanza firstChildWithName:@"domain"];
        var hypervisor      = [domain valueForAttribute:@"type"];
        var memory          = [[domain firstChildWithName:@"currentMemory"] text];
        var memoryBacking   = [domain firstChildWithName:@"memoryBacking"];
        var arch            = [[[domain firstChildWithName:@"os"] firstChildWithName:@"type"] valueForAttribute:@"arch"];
        var machine         = [[[domain firstChildWithName:@"os"] firstChildWithName:@"type"] valueForAttribute:@"machine"];
        var vcpu            = [[domain firstChildWithName:@"vcpu"] text];
        var boot            = [[domain firstChildWithName:@"boot"] valueForAttribute:@"dev"];
        var interfaces      = [domain childrenWithName:@"interface"];
        var disks           = [domain childrenWithName:@"disk"];
        var graphics        = [domain childrenWithName:@"graphics"];
        var onPowerOff      = [domain firstChildWithName:@"on_poweroff"];
        var onReboot        = [domain firstChildWithName:@"on_reboot"];
        var onCrash         = [domain firstChildWithName:@"on_crash"];
        var features        = [domain firstChildWithName:@"features"];
        var clock           = [domain firstChildWithName:@"clock"];
        var capabilities    = [_supportedCapabilities objectForKey:arch];
        var shouldRefresh   = NO;
        
        
        // button ARCH
        [buttonArchitecture removeAllItems];
        [buttonArchitecture addItemsWithTitles:[_supportedCapabilities allKeys]];
        if ([buttonArchitecture indexOfItemWithTitle:arch] == -1)
        {
            [buttonArchitecture selectItemAtIndex:0];
            shouldRefresh = YES;
        }
        else
            [buttonArchitecture selectItemWithTitle:arch];
        
        // button Hypervisor
        [buttonHypervisor removeAllItems];
        [buttonHypervisor addItemsWithTitles:[[capabilities objectForKey:@"domains"] allKeys]];
        if ([buttonHypervisor indexOfItemWithTitle:hypervisor] == -1)
        {
            [buttonHypervisor selectItemAtIndex:0];
            shouldRefresh = YES;
        }
        else
            [buttonHypervisor selectItemWithTitle:hypervisor];
        
        
        // button Machine
        [buttonMachines removeAllItems];
        if ([[[capabilities objectForKey:@"domains"] objectForKey:hypervisor] containsKey:@"machines"] &&
            [[[[capabilities objectForKey:@"domains"] objectForKey:hypervisor] objectForKey:@"machines"] count])
        {
            [buttonMachines setEnabled:YES];
            [buttonMachines addItemsWithTitles:[[[capabilities objectForKey:@"domains"] objectForKey:hypervisor] objectForKey:@"machines"]];
            if ([buttonMachines indexOfItemWithTitle:machine] == -1)
            {
                [buttonMachines selectItemAtIndex:0];
                shouldRefresh = YES;
            }
            else
            {
                [buttonMachines selectItemWithTitle:machine];
            }
        }
        else
            [buttonMachines setEnabled:NO];
        
        
        _stringXMLDesc      = [[aStanza firstChildWithName:@"domain"] stringValue];
        _stringXMLDesc      = _stringXMLDesc.replace("\n  \n", "\n");
        _stringXMLDesc      = _stringXMLDesc.replace("xmlns='http://www.gajim.org/xmlns/undeclared' ", "");
        
        [fieldStringXMLDesc setStringValue:_stringXMLDesc];
        
        [_nicsDatasource removeAllObjects];
        [_drivesDatasource removeAllObjects];
        
        [fieldMemory setStringValue:(parseInt(memory) / 1024)];
        [buttonNumberCPUs selectItemWithTitle:vcpu];
        
        for (var i = 0; i < [graphics count]; i++)
        {
            var graphic = [graphics objectAtIndex:i];
            if ([graphic valueForAttribute:@"type"] == "vnc")
            {
                var keymap = [graphic valueForAttribute:@"keymap"];
                if (keymap)
                    [buttonVNCKeymap selectItemWithTitle:keymap];
                
                var passwd = [graphic valueForAttribute:@"passwd"];
                if (passwd)
                    [fieldVNCPassword setStringValue:passwd];
            }
        }
        
        if (boot == "cdrom")
            [buttonBoot selectItemWithTitle:TNXMLDescBootCDROM];
        else
            [buttonBoot selectItemWithTitle:TNXMLDescBootHardDrive];
        
        
        //power 
        if (onPowerOff)
            [buttonOnPowerOff selectItemWithTitle:[onPowerOff text]];
        else
            [buttonOnPowerOff selectItemWithTitle:@"Default"];
        
        if (onReboot)
            [buttonOnReboot selectItemWithTitle:[onReboot text]];
        else
            [buttonOnPowerOff selectItemWithTitle:@"Default"];
                
        if (onCrash)
            [buttonOnCrash selectItemWithTitle:[onCrash text]];
        else
            [buttonOnPowerOff selectItemWithTitle:@"Default"];
        
        // features
        [checkboxAPIC setEnabled:NO];
        [checkboxAPIC setState:CPOffState];
        if ([capabilities containsKey:@"APIC"] && [capabilities objectForKey:@"APIC"])
        {
            [checkboxAPIC setEnabled:YES];
            
            if (features && [features containsChildrenWithName:TNXMLDescFeatureAPIC])
                [checkboxAPIC setState:CPOnState];
        }
        
        [checkboxACPI setEnabled:NO];
        [checkboxACPI setState:CPOffState];
        if ([capabilities containsKey:@"ACPI"] && [capabilities objectForKey:@"ACPI"])
        {
            [checkboxACPI setEnabled:YES];
            
            if (features && [features containsChildrenWithName:TNXMLDescFeatureACPI])
                [checkboxACPI setState:CPOnState];
        }
        
        [checkboxPAE setEnabled:NO];
        [checkboxPAE setState:CPOffState];
        
        if ([capabilities containsKey:@"PAE"] && ![capabilities containsKey:@"NONPAE"])
        {
            [checkboxPAE setState:CPOnState];
        }
        else if (![capabilities containsKey:@"PAE"] && [capabilities containsKey:@"NONPAE"])
        {
            [checkboxPAE setState:CPOffState];
        }
        else if ([capabilities containsKey:@"PAE"] && [capabilities objectForKey:@"PAE"] 
            && [capabilities containsKey:@"NONPAE"] && [capabilities objectForKey:@"NONPAE"])
        {
            [checkboxPAE setEnabled:YES];
            if (features && [features containsChildrenWithName:TNXMLDescFeaturePAE])
                [checkboxPAE setState:CPOnState];
        }
        
        
        // huge pages
        [checkboxHugePages setState:CPOffState];
        if (memoryBacking)
        {
            if ([memoryBacking containsChildrenWithName:@"hugepages"])
                [checkboxHugePages setState:CPOnState];
        }
        
        
        //clock
        if ((hypervisor == TNXMLDescHypervisorKVM) || (hypervisor == TNXMLDescHypervisorQemu) || (hypervisor == TNXMLDescHypervisorKQemu))
        {
            [buttonClocks setEnabled:YES];
            
            if (clock)
            {
                [buttonClocks selectItemWithTitle:[clock valueForAttribute:@"offset"]];
            }
        }
        else
        {
            [buttonClocks setEnabled:NO];
        }
        
        // NICs
        for (var i = 0; i < [interfaces count]; i++)
        {
            var currentInterface    = [interfaces objectAtIndex:i];
            var iType               = [currentInterface valueForAttribute:@"type"];
            var iModel              = ([currentInterface firstChildWithName:@"model"]) ? [[currentInterface firstChildWithName:@"model"] valueForAttribute:@"type"] : @"pcnet";
            var iMac                = [[currentInterface firstChildWithName:@"mac"] valueForAttribute:@"address"];

            if (iType == "bridge")
                var iSource = [[currentInterface firstChildWithName:@"source"] valueForAttribute:@"bridge"];
            else if (iType == "network")
                var iSource = [[currentInterface firstChildWithName:@"source"] valueForAttribute:@"network"];


            var iTarget = "";//interfaces[i].getElementsByTagName("target")[0].getAttribute("dev");

            var newNic = [TNNetworkInterface networkInterfaceWithType:iType model:iModel mac:iMac source:iSource]

            [_nicsDatasource addObject:newNic];
        }
        [_tableNetworkNics reloadData];

        //Drives
        for (var i = 0; i < [disks count]; i++)
        {
            var currentDisk = [disks objectAtIndex:i];
            var iType       = [currentDisk valueForAttribute:@"type"];
            var iDevice     = [currentDisk valueForAttribute:@"device"];
            var iTarget     = [[currentDisk firstChildWithName:@"target"] valueForAttribute:@"dev"];
            var iBus        = [[currentDisk firstChildWithName:@"target"] valueForAttribute:@"bus"];
            var iSource     = (iType == @"file") ? [[currentDisk firstChildWithName:@"source"] valueForAttribute:@"file"] : [[currentDisk firstChildWithName:@"source"] valueForAttribute:@"dev"];

            var newDrive =  [TNDrive driveWithType:iType device:iDevice source:iSource target:iTarget bus:iBus]

            [_drivesDatasource addObject:newDrive];
        }
        [_tableDrives reloadData];
        
        // if automatic changes has been done while changing arch, hypervisor etc, 
        // redefine virtual machine
        if (shouldRefresh)
            [self defineXML:nil];
    }
    else if ([aStanza type] == @"error")
    {
        if ([[[aStanza firstChildWithName:@"error"] firstChildWithName:@"text"] text] == "not-defined")
        {
            [checkboxAPIC setEnabled:NO];
            [checkboxACPI setEnabled:NO];
            [checkboxPAE setEnabled:NO];
            
            [buttonArchitecture removeAllItems];
            [buttonArchitecture addItemsWithTitles:[_supportedCapabilities allKeys]];
            [buttonArchitecture selectItemAtIndex:0];
            
            var capabilities = [_supportedCapabilities objectForKey:[buttonArchitecture title]];
            
            [buttonHypervisor setEnabled:NO];
            [buttonHypervisor removeAllItems];
            if ([capabilities containsKey:@"domains"])
            {
                [buttonHypervisor addItemsWithTitles:[[capabilities objectForKey:@"domains"] allKeys]];
                [buttonHypervisor selectItemAtIndex:0];
                [buttonHypervisor setEnabled:YES];
            }
            
            [buttonMachines setEnabled:NO];
            [buttonMachines removeAllItems];
            if ([capabilities containsKey:@"domains"] && [[[capabilities objectForKey:@"domains"] objectForKey:@"machines"] count] > 0)
            {
                [buttonMachines addItemsWithTitles:[[[capabilities objectForKey:@"domains"] objectForKey:[buttonHypervisor title]] objectForKey:@"machines"]];
                [buttonMachines selectItemAtIndex:0];
                [buttonMachines setEnabled:YES];
            }
        }
        else
        {
            [self handleIqErrorFromStanza:aStanza];
        }
    }
}


- (IBAction)openXMLEditor:(id)sender
{
    [windowXMLEditor center];
    [windowXMLEditor makeKeyAndOrderFront:sender];
    
}


- (IBAction)defineXML:(id)sender
{
    var uid             = [_connection getUniqueId];
    var defineStanza    = [self generateXMLDescStanzaWithUniqueID:uid];

    [_entity sendStanza:defineStanza andRegisterSelector:@selector(didDefineXML:) ofObject:self withSpecificID:uid];
}

- (IBAction)defineXMLString:(id)sender
{
    var desc    = (new DOMParser()).parseFromString(unescape(""+[fieldStringXMLDesc stringValue]+""), "text/xml").getElementsByTagName("domain")[0];
    desc        = document.importNode(desc, true);
    
    var stanza  = [TNStropheStanza iqWithType:@"get"];
    
    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeVirtualMachineDefinition}];
    [stanza addChildName:@"archipel" withAttributes:{"action": TNArchipelTypeVirtualMachineDefinitionDefine}];
    [stanza addNode:desc];
    
    [self sendStanza:stanza andRegisterSelector:@selector(didDefineXML:)];
    [windowXMLEditor close];
}

- (void)didDefineXML:(TNStropheStanza)aStanza
{
    var responseType    = [aStanza type];
    var responseFrom    = [aStanza from];

    if (responseType == @"result")
    {
        var msg = @"Definition of virtual machine " + [_entity nickname] + " sucessfuly updated"
        CPLog.info(msg)
    }
    else if (responseType == @"error")
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}


- (IBAction)undefineXML:(id)sender
{
        var alert = [TNAlert alertWithTitle:@"Undefine virtual machine"
                                    message:@"Are you sure you want to undefine this virtual machine ?"
                         informativeMessage:@"All your changes will be definitly lost."
                                    delegate:self
                                     actions:[["Undefine", @selector(performUndefineXML:)], ["Cancel", nil]]];
        [alert runModal];
    }

- (void)performUndefineXML:(id)someUserInfo
{
    var stanza   = [TNStropheStanza iqWithType:@"get"];
    
    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeVirtualMachineDefinition}];
    [stanza addChildName:@"archipel" withAttributes:{"action": TNArchipelTypeVirtualMachineDefinitionUndefine}];
    
    [_entity sendStanza:stanza andRegisterSelector:@selector(didUndefineXML:) ofObject:self];
}

- (void)didUndefineXML:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Virtual machine" message:@"Virtual machine has been undefined"];
        // [self setDefaultValues];
        [self getXMLDesc];
    }
    else if ([aStanza type] == @"error")
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}



- (IBAction)addNetworkCard:(id)sender
{
    var defaultNic = [TNNetworkInterface networkInterfaceWithType:@"bridge" model:@"pcnet" mac:generateMacAddr() source:@"virbr0"]

    [_nicsDatasource addObject:defaultNic];
    [_tableNetworkNics reloadData];
    [self defineXML:nil];
}

- (IBAction)editNetworkCard:(id)sender
{
    if ([[_tableNetworkNics selectedRowIndexes] count] != 1)
    {
         //[CPAlert alertWithTitle:@"Error" message:@"You must select one network interface"];
         [self addNetworkCard:sender];
         return;
    }
    var selectedIndex   = [[_tableNetworkNics selectedRowIndexes] firstIndex];
    var nicObject       = [_nicsDatasource objectAtIndex:selectedIndex];

    [windowNicEdition setNic:nicObject];
    [windowNicEdition update];
    [windowNicEdition center];
    [windowNicEdition orderFront:nil];
}


- (IBAction)deleteNetworkCard:(id)sender
{
    if ([_tableNetworkNics numberOfSelectedRows] <= 0)
    {
         [CPAlert alertWithTitle:@"Error" message:@"You must select a network interface"];
         return;
    }

     var selectedIndexes = [_tableNetworkNics selectedRowIndexes];
     [_nicsDatasource removeObjectsAtIndexes:selectedIndexes];
     
     [_tableNetworkNics reloadData];
     [_tableNetworkNics deselectAll];
     [self defineXML:nil];
}

- (IBAction)addDrive:(id)sender
{
    var defaultDrive = [TNDrive driveWithType:@"file" device:@"disk" source:"/drives/drive.img" target:@"hda" bus:@"ide"]

    [_drivesDatasource addObject:defaultDrive];
    [_tableDrives reloadData];
    [self defineXML:nil];
}

- (IBAction)editDrive:(id)sender
{
    if ([[_tableDrives selectedRowIndexes] count] != 1)
    {
         //[CPAlert alertWithTitle:@"Error" message:@"You must select one drive"];
         [self addDrive:sender];
         return;
    }
    var selectedIndex   = [[_tableDrives selectedRowIndexes] firstIndex];
    var driveObject     = [_drivesDatasource objectAtIndex:selectedIndex];

    [windowDriveEdition setDrive:driveObject];
    [windowDriveEdition update];
    [windowDriveEdition center];
    [windowDriveEdition makeKeyAndOrderFront:nil];
}

- (IBAction)deleteDrive:(id)sender
{
    if ([_tableDrives numberOfSelectedRows] <= 0)
    {
        [CPAlert alertWithTitle:@"Error" message:@"You must select a drive"];
        return;
    }
    
     var selectedIndexes = [_tableDrives selectedRowIndexes];
     
     [_drivesDatasource removeObjectsAtIndexes:selectedIndexes];
     
     [_tableDrives reloadData];
     [_tableDrives deselectAll];
     [self defineXML:nil];
}



- (void)tableViewSelectionDidChange:(CPNotification)aNotification
{
    if ([aNotification object] == _tableDrives)
    {
        [_minusButtonDrives setEnabled:NO];
        [_editButtonDrives setEnabled:NO];

        if ([[aNotification object] numberOfSelectedRows] > 0)
        {
            [_minusButtonDrives setEnabled:YES];
            [_editButtonDrives setEnabled:YES];
        }
    }
    else if ([aNotification object] == _tableNetworkNics)
    {
        [_minusButtonNics setEnabled:NO];
        [_editButtonNics setEnabled:NO];

        if ([[aNotification object] numberOfSelectedRows] > 0)
        {
            [_minusButtonNics setEnabled:YES];
            [_editButtonNics setEnabled:YES];
        }
    }
}

@end



