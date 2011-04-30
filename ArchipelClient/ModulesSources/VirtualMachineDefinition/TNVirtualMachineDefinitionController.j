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
@import <AppKit/CPColor.j>
@import <AppKit/CPImage.j>
@import <AppKit/CPPopUpButton.j>
@import <AppKit/CPSearchField.j>
@import <AppKit/CPTableView.j>
@import <AppKit/CPTabView.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPView.j>
@import <AppKit/CPWindow.j>

@import <LPKit/LPMultiLineTextField.j>
@import <TNKit/TNAlert.j>
@import <TNKit/TNTableViewDataSource.j>
@import <TNKit/TNTextFieldStepper.j>
@import <TNKit/TNUIKitScrollView.j>

@import "TNDriveObject.j"
@import "TNNetworkInterfaceObject.j"
@import "TNDriveController.j"
@import "TNNetworkController.j"
@import "TNVirtualMachineGuestItem.j"



var TNArchipelTypeVirtualMachineControl                 = @"archipel:vm:control",
    TNArchipelTypeVirtualMachineDefinition              = @"archipel:vm:definition",
    TNArchipelTypeVirtualMachineControlXMLDesc          = @"xmldesc",
    TNArchipelTypeVirtualMachineDefinitionDefine        = @"define",
    TNArchipelTypeVirtualMachineDefinitionUndefine      = @"undefine",
    TNArchipelTypeVirtualMachineDefinitionCapabilities  = @"capabilities",
    TNArchipelPushNotificationDefinitition              = @"archipel:push:virtualmachine:definition",
    VIR_DOMAIN_NOSTATE                                  =   0,
    VIR_DOMAIN_RUNNING                                  =   1,
    VIR_DOMAIN_BLOCKED                                  =   2,
    VIR_DOMAIN_PAUSED                                   =   3,
    VIR_DOMAIN_SHUTDOWN                                 =   4,
    VIR_DOMAIN_SHUTOFF                                  =   5,
    VIR_DOMAIN_CRASHED                                  =   6,
    TNXMLDescBootHardDrive                              = @"hd",
    TNXMLDescBootCDROM                                  = @"cdrom",
    TNXMLDescBootNetwork                                = @"network",
    TNXMLDescBootFileDescriptor                         = @"fd",
    TNXMLDescBoots                                      = [ TNXMLDescBootHardDrive, TNXMLDescBootCDROM,
                                                            TNXMLDescBootNetwork, TNXMLDescBootFileDescriptor],
    TNXMLDescHypervisorKVM                              = @"kvm",
    TNXMLDescHypervisorXen                              = @"xen",
    TNXMLDescHypervisorOpenVZ                           = @"openvz",
    TNXMLDescHypervisorQemu                             = @"qemu",
    TNXMLDescHypervisorKQemu                            = @"kqemu",
    TNXMLDescHypervisorLXC                              = @"lxc",
    TNXMLDescHypervisorUML                              = @"uml",
    TNXMLDescHypervisorVBox                             = @"vbox",
    TNXMLDescHypervisorVMWare                           = @"vmware",
    TNXMLDescHypervisorOpenNebula                       = @"one",
    TNXMLDescVNCKeymapFR                                = @"fr",
    TNXMLDescVNCKeymapEN_US                             = @"en-us",
    TNXMLDescVNCKeymapDeutch                            = @"de",
    TNXMLDescVNCKeymaps                                 = [TNXMLDescVNCKeymapEN_US, TNXMLDescVNCKeymapFR, TNXMLDescVNCKeymapDeutch],
    TNXMLDescLifeCycleDestroy                           = @"destroy",
    TNXMLDescLifeCycleRestart                           = @"restart",
    TNXMLDescLifeCyclePreserve                          = @"preserve",
    TNXMLDescLifeCycleRenameRestart                     = @"rename-restart",
    TNXMLDescLifeCycles                                 = [TNXMLDescLifeCycleDestroy, TNXMLDescLifeCycleRestart,
                                                            TNXMLDescLifeCyclePreserve, TNXMLDescLifeCycleRenameRestart],
    TNXMLDescFeaturePAE                                 = @"pae",
    TNXMLDescFeatureACPI                                = @"acpi",
    TNXMLDescFeatureAPIC                                = @"apic",
    TNXMLDescClockUTC                                   = @"utc",
    TNXMLDescClockLocalTime                             = @"localtime",
    TNXMLDescClockTimezone                              = @"timezone",
    TNXMLDescClockVariable                              = @"variable",
    TNXMLDescClocks                                     = [TNXMLDescClockUTC, TNXMLDescClockLocalTime],
    TNXMLDescInputTypeMouse                             = @"mouse",
    TNXMLDescInputTypeTablet                            = @"tablet",
    TNXMLDescInputTypes                                 = [TNXMLDescInputTypeMouse, TNXMLDescInputTypeTablet];


