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

@import "TNDriveObject.j"
@import "TNNetworkInterfaceObject.j"
@import "TNDriveController.j"
@import "TNNetworkController.j"
@import "TNVirtualMachineGuestItem.j"

TNArchipelTypeVirtualMachineControl                 = @"archipel:vm:control";
TNArchipelTypeVirtualMachineDefinition              = @"archipel:vm:definition";

TNArchipelTypeVirtualMachineControlXMLDesc          = @"xmldesc";
TNArchipelTypeVirtualMachineDefinitionDefine        = @"define";
TNArchipelTypeVirtualMachineDefinitionUndefine      = @"undefine";
TNArchipelTypeVirtualMachineDefinitionCapabilities  = @"capabilities";

TNArchipelPushNotificationDefinitition              = @"archipel:push:virtualmachine:definition";

VIR_DOMAIN_NOSTATE          =   0;
VIR_DOMAIN_RUNNING          =   1;
VIR_DOMAIN_BLOCKED          =   2;
VIR_DOMAIN_PAUSED           =   3;
VIR_DOMAIN_SHUTDOWN         =   4;
VIR_DOMAIN_SHUTOFF          =   5;
VIR_DOMAIN_CRASHED          =   6;

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
TNXMLDescVNCKeymapDeutch        = @"de";
TNXMLDescVNCKeymaps             = [TNXMLDescVNCKeymapEN_US, TNXMLDescVNCKeymapFR, TNXMLDescVNCKeymapDeutch];


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

/*! @defgroup virtualmachinedefinition Module VirtualMachine Definition
    @desc Allow to define virtual machines
*/

/*! @ingroup virtualmachinedefinition
    main class of the module
*/
@implementation VirtualMachineDefinitionController : TNModule
{
    @outlet CPButton                buttonAddNic;
    @outlet CPButton                buttonClocks;
    @outlet CPButton                buttonDefine;
    @outlet CPButton                buttonDelNic;
    @outlet CPButton                buttonDomainType;
    @outlet CPButton                buttonOnCrash;
    @outlet CPButton                buttonOnPowerOff;
    @outlet CPButton                buttonOnReboot;
    @outlet CPButton                buttonUndefine;
    @outlet CPButton                buttonXMLEditor;
    @outlet CPButtonBar             buttonBarControlDrives;
    @outlet CPButtonBar             buttonBarControlNics;
    @outlet CPImageView             imageViewDefinitionEdited;
    @outlet CPPopUpButton           buttonBoot;
    @outlet CPPopUpButton           buttonGuests;
    @outlet CPPopUpButton           buttonInputType;
    @outlet CPPopUpButton           buttonMachines;
    @outlet CPPopUpButton           buttonPreferencesBoot;
    @outlet CPPopUpButton           buttonPreferencesClockOffset;
    @outlet CPPopUpButton           buttonPreferencesInput;
    @outlet CPPopUpButton           buttonPreferencesNumberOfCPUs;
    @outlet CPPopUpButton           buttonPreferencesOnCrash;
    @outlet CPPopUpButton           buttonPreferencesOnPowerOff;
    @outlet CPPopUpButton           buttonPreferencesOnReboot;
    @outlet CPPopUpButton           buttonPreferencesVNCKeyMap;
    @outlet CPPopUpButton           buttonVNCKeymap;
    @outlet CPScrollView            scrollViewForDrives;
    @outlet CPScrollView            scrollViewForNics;
    @outlet CPSearchField           fieldFilterDrives;
    @outlet CPSearchField           fieldFilterNics;
    @outlet CPTabView               tabViewDevices;
    @outlet CPTextField             fieldJID;
    @outlet CPTextField             fieldMemory;
    @outlet CPTextField             fieldName;
    @outlet CPTextField             fieldPreferencesDomainType;
    @outlet CPTextField             fieldPreferencesGuest;
    @outlet CPTextField             fieldPreferencesMachine;
    @outlet CPTextField             fieldPreferencesMemory;
    @outlet CPTextField             fieldVNCPassword;
    @outlet CPView                  maskingView;
    @outlet CPView                  viewDeviceVirtualDrives;
    @outlet CPView                  viewDeviceVirtualNics;
    @outlet CPView                  viewDrivesContainer;
    @outlet CPView                  viewNicsContainer;
    @outlet CPWindow                windowXMLEditor;
    @outlet LPMultiLineTextField    fieldStringXMLDesc;
    @outlet TNDriveController       driveController;
    @outlet TNNetworkController     networkController;
    @outlet TNSwitch                switchACPI;
    @outlet TNSwitch                switchAPIC;
    @outlet TNSwitch                switchHugePages;
    @outlet TNSwitch                switchPAE;
    @outlet TNSwitch                switchPreferencesHugePages;
    @outlet TNTextFieldStepper      stepperNumberCPUs;

    BOOL                            _basicDefinitionEdited;
    BOOL                            _definitionRecovered;
    CPButton                        _editButtonDrives;
    CPButton                        _editButtonNics;
    CPButton                        _minusButtonDrives;
    CPButton                        _minusButtonNics;
    CPButton                        _plusButtonDrives;
    CPButton                        _plusButtonNics;
    CPColor                         _bezelColor;
    CPColor                         _buttonBezelHighlighted;
    CPColor                         _buttonBezelSelected;
    CPImage                         _imageDefining;
    CPImage                         _imageEdited;
    CPString                        _stringXMLDesc;
    CPTableView                     _tableDrives;
    CPTableView                     _tableNetworkNics;
    TNTableViewDataSource           _drivesDatasource;
    TNTableViewDataSource           _nicsDatasource;
}


#pragma mark -
#pragma mark Initialization

/*! called at cib awaking
*/
- (void)awakeFromCib
{
    var bundle      = [CPBundle bundleForClass:[self class]],
        defaults    = [CPUserDefaults standardUserDefaults];

    // this really sucks, but something have change in capp that made the textfield not take care of the Atlas defined values;
    [fieldStringXMLDesc setFrameSize:CPSizeMake(591, 378)];

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
            [bundle objectForInfoDictionaryKey:@"TNDescDefaultInputType"], @"TNDescDefaultInputType",
            [bundle objectForInfoDictionaryKey:@"TNDescDefaultDomainType"], @"TNDescDefaultDomainType",
            [bundle objectForInfoDictionaryKey:@"TNDescDefaultGuest"], @"TNDescDefaultGuest",
            [bundle objectForInfoDictionaryKey:@"TNDescDefaultMachine"], @"TNDescDefaultMachine"
    ]];

    [fieldJID setSelectable:YES];
    [fieldStringXMLDesc setFont:[CPFont fontWithName:@"Andale Mono, Courier New" size:12]];

    _stringXMLDesc = @"";

    var mainBundle              = [CPBundle mainBundle],
        centerBezel             = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:"TNButtonBar/buttonBarCenterBezel.png"] size:CGSizeMake(1, 26)],
        buttonBezel             = [CPColor colorWithPatternImage:centerBezel],
        centerBezelHighlighted  = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:"TNButtonBar/buttonBarCenterBezelHighlighted.png"] size:CGSizeMake(1, 26)],
        centerBezelSelected     = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:"TNButtonBar/buttonBarCenterBezelSelected.png"] size:CGSizeMake(1, 26)];

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
    [_editButtonDrives setImage:[[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"IconsButtons/edit.png"] size:CPSizeMake(16, 16)]];
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
    [_editButtonNics setImage:[[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"IconsButtons/edit.png"] size:CPSizeMake(16, 16)]];
    [_editButtonNics setTarget:self];
    [_editButtonNics setAction:@selector(editNetworkCard:)];
    [_minusButtonNics setEnabled:NO];
    [_editButtonNics setEnabled:NO];
    [buttonBarControlNics setButtons:[_plusButtonNics, _minusButtonNics, _editButtonNics]];


    [viewDrivesContainer setBorderedWithHexColor:@"#C0C7D2"];
    [viewNicsContainer setBorderedWithHexColor:@"#C0C7D2"];

    [networkController setDelegate:self];
    [networkController setDelegate:self];

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

    var driveColumnType = [[CPTableColumn alloc] initWithIdentifier:@"type"],
        driveColumnDevice = [[CPTableColumn alloc] initWithIdentifier:@"device"],
        driveColumnTarget = [[CPTableColumn alloc] initWithIdentifier:@"target"],
        driveColumnSource = [[CPTableColumn alloc] initWithIdentifier:@"source"],
        driveColumnBus = [[CPTableColumn alloc] initWithIdentifier:@"bus"];

    [[driveColumnType headerView] setStringValue:@"Type"];
    [driveColumnType setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"type" ascending:YES]];

    [[driveColumnDevice headerView] setStringValue:@"Device"];
    [driveColumnDevice setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"device" ascending:YES]];

    [[driveColumnTarget headerView] setStringValue:@"Target"];
    [driveColumnTarget setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"target" ascending:YES]];

    [driveColumnSource setWidth:300];
    [[driveColumnSource headerView] setStringValue:@"Source"];
    [driveColumnSource setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"source" ascending:YES]];

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

    var columnType = [[CPTableColumn alloc] initWithIdentifier:@"type"],
        columnModel = [[CPTableColumn alloc] initWithIdentifier:@"model"],
        columnMac = [[CPTableColumn alloc] initWithIdentifier:@"mac"],
        columnSource = [[CPTableColumn alloc] initWithIdentifier:@"source"];

    [[columnType headerView] setStringValue:@"Type"];
    [columnType setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"type" ascending:YES]];

    [[columnModel headerView] setStringValue:@"Model"];
    [columnModel setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"model" ascending:YES]];

    [columnMac setWidth:150];
    [[columnMac headerView] setStringValue:@"MAC"];
    [columnMac setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"mac" ascending:YES]];

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
    var tabViewItemDrives = [[CPTabViewItem alloc] initWithIdentifier:@"IDtabViewItemDrives"],
        tabViewItemNics = [[CPTabViewItem alloc] initWithIdentifier:@"IDtabViewItemNics"];

    [tabViewItemDrives setLabel:@"Virtual Medias"];
    [tabViewItemDrives setView:viewDeviceVirtualDrives];
    [tabViewDevices addTabViewItem:tabViewItemDrives];

    [tabViewItemNics setLabel:@"Virtual Nics"];
    [tabViewItemNics setView:viewDeviceVirtualNics];
    [tabViewDevices addTabViewItem:tabViewItemNics];

    // others..
    [buttonBoot removeAllItems];
    [buttonDomainType removeAllItems];
    [buttonVNCKeymap removeAllItems];
    [buttonMachines removeAllItems];
    [buttonOnPowerOff removeAllItems];
    [buttonOnReboot removeAllItems];
    [buttonOnCrash removeAllItems];
    [buttonClocks removeAllItems];
    [buttonInputType removeAllItems];
    [buttonGuests removeAllItems];

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

    var menuNet = [[CPMenu alloc] init],
        menuDrive = [[CPMenu alloc] init];

    [menuNet addItemWithTitle:@"Create new network interface" action:@selector(addNetworkCard:) keyEquivalent:@""];
    [menuNet addItem:[CPMenuItem separatorItem]];
    [menuNet addItemWithTitle:@"Edit" action:@selector(editNetworkCard:) keyEquivalent:@""];
    [menuNet addItemWithTitle:@"Delete" action:@selector(deleteNetworkCard:) keyEquivalent:@""];
    [_tableNetworkNics setMenu:menuNet];

    [menuDrive addItemWithTitle:@"Create new drive" action:@selector(addDrive:) keyEquivalent:@""];
    [menuDrive addItem:[CPMenuItem separatorItem]];
    [menuDrive addItemWithTitle:@"Edit" action:@selector(editDrive:) keyEquivalent:@""];
    [menuDrive addItemWithTitle:@"Delete" action:@selector(deleteDrive:) keyEquivalent:@""];
    [_tableDrives setMenu:menuDrive];

    [fieldVNCPassword setSecure:YES];

    [driveController setTable:_tableDrives];
    [networkController setTable:_tableNetworkNics];

    // switch
    [switchAPIC setTarget:self];
    [switchAPIC setAction:@selector(defineXML:)];
    [switchACPI setTarget:self];
    [switchACPI setAction:@selector(defineXML:)];
    [switchPAE setTarget:self];
    [switchPAE setAction:@selector(defineXML:)];
    [switchHugePages setTarget:self];
    [switchHugePages setAction:@selector(defineXML:)];


    //CPUStepper
    [stepperNumberCPUs setMaxValue:4];
    [stepperNumberCPUs setMinValue:1];
    [stepperNumberCPUs setDoubleValue:1];
    [stepperNumberCPUs setValueWraps:NO];
    [stepperNumberCPUs setAutorepeat:NO];
    [stepperNumberCPUs setTarget:self];
    [stepperNumberCPUs setAction:@selector(performCPUStepperClick:)];

    _imageEdited = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"edited.png"]];
    _imageDefining = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"spinner.gif"]];
    [imageViewDefinitionEdited setImage:_imageEdited];
    [imageViewDefinitionEdited setHidden:YES];
    [buttonDefine setEnabled:NO];
}


#pragma mark -
#pragma mark TNModule overrides

/*! called when module is loaded
*/
- (void)willLoad
{
    [super willLoad];

    _basicDefinitionEdited  = NO;
    _definitionRecovered    = NO;
    [imageViewDefinitionEdited setHidden:YES];
    [imageViewDefinitionEdited setImage:_imageEdited];
    [buttonDefine setEnabled:NO];

    var center = [CPNotificationCenter defaultCenter];

    [center addObserver:self selector:@selector(_didUpdateNickName:) name:TNStropheContactNicknameUpdatedNotification object:_entity];
    [center addObserver:self selector:@selector(_didUpdatePresence:) name:TNStropheContactPresenceUpdatedNotification object:_entity];
    [center addObserver:self selector:@selector(_didBasicDefintionEdit:) name:CPControlTextDidChangeNotification object:fieldMemory];
    [center addObserver:self selector:@selector(_didBasicDefintionEdit:) name:CPControlTextDidChangeNotification object:fieldVNCPassword];

    [self registerSelector:@selector(_didReceivePush:) forPushNotificationType:TNArchipelPushNotificationDefinitition];

    [center postNotificationName:TNArchipelModulesReadyNotification object:self];

    [_tableDrives setDelegate:nil];
    [_tableDrives setDelegate:self];
    [_tableNetworkNics setDelegate:nil];
    [_tableNetworkNics setDelegate:self];

    [driveController setDelegate:nil];
    [driveController setDelegate:self];
    [driveController setEntity:_entity];

    [networkController setDelegate:nil];
    [networkController setDelegate:self];
    [networkController setEntity:_entity];

    [self setDefaultValues];

    [fieldStringXMLDesc setStringValue:@""];

    [self getCapabilities];

    // seems to be necessary
    [_tableDrives reloadData];
    [_tableNetworkNics reloadData];
}

/*! called when module is unloaded
*/
- (void)willUnload
{
    [self setDefaultValues];

    [super willUnload];
}

/*! called when module becomes visible
*/
- (BOOL)willShow
{
    if (![super willShow])
        return NO;

    [fieldName setStringValue:[_entity nickname]];
    [fieldJID setStringValue:[_entity JID]];

    [self checkIfRunning];

    return YES;
}

/*! return YES if module can be hidden
*/
- (BOOL)shouldHide
{
    if (_basicDefinitionEdited)
    {
        var alert = [TNAlert alertWithMessage:@"Unsaved changes"
                                    informative:@"You have made some changes in the virtual machine definition. Would you like save these changes?"
                                     target:self
                                     actions:[["Define", @selector(defineXML:)], ["Cancel", nil]]];
        [alert runModal];
        return NO;
    }

    return YES;
}



/*! called when users saves preferences
*/
- (void)savePreferences
{
    var defaults = [CPUserDefaults standardUserDefaults];

    [defaults setBool:[switchPreferencesHugePages isOn] forKey:@"TNDescDefaultHugePages"];
    [defaults setObject:[buttonPreferencesBoot title] forKey:@"TNDescDefaultBoot"];
    [defaults setObject:[buttonPreferencesClockOffset title] forKey:@"TNDescDefaultClockOffset"];
    [defaults setObject:[buttonPreferencesInput title] forKey:@"TNDescDefaultInputType"];
    [defaults setObject:[buttonPreferencesNumberOfCPUs title] forKey:@"TNDescDefaultNumberCPU"];
    [defaults setObject:[buttonPreferencesOnCrash title] forKey:@"TNDescDefaultOnCrash"];
    [defaults setObject:[buttonPreferencesOnPowerOff title] forKey:@"TNDescDefaultOnPowerOff"];
    [defaults setObject:[buttonPreferencesOnReboot title] forKey:@"TNDescDefaultOnReboot"];
    [defaults setObject:[buttonPreferencesVNCKeyMap title] forKey:@"TNDescDefaultVNCKeymap"];
    [defaults setObject:[fieldPreferencesDomainType stringValue] forKey:@"TNDescDefaultDomainType"];
    [defaults setObject:[fieldPreferencesGuest stringValue] forKey:@"TNDescDefaultGuest"];
    [defaults setObject:[fieldPreferencesMachine stringValue] forKey:@"TNDescDefaultMachine"];
    [defaults setObject:[fieldPreferencesMemory intValue] forKey:@"TNDescDefaultMemory"];
}

/*! called when users gets preferences
*/
- (void)loadPreferences
{
    var defaults = [CPUserDefaults standardUserDefaults];

    [buttonPreferencesBoot selectItemWithTitle:[defaults objectForKey:@"TNDescDefaultBoot"]];
    [buttonPreferencesClockOffset selectItemWithTitle:[defaults objectForKey:@"TNDescDefaultClockOffset"]];
    [buttonPreferencesInput selectItemWithTitle:[defaults objectForKey:@"TNDescDefaultInputType"]];
    [buttonPreferencesNumberOfCPUs selectItemWithTitle:[defaults objectForKey:@"TNDescDefaultNumberCPU"]];
    [buttonPreferencesOnCrash selectItemWithTitle:[defaults objectForKey:@"TNDescDefaultOnCrash"]];
    [buttonPreferencesOnPowerOff selectItemWithTitle:[defaults objectForKey:@"TNDescDefaultOnPowerOff"]];
    [buttonPreferencesOnReboot selectItemWithTitle:[defaults objectForKey:@"TNDescDefaultOnReboot"]];
    [buttonPreferencesVNCKeyMap selectItemWithTitle:[defaults objectForKey:@"TNDescDefaultVNCKeymap"]];
    [fieldPreferencesDomainType setStringValue:[defaults objectForKey:@"TNDescDefaultDomainType"]];
    [fieldPreferencesGuest setStringValue:[defaults objectForKey:@"TNDescDefaultGuest"]];
    [fieldPreferencesMachine setIntValue:[defaults objectForKey:@"TNDescDefaultMachine"]];
    [fieldPreferencesMemory setIntValue:[defaults objectForKey:@"TNDescDefaultMemory"]];
    [switchPreferencesHugePages setOn:[defaults boolForKey:@"TNDescDefaultHugePages"] animated:YES sendAction:NO];
}

/*! called when MainMenu is ready
*/
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

/*! called when permissions changes
*/
- (void)permissionsChanged
{
    [self setControl:buttonBoot enabledAccordingToPermission:@"define"];
    [self setControl:buttonClocks enabledAccordingToPermission:@"define"];
    [self setControl:buttonDomainType enabledAccordingToPermission:@"define"];
    [self setControl:buttonGuests enabledAccordingToPermission:@"define"];
    [self setControl:buttonInputType enabledAccordingToPermission:@"define"];
    [self setControl:buttonMachines enabledAccordingToPermission:@"define"];
    [self setControl:buttonOnCrash enabledAccordingToPermission:@"define"];
    [self setControl:buttonOnPowerOff enabledAccordingToPermission:@"define"];
    [self setControl:buttonOnReboot enabledAccordingToPermission:@"define"];
    [self setControl:buttonUndefine enabledAccordingToPermission:@"undefine"];
    [self setControl:buttonVNCKeymap enabledAccordingToPermission:@"define"];
    [self setControl:buttonXMLEditor enabledAccordingToPermission:@"define"];
    [self setControl:fieldMemory enabledAccordingToPermission:@"define"];
    [self setControl:fieldVNCPassword enabledAccordingToPermission:@"define"];
    [self setControl:stepperNumberCPUs enabledAccordingToPermission:@"define"];
    [self setControl:switchACPI enabledAccordingToPermission:@"define"];
    [self setControl:switchAPIC enabledAccordingToPermission:@"define"];
    [self setControl:switchHugePages enabledAccordingToPermission:@"define"];
    [self setControl:switchPAE enabledAccordingToPermission:@"define"];
    [self setControl:_editButtonDrives enabledAccordingToPermission:@"define"];
    [self setControl:_editButtonNics enabledAccordingToPermission:@"define"];
    [self setControl:_minusButtonDrives enabledAccordingToPermission:@"define"];
    [self setControl:_minusButtonNics enabledAccordingToPermission:@"define"];
    [self setControl:_plusButtonDrives enabledAccordingToPermission:@"define"];
    [self setControl:_plusButtonNics enabledAccordingToPermission:@"define"];


    if (![self currentEntityHasPermission:@"define"])
    {
        [networkController hideWindow:nil];
        [driveController hideWindow:nil];
    }

    [networkController updateAfterPermissionChanged];
    [driveController updateAfterPermissionChanged];
}


#pragma mark -
#pragma mark Notification handlers

/*! called when entity's nickname changes
    @param aNotification the notification
*/
- (void)_didUpdateNickName:(CPNotification)aNotification
{
    if ([aNotification object] == _entity)
    {
       [fieldName setStringValue:[_entity nickname]]
    }
}

/*! called if entity changes it presence
    @param aNotification the notification
*/
- (void)_didUpdatePresence:(CPNotification)aNotification
{
    [self checkIfRunning];
}

/*! called when an Archipel push is received
    @param somePushInfo CPDictionary containing the push information
*/
- (BOOL)_didReceivePush:(CPDictionary)somePushInfo
{
    var sender  = [somePushInfo objectForKey:@"owner"],
        type    = [somePushInfo objectForKey:@"type"],
        change  = [somePushInfo objectForKey:@"change"],
        date    = [somePushInfo objectForKey:@"date"];

    CPLog.info(@"PUSH NOTIFICATION: from: " + sender + ", type: " + type + ", change: " + change);

    [self getXMLDesc];

    return YES;
}

/*! called when a basic definition field has changed
    @param aNotification the notification
*/
- (void)_didBasicDefintionEdit:(CPNotification)aNotification
{
    [self handleDefintionEdition];
}


#pragma mark -
#pragma mark Utilities

/*! handle definition changes
*/
- (void)handleDefintionEdition
{
    if (!_definitionRecovered)
        return;

    _basicDefinitionEdited = YES;
    [imageViewDefinitionEdited setHidden:NO];
    [buttonDefine setEnabled:YES];
}

/*! generate a random Mac address.
    @return CPString containing a random Mac address
*/
- (CPString)generateMacAddr
{
    var hexTab      = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"],
        dA          = "DE",
        dB          = "AD",
        dC          = hexTab[Math.round(Math.random() * 15)] + hexTab[Math.round(Math.random() * 15)],
        dD          = hexTab[Math.round(Math.random() * 15)] + hexTab[Math.round(Math.random() * 15)],
        dE          = hexTab[Math.round(Math.random() * 15)] + hexTab[Math.round(Math.random() * 15)],
        dF          = hexTab[Math.round(Math.random() * 15)] + hexTab[Math.round(Math.random() * 15)];

    return dA + ":" + dB + ":" + dC + ":" + dD + ":" + dE + ":" + dF;
}

/*! set the default value of all widgets
*/
- (void)setDefaultValues
{
    var defaults    = [CPUserDefaults standardUserDefaults],
        cpu         = [defaults integerForKey:@"TNDescDefaultNumberCPU"],
        mem         = [defaults integerForKey:@"TNDescDefaultMemory"],
        vnck        = [defaults objectForKey:@"TNDescDefaultVNCKeymap"],
        opo         = [defaults objectForKey:@"TNDescDefaultOnPowerOff"],
        or          = [defaults objectForKey:@"TNDescDefaultOnReboot"],
        oc          = [defaults objectForKey:@"TNDescDefaultOnCrash"],
        hp          = [defaults boolForKey:@"TNDescDefaultHugePages"],
        clock       = [defaults objectForKey:@"TNDescDefaultClockOffset"],
        pae         = [defaults boolForKey:@"TNDescDefaultPAE"],
        acpi        = [defaults boolForKey:@"TNDescDefaultACPI"],
        apic        = [defaults boolForKey:@"TNDescDefaultAPIC"],
        input       = [defaults objectForKey:@"TNDescDefaultInputType"];

    [stepperNumberCPUs setDoubleValue:cpu];
    [fieldMemory setStringValue:@""];
    [fieldVNCPassword setStringValue:@""];
    [fieldStringXMLDesc setStringValue:@""];
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
    [buttonDomainType removeAllItems];

    [_nicsDatasource removeAllObjects];
    [_drivesDatasource removeAllObjects];
    [_tableNetworkNics reloadData];
    [_tableDrives reloadData];

}

/*! checks if virtual machine is running. if yes, display the masking view
*/
- (void)checkIfRunning
{
    var XMPPShow = [_entity XMPPShow];

    if (XMPPShow != TNStropheContactStatusBusy)
    {
        [self displayMaskingView:YES];
    }
    else
    {
        [self displayMaskingView:NO];
    }
}

/*! display or hide the masking view
    @param shouldDisplay displays if YES, hide if NO
*/
- (void)displayMaskingView:(BOOL)shouldDisplay
{
    if (shouldDisplay)
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

/*! check if given hypervisor is in given list (hum I think this will be throw away...)
    @param anHypervisor an Hypervisor type
    @param anArray an array of string
*/
- (BOOL)isHypervisor:(CPString)anHypervisor inList:(CPArray)anArray
{
    return [anArray containsObject:anHypervisor];
}

/*! return the emulator value of the current selected guest
    @return current emulator
*/
- (CPString)emulatorOfCurrentGuest
{
    var currentGuest        = [[buttonGuests selectedItem] XMLGuest],
        currentDomainType   = [buttonDomainType title],
        defaultEmulator     = [[[currentGuest firstChildWithName:@"arch"] firstChildWithName:@"emulator"] text],
        domains             = [[currentGuest firstChildWithName:@"arch"] childrenWithName:@"domain"];

    for (var i = 0; i < [domains count]; i++)
    {
        var domain = [domains objectAtIndex:i];

        if ([domain valueForAttribute:@"type"] == currentDomainType && [domain containsChildrenWithName:@"emulator"])
            return [[domain firstChildWithName:@"emulator"] text];
    }

    return defaultEmulator;
}

/*! get the domain of the current guest with given type
    @param aType the type of the domain
    @return the TNXMLNode of the domain with given type
*/
- (TNXMLNode)domainOfCurrentGuestWithType:(CPString)aType
{
    var currentSelectedGuest    = [buttonGuests selectedItem],
        capabilities            = [currentSelectedGuest XMLGuest],
        domains                 = [capabilities childrenWithName:@"domain"];

    for (var i = 0; i < [domains count]; i++)
    {
        var domain = [domains objectAtIndex:i];
        if ([domain valueForAttribute:@"type"] == aType)
            return domain
    }

    return nil;
}

/*! return the capabitilies for guest with given type and architecture
    @param aType the guest type
    @param anArch the architecture
    @return TNXMLNode containing the guest
*/
- (TNXMLNode)guestWithType:(CPString)aType architecture:(CPString)anArch
{
    var guests = [buttonGuests itemArray];

    for (var i = 0; i < [guests count]; i++)
    {
        var guest = [[guests objectAtIndex:i] XMLGuest];
        if (([[guest firstChildWithName:@"os_type"] text] == aType)
            && ([[guest firstChildWithName:@"arch"] valueForAttribute:@"name"] == anArch))
            return guest
    }

    return nil;
}

/*! will select the item macthing given type and architecture
    @param aType the guest type
    @param anArch the architecture
*/
- (void)selectGuestWithType:(CPString)aType architecture:(CPString)anArch
{
    var guests = [buttonGuests itemArray];

    for (var i = 0; i < [guests count]; i++)
    {
        var guest = [[guests objectAtIndex:i] XMLGuest];
        if (([[guest firstChildWithName:@"os_type"] text] == aType)
            && ([[guest firstChildWithName:@"arch"] valueForAttribute:@"name"] == anArch))
            [buttonGuests selectItemAtIndex:i];
    }
}

/*! set the value on controls, according to the selected guest
*/
- (void)buildGUIAccordingToCurrentGuest
{
    var currentSelectedGuest    = [buttonGuests selectedItem],
        capabilities            = [currentSelectedGuest XMLGuest],
        domains                 = [capabilities childrenWithName:@"domain"];

    if (domains && [domains count] > 0)
    {
        [buttonDomainType setEnabled:NO];
        [buttonDomainType removeAllItems];

        for (var i = 0; i < [domains count]; i++)
        {
            var domain = [domains objectAtIndex:i];
            [buttonDomainType addItemWithTitle:[domain valueForAttribute:@"type"]];
        }

        var defaultDomainType = [[CPUserDefaults standardUserDefaults] objectForKey:@"TNDescDefaultDomainType"];
        if (defaultDomainType)
            [buttonDomainType selectItemWithTitle:defaultDomainType];
        else
            [buttonDomainType selectItemAtIndex:0];
        [self setControl:buttonDomainType enabledAccordingToPermission:@"define"];
        [buttonDomainType setEnabled:YES];

        [buttonMachines setEnabled:NO];
        [buttonMachines removeAllItems];

        [self updateMachinesAccordingToDomainType:nil];
    }

    if ([capabilities containsChildrenWithName:@"features"])
    {
        var features = [capabilities firstChildWithName:@"features"];

        [switchPAE setEnabled:NO];
        if ([features containsChildrenWithName:@"nonpae"] && [features containsChildrenWithName:@"pae"])
            [switchPAE setEnabled:YES];
        if (![features containsChildrenWithName:@"nonpae"] && [features containsChildrenWithName:@"pae"])
            [switchPAE setOn:YES animated:NO sendAction:NO];
        if ([features containsChildrenWithName:@"nonpae"] && ![features containsChildrenWithName:@"pae"])
            [switchPAE setOn:NO animated:NO sendAction:NO];

        [switchACPI setEnabled:NO];
        if ([features containsChildrenWithName:@"acpi"])
        {
            var on = [[features firstChildWithName:@"acpi"] valueForAttribute:@"default"] == "on" ? YES : NO,
                toggle = [[features firstChildWithName:@"acpi"] valueForAttribute:@"toggle"] == "yes" ? YES : NO;

            if (toggle)
                [switchACPI setEnabled:YES];

            [switchACPI setOn:on animated:NO sendAction:NO];
        }

        [switchAPIC setEnabled:NO];
        if ([features containsChildrenWithName:@"apic"])
        {
            var on = [[features firstChildWithName:@"apic"] valueForAttribute:@"default"] == "on" ? YES : NO,
                toggle = [[features firstChildWithName:@"apic"] valueForAttribute:@"toggle"] == "yes" ? YES : NO;

            if (toggle)
                [switchAPIC setEnabled:YES];

            [switchAPIC setOn:on animated:NO sendAction:NO];
        }
    }

}


#pragma mark -
#pragma mark Actions

/*! open the manual XML editor
    @param sender the sender of the action
*/
- (IBAction)openXMLEditor:(id)aSender
{
    [windowXMLEditor center];
    [windowXMLEditor makeKeyAndOrderFront:aSender];
}

/*! make the definition set as edited
    @param sender the sender of the action
*/
- (IBAction)makeDefinitionEdited:(id)aSender
{
    [self handleDefintionEdition];
}

/*! define XML
    @param sender the sender of the action
*/
- (IBAction)defineXML:(id)aSender
{
    [self defineXML];
}

/*! define XML from the manual editor
    @param sender the sender of the action
*/
- (IBAction)defineXMLString:(id)aSender
{
    [self defineXMLString];
}

/*! undefine virtual machine
    @param sender the sender of the action
*/
- (IBAction)undefineXML:(id)aSender
{
    [self undefineXML];
}

/*! add a network card
    @param sender the sender of the action
*/
- (IBAction)addNetworkCard:(id)aSender
{
    var defaultNic = [TNNetworkInterface networkInterfaceWithType:@"bridge" model:@"pcnet" mac:[self generateMacAddr] source:@"virbr0"];

    [_nicsDatasource addObject:defaultNic];
    [_tableNetworkNics reloadData];
    [self defineXML];
}

/*! open the network editor
    @param sender the sender of the action
*/
- (IBAction)editNetworkCard:(id)aSender
{
    if (![self currentEntityHasPermission:@"define"])
        return;

    if ([[_tableNetworkNics selectedRowIndexes] count] != 1)
    {
         [self addNetworkCard:aSender];
         return;
    }
    var selectedIndex   = [[_tableNetworkNics selectedRowIndexes] firstIndex],
        nicObject       = [_nicsDatasource objectAtIndex:selectedIndex];

    [networkController setNic:nicObject];
    [networkController showWindow:aSender];
}

/*! delete a network card
    @param sender the sender of the action
*/
- (IBAction)deleteNetworkCard:(id)aSender
{
    if (![self currentEntityHasPermission:@"define"])
        return;

    if ([_tableNetworkNics numberOfSelectedRows] <= 0)
    {
         [TNAlert showAlertWithMessage:@"Error" informative:@"You must select a network interface"];
         return;
    }

     var selectedIndexes = [_tableNetworkNics selectedRowIndexes];

     [_nicsDatasource removeObjectsAtIndexes:selectedIndexes];

     [_tableNetworkNics reloadData];
     [_tableNetworkNics deselectAll];
     [self defineXML];
}

/*! add a drive
    @param sender the sender of the action
*/
- (IBAction)addDrive:(id)aSender
{
    if (![self currentEntityHasPermission:@"define"])
        return;

    var defaultDrive = [TNDrive driveWithType:@"file" device:@"disk" source:"/drives/drive.img" target:@"hda" bus:@"ide"];

    [_drivesDatasource addObject:defaultDrive];
    [_tableDrives reloadData];
    [self defineXML];
}

/*! open the drive editor
    @param sender the sender of the action
*/
- (IBAction)editDrive:(id)aSender
{
    if (![self currentEntityHasPermission:@"define"])
        return;

    if ([[_tableDrives selectedRowIndexes] count] != 1)
    {
         [self addDrive:aSender];
         return;
    }

    var selectedIndex   = [[_tableDrives selectedRowIndexes] firstIndex],
        driveObject     = [_drivesDatasource objectAtIndex:selectedIndex];

    [driveController setDrive:driveObject];
    [driveController showWindow:aSender];
}

/*! delete a drive
    @param sender the sender of the action
*/
- (IBAction)deleteDrive:(id)aSender
{
    if (![self currentEntityHasPermission:@"define"])
        return;

    if ([_tableDrives numberOfSelectedRows] <= 0)
    {
        [TNAlert showAlertWithMessage:@"Error" informative:@"You must select a drive"];
        return;
    }

     var selectedIndexes = [_tableDrives selectedRowIndexes];

     [_drivesDatasource removeObjectsAtIndexes:selectedIndexes];

     [_tableDrives reloadData];
     [_tableDrives deselectAll];
     [self defineXML];
}

/*! perpare the interface according to the selected guest
    @param aSender the sender of the action
*/
- (IBAction)buildGUIAccordingToCurrentGuest:(id)aSender
{
    [self buildGUIAccordingToCurrentGuest]
}

- (IBAction)updateMachinesAccordingToDomainType:(id)aSender
{
    var currentSelectedGuest    = [buttonGuests selectedItem],
        capabilities            = [currentSelectedGuest XMLGuest],
        currentDomain           = [self domainOfCurrentGuestWithType:[buttonDomainType title]],
        machines                = [currentDomain childrenWithName:@"machine"];

    [buttonMachines removeAllItems];
    [self setControl:buttonMachines enabledAccordingToPermission:@"define"];

    for (var i = 0; i < [machines count]; i++)
    {
        var machine = [machines objectAtIndex:i];
        [buttonMachines addItemWithTitle:[machine text]];
    }

    if ([[buttonMachines itemArray] count] == 0)
    {
        var defaultMachines = [[capabilities firstChildWithName:@"arch"] childrenWithName:@"machine"];
        for (var i = 0; i < [defaultMachines count]; i++)
        {
            var machine = [defaultMachines objectAtIndex:i];
            [buttonMachines addItemWithTitle:[machine text]];
        }
    }

    if ([[buttonMachines itemArray] count] == 0)
        [buttonMachines setEnabled:NO];

    var defaultMachine = [[CPUserDefaults standardUserDefaults] objectForKey:@"TNDescDefaultMachine"];
    if (defaultMachine)
        [buttonMachines selectItemWithTitle:defaultMachine];
    else
        [buttonMachines selectItemAtIndex:0];

    [self handleDefintionEdition];
}


#pragma mark -
#pragma mark XMPP Controls

/*! ask hypervisor for its capabilities
*/
- (void)getCapabilities
{
    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeVirtualMachineDefinition}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeVirtualMachineDefinitionCapabilities}];

    [_entity sendStanza:stanza andRegisterSelector:@selector(_didReceiveXMLCapabilities:) ofObject:self];
}

/*! compute hypervisor capabilities
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)_didReceiveXMLCapabilities:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        [buttonGuests removeAllItems];

        var host = [aStanza firstChildWithName:@"host"],
            guests = [aStanza childrenWithName:@"guest"],
            supportedCapabilities = [CPDictionary dictionary];

        if ([guests count] == 0)
        {
            [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Capabilities" message:@"Your hypervisor have not pushed any guest support. For some reason, you can't create domains. Sorry." icon:TNGrowlIconError];
            [self displayMaskingView:YES];
        }

        [supportedCapabilities setObject:host forKey:@"host"];
        [supportedCapabilities setObject:[CPArray array] forKey:@"guests"];

        for (var i = 0; i < [guests count]; i++)
        {
            var guestItem   = [[TNVirtualMachineGuestItem alloc] init],
                guest       = [guests objectAtIndex:i],
                osType      = [[guest firstChildWithName:@"os_type"] text],
                arch        = [[guest firstChildWithName:@"arch"] valueForAttribute:@"name"];

            [guestItem setXMLGuest:guest];
            [guestItem setTitle:osType + @" (" + arch + @")"];
            [buttonGuests addItem:guestItem];

            [[supportedCapabilities objectForKey:@"guests"] addObject:guest];
        }

        var defaultGuest = [[CPUserDefaults standardUserDefaults] objectForKey:@"TNDescDefaultGuest"];
        if (defaultGuest)
            [buttonGuests selectItemWithTitle:defaultGuest];

        CPLog.trace(supportedCapabilities);
        [self getXMLDesc];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}


/*! ask hypervisor for its description
*/
- (void)getXMLDesc
{
    var stanza   = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeVirtualMachineControl}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeVirtualMachineControlXMLDesc}];

    [_entity sendStanza:stanza andRegisterSelector:@selector(_didReceiveXMLDesc:) ofObject:self];
}

/*! compute hypervisor description
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)_didReceiveXMLDesc:(TNStropheStanza)aStanza
{
    var defaults = [CPUserDefaults standardUserDefaults];

    if ([aStanza type] == @"error")
    {
        if ([[[aStanza firstChildWithName:@"error"] firstChildWithName:@"text"] text] != "not-defined")
            [self handleIqErrorFromStanza:aStanza];

        [self buildGUIAccordingToCurrentGuest];
        return;
    }

    var domain          = [aStanza firstChildWithName:@"domain"],
        hypervisor      = [domain valueForAttribute:@"type"],
        memory          = [[domain firstChildWithName:@"currentMemory"] text],
        memoryBacking   = [domain firstChildWithName:@"memoryBacking"],
        type            = [[[domain firstChildWithName:@"os"] firstChildWithName:@"type"] text],
        arch            = [[[domain firstChildWithName:@"os"] firstChildWithName:@"type"] valueForAttribute:@"arch"],
        machine         = [[[domain firstChildWithName:@"os"] firstChildWithName:@"type"] valueForAttribute:@"machine"],
        vcpu            = [[domain firstChildWithName:@"vcpu"] text],
        boot            = [[domain firstChildWithName:@"boot"] valueForAttribute:@"dev"],
        interfaces      = [domain childrenWithName:@"interface"],
        disks           = [domain childrenWithName:@"disk"],
        graphics        = [domain childrenWithName:@"graphics"],
        onPowerOff      = [domain firstChildWithName:@"on_poweroff"],
        onReboot        = [domain firstChildWithName:@"on_reboot"],
        onCrash         = [domain firstChildWithName:@"on_crash"],
        features        = [domain firstChildWithName:@"features"],
        clock           = [domain firstChildWithName:@"clock"],
        input           = [[domain firstChildWithName:@"input"] valueForAttribute:@"type"],
        capabilities    = [self guestWithType:type architecture:arch];

    [self selectGuestWithType:type architecture:arch];
    [self buildGUIAccordingToCurrentGuest];


    // BASIC SETTINGS

    // button domainType
    [buttonDomainType selectItemWithTitle:hypervisor];

    // button Machine
    [self updateMachinesAccordingToDomainType:nil];
    if (machine && machine != "")
        [buttonMachines selectItemWithTitle:machine];

    // Memory
    [fieldMemory setStringValue:(parseInt(memory) / 1024)];

    // CPUs
    [stepperNumberCPUs setDoubleValue:[vcpu intValue]];

    // button BOOT
    if ([self isHypervisor:hypervisor inList:[TNXMLDescHypervisorKVM, TNXMLDescHypervisorQemu, TNXMLDescHypervisorKQemu]])
    {
        [self setControl:buttonBoot enabledAccordingToPermission:@"define"];

        if (boot == "cdrom")
            [buttonBoot selectItemWithTitle:TNXMLDescBootCDROM];
        else
            [buttonBoot selectItemWithTitle:TNXMLDescBootHardDrive];
    }
    else
    {
        [self setControl:buttonBoot enabledAccordingToPermission:@"define"];
    }


    // LIFECYCLE

    // power Off
    if (onPowerOff)
        [buttonOnPowerOff selectItemWithTitle:[onPowerOff text]];
    else
        [buttonOnPowerOff selectItemWithTitle:@"Destroy"];

    // reboot
    if (onReboot)
        [buttonOnReboot selectItemWithTitle:[onReboot text]];
    else
        [buttonOnPowerOff selectItemWithTitle:@"Reboot"];

    // crash
    if (onCrash)
        [buttonOnCrash selectItemWithTitle:[onCrash text]];
    else
        [buttonOnPowerOff selectItemWithTitle:@"Reboot"];


    // CONTROLS

    // graphics
    if ([self isHypervisor:hypervisor inList:[TNXMLDescHypervisorKVM, TNXMLDescHypervisorQemu, TNXMLDescHypervisorKQemu]])
    {
        [self setControl:fieldVNCPassword enabledAccordingToPermission:@"define"];
        [self setControl:buttonVNCKeymap enabledAccordingToPermission:@"define"];

        for (var i = 0; i < [graphics count]; i++)
        {
            var graphic = [graphics objectAtIndex:i];

            if ([graphic valueForAttribute:@"type"] == "vnc")
            {
                var keymap = [graphic valueForAttribute:@"keymap"],
                    passwd = [graphic valueForAttribute:@"passwd"];

                if (keymap)
                    [buttonVNCKeymap selectItemWithTitle:keymap];
                if (passwd)
                    [fieldVNCPassword setStringValue:passwd];
            }
        }
    }
    else
    {
        [fieldVNCPassword setEnabled:NO];
        [buttonVNCKeymap setEnabled:NO];
    }

    //input type
    if ([self isHypervisor:hypervisor inList:[TNXMLDescHypervisorKVM, TNXMLDescHypervisorQemu, TNXMLDescHypervisorKQemu]])
    {
        [self setControl:buttonInputType enabledAccordingToPermission:@"define"];

        [buttonInputType selectItemWithTitle:input];
    }
    else
    {
        [buttonInputType setEnabled:NO];
    }


    // ADVANCED FEATURES

    // APIC
    if ([features containsChildrenWithName:@"apic"])
        [switchAPIC setOn:YES animated:NO sendAction:NO];

    // ACPI
    if ([features containsChildrenWithName:@"acpi"])
        [switchACPI setOn:YES animated:YES sendAction:NO];

    // PAE
    if ([features containsChildrenWithName:@"pae"])
        [switchPAE setOn:NO animated:YES sendAction:NO];

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
        [self setControl:buttonClocks enabledAccordingToPermission:@"define"];

        if (clock)
            [buttonClocks selectItemWithTitle:[clock valueForAttribute:@"offset"]];
    }
    else
        [buttonClocks setEnabled:NO];


    // MANUAL

    // field XML
    _stringXMLDesc  = [[aStanza firstChildWithName:@"domain"] stringValue];
    [fieldStringXMLDesc setStringValue:@""];
    if (_stringXMLDesc)
    {
        _stringXMLDesc  = _stringXMLDesc.replace("\n  \n", "\n");
        _stringXMLDesc  = _stringXMLDesc.replace("xmlns='http://www.gajim.org/xmlns/undeclared' ", "");
        [fieldStringXMLDesc setStringValue:_stringXMLDesc];
    }


    // DRIVES

    [_drivesDatasource removeAllObjects];
    for (var i = 0; i < [disks count]; i++)
    {
        var currentDisk = [disks objectAtIndex:i],
            iType       = [currentDisk valueForAttribute:@"type"],
            iDevice     = [currentDisk valueForAttribute:@"device"],
            iTarget     = [[currentDisk firstChildWithName:@"target"] valueForAttribute:@"dev"],
            iBus        = [[currentDisk firstChildWithName:@"target"] valueForAttribute:@"bus"],
            iSource     = (iType == @"file") ? [[currentDisk firstChildWithName:@"source"] valueForAttribute:@"file"] : [[currentDisk firstChildWithName:@"source"] valueForAttribute:@"dev"],
            newDrive    =  [TNDrive driveWithType:iType device:iDevice source:iSource target:iTarget bus:iBus];

        [_drivesDatasource addObject:newDrive];
    }

    [_tableDrives reloadData];

    // THE dirty temporary solution
    setTimeout(function(){[_tableDrives setNeedsLayout]; [_tableDrives setNeedsDisplay:YES]}, 1000);


    // NICS
    [_nicsDatasource removeAllObjects];
    for (var i = 0; i < [interfaces count]; i++)
    {
        var currentInterface    = [interfaces objectAtIndex:i],
            iType               = [currentInterface valueForAttribute:@"type"],
            iModel              = ([currentInterface firstChildWithName:@"model"]) ? [[currentInterface firstChildWithName:@"model"] valueForAttribute:@"type"] : @"pcnet",
            iMac                = [[currentInterface firstChildWithName:@"mac"] valueForAttribute:@"address"],
            iSource             = (iType == "bridge") ? [[currentInterface firstChildWithName:@"source"] valueForAttribute:@"bridge"] : [[currentInterface firstChildWithName:@"source"] valueForAttribute:@"network"],
            newNic              = [TNNetworkInterface networkInterfaceWithType:iType model:iModel mac:iMac source:iSource];

        [_nicsDatasource addObject:newNic];
    }

    [_tableNetworkNics reloadData];

    _definitionRecovered = YES;

    return NO;
}

/*! ask hypervisor to define XML
*/
- (void)defineXML
{
    var uid             = [[[TNStropheIMClient defaultClient] connection] getUniqueId],
        capabilities    = [[buttonGuests selectedItem] XMLGuest],
        memory          = "" + [fieldMemory intValue] * 1024 + "",
        arch            = [[capabilities firstChildWithName:@"arch"] valueForAttribute:@"name"],
        machine         = [buttonMachines title],
        hypervisor      = [buttonDomainType title],
        nCPUs           = [stepperNumberCPUs doubleValue],
        boot            = [buttonBoot title],
        nics            = [_nicsDatasource content],
        drives          = [_drivesDatasource content],
        OSType          = [[capabilities firstChildWithName:@"os_type"] text],
        VNCKeymap       = [buttonVNCKeymap title],
        VNCPassword     = [fieldVNCPassword stringValue],
        stanza          = [TNStropheStanza iqWithAttributes:{"to": [[_entity JID] full], "id": uid, "type": "set"}];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeVirtualMachineDefinition}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeVirtualMachineDefinitionDefine}];

    // COMMON INFORMATION

    [stanza addChildWithName:@"domain" andAttributes:{"type": hypervisor}];

    // name
    [stanza addChildWithName:@"name"];
    [stanza addTextNode:[[_entity JID] node]];
    [stanza up];

    // uuid
    [stanza addChildWithName:@"uuid"];
    [stanza addTextNode:[[_entity JID] node]];
    [stanza up];

    //memory
    [stanza addChildWithName:@"memory"];
    [stanza addTextNode:memory];
    [stanza up];

    // current memory
    [stanza addChildWithName:@"currentMemory"];
    [stanza addTextNode:memory];
    [stanza up];

    // huge pages
    if ([switchHugePages isOn])
    {
        [stanza addChildWithName:@"memoryBacking"]
        [stanza addChildWithName:@"hugepages"];
        [stanza up];
        [stanza up];
    }

    // cpu
    [stanza addChildWithName:@"vcpu"];
    [stanza addTextNode:@"" + nCPUs + @""];
    [stanza up];


    // OS PART

    [stanza addChildWithName:@"os"];

    switch (hypervisor)
    {
        case TNXMLDescHypervisorLXC:
            [stanza addChildWithName:@"type"];
            [stanza addTextNode:OSType];
            [stanza up];

            // TODO
            [stanza addChildWithName:@"init"];
            [stanza addTextNode:@"/bin/sh"];
            [stanza up];
            break;

        case TNXMLDescHypervisorXen:
            if (machine && machine != "")
                [stanza addChildWithName:@"type" andAttributes:{"machine": machine, "arch": arch}];
            else
                [stanza addChildWithName:@"type" andAttributes:{"arch": arch}];

            [stanza addTextNode:(OSType == "hvm" ? OSType : @"linux")]; // TODO: improve this
            [stanza up];

            // loader
            if ([[capabilities firstChildWithName:@"arch"] containsChildrenWithName:@"loader"])
            {
                [stanza addChildWithName:@"loader"];
                [stanza addTextNode:[[[capabilities firstChildWithName:@"arch"] firstChildWithName:@"loader"] text]]
                [stanza up];
            }

            [stanza addChildWithName:@"boot" andAttributes:{"dev": boot}]
            [stanza up];
            break;

        default:
            if (machine && machine != "")
                [stanza addChildWithName:@"type" andAttributes:{"machine": machine, "arch": arch}];
            else
                [stanza addChildWithName:@"type" andAttributes:{"arch": arch}];
            [stanza addTextNode:OSType];
            [stanza up];

            [stanza addChildWithName:@"boot" andAttributes:{"dev": boot}]
            [stanza up];
            break;
    }
    [stanza up];


    // POWER MANAGEMENT

    [stanza addChildWithName:@"on_poweroff"];
    [stanza addTextNode:[buttonOnPowerOff title]];
    [stanza up];

    [stanza addChildWithName:@"on_reboot"];
    [stanza addTextNode:[buttonOnReboot title]];
    [stanza up];

    [stanza addChildWithName:@"on_crash"];
    [stanza addTextNode:[buttonOnCrash title]];
    [stanza up];


    // FEATURES

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


    // DEVICES

    [stanza addChildWithName:@"devices"];

    // emulator
    var emulator = [self emulatorOfCurrentGuest];
    if (emulator)
    {
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
        var nic     = [nics objectAtIndex:i],
            nicType = [nic type];

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


    // CONTROLS

    if ([self isHypervisor:hypervisor inList:[TNXMLDescHypervisorKVM, TNXMLDescHypervisorQemu, TNXMLDescHypervisorKQemu]])
    {
        if (![self isHypervisor:hypervisor inList:[TNXMLDescHypervisorXen]])
        {
            [stanza addChildWithName:@"input" andAttributes:{"bus": @"usb", "type": [buttonInputType title]}];
            [stanza up];
        }

        if ([fieldVNCPassword stringValue] != @"")
        {
            [stanza addChildWithName:@"graphics" andAttributes:{
                "autoport": "yes",
                "type": "vnc",
                "port": "-1",
                "keymap": VNCKeymap,
                "passwd": VNCPassword}];
            [stanza up];
        }
        else
        {
            [stanza addChildWithName:@"graphics" andAttributes:{
                "autoport": "yes",
                "type": "vnc",
                "port": "-1",
                "keymap": VNCKeymap}];
            [stanza up];
        }
    }

    //devices up
    [stanza up];

    // send stanza
    [imageViewDefinitionEdited setImage:_imageDefining];
    [_entity sendStanza:stanza andRegisterSelector:@selector(_didDefineXML:) ofObject:self withSpecificID:uid];
}

/*! ask hypervisor to define XML from string
*/
- (void)defineXMLString
{
    var desc        = (new DOMParser()).parseFromString(unescape(""+[fieldStringXMLDesc stringValue]+""), "text/xml").getElementsByTagName("domain")[0],
        stanza      = [TNStropheStanza iqWithType:@"get"],
        descNode    = [TNXMLNode nodeWithXMLNode:desc];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeVirtualMachineDefinition}];
    [stanza addChildWithName:@"archipel" andAttributes:{"action": TNArchipelTypeVirtualMachineDefinitionDefine}];
    [stanza addNode:descNode];

    [imageViewDefinitionEdited setImage:_imageDefining];
    [self sendStanza:stanza andRegisterSelector:@selector(_didDefineXML:)];
    [windowXMLEditor close];
}

/*! compute hypervisor answer about the definition
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)_didDefineXML:(TNStropheStanza)aStanza
{
    var responseType    = [aStanza type],
        responseFrom    = [aStanza from];

    if (responseType == @"result")
    {
        CPLog.info(@"Definition of virtual machine " + [_entity nickname] + " sucessfuly updated")
        _basicDefinitionEdited  = NO;
        _definitionRecovered    = NO;
        [imageViewDefinitionEdited setHidden:YES];
        [imageViewDefinitionEdited setImage:_imageEdited];
        [buttonDefine setEnabled:NO];
    }
    else if (responseType == @"error")
    {
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}

/*! ask hypervisor to undefine virtual machine. but before ask for a confirmation
*/
- (void)undefineXML
{
        var alert = [TNAlert alertWithMessage:@"Are you sure you want to undefine this virtual machine ?"
                                informative:@"All your changes will be definitly lost."
                                     target:self
                                     actions:[["Undefine", @selector(performUndefineXML:)], ["Cancel", nil]]];
        [alert runModal];
}

/*! ask hypervisor to undefine virtual machine
*/
- (void)performUndefineXML:(id)someUserInfo
{
    var stanza   = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeVirtualMachineDefinition}];
    [stanza addChildWithName:@"archipel" andAttributes:{"action": TNArchipelTypeVirtualMachineDefinitionUndefine}];

    [_entity sendStanza:stanza andRegisterSelector:@selector(didUndefineXML:) ofObject:self];
}

/*! compute hypervisor answer about the undefinition
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)didUndefineXML:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Virtual machine" message:@"Virtual machine has been undefined"];
        [self setDefaultValues];
        [self getXMLDesc];
    }
    else if ([aStanza type] == @"error")
    {
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}


#pragma mark -
#pragma mark Delegates

/*! table view delegate
*/
- (void)tableViewSelectionDidChange:(CPNotification)aNotification
{
    [_minusButtonDrives setEnabled:NO];
    [_editButtonDrives setEnabled:NO];

    if ([aNotification object] == _tableDrives)
    {
        if ([[aNotification object] numberOfSelectedRows] > 0)
        {
            [self setControl:_minusButtonDrives enabledAccordingToPermission:@"define"];
            [self setControl:_editButtonDrives enabledAccordingToPermission:@"define"];
        }
    }
    else if ([aNotification object] == _tableNetworkNics)
    {
        if ([[aNotification object] numberOfSelectedRows] > 0)
        {
            [self setControl:_minusButtonDrives enabledAccordingToPermission:@"define"];
            [self setControl:_editButtonDrives enabledAccordingToPermission:@"define"];
        }
    }
}

@end