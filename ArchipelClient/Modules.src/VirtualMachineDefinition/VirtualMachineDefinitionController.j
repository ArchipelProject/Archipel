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
@import <LPKit/LPKit.j>

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

TNXMLDescInputTypeMouse     = @"mouse";
TNXMLDescInputTypeTablet    = @"tablet";
TNXMLDescInputTypes         = [TNXMLDescInputTypeMouse, TNXMLDescInputTypeTablet];

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
    @outlet TNSwitch                switchACPI;
    @outlet TNSwitch                switchAPIC;
    @outlet TNSwitch                switchHugePages;
    @outlet TNSwitch                switchPAE;
    @outlet CPPopUpButton           buttonBoot;
    @outlet CPPopUpButton           buttonInputType;
    @outlet CPPopUpButton           buttonMachines;
    @outlet CPPopUpButton           buttonNumberCPUs;
    @outlet CPPopUpButton           buttonOSType;
    @outlet CPPopUpButton           buttonVNCKeymap;
    @outlet CPScrollView            scrollViewForDrives;
    @outlet CPScrollView            scrollViewForNics;
    @outlet CPSearchField           fieldFilterDrives;
    @outlet CPSearchField           fieldFilterNics;
    @outlet CPTabView               tabViewDevices;
    @outlet CPTextField             fieldJID;
    @outlet CPTextField             fieldMemory;
    @outlet CPTextField             fieldName;
    @outlet CPTextField             fieldVNCPassword;
    @outlet CPView                  maskingView;
    @outlet CPView                  viewDeviceVirtualDrives;
    @outlet CPView                  viewDeviceVirtualNics;
    @outlet CPView                  viewDrivesContainer;
    @outlet CPView                  viewNicsContainer;
    @outlet CPWindow                windowXMLEditor;
    @outlet LPMultiLineTextField    fieldStringXMLDesc;
    @outlet TNWindowDriveEdition    windowDriveEdition;
    @outlet TNWindowNicEdition      windowNicEdition;
    @outlet CPTextField             fieldPreferencesMemory;
    @outlet CPPopUpButton           buttonPreferencesNumberOfCPUs;
    @outlet CPPopUpButton           buttonPreferencesBoot;
    @outlet CPPopUpButton           buttonPreferencesVNCKeyMap;
    @outlet CPPopUpButton           buttonPreferencesOnPowerOff;
    @outlet CPPopUpButton           buttonPreferencesOnReboot;
    @outlet CPPopUpButton           buttonPreferencesOnCrash;
    @outlet CPPopUpButton           buttonPreferencesClockOffset;
    @outlet CPPopUpButton           buttonPreferencesInput;
    @outlet TNSwitch                switchPreferencesPAE;
    @outlet TNSwitch                switchPreferencesAPIC;
    @outlet TNSwitch                switchPreferencesACPI;
    @outlet TNSwitch                switchPreferencesHugePages;

    CPButton                        _editButtonDrives;
    CPButton                        _editButtonNics;
    CPButton                        _minusButtonDrives;
    CPButton                        _minusButtonNics;
    CPButton                        _plusButtonDrives;
    CPButton                        _plusButtonNics;
    CPColor                         _bezelColor;
    CPColor                         _buttonBezelHighlighted;
    CPColor                         _buttonBezelSelected;
    CPDictionary                    _supportedCapabilities;
    CPString                        _stringXMLDesc;
    CPTableView                     _tableDrives;
    CPTableView                     _tableNetworkNics;
    TNTableViewDataSource           _drivesDatasource;
    TNTableViewDataSource           _nicsDatasource;
}

- (void)awakeFromCib
{
    var bundle      = [CPBundle bundleForClass:[self class]],
        defaults    = [TNUserDefaults standardUserDefaults];

    // register defaults defaults
    [defaults registerDefaults:[CPDictionary dictionaryWithObjectsAndKeys:
            [bundle objectForInfoDictionaryKey:@"TNDescDefaultNumberCPU"], @"TNDescDefaultNumberCPU",
            [bundle objectForInfoDictionaryKey:@"TNDescDefaultMemory"], @"TNDescDefaultMemory",
            [bundle objectForInfoDictionaryKey:@"TNDescDefaultBoot"], @"TNDescDefaultBoot",
            [bundle objectForInfoDictionaryKey:@"TNDescDefaultVNCKeymap"], @"TNDescDefaultVNCKeymap",
            [bundle objectForInfoDictionaryKey:@"TNDescDefaultOnPowerOff"], @"TNDescDefaultOnPowerOff",
            [bundle objectForInfoDictionaryKey:@"TNDescDefaultOnReboot"], @"TNDescDefaultOnReboot",
            [bundle objectForInfoDictionaryKey:@"TNDescDefaultOnCrash"], @"TNDescDefaultOnCrash",
            [bundle objectForInfoDictionaryKey:@"TNDescDefaultClockOffset"], @"TNDescDefaultClockOffset",
            [bundle objectForInfoDictionaryKey:@"TNDescDefaultPAE"], @"TNDescDefaultPAE",
            [bundle objectForInfoDictionaryKey:@"TNDescDefaultACPI"], @"TNDescDefaultACPI",
            [bundle objectForInfoDictionaryKey:@"TNDescDefaultAPIC"], @"TNDescDefaultAPIC",
            [bundle objectForInfoDictionaryKey:@"TNDescDefaultHugePages"], @"TNDescDefaultHugePages",
            [bundle objectForInfoDictionaryKey:@"TNDescDefaultInputType"], @"TNDescDefaultInputType"
    ]];
    
    
    [fieldJID setSelectable:YES];
    [fieldStringXMLDesc setFont:[CPFont fontWithName:@"Andale Mono, Courier New" size:12]];

    _stringXMLDesc = @"";

    var mainBundle              = [CPBundle mainBundle];
    var centerBezel             = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:"TNButtonBar/buttonBarCenterBezel.png"] size:CGSizeMake(1, 26)];
    var buttonBezel             = [CPColor colorWithPatternImage:centerBezel];
    var centerBezelHighlighted  = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:"TNButtonBar/buttonBarCenterBezelHighlighted.png"] size:CGSizeMake(1, 26)];
    var centerBezelSelected     = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:"TNButtonBar/buttonBarCenterBezelSelected.png"] size:CGSizeMake(1, 26)];

    _bezelColor                 = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:"TNButtonBar/buttonBarBackground.png"] size:CGSizeMake(1, 27)]];
    _buttonBezelHighlighted     = [CPColor colorWithPatternImage:centerBezelHighlighted];
    _buttonBezelSelected        = [CPColor colorWithPatternImage:centerBezelSelected];

    _plusButtonDrives   = [CPButtonBar plusButton];
    _minusButtonDrives  = [CPButtonBar minusButton];
    _editButtonDrives   = [CPButtonBar plusButton];

    [_plusButtonDrives setTarget:self];
    [_plusButtonDrives setAction:@selector(addDrive:)];
    [_minusButtonDrives setTarget:self];
    [_minusButtonDrives setAction:@selector(deleteDrive:)];
    [_editButtonDrives setImage:[[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"button-icons/button-icon-edit.png"] size:CPSizeMake(16, 16)]];
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
    [_editButtonNics setImage:[[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"button-icons/button-icon-edit.png"] size:CPSizeMake(16, 16)]];
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


    // device tabView
    [tabViewDevices setAutoresizingMask:CPViewWidthSizable];
    var tabViewItemDrives = [[CPTabViewItem alloc] initWithIdentifier:@"IDtabViewItemDrives"];
    [tabViewItemDrives setLabel:@"Virtual Medias"];
    [tabViewItemDrives setView:viewDeviceVirtualDrives];
    [tabViewDevices addTabViewItem:tabViewItemDrives];

    var tabViewItemNics = [[CPTabViewItem alloc] initWithIdentifier:@"IDtabViewItemNics"];
    [tabViewItemNics setLabel:@"Virtual Nics"];
    [tabViewItemNics setView:viewDeviceVirtualNics];
    [tabViewDevices addTabViewItem:tabViewItemNics];

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
    [buttonInputType removeAllItems];
    
    [buttonPreferencesNumberOfCPUs removeAllItems];
    [buttonPreferencesBoot removeAllItems];
    [buttonPreferencesVNCKeyMap removeAllItems];
    [buttonPreferencesOnPowerOff removeAllItems];
    [buttonPreferencesOnReboot removeAllItems];
    [buttonPreferencesOnCrash removeAllItems];
    [buttonPreferencesClockOffset removeAllItems];
    [buttonPreferencesInput removeAllItems];
    
    [buttonBoot addItemsWithTitles:TNXMLDescBoots];
    [buttonPreferencesBoot addItemsWithTitles:TNXMLDescBoots];
    
    [buttonNumberCPUs addItemsWithTitles:[@"1", @"2", @"3", @"4"]];
    [buttonPreferencesNumberOfCPUs addItemsWithTitles:[@"1", @"2", @"3", @"4"]];
    
    [buttonVNCKeymap addItemsWithTitles:TNXMLDescVNCKeymaps];
    [buttonPreferencesVNCKeyMap addItemsWithTitles:TNXMLDescVNCKeymaps];
    
    [buttonOnPowerOff addItemsWithTitles:TNXMLDescLifeCycles];
    [buttonPreferencesOnPowerOff addItemsWithTitles:TNXMLDescLifeCycles];
    
    [buttonOnReboot addItemsWithTitles:TNXMLDescLifeCycles];
    [buttonPreferencesOnReboot addItemsWithTitles:TNXMLDescLifeCycles];
    
    [buttonOnCrash addItemsWithTitles:TNXMLDescLifeCycles];
    [buttonPreferencesOnCrash addItemsWithTitles:TNXMLDescLifeCycles];
    
    [buttonClocks addItemsWithTitles:TNXMLDescClocks];
    [buttonPreferencesClockOffset addItemsWithTitles:TNXMLDescClocks];
    
    [buttonInputType addItemsWithTitles:TNXMLDescInputTypes];
    [buttonPreferencesInput addItemsWithTitles:TNXMLDescInputTypes];

    [switchPAE setOn:NO animated:YES sendAction:NO];
    [switchACPI setOn:NO animated:YES sendAction:NO];
    [switchAPIC setOn:NO animated:YES sendAction:NO];

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
    
    // switch
    [switchAPIC setTarget:self];
    [switchAPIC setAction:@selector(defineXML:)];
    [switchACPI setTarget:self];
    [switchACPI setAction:@selector(defineXML:)];
    [switchPAE setTarget:self];
    [switchPAE setAction:@selector(defineXML:)];
    [switchHugePages setTarget:self];
    [switchHugePages setAction:@selector(defineXML:)];
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
    
    // seems to be necessary
    [_tableDrives reloadData];
    [_tableNetworkNics reloadData];
}

- (void)willShow
{
    [super willShow];
    [fieldName setStringValue:[_entity nickname]];
    [fieldJID setStringValue:[_entity JID]];

    [self checkIfRunning];
    
    // seems to be necessary
    [_tableDrives reloadData];
    [_tableNetworkNics reloadData];
    
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

- (void)loadPreferences
{
    var defaults = [TNUserDefaults standardUserDefaults];
    
    [fieldPreferencesMemory setIntValue:[defaults objectForKey:@"TNDescDefaultMemory"]];
    [buttonPreferencesNumberOfCPUs selectItemWithTitle:[defaults objectForKey:@"TNDescDefaultNumberCPU"]];
    [buttonPreferencesBoot selectItemWithTitle:[defaults objectForKey:@"TNDescDefaultBoot"]];
    [buttonPreferencesVNCKeyMap selectItemWithTitle:[defaults objectForKey:@"TNDescDefaultVNCKeymap"]];
    [buttonPreferencesOnPowerOff selectItemWithTitle:[defaults objectForKey:@"TNDescDefaultOnPowerOff"]];
    [buttonPreferencesOnReboot selectItemWithTitle:[defaults objectForKey:@"TNDescDefaultOnReboot"]];
    [buttonPreferencesOnCrash selectItemWithTitle:[defaults objectForKey:@"TNDescDefaultOnCrash"]];
    [buttonPreferencesClockOffset selectItemWithTitle:[defaults objectForKey:@"TNDescDefaultClockOffset"]];
    [buttonPreferencesInput selectItemWithTitle:[defaults objectForKey:@"TNDescDefaultInputType"]];
    [switchPreferencesPAE setOn:[defaults boolForKey:@"TNDescDefaultPAE"] animated:YES sendAction:NO];
    [switchPreferencesACPI setOn:[defaults boolForKey:@"TNDescDefaultACPI"] animated:YES sendAction:NO];
    [switchPreferencesAPIC setOn:[defaults boolForKey:@"TNDescDefaultAPIC"] animated:YES sendAction:NO];
    [switchPreferencesHugePages setOn:[defaults boolForKey:@"TNDescDefaultHugePages"] animated:YES sendAction:NO];
}

- (void)savePreferences
{
    var defaults = [TNUserDefaults standardUserDefaults];
    
    [defaults setObject:[fieldPreferencesMemory intValue] forKey:@"TNDescDefaultMemory"];
    [defaults setObject:[buttonPreferencesNumberOfCPUs title] forKey:@"TNDescDefaultNumberCPU"];
    [defaults setObject:[buttonPreferencesBoot title] forKey:@"TNDescDefaultBoot"];
    [defaults setObject:[buttonPreferencesVNCKeyMap title] forKey:@"TNDescDefaultVNCKeymap"];
    [defaults setObject:[buttonPreferencesOnPowerOff title] forKey:@"TNDescDefaultOnPowerOff"];
    [defaults setObject:[buttonPreferencesOnReboot title] forKey:@"TNDescDefaultOnReboot"];
    [defaults setObject:[buttonPreferencesOnCrash title] forKey:@"TNDescDefaultOnCrash"];
    [defaults setObject:[buttonPreferencesClockOffset title] forKey:@"TNDescDefaultClockOffset"];
    [defaults setObject:[buttonPreferencesInput title] forKey:@"TNDescDefaultInputType"];
    [defaults setBool:[switchPreferencesPAE isOn] forKey:@"TNDescDefaultPAE"];
    [defaults setBool:[switchPreferencesACPI isOn] forKey:@"TNDescDefaultACPI"];
    [defaults setBool:[switchPreferencesAPIC isOn] forKey:@"TNDescDefaultAPIC"];
    [defaults setBool:[switchPreferencesHugePages isOn] forKey:@"TNDescDefaultHugePages"];
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
    var defaults    = [TNUserDefaults standardUserDefaults];
    var cpu     = [defaults integerForKey:@"TNDescDefaultNumberCPU"];
    var mem     = [defaults integerForKey:@"TNDescDefaultMemory"];
    var vnck    = [defaults objectForKey:@"TNDescDefaultVNCKeymap"];
    var opo     = [defaults objectForKey:@"TNDescDefaultOnPowerOff"];
    var or      = [defaults objectForKey:@"TNDescDefaultOnReboot"];
    var oc      = [defaults objectForKey:@"TNDescDefaultOnCrash"];
    var hp      = [defaults boolForKey:@"TNDescDefaultHugePages"];
    var clock   = [defaults objectForKey:@"TNDescDefaultClockOffset"];
    var pae     = [defaults boolForKey:@"TNDescDefaultPAE"];
    var acpi    = [defaults boolForKey:@"TNDescDefaultACPI"];
    var apic    = [defaults boolForKey:@"TNDescDefaultAPIC"];
    var input   = [defaults objectForKey:@"TNDescDefaultInputType"];

    _supportedCapabilities = [CPDictionary dictionary];

    [buttonNumberCPUs selectItemWithTitle:cpu];
    [fieldMemory setStringValue:@""];
    [fieldVNCPassword setStringValue:@""];
    [buttonVNCKeymap selectItemWithTitle:vnck];
    [buttonOnPowerOff selectItemWithTitle:opo];
    [buttonOnReboot selectItemWithTitle:or];
    [buttonOnCrash selectItemWithTitle:oc];
    [buttonClocks selectItemWithTitle:clock];
    [buttonInputType selectItemWithTitle:input];
    [switchPAE setOn:((pae == 1) ? YES : NO) animated:YES sendAction:NO];
    [switchACPI setOn:((acpi == 1) ? YES : NO) animated:YES sendAction:NO];
    [switchAPIC setOn:((apic == 1) ? YES : NO) animated:YES sendAction:NO];
    [switchHugePages setOn:((hp == 1) ? YES : NO) animated:YES sendAction:NO];

    [buttonMachines removeAllItems];
    [buttonHypervisor removeAllItems];
    [buttonArchitecture removeAllItems];
    [buttonOSType removeAllItems];

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

- (BOOL)isHypervisor:(CPString)anHypervisor inList:(CPArray)anArray
{
    return [anArray containsObject:anHypervisor];
}



// XML Capabilities
- (void)getCapabilities
{
    var stanza   = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeVirtualMachineDefinition}];
    [stanza addChildWithName:@"archipel" andAttributes:{
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
                                                                    domainsDict,        @"domains",
                                                                    osType,             @"OSType"];

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

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeVirtualMachineControl}];
    [stanza addChildWithName:@"archipel" andAttributes:{
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
        var input           = [[domain firstChildWithName:@"input"] valueForAttribute:@"type"];
        var capabilities    = [_supportedCapabilities objectForKey:arch];
        var shouldRefresh   = NO;

        //////////////////////////////////////////
        // BASIC SETTINGS
        //////////////////////////////////////////

        // Memory
        [fieldMemory setStringValue:(parseInt(memory) / 1024)];

        // CPUs
        [buttonNumberCPUs selectItemWithTitle:vcpu];

        // button architecture
        [buttonArchitecture removeAllItems];
        [buttonArchitecture addItemsWithTitles:[_supportedCapabilities allKeys]];
        if ([buttonArchitecture indexOfItemWithTitle:arch] == -1)
        {
            [buttonArchitecture selectItemAtIndex:0];
            shouldRefresh = YES;
        }
        else
            [buttonArchitecture selectItemWithTitle:arch];

        // button BOOT
        if ([self isHypervisor:hypervisor inList:[TNXMLDescHypervisorKVM, TNXMLDescHypervisorQemu, TNXMLDescHypervisorKQemu]])
        {
            [buttonBoot setEnabled:YES];

            if (boot == "cdrom")
                [buttonBoot selectItemWithTitle:TNXMLDescBootCDROM];
            else
                [buttonBoot selectItemWithTitle:TNXMLDescBootHardDrive];
        }
        else
        {
            [buttonBoot setEnabled:NO];
        }


        //////////////////////////////////////////
        // LIFECYCLE
        //////////////////////////////////////////

        // power Off
        if (onPowerOff)
            [buttonOnPowerOff selectItemWithTitle:[onPowerOff text]];
        else
            [buttonOnPowerOff selectItemWithTitle:@"Default"];

        // reboot
        if (onReboot)
            [buttonOnReboot selectItemWithTitle:[onReboot text]];
        else
            [buttonOnPowerOff selectItemWithTitle:@"Default"];

        // crash
        if (onCrash)
            [buttonOnCrash selectItemWithTitle:[onCrash text]];
        else
            [buttonOnPowerOff selectItemWithTitle:@"Default"];


        //////////////////////////////////////////
        // CONTROLS
        //////////////////////////////////////////

        if ([self isHypervisor:hypervisor inList:[TNXMLDescHypervisorKVM, TNXMLDescHypervisorQemu, TNXMLDescHypervisorKQemu]])
        {
            [fieldVNCPassword setEnabled:YES];
            [buttonVNCKeymap setEnabled:YES]

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
        }
        else
        {
            [fieldVNCPassword setEnabled:NO];
            [buttonVNCKeymap setEnabled:NO]
        }

        //input type
        if ((hypervisor == TNXMLDescHypervisorKVM)
            || (hypervisor == TNXMLDescHypervisorQemu)
            || (hypervisor == TNXMLDescHypervisorKQemu))
        {
            [buttonInputType setEnabled:YES];
            [buttonInputType selectItemWithTitle:input];
        }
        else
        {
            [buttonInputType setEnabled:NO];
        }


        //////////////////////////////////////////
        // HYPERVISOR
        //////////////////////////////////////////

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

        // button OStype
        [buttonOSType removeAllItems];
        [buttonOSType addItemWithTitle:[capabilities objectForKey:@"OSType"]];


        //////////////////////////////////////////
        // ADVANCED FEATURES
        //////////////////////////////////////////

        // APIC
        [switchAPIC setEnabled:NO];
        [switchAPIC setOn:NO animated:YES sendAction:NO];
        if ([capabilities containsKey:@"APIC"] && [capabilities objectForKey:@"APIC"])
        {
            [switchAPIC setEnabled:YES];

            if (features && [features containsChildrenWithName:TNXMLDescFeatureAPIC])
                [switchAPIC setOn:YES animated:YES sendAction:NO];
        }

        // ACPI
        [switchACPI setEnabled:NO];
        [switchACPI setOn:NO animated:YES sendAction:NO];
        if ([capabilities containsKey:@"ACPI"] && [capabilities objectForKey:@"ACPI"])
        {
            [switchACPI setEnabled:YES];

            if (features && [features containsChildrenWithName:TNXMLDescFeatureACPI])
                [switchACPI setOn:YES animated:YES sendAction:NO];
        }

        // PAE
        [switchPAE setEnabled:NO];
        [switchPAE setOn:NO animated:YES sendAction:NO];

        if ([capabilities containsKey:@"PAE"] && ![capabilities containsKey:@"NONPAE"])
        {
            [switchPAE setOn:YES animated:YES sendAction:NO];
        }
        else if (![capabilities containsKey:@"PAE"] && [capabilities containsKey:@"NONPAE"])
        {
            [switchPAE setOn:NO animated:YES sendAction:NO];
        }
        else if ([capabilities containsKey:@"PAE"] && [capabilities objectForKey:@"PAE"]
            && [capabilities containsKey:@"NONPAE"] && [capabilities objectForKey:@"NONPAE"])
        {
            [switchPAE setEnabled:YES];
            if (features && [features containsChildrenWithName:TNXMLDescFeaturePAE])
                [switchPAE setOn:YES animated:YES sendAction:NO];
        }

        // huge pages
        [switchHugePages setOn:NO animated:YES sendAction:NO];
        if (memoryBacking)
        {
            if ([memoryBacking containsChildrenWithName:@"hugepages"])
                [switchHugePages setOn:YES animated:YES sendAction:NO];
        }

        //clock
        if ([self isHypervisor:hypervisor inList:[TNXMLDescHypervisorKVM, TNXMLDescHypervisorQemu, TNXMLDescHypervisorKQemu, TNXMLDescHypervisorLXC]])
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


        //////////////////////////////////////////
        // MANUAL
        //////////////////////////////////////////

        // field XML
        _stringXMLDesc  = [[aStanza firstChildWithName:@"domain"] stringValue];
        if (_stringXMLDesc)
        {
            _stringXMLDesc      = _stringXMLDesc.replace("\n  \n", "\n");
            _stringXMLDesc      = _stringXMLDesc.replace("xmlns='http://www.gajim.org/xmlns/undeclared' ", "");
            [fieldStringXMLDesc setStringValue:_stringXMLDesc];
        }


        //////////////////////////////////////////
        // DRIVES
        //////////////////////////////////////////
        [_drivesDatasource removeAllObjects];
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


        //////////////////////////////////////////
        // NICS
        //////////////////////////////////////////
        [_nicsDatasource removeAllObjects];
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
        
        // if automatic changes has been done while changing arch, hypervisor etc,
        // redefine virtual machine
        if (shouldRefresh)
            [self defineXML:nil];
    }
    else if ([aStanza type] == @"error")
    {
        if ([[[aStanza firstChildWithName:@"error"] firstChildWithName:@"text"] text] == "not-defined")
        {
            [switchAPIC setEnabled:NO];
            [switchACPI setEnabled:NO];
            [swutchPAE setEnabled:NO];

            [buttonArchitecture removeAllItems];
            [buttonArchitecture addItemsWithTitles:[_supportedCapabilities allKeys]];
            [buttonArchitecture selectItemAtIndex:0];

            var capabilities = [_supportedCapabilities objectForKey:[buttonArchitecture title]];

            [buttonOSType removeAllItems];
            [buttonOSType addItemWithTitle:[capabilities objectForKey:@"OSType"]];
            [buttonOSType selectItemAtIndex:0];


            CPLog.info(capabilities);
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


// XML Auto Definition
- (IBAction)defineXML:(id)sender
{
    var uid             = [_connection getUniqueId];
    var memory          = "" + [fieldMemory intValue] * 1024 + ""; //put it into kb and make a string like a pig
    var arch            = [buttonArchitecture title];
    var machine         = [buttonMachines title];
    var hypervisor      = [buttonHypervisor title];
    var nCPUs           = [buttonNumberCPUs title];
    var boot            = [buttonBoot title];
    var nics            = [_nicsDatasource content];
    var drives          = [_drivesDatasource content];
    var OSType          = [buttonOSType title];
    var VNCKeymap       = [buttonVNCKeymap title];
    var VNCPassword     = [fieldVNCPassword stringValue];

    var capabilities    = [_supportedCapabilities objectForKey:arch];
    var stanza          = [TNStropheStanza iqWithAttributes:{"to": [_entity fullJID], "id": uid, "type": "set"}];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeVirtualMachineDefinition}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeVirtualMachineDefinitionDefine}];

    //////////////////////////////////////////
    // COMMON INFORMATION
    //////////////////////////////////////////

    [stanza addChildWithName:@"domain" andAttributes:{"type": hypervisor}];

    // name
    [stanza addChildWithName:@"name"];
    [stanza addTextNode:[_entity nodeName]];
    [stanza up];

    // uuid
    [stanza addChildWithName:@"uuid"];
    [stanza addTextNode:[_entity nodeName]];
    [stanza up];

    //memory
    [stanza addChildWithName:@"memory"];
    [stanza addTextNode:memory];
    [stanza up];

    // currenrt memory
    [stanza addChildWithName:@"currentMemory"];
    [stanza addTextNode:memory];
    [stanza up];

    if ([switchHugePages isOn])
    {
        [stanza addChildWithName:@"memoryBacking"]
        [stanza addChildWithName:@"hugepages"];
        [stanza up];
        [stanza up];
    }

    // cpu
    [stanza addChildWithName:@"vcpu"];
    [stanza addTextNode:nCPUs];
    [stanza up];

    //////////////////////////////////////////
    // OS PART
    //////////////////////////////////////////
    [stanza addChildWithName:@"os"];

    if ([self isHypervisor:hypervisor inList:[TNXMLDescHypervisorLXC]])
    {
        [stanza addChildWithName:@"type"];
        [stanza addTextNode:OSType];
        [stanza up];

        // TODO
        [stanza addChildWithName:@"init"];
        [stanza addTextNode:@"/bin/sh"];
        [stanza up];
    }
    else
    {
        [stanza addChildWithName:@"type" andAttributes:{"machine": machine, "arch": arch}]
        [stanza addTextNode:OSType];
        [stanza up];

        [stanza addChildWithName:@"boot" andAttributes:{"dev": boot}]
        [stanza up];
        [stanza up];
    }

    //////////////////////////////////////////
    // POWER MANAGEMENT
    //////////////////////////////////////////
    [stanza addChildWithName:@"on_poweroff"];
    [stanza addTextNode:[buttonOnPowerOff title]];
    [stanza up];

    [stanza addChildWithName:@"on_reboot"];
    [stanza addTextNode:[buttonOnReboot title]];
    [stanza up];

    [stanza addChildWithName:@"on_crash"];
    [stanza addTextNode:[buttonOnCrash title]];
    [stanza up];

    //////////////////////////////////////////
    // FEATURES
    //////////////////////////////////////////
    [stanza addChildWithName:@"features"];

    if ([switchPAE isOn])
    {
        [stanza addChildWithName:TNXMLDescFeaturePAE];
        [stanza up];
    }

    if ([switchACPI isOn])
    {
        [stanza addChildWithName:TNXMLDescFeatureACPI];
        [stanza up];
    }

    if ([switchAPIC isOn])
    {
        [stanza addChildWithName:TNXMLDescFeatureAPIC];
        [stanza up];
    }

    [stanza up];

    //Clock
    if ([self isHypervisor:hypervisor inList:[TNXMLDescHypervisorKVM, TNXMLDescHypervisorQemu, TNXMLDescHypervisorKQemu, TNXMLDescHypervisorLXC]])
    {
        [stanza addChildWithName:@"clock" andAttributes:{"offset": [buttonClocks title]}];
        [stanza up];
    }


    //////////////////////////////////////////
    // DEVICES
    //////////////////////////////////////////
    [stanza addChildWithName:@"devices"];

    // emulator
    if ([[[capabilities objectForKey:@"domains"] objectForKey:hypervisor] containsKey:@"emulator"])
    {
        var emulator = [[[capabilities objectForKey:@"domains"] objectForKey:hypervisor] objectForKey:@"emulator"];

        [stanza addChildWithName:@"emulator"];
        [stanza addTextNode:emulator];
        [stanza up];
    }

    // drives
    for (var i = 0; i < [drives count]; i++)
    {
        var drive = [drives objectAtIndex:i];

        [stanza addChildWithName:@"disk" andAttributes:{"device": [drive device], "type": [drive type]}];
        if ([[drive source] uppercaseString].indexOf("QCOW2") != -1) // !!!!!! Argh! FIXME!
        {
            [stanza addChildWithName:@"driver" andAttributes:{"type": "qcow2"}];
            [stanza up];
        }
        if ([drive type] == @"file")
            [stanza addChildWithName:@"source" andAttributes:{"file": [drive source]}];
        else if ([drive type] == @"block")
            [stanza addChildWithName:@"source" andAttributes:{"dev": [drive source]}];

        [stanza up];
        [stanza addChildWithName:@"target" andAttributes:{"bus": [drive bus], "dev": [drive target]}];
        [stanza up];
        [stanza up];
    }

    // nics
    for (var i = 0; i < [nics count]; i++)
    {
        var nic     = [nics objectAtIndex:i];
        var nicType = [nic type];

        [stanza addChildWithName:@"interface" andAttributes:{"type": nicType}];
        [stanza addChildWithName:@"mac" andAttributes:{"address": [nic mac]}];
        [stanza up];

        [stanza addChildWithName:@"model" andAttributes:{"type": [nic model]}];
        [stanza up];

        if (nicType == @"bridge")
            [stanza addChildWithName:@"source" andAttributes:{"bridge": [nic source]}];
        else
            [stanza addChildWithName:@"source" andAttributes:{"network": [nic source]}];

        [stanza up];
        [stanza up];
    }


    //////////////////////////////////////////
    // CONTROLS
    //////////////////////////////////////////
    if ([self isHypervisor:hypervisor inList:[TNXMLDescHypervisorKVM, TNXMLDescHypervisorQemu, TNXMLDescHypervisorKQemu, TNXMLDescHypervisorXen]])
    {
        [stanza addChildWithName:@"input" andAttributes:{"bus": "usb", "type": [buttonInputType title]}];
        [stanza up];

        if ([fieldVNCPassword stringValue] != @"")
        {
            [stanza addChildWithName:@"graphics" andAttributes:{
                "autoport": "yes",
                "type": "vnc",
                "port": "-1",
                "keymap": VNCKeymap,
                "passwd": VNCPassword}];
        }
        else
        {
            [stanza addChildWithName:@"graphics" andAttributes:{
                "autoport": "yes",
                "type": "vnc",
                "port": "-1",
                "keymap": VNCKeymap}];
        }
        [stanza up];
    }

    //devices up
    [stanza up];


    // send stanza
    [_entity sendStanza:stanza andRegisterSelector:@selector(didDefineXML:) ofObject:self withSpecificID:uid];
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


// XML Manual definition
- (IBAction)openXMLEditor:(id)sender
{
    [windowXMLEditor center];
    [windowXMLEditor makeKeyAndOrderFront:sender];

}

- (IBAction)defineXMLString:(id)sender
{
    var desc    = (new DOMParser()).parseFromString(unescape(""+[fieldStringXMLDesc stringValue]+""), "text/xml").getElementsByTagName("domain")[0];
    desc        = document.importNode(desc, true);

    var stanza  = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeVirtualMachineDefinition}];
    [stanza addChildWithName:@"archipel" andAttributes:{"action": TNArchipelTypeVirtualMachineDefinitionDefine}];
    [stanza addNode:desc];

    [self sendStanza:stanza andRegisterSelector:@selector(didDefineXML:)];
    [windowXMLEditor close];
}


// Undeinfition
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

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeVirtualMachineDefinition}];
    [stanza addChildWithName:@"archipel" andAttributes:{"action": TNArchipelTypeVirtualMachineDefinitionUndefine}];

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
    [windowNicEdition makeKeyAndOrderFront:nil];
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