/*! @defgroup virtualmachinedefinition Module VirtualMachine Definition
    @desc Allow to define virtual machines
*/

/*! @ingroup virtualmachinedefinition
    main class of the module
*/
@implementation TNVirtualMachineDefinitionController : TNModule
{
    @outlet CPButton                buttonClocks;
    @outlet CPButton                buttonDefine;
    @outlet CPButton                buttonDomainType;
    @outlet CPButton                buttonOnCrash;
    @outlet CPButton                buttonOnPowerOff;
    @outlet CPButton                buttonOnReboot;
    @outlet CPButton                buttonUndefine;
    @outlet CPButton                buttonXMLEditor;
    @outlet CPButtonBar             buttonBarControlDrives;
    @outlet CPButtonBar             buttonBarControlNics;
    @outlet CPPopUpButton           buttonBoot;
    @outlet CPPopUpButton           buttonGuests;
    @outlet CPPopUpButton           buttonInputType;
    @outlet CPPopUpButton           buttonMachines;
    @outlet CPPopUpButton           buttonPreferencesBoot;
    @outlet CPPopUpButton           buttonPreferencesClockOffset;
    @outlet CPPopUpButton           buttonPreferencesDriveCache;
    @outlet CPPopUpButton           buttonPreferencesInput;
    @outlet CPPopUpButton           buttonPreferencesNumberOfCPUs;
    @outlet CPPopUpButton           buttonPreferencesOnCrash;
    @outlet CPPopUpButton           buttonPreferencesOnPowerOff;
    @outlet CPPopUpButton           buttonPreferencesOnReboot;
    @outlet CPPopUpButton           buttonPreferencesVNCKeyMap;
    @outlet CPPopUpButton           buttonVNCKeymap;
    @outlet CPSearchField           fieldFilterDrives;
    @outlet CPSearchField           fieldFilterNics;
    @outlet CPTabView               tabViewDevices;
    @outlet CPTextField             fieldMemory;
    @outlet CPTextField             fieldPreferencesDomainType;
    @outlet CPTextField             fieldPreferencesGuest;
    @outlet CPTextField             fieldPreferencesMachine;
    @outlet CPTextField             fieldPreferencesMemory;
    @outlet CPTextField             fieldVNCPassword;
    @outlet CPView                  viewBottomControl;
    @outlet CPView                  viewDeviceVirtualDrives;
    @outlet CPView                  viewDeviceVirtualNics;
    @outlet CPView                  viewDrivesContainer;
    @outlet CPView                  viewMainContent;
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
    @outlet TNUIKitScrollView       scrollViewContentView;
    @outlet TNUIKitScrollView       scrollViewForDrives;
    @outlet TNUIKitScrollView       scrollViewForNics;

    BOOL                            _definitionEdited @accessors(setter=setBasicDefinitionEdited:);
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
    CPDictionary                    _currentBasicSettingsValues;
}


#pragma mark -
#pragma mark Initialization

/*! called at cib awaking
*/
- (void)awakeFromCib
{
    var bundle      = [CPBundle bundleForClass:[self class]],
        defaults    = [CPUserDefaults standardUserDefaults],
        imageBg     = [[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:[self class]] pathForResource:@"bg-controls.png"]];

    [scrollViewContentView setDocumentView:viewMainContent];
    [scrollViewContentView setAutohidesScrollers:YES];
    var frameSize = [scrollViewContentView contentSize];
    frameSize.height = [viewMainContent frameSize].height;
    [viewMainContent setFrameOrigin:CPPointMake(0.0, 0.0)];
    [viewMainContent setFrameSize:frameSize];
    [viewMainContent setAutoresizingMask:CPViewWidthSizable];
    [viewBottomControl setBackgroundColor:[CPColor colorWithPatternImage:imageBg]];

     var inset = CGInsetMake(2, 2, 2, 5);
    [buttonUndefine setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"undefine.png"] size:CPSizeMake(16, 16)]];
    [buttonUndefine setValue:inset forThemeAttribute:@"content-inset"];
    [buttonXMLEditor setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"editxml.png"] size:CPSizeMake(16, 16)]];
    [buttonXMLEditor setValue:inset forThemeAttribute:@"content-inset"];


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
            [bundle objectForInfoDictionaryKey:@"TNDescDefaultHugePages"], @"TNDescDefaultHugePages",
            [bundle objectForInfoDictionaryKey:@"TNDescDefaultInputType"], @"TNDescDefaultInputType",
            [bundle objectForInfoDictionaryKey:@"TNDescDefaultDomainType"], @"TNDescDefaultDomainType",
            [bundle objectForInfoDictionaryKey:@"TNDescDefaultGuest"], @"TNDescDefaultGuest",
            [bundle objectForInfoDictionaryKey:@"TNDescDefaultMachine"], @"TNDescDefaultMachine",
            [bundle objectForInfoDictionaryKey:@"TNDescDefaultDriveCacheMode"], @"TNDescDefaultDriveCacheMode"
    ]];

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

    _plusButtonDrives = [CPButtonBar plusButton];
    [_plusButtonDrives setTarget:self];
    [_plusButtonDrives setAction:@selector(addDrive:)];
    [_plusButtonDrives setToolTip:@"Add a virtual drive"];

    _minusButtonDrives = [CPButtonBar minusButton];
    [_minusButtonDrives setTarget:self];
    [_minusButtonDrives setAction:@selector(deleteDrive:)];
    [_minusButtonDrives setEnabled:NO];
    [_minusButtonDrives setToolTip:@"Delete selected drives"];

    _editButtonDrives = [CPButtonBar plusButton];
    [_editButtonDrives setImage:[[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"IconsButtons/edit.png"] size:CPSizeMake(16, 16)]];
    [_editButtonDrives setTarget:self];
    [_editButtonDrives setAction:@selector(editDrive:)];
    [_editButtonDrives setEnabled:NO];
    [_editButtonDrives setToolTip:@"Edit selected drive"];

    [buttonBarControlDrives setButtons:[_plusButtonDrives, _minusButtonDrives, _editButtonDrives]];


    _plusButtonNics = [CPButtonBar plusButton];
    [_plusButtonNics setTarget:self];
    [_plusButtonNics setAction:@selector(addNetworkCard:)];
    [_plusButtonNics setToolTip:@"Add a virtual network card"];

    _minusButtonNics = [CPButtonBar minusButton];
    [_minusButtonNics setTarget:self];
    [_minusButtonNics setAction:@selector(deleteNetworkCard:)];
    [_minusButtonNics setEnabled:NO];
    [_minusButtonNics setToolTip:@"Remove selected virtual network card"];

    _editButtonNics = [CPButtonBar plusButton];
    [_editButtonNics setImage:[[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"IconsButtons/edit.png"] size:CPSizeMake(16, 16)]];
    [_editButtonNics setTarget:self];
    [_editButtonNics setAction:@selector(editNetworkCard:)];
    [_editButtonNics setEnabled:NO];
    [_editButtonNics setToolTip:@"Edit selected virtual network card"];

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
        driveColumnBus = [[CPTableColumn alloc] initWithIdentifier:@"bus"],
        driveColumnCache = [[CPTableColumn alloc] initWithIdentifier:@"cache"],
        driveColumnFormat = [[CPTableColumn alloc] initWithIdentifier:@"format"],
        driveColumnSource = [[CPTableColumn alloc] initWithIdentifier:@"source"];

    [[driveColumnType headerView] setStringValue:@"Type"];
    [driveColumnType setWidth:80.0];
    [driveColumnType setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"type" ascending:YES]];

    [[driveColumnDevice headerView] setStringValue:@"Device"];
    [driveColumnDevice setWidth:80.0];
    [driveColumnDevice setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"device" ascending:YES]];

    [[driveColumnTarget headerView] setStringValue:@"Target"];
    [driveColumnTarget setWidth:80.0];
    [driveColumnTarget setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"target" ascending:YES]];

    [[driveColumnBus headerView] setStringValue:@"Bus"];
    [driveColumnBus setWidth:80.0];
    [driveColumnBus setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"bus" ascending:YES]];

    [[driveColumnCache headerView] setStringValue:@"Cache mode"];
    [driveColumnCache setWidth:80.0];
    [driveColumnCache setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"cache" ascending:YES]];

    [[driveColumnFormat headerView] setStringValue:@"Format"];
    [driveColumnFormat setWidth:80.0];
    [driveColumnFormat setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"format" ascending:YES]];

    [driveColumnSource setWidth:300];
    [[driveColumnSource headerView] setStringValue:@"Source"];
    [driveColumnSource setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"source" ascending:YES]];

    [_tableDrives addTableColumn:driveColumnType];
    [_tableDrives addTableColumn:driveColumnDevice];
    [_tableDrives addTableColumn:driveColumnTarget];
    [_tableDrives addTableColumn:driveColumnBus];
    [_tableDrives addTableColumn:driveColumnCache];
    [_tableDrives addTableColumn:driveColumnFormat];
    [_tableDrives addTableColumn:driveColumnSource];

    [_drivesDatasource setTable:_tableDrives];
    [_drivesDatasource setSearchableKeyPaths:[@"type", @"device", @"target", @"source", @"bus", @"cache"]];

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
    [buttonPreferencesDriveCache removeAllItems];

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

    [buttonPreferencesDriveCache addItemsWithTitles:TNXMLDescDiskCaches];

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
    [switchAPIC setAction:@selector(makeDefinitionEdited:)];
    [switchACPI setTarget:self];
    [switchACPI setAction:@selector(makeDefinitionEdited:)];
    [switchPAE setTarget:self];
    [switchPAE setAction:@selector(makeDefinitionEdited:)];
    [switchAPIC setToolTip:@"Enable or disable PAE"];

    [switchHugePages setTarget:self];
    [switchHugePages setAction:@selector(makeDefinitionEdited:)];
    [switchHugePages setToolTip:@"Enable or disable usage of huge pages backed memory"];

    //CPUStepper
    [stepperNumberCPUs setMaxValue:4];
    [stepperNumberCPUs setMinValue:1];
    [stepperNumberCPUs setDoubleValue:1];
    [stepperNumberCPUs setValueWraps:NO];
    [stepperNumberCPUs setAutorepeat:NO];
    [stepperNumberCPUs setTarget:self];
    [stepperNumberCPUs setAction:@selector(makeDefinitionEdited:)];
    [stepperNumberCPUs setToolTip:@"Set the number of virtual CPUs"];

    _imageEdited = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"edited.png"] size:CPSizeMake(16.0, 16.0)];
    _imageDefining = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"spinner.gif"] size:CPSizeMake(16.0, 16.0)];
    [buttonDefine setEnabled:NO];
    [buttonDefine setToolTip:@"Save changes"];

    [buttonXMLEditor setToolTip:@"Open the XML editor"];
    [buttonBoot setToolTip:@"Set boot origin"];
    [buttonClocks setToolTip:@"Set the mode of the virtual machine clock"];
    [buttonDomainType setToolTip:@"Set the domain type"];
    [buttonGuests setToolTip:@"Set the guest type"];
    [buttonInputType setToolTip:@"Set the input device"];
    [buttonMachines setToolTip:@"Set the domain machine type"];
    [buttonOnCrash setToolTip:@"Set what to do when virtual machine crashes"];
    [buttonOnPowerOff setToolTip:@"Set what to do when virtual machine is stopped"];
    [buttonOnReboot setToolTip:@"Set what to do when virtual machine is rebooted"];
    [buttonUndefine setToolTip:@"Undefine the domain"];
    [buttonVNCKeymap setToolTip:@"Set the VNC keymap to use"];
    [switchPAE setToolTip:@"Enable usage of PAE"];
    [switchAPIC setToolTip:@"Enable usage of APIC"];
    [switchACPI setToolTip:@"Enable usage of ACPI (allow to use 'shutdown' control)"];
    [fieldMemory setToolTip:@"Set amount of memort (in Mb)"];
    [fieldVNCPassword setToolTip:@"Set the VNC password (no password if blank)"];
    [buttonPreferencesBoot setToolTip:@"Set the default boot device for new domains"];
    [buttonPreferencesClockOffset setToolTip:@"Set the default clock offset for new domains"];
    [buttonPreferencesInput setToolTip:@"Set the default input type for new domains"];
    [buttonPreferencesNumberOfCPUs setToolTip:@"Set the default number of CPUs for new domains"];
    [buttonPreferencesOnCrash setToolTip:@"Set the default behaviour on crash for new domains"];
    [buttonPreferencesOnPowerOff setToolTip:@"Set the default behaviour on power off for new domains"];
    [buttonPreferencesOnReboot setToolTip:@"Set the default behaviour on reboot for new domains"];
    [buttonPreferencesVNCKeyMap setToolTip:@"Set the default VNC keymap for new domains"];
    [buttonPreferencesDriveCache setToolTip:@"Set the default drive cache for new drives"];
    [fieldPreferencesDomainType setToolTip:@"Set the default domain type for new domains"];
    [fieldPreferencesGuest setToolTip:@"Set the default guest for new domains"];
    [fieldPreferencesMachine setToolTip:@"Set the default machine type for new domains"];
    [fieldPreferencesMemory setToolTip:@"Set the default amount of memory for new domains"];
    [switchPreferencesHugePages setToolTip:@"Set the default usage of huge pages for new domains"];
}


#pragma mark -
#pragma mark TNModule overrides

/*! called when module is loaded
*/
- (void)willLoad
{
    [super willLoad];

    _definitionRecovered = NO;
    _currentBasicSettingsValues = [CPDictionary dictionary];
    [self handleDefinitionEdition:NO];

    var center = [CPNotificationCenter defaultCenter];

    [center addObserver:self selector:@selector(_didUpdatePresence:) name:TNStropheContactPresenceUpdatedNotification object:_entity];
    [center addObserver:self selector:@selector(_didBasicDefinitionEdit:) name:CPControlTextDidChangeNotification object:fieldMemory];
    [center addObserver:self selector:@selector(_didBasicDefinitionEdit:) name:CPControlTextDidChangeNotification object:fieldVNCPassword];

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

    [self checkIfRunning];

    return YES;
}

/*! return YES if module can be hidden
*/
- (BOOL)shouldHideAndSelectItem:(anItem)nextItem ofObject:(id)anObject
{
    if (_definitionEdited)
    {
        var alert = [TNAlert alertWithMessage:@"Unsaved changes"
                                    informative:@"You have made some changes in the virtual machine definition. Would you like save these changes?"
                                     target:self
                                     actions:[["Validate", @selector(saveChanges:)], ["Discard", @selector(discardChanges:)]]];

        [alert setUserInfo:[CPArray arrayWithObjects:nextItem, anObject]];
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
    [defaults setObject:[buttonPreferencesDriveCache title] forKey:@"TNDescDefaultDriveCacheMode"];
    [defaults setObject:[fieldPreferencesDomainType stringValue] forKey:@"TNDescDefaultDomainType"];
    [defaults setObject:[fieldPreferencesGuest stringValue] forKey:@"TNDescDefaultGuest"];
    [defaults setObject:[fieldPreferencesMachine stringValue] forKey:@"TNDescDefaultMachine"];
    [defaults setObject:[fieldPreferencesMemory stringValue] forKey:@"TNDescDefaultMemory"];
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
    [buttonPreferencesDriveCache selectItemWithTitle:[defaults objectForKey:@"TNDescDefaultDriveCacheMode"]];
    [fieldPreferencesDomainType setStringValue:[defaults objectForKey:@"TNDescDefaultDomainType"]];
    [fieldPreferencesGuest setStringValue:[defaults objectForKey:@"TNDescDefaultGuest"]];
    [fieldPreferencesMachine setIntValue:[defaults objectForKey:@"TNDescDefaultMachine"]];
    [fieldPreferencesMemory setStringValue:[defaults objectForKey:@"TNDescDefaultMemory"]];
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
- (void)_didBasicDefinitionEdit:(CPNotification)aNotification
{
    [self handleDefinitionEdition:YES];
}


#pragma mark -
#pragma mark Utilities

/*! Called when module should hide and user wants to discard changes
    @param someUserInfo CPArray containing the next item and the object (the tabview or the roster outlineview)
*/
- (void)discardChanges:(id)someUserInfo
{
    var item = [someUserInfo objectAtIndex:0],
        object = [someUserInfo objectAtIndex:1];

    _definitionEdited = NO;
    [self getXMLDesc];

    if ([object isKindOfClass:TNiTunesTabView])
        [object selectTabViewItem:item];
    else
    {
        var idx = [CPIndexSet indexSetWithIndex:[object rowForItem:item]];
        [object selectRowIndexes:idx byExtendingSelection:NO]
    }
}

/*! Called when module should hide and user wants to save changes
    @param someUserInfo CPArray containing the next item and the object (the tabview or the roster outlineview)
*/
- (void)saveChanges:(id)someUserInfo
{
    var item = [someUserInfo objectAtIndex:0],
        object = [someUserInfo objectAtIndex:1];

    _definitionEdited = NO;
    [self defineXML];

    if ([object isKindOfClass:TNiTunesTabView])
        [object selectTabViewItem:item];
    else
    {
        var idx = [CPIndexSet indexSetWithIndex:[object rowForItem:item]];
        [object selectRowIndexes:idx byExtendingSelection:NO]
    }
}

/*! handle definition changes. If all values match ones stored in
    _currentBasicSettingsValues, then it will put the GUI in not edited mode
    @param shouldSetEdited if yes, will try to set GUI in edited mode
*/
- (void)handleDefinitionEdition:(BOOL)shouldSetEdited
{
    if (shouldSetEdited)
    {
        if (!_definitionRecovered)
            return;

        // if ([self doesBasicValueMatchGUI])
        // {
        //     _definitionEdited = NO;
        //     [self markGUIAsNotEdited];
        //     return;
        // }

        _definitionEdited = YES;
        [self markGUIAsEdited];
    }
    else
    {
        _definitionEdited = NO;
        [self markGUIAsNotEdited];
    }
}

/*! set the GUI in the mode "something has been edited"
*/
- (void)markGUIAsEdited
{
    [buttonDefine setEnabled:YES];
    [buttonDefine setThemeState:CPThemeStateDefault];
    [buttonDefine setImage:_imageEdited];
}

/*! set the GUI in the mode "nothing has been edited"
*/
- (void)markGUIAsNotEdited
{
    [buttonDefine setImage:nil];
    [buttonDefine setEnabled:NO];
    [buttonDefine unsetThemeState:CPThemeStateDefault];
}

/*! return YES if all values of the GUI matches ones stored
    in _currentBasicSettingsValues
    @return boolean YES or NO
*/
- (BOOL)doesBasicValueMatchGUI
{
    return (([_currentBasicSettingsValues objectForKey:@"memory"] == [fieldMemory intValue] * 1024)
        && [_currentBasicSettingsValues objectForKey:@"vcpu"] == [stepperNumberCPUs intValue]
        && [_currentBasicSettingsValues objectForKey:@"boot"] == [buttonBoot title]
        && [_currentBasicSettingsValues objectForKey:@"input"] == [buttonInputType title]
        && [_currentBasicSettingsValues objectForKey:@"keymap"] == [buttonVNCKeymap title]
        && (![_currentBasicSettingsValues objectForKey:@"passwd"]
            || [_currentBasicSettingsValues objectForKey:@"passwd"] == [fieldVNCPassword stringValue])
        && [_currentBasicSettingsValues objectForKey:@"onCrash"] == [buttonOnCrash title]
        && [_currentBasicSettingsValues objectForKey:@"onReboot"] == [buttonOnReboot title]
        && [_currentBasicSettingsValues objectForKey:@"onPowerOff"] == [buttonOnPowerOff title]
        && [_currentBasicSettingsValues objectForKey:@"hypervisor"] == [buttonDomainType title]
        && [_currentBasicSettingsValues objectForKey:@"machine"] == [buttonMachines title]
        && [_currentBasicSettingsValues objectForKey:@"clock"] == [buttonClocks title]
        && [_currentBasicSettingsValues valueForKey:@"acpi"] == [switchACPI isOn]
        && [_currentBasicSettingsValues valueForKey:@"apic"] == [switchAPIC isOn]
        && [_currentBasicSettingsValues valueForKey:@"pae"] == [switchPAE isOn]
        && [_currentBasicSettingsValues valueForKey:@"hugepages"] == [switchHugePages isOn]
        && [_currentBasicSettingsValues objectForKey:@"type"] + @" (" + [_currentBasicSettingsValues objectForKey:@"arch"] + @")" == [buttonGuests title])
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
        mem         = [defaults objectForKey:@"TNDescDefaultMemory"],
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
    [fieldMemory setStringValue:mem];
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
        [self showMaskView:YES];
        if (_definitionEdited)
            [TNAlert showAlertWithMessage:@"Definition edited" informative:@"You started the virtual machine, but you haven't save the current changes."];
    }
    else
    {
        [self showMaskView:NO];
    }
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
    [self handleDefinitionEdition:YES];
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
    [networkController setNic:defaultNic];
    [networkController showWindow:aSender];
    [self makeDefinitionEdited:YES];
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
     [self handleDefinitionEdition:YES];
}

/*! add a drive
    @param sender the sender of the action
*/
- (IBAction)addDrive:(id)aSender
{
    if (![self currentEntityHasPermission:@"define"])
        return;

    var defaultDrive = [TNDrive driveWithType:@"file" device:@"disk" source:"/drives/drive.img" target:@"hda" bus:@"ide" cache:[[CPUserDefaults standardUserDefaults] objectForKey:@"TNDescDefaultDriveCacheMode"] format:nil];

    [_drivesDatasource addObject:defaultDrive];
    [_tableDrives reloadData];
    [driveController setDrive:defaultDrive];
    [driveController showWindow:aSender];
    [self makeDefinitionEdited:YES];
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
     [self handleDefinitionEdition:YES];
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

    [self handleDefinitionEdition:YES];
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
            [self showMaskView:YES];
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
        _definitionRecovered = YES;
        [self handleDefinitionEdition:NO];

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

    // store current values for matching edition
    [_currentBasicSettingsValues setObject:memory forKey:@"memory"];
    [_currentBasicSettingsValues setObject:hypervisor forKey:@"hypervisor"];
    [_currentBasicSettingsValues setObject:type forKey:@"type"];
    [_currentBasicSettingsValues setObject:arch forKey:@"arch"];
    [_currentBasicSettingsValues setObject:machine forKey:@"machine"];
    [_currentBasicSettingsValues setObject:vcpu forKey:@"vcpu"];
    [_currentBasicSettingsValues setObject:boot forKey:@"boot"];
    [_currentBasicSettingsValues setObject:[onPowerOff text] forKey:@"onPowerOff"];
    [_currentBasicSettingsValues setObject:[onReboot text] forKey:@"onReboot"];
    [_currentBasicSettingsValues setObject:[onCrash text] forKey:@"onCrash"];
    [_currentBasicSettingsValues setObject:[clock valueForAttribute:@"offset"] forKey:@"clock"];
    [_currentBasicSettingsValues setObject:input forKey:@"input"];

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
                {
                    [_currentBasicSettingsValues setObject:keymap forKey:@"keymap"];
                    [buttonVNCKeymap selectItemWithTitle:keymap];
                }

                if (passwd)
                {
                    [_currentBasicSettingsValues setObject:passwd forKey:@"passwd"];
                    [fieldVNCPassword setStringValue:passwd];
                }
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
    [_currentBasicSettingsValues setValue:NO forKey:@"apic"];
    [switchAPIC setOn:NO animated:NO sendAction:NO];
    if ([features containsChildrenWithName:@"apic"])
    {
        [_currentBasicSettingsValues setValue:YES forKey:@"apic"];
        [switchAPIC setOn:YES animated:NO sendAction:NO];
    }

    // ACPI
    [_currentBasicSettingsValues setValue:NO forKey:@"acpi"];
    [switchACPI setOn:NO animated:NO sendAction:NO];
    if ([features containsChildrenWithName:@"acpi"])
    {
        [_currentBasicSettingsValues setValue:YES forKey:@"acpi"];
        [switchACPI setOn:YES animated:NO sendAction:NO];
    }

    // PAE
    [_currentBasicSettingsValues setValue:NO forKey:@"pae"];
    [switchPAE setOn:NO animated:NO sendAction:NO];
    if ([features containsChildrenWithName:@"pae"])
    {
        [_currentBasicSettingsValues setValue:YES forKey:@"pae"];
        [switchPAE setOn:YES animated:NO sendAction:NO];
    }

    // huge pages
    [_currentBasicSettingsValues setValue:NO forKey:@"hugepages"];
    [switchHugePages setOn:NO animated:NO sendAction:NO];
    if (memoryBacking)
    {
        if ([memoryBacking containsChildrenWithName:@"hugepages"])
        {
            [_currentBasicSettingsValues setValue:YES forKey:@"hugepages"];
            [switchHugePages setOn:YES animated:NO sendAction:NO];
        }
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
            iCache      = (iType == @"file" && [currentDisk firstChildWithName:@"driver"]) ? [[currentDisk firstChildWithName:@"driver"] valueForAttribute:@"cache"] : [defaults objectForKey:@"TNDescDefaultDriveCacheMode"],
            iFormat     = (iType == @"file" && [currentDisk firstChildWithName:@"driver"]) ? [[currentDisk firstChildWithName:@"driver"] valueForAttribute:@"type"] : nil,
            newDrive    = [TNDrive driveWithType:iType device:iDevice source:iSource target:iTarget bus:iBus cache:iCache format:iFormat];

        [_drivesDatasource addObject:newDrive];
    }

    [_tableDrives reloadData];

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
    [self handleDefinitionEdition:NO];
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

        if ([drive format])
        {
            [stanza addChildWithName:@"driver" andAttributes:{"type": [drive format], "cache": [drive cache]}];
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
    [buttonDefine setImage:_imageDefining];
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

    [buttonDefine setImage:_imageDefining];
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
        [self handleDefinitionEdition:NO];
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