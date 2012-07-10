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
@import <TNKit/TNSwipeView.j>

@import "Model/TNLibvirt.j"
@import "TNCharacterDeviceController.j"
@import "TNCharacterDeviceDataView.j"
@import "TNDriveController.j"
@import "TNDriveDeviceDataView.j"
@import "TNGraphicDeviceController.j"
@import "TNGraphicDeviceDataView.j"
@import "TNInputDeviceController.j"
@import "TNInputDeviceDataView.j"
@import "TNInterfaceController.j"
@import "TNInterfaceDeviceDataView.j"
@import "TNVirtualMachineGuestItem.j"


var TNArchipelDefinitionUpdatedNotification             = @"TNArchipelDefinitionUpdatedNotification",
    TNArchipelTypeVirtualMachineControl                 = @"archipel:vm:control",
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
    VIR_DOMAIN_CRASHED                                  =   6;


/*! @defgroup virtualmachinedefinition Module VirtualMachine Definition
    @desc Allow to define virtual machines
*/

/*! @ingroup virtualmachinedefinition
    main class of the module
*/
@implementation TNVirtualMachineDefinitionController : TNModule
{
    @outlet CPButton                    buttonClocks;
    @outlet CPButton                    buttonDefine;
    @outlet CPButton                    buttonDomainType;
    @outlet CPButton                    buttonOnCrash;
    @outlet CPButton                    buttonOnPowerOff;
    @outlet CPButton                    buttonOnReboot;
    @outlet CPButton                    buttonUndefine;
    @outlet CPButton                    buttonXMLEditor;
    @outlet CPButton                    buttonXMLEditorDefine;
    @outlet CPButtonBar                 buttonBarCharacterDevices;
    @outlet CPButtonBar                 buttonBarControlDrives;
    @outlet CPButtonBar                 buttonBarControlNics;
    @outlet CPButtonBar                 buttonBarGraphicDevices;
    @outlet CPButtonBar                 buttonBarInputDevices;
    @outlet CPPopover                   popoverXMLEditor;
    @outlet CPPopUpButton               buttonBoot;
    @outlet CPPopUpButton               buttonGuests;
    @outlet CPPopUpButton               buttonMachines;
    @outlet CPPopUpButton               buttonPreferencesBoot;
    @outlet CPPopUpButton               buttonPreferencesClockOffset;
    @outlet CPPopUpButton               buttonPreferencesDriveCache;
    @outlet CPPopUpButton               buttonPreferencesInput;
    @outlet CPPopUpButton               buttonPreferencesNumberOfCPUs;
    @outlet CPPopUpButton               buttonPreferencesOnCrash;
    @outlet CPPopUpButton               buttonPreferencesOnPowerOff;
    @outlet CPPopUpButton               buttonPreferencesOnReboot;
    @outlet CPPopUpButton               buttonPreferencesVNCKeyMap;
    @outlet CPScrollView                scrollViewContentView;
    @outlet CPSearchField               fieldFilterCharacters;
    @outlet CPSearchField               fieldFilterDrives;
    @outlet CPSearchField               fieldFilterNics;
    @outlet CPTableView                 tableCharacterDevices;
    @outlet CPTableView                 tableDrives;
    @outlet CPTableView                 tableGraphicsDevices;
    @outlet CPTableView                 tableInputDevices;
    @outlet CPTableView                 tableInterfaces;
    @outlet CPTextField                 fieldBlockIOTuningWeight;
    @outlet CPTextField                 fieldMemory;
    @outlet CPTextField                 fieldMemoryTuneGuarantee;
    @outlet CPTextField                 fieldMemoryTuneHardLimit;
    @outlet CPTextField                 fieldMemoryTuneSoftLimit;
    @outlet CPTextField                 fieldMemoryTuneSwapHardLimit;
    @outlet CPTextField                 fieldOSInitrd;
    @outlet CPTextField                 fieldOSKernel;
    @outlet CPTextField                 fieldOSLoader;
    @outlet CPTextField                 fieldPreferencesDomainType;
    @outlet CPTextField                 fieldPreferencesGuest;
    @outlet CPTextField                 fieldPreferencesMachine;
    @outlet CPTextField                 fieldPreferencesMemory;
    @outlet CPTextField                 labelVirtualMachineIsRunning;
    @outlet CPView                      viewBottomControl;
    @outlet CPView                      viewCharacterDevicesContainer;
    @outlet CPView                      viewDrivesContainer;
    @outlet CPView                      viewGraphicDevicesContainer;
    @outlet CPView                      viewInputDevicesContainer;
    @outlet CPView                      viewMainContent;
    @outlet CPView                      viewNicsContainer;
    @outlet CPView                      viewParametersAdvanced;
    @outlet CPView                      viewParametersCharacterDevices;
    @outlet CPView                      viewParametersDrives;
    @outlet CPView                      viewParametersEffectBottom;
    @outlet CPView                      viewParametersEffectTop;
    @outlet CPView                      viewParametersNICs;
    @outlet CPView                      viewParametersStandard;
    @outlet LPMultiLineTextField        fieldOSCommandLine;
    @outlet LPMultiLineTextField        fieldStringXMLDesc;
    @outlet TNCharacterDeviceController characterDeviceController;
    @outlet TNCharacterDeviceDataView   dataViewCharacterDevicePrototype;
    @outlet TNDriveController           driveController;
    @outlet TNDriveDeviceDataView       dataViewDrivesPrototype;
    @outlet TNGraphicDeviceController   graphicDeviceController;
    @outlet TNGraphicDeviceDataView     dataViewGraphicDevicePrototype;
    @outlet TNInputDeviceController     inputDeviceController;
    @outlet TNInputDeviceDataView       dataViewInputDevicePrototype;
    @outlet TNInterfaceController       interfaceController;
    @outlet TNInterfaceDeviceDataView   dataViewNICsPrototype;
    @outlet TNSwitch                    switchACPI;
    @outlet TNSwitch                    switchAPIC;
    @outlet TNSwitch                    switchHugePages;
    @outlet TNSwitch                    switchPAE;
    @outlet TNSwitch                    switchPreferencesHugePages;
    @outlet TNTabView                   tabViewParameters;
    @outlet TNTextFieldStepper          stepperNumberCPUs;

    BOOL                                _definitionEdited @accessors(setter=setBasicDefinitionEdited:);
    BOOL                                _definitionRecovered;
    CPButton                            _editButtonCharacterDevice;
    CPButton                            _editButtonDrives;
    CPButton                            _editButtonGraphicDevice;
    CPButton                            _editButtonInputDevice;
    CPButton                            _editButtonNics;
    CPButton                            _minusButtonCharacterDevice;
    CPButton                            _minusButtonDrives;
    CPButton                            _minusButtonGraphicDevice;
    CPButton                            _minusButtonInputDevice;
    CPButton                            _minusButtonNics;
    CPButton                            _plusButtonCharacter;
    CPButton                            _plusButtonDrives;
    CPButton                            _plusButtonGraphics;
    CPButton                            _plusButtonInputs;
    CPButton                            _plusButtonNics;
    CPImage                             _imageDefining;
    CPImage                             _imageEdited;
    CPPredicate                         _consoleFilterPredicate;
    CPString                            _stringXMLDesc;
    TNTableViewDataSource               _characterDevicesDatasource;
    TNTableViewDataSource               _drivesDatasource;
    TNTableViewDataSource               _graphicDevicesDatasource;
    TNTableViewDataSource               _inputDevicesDatasource;
    TNTableViewDataSource               _nicsDatasource;
    TNXMLNode                           _libvirtCapabilities;
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
    [viewMainContent setFrameOrigin:CPPointMake(0.0, 0.0)];
    [viewMainContent setFrameSize:frameSize];
    [viewMainContent setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [viewBottomControl setBackgroundColor:[CPColor colorWithPatternImage:imageBg]];

     var inset = CGInsetMake(2, 2, 2, 5);
    [buttonUndefine setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"undefine.png"] size:CPSizeMake(16, 16)]];
    [buttonUndefine setValue:inset forThemeAttribute:@"content-inset"];
    [buttonXMLEditor setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"editxml.png"] size:CPSizeMake(16, 16)]];
    [buttonXMLEditor setValue:inset forThemeAttribute:@"content-inset"];

    // paramaters tabView
    var mainBundle = [CPBundle mainBundle],
        imageSwipeViewBG = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"Backgrounds/paper-bg-dark.png"]],
        tabViewItemStandard = [[CPTabViewItem alloc] initWithIdentifier:@"standard"],
        tabViewItemAdvanced = [[CPTabViewItem alloc] initWithIdentifier:@"advanced"],
        tabViewItemDrives = [[CPTabViewItem alloc] initWithIdentifier:@"IDtabViewItemDrives"],
        tabViewItemNics = [[CPTabViewItem alloc] initWithIdentifier:@"IDtabViewItemNics"],
        tabViewItemCharacter = [[CPTabViewItem alloc] initWithIdentifier:@"IDtabViewItemCharacters"];

    [tabViewParameters setContentBackgroundColor:[CPColor colorWithPatternImage:imageSwipeViewBG]];

    var scrollViewParametersStandard = [[CPScrollView alloc] initWithFrame:[tabViewParameters bounds]],
        scrollViewParametersAdvanced = [[CPScrollView alloc] initWithFrame:[tabViewParameters bounds]];

    [viewParametersStandard setAutoresizingMask:CPViewWidthSizable];
    [viewParametersAdvanced setAutoresizingMask:CPViewWidthSizable];
    [viewParametersStandard setFrameSize:CPSizeMake([scrollViewParametersStandard frameSize].width, [viewParametersStandard frameSize].height)];
    [viewParametersAdvanced setFrameSize:CPSizeMake([scrollViewParametersAdvanced frameSize].width, [viewParametersAdvanced frameSize].height)];

    [scrollViewParametersStandard setAutoresizingMask:CPViewWidthSizable];
    [scrollViewParametersAdvanced setAutoresizingMask:CPViewWidthSizable];
    [scrollViewParametersStandard setDocumentView:viewParametersStandard];
    [scrollViewParametersAdvanced setDocumentView:viewParametersAdvanced];

    [tabViewItemStandard setLabel:CPLocalizedString(@"Basics", @"Basics")];
    [tabViewItemStandard setView:scrollViewParametersStandard];
    [tabViewItemAdvanced setLabel:CPLocalizedString(@"Advanced", @"Advanced")];
    [tabViewItemAdvanced setView:scrollViewParametersAdvanced];
    [tabViewItemDrives setLabel:CPBundleLocalizedString(@"Virtual Medias", @"Virtual Medias")];
    [tabViewItemDrives setView:viewParametersDrives];
    [tabViewItemNics setLabel:CPBundleLocalizedString(@"Virtual Nics", @"Virtual Nics")];
    [tabViewItemNics setView:viewParametersNICs];
    [tabViewItemCharacter setLabel:CPBundleLocalizedString(@"Char Devices", @"Char Devices")];
    [tabViewItemCharacter setView:viewParametersCharacterDevices];


    [tabViewParameters addTabViewItem:tabViewItemStandard];
    [tabViewParameters addTabViewItem:tabViewItemAdvanced];
    [tabViewParameters addTabViewItem:tabViewItemDrives];
    [tabViewParameters addTabViewItem:tabViewItemNics];
    [tabViewParameters addTabViewItem:tabViewItemCharacter];
    [tabViewParameters setDelegate:self];

    var shadowTop = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"shadow-top.png"] size:CPSizeMake(1.0, 10.0)],
        shadowBottom = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"shadow-bottom.png"] size:CPSizeMake(1.0, 10.0)];
    [viewParametersEffectTop setBackgroundColor:[CPColor colorWithPatternImage:shadowTop]];
    [viewParametersEffectBottom setBackgroundColor:[CPColor colorWithPatternImage:shadowBottom]];

    [fieldStringXMLDesc setTextColor:[CPColor blackColor]];
    [fieldOSCommandLine setTextColor:[CPColor blackColor]];

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
            [bundle objectForInfoDictionaryKey:@"TNDescDefaultEnableVNC"], @"TNDescDefaultEnableVNC",
            [bundle objectForInfoDictionaryKey:@"TNDescDefaultInputType"], @"TNDescDefaultInputType",
            [bundle objectForInfoDictionaryKey:@"TNDescDefaultDomainType"], @"TNDescDefaultDomainType",
            [bundle objectForInfoDictionaryKey:@"TNDescDefaultGuest"], @"TNDescDefaultGuest",
            [bundle objectForInfoDictionaryKey:@"TNDescDefaultMachine"], @"TNDescDefaultMachine",
            [bundle objectForInfoDictionaryKey:@"TNDescDefaultDriveCacheMode"], @"TNDescDefaultDriveCacheMode",
            [bundle objectForInfoDictionaryKey:@"TNDescMaxNumberCPU"], @"TNDescMaxNumberCPU"
    ]];

    [fieldStringXMLDesc setFont:[CPFont fontWithName:@"Andale Mono, Courier New" size:12]];

    _stringXMLDesc = @"";

    // DRIVES
    _drivesDatasource = [[TNTableViewDataSource alloc] init];
    [_drivesDatasource setTable:tableDrives];
    [_drivesDatasource setSearchableKeyPaths:[@"type", @"driver.type", @"target.device", @"source.sourceObject", @"target.bus", @"driver.cache"]];
    [[tableDrives tableColumnWithIdentifier:@"self"] setDataView:[dataViewDrivesPrototype duplicate]];
    [tableDrives setDataSource:_drivesDatasource];
    [tableDrives setTarget:self];
    [tableDrives setDoubleAction:@selector(editDrive:)];
    [tableDrives setSelectionHighlightStyle:CPTableViewSelectionHighlightStyleNone];
    [tableDrives setBackgroundColor:[CPColor colorWithHexString:@"F7F7F7"]];

    [viewDrivesContainer setBorderedWithHexColor:@"#C0C7D2"];

    [driveController setDelegate:self];

    [fieldFilterDrives setTarget:_drivesDatasource];
    [fieldFilterDrives setAction:@selector(filterObjects:)];

    _plusButtonDrives = [CPButtonBar plusButton];
    [_plusButtonDrives setTarget:self];
    [_plusButtonDrives setAction:@selector(addDrive:)];

    _minusButtonDrives = [CPButtonBar minusButton];
    [_minusButtonDrives setTarget:self];
    [_minusButtonDrives setAction:@selector(deleteDrive:)];
    [_minusButtonDrives setEnabled:NO];

    _editButtonDrives = [CPButtonBar plusButton];
    [_editButtonDrives setImage:[[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"IconsButtons/edit.png"] size:CPSizeMake(16, 16)]];
    [_editButtonDrives setTarget:self];
    [_editButtonDrives setAction:@selector(editDrive:)];
    [_editButtonDrives setEnabled:NO];

    [buttonBarControlDrives setButtons:[_plusButtonDrives, _minusButtonDrives, _editButtonDrives]];
    [driveController setTable:tableDrives];

    // NICs
    _nicsDatasource = [[TNTableViewDataSource alloc] init];
    [_nicsDatasource setTable:tableInterfaces];
    [_nicsDatasource setSearchableKeyPaths:[@"type", @"model", @"MAC", @"source.bridge"]];
    [[tableInterfaces tableColumnWithIdentifier:@"self"] setDataView:[dataViewNICsPrototype duplicate]];
    [tableInterfaces setDataSource:_nicsDatasource];
    [tableInterfaces setTarget:self];
    [tableInterfaces setDoubleAction:@selector(editInterface:)];
    [tableInterfaces setSelectionHighlightStyle:CPTableViewSelectionHighlightStyleNone];
    [tableInterfaces setBackgroundColor:[CPColor colorWithHexString:@"F7F7F7"]];

    [viewNicsContainer setBorderedWithHexColor:@"#C0C7D2"];

    [interfaceController setDelegate:self];

    [fieldFilterNics setTarget:_nicsDatasource];
    [fieldFilterNics setAction:@selector(filterObjects:)];

    _plusButtonNics = [CPButtonBar plusButton];
    [_plusButtonNics setTarget:self];
    [_plusButtonNics setAction:@selector(addNetworkCard:)];

    _minusButtonNics = [CPButtonBar minusButton];
    [_minusButtonNics setTarget:self];
    [_minusButtonNics setAction:@selector(deleteNetworkCard:)];
    [_minusButtonNics setEnabled:NO];

    _editButtonNics = [CPButtonBar plusButton];
    [_editButtonNics setImage:[[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"IconsButtons/edit.png"] size:CPSizeMake(16, 16)]];
    [_editButtonNics setTarget:self];
    [_editButtonNics setAction:@selector(editInterface:)];
    [_editButtonNics setEnabled:NO];

    [buttonBarControlNics setButtons:[_plusButtonNics, _minusButtonNics, _editButtonNics]];
    [interfaceController setTable:tableInterfaces];

    // Input Devices
    _inputDevicesDatasource = [[TNTableViewDataSource alloc] init];
    [[tableInputDevices tableColumnWithIdentifier:@"self"] setDataView:[dataViewInputDevicePrototype duplicate]];
    [tableInputDevices setTarget:self];
    [tableInputDevices setDoubleAction:@selector(editInputDevice:)];
    [tableInputDevices setSelectionHighlightStyle:CPTableViewSelectionHighlightStyleNone];
    [tableInputDevices setBackgroundColor:[CPColor colorWithHexString:@"F7F7F7"]];

    [_inputDevicesDatasource setTable:tableInputDevices];
    [tableInputDevices setDataSource:_inputDevicesDatasource];
    [viewInputDevicesContainer setBorderedWithHexColor:@"#C0C7D2"];

    _plusButtonInputs = [CPButtonBar plusButton];
    [_plusButtonInputs setTarget:self];
    [_plusButtonInputs setAction:@selector(addInputDevice:)];

    _minusButtonInputDevice = [CPButtonBar minusButton];
    [_minusButtonInputDevice setTarget:self];
    [_minusButtonInputDevice setAction:@selector(deleteInputDevice:)];

    _editButtonInputDevice = [CPButtonBar plusButton];
    [_editButtonInputDevice setImage:[[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"IconsButtons/edit.png"] size:CPSizeMake(16, 16)]];
    [_editButtonInputDevice setTarget:self];
    [_editButtonInputDevice setAction:@selector(editInputDevice:)];

    [buttonBarInputDevices setButtons:[_plusButtonInputs, _minusButtonInputDevice, _editButtonInputDevice]];

    [inputDeviceController setDelegate:self];
    [inputDeviceController setTable:tableInputDevices];

    // Graphic Devices
    _graphicDevicesDatasource = [[TNTableViewDataSource alloc] init];
    [[tableGraphicsDevices tableColumnWithIdentifier:@"self"] setDataView:[dataViewGraphicDevicePrototype duplicate]];
    [tableGraphicsDevices setTarget:self];
    [tableGraphicsDevices setDoubleAction:@selector(editGraphicDevice:)];
    [tableGraphicsDevices setSelectionHighlightStyle:CPTableViewSelectionHighlightStyleNone];
    [tableGraphicsDevices setBackgroundColor:[CPColor colorWithHexString:@"F7F7F7"]];

    [_graphicDevicesDatasource setTable:tableGraphicsDevices];
    [tableGraphicsDevices setDataSource:_graphicDevicesDatasource];
    [viewGraphicDevicesContainer setBorderedWithHexColor:@"#C0C7D2"];

    _plusButtonGraphics = [CPButtonBar plusButton];
    [_plusButtonGraphics setTarget:self];
    [_plusButtonGraphics setAction:@selector(addGraphicDevice:)];

    _minusButtonGraphicDevice = [CPButtonBar minusButton];
    [_minusButtonGraphicDevice setTarget:self];
    [_minusButtonGraphicDevice setAction:@selector(deleteGraphicDevice:)];

    _editButtonGraphicDevice = [CPButtonBar plusButton];
    [_editButtonGraphicDevice setImage:[[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"IconsButtons/edit.png"] size:CPSizeMake(16, 16)]];
    [_editButtonGraphicDevice setTarget:self];
    [_editButtonGraphicDevice setAction:@selector(editGraphicDevice:)];

    [buttonBarGraphicDevices setButtons:[_plusButtonGraphics, _minusButtonGraphicDevice, _editButtonGraphicDevice]];
    [graphicDeviceController setDelegate:self];
    [graphicDeviceController setTable:tableGraphicsDevices];


    // Character devices
    _consoleFilterPredicate = [CPPredicate predicateWithFormat:@"not kind like %@", TNLibvirtDeviceCharacterKindConsole];
    _characterDevicesDatasource = [[TNTableViewDataSource alloc] init];
    [_characterDevicesDatasource setDisplayFilter:_consoleFilterPredicate];

    [[tableCharacterDevices tableColumnWithIdentifier:@"self"] setDataView:[dataViewCharacterDevicePrototype duplicate]];
    [tableCharacterDevices setTarget:self];
    [tableCharacterDevices setDoubleAction:@selector(editCharacterDevice:)];
    [tableCharacterDevices setSelectionHighlightStyle:CPTableViewSelectionHighlightStyleNone];
    [tableCharacterDevices setBackgroundColor:[CPColor colorWithHexString:@"F7F7F7"]];


    [_characterDevicesDatasource setTable:tableCharacterDevices];
    [tableCharacterDevices setDataSource:_characterDevicesDatasource];
    [viewCharacterDevicesContainer setBorderedWithHexColor:@"#C0C7D2"];

    [fieldFilterCharacters setTarget:_characterDevicesDatasource];
    [fieldFilterCharacters setAction:@selector(filterObjects:)];

    _plusButtonCharacter = [CPButtonBar plusButton];
    [_plusButtonCharacter setTarget:self];
    [_plusButtonCharacter setAction:@selector(addCharacterDevice:)];

    _minusButtonCharacterDevice = [CPButtonBar minusButton];
    [_minusButtonCharacterDevice setTarget:self];
    [_minusButtonCharacterDevice setAction:@selector(deleteCharacterDevice:)];

    _editButtonCharacterDevice = [CPButtonBar plusButton];
    [_editButtonCharacterDevice setImage:[[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"IconsButtons/edit.png"] size:CPSizeMake(16, 16)]];
    [_editButtonCharacterDevice setTarget:self];
    [_editButtonCharacterDevice setAction:@selector(editCharacterDevice:)];

    [buttonBarCharacterDevices setButtons:[_plusButtonCharacter, _minusButtonCharacterDevice, _editButtonCharacterDevice]];

    [characterDeviceController setDelegate:self];
    [characterDeviceController setTable:tableCharacterDevices];


    // others..
    [buttonBoot removeAllItems];
    [buttonDomainType removeAllItems];
    [buttonMachines removeAllItems];
    [buttonOnPowerOff removeAllItems];
    [buttonOnReboot removeAllItems];
    [buttonOnCrash removeAllItems];
    [buttonClocks removeAllItems];
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

    [buttonBoot addItemsWithTitles:TNLibvirtDomainOSBoots];
    [buttonPreferencesBoot addItemsWithTitles:TNLibvirtDomainOSBoots];

    var ncpus = [];
    for (var i = 1; i <= [defaults integerForKey:@"TNDescMaxNumberCPU"]; i++)
        [ncpus addObject:@"" + i]

    [buttonPreferencesNumberOfCPUs addItemsWithTitles:ncpus];

    [buttonPreferencesVNCKeyMap addItemsWithTitles:TNLibvirtDeviceGraphicVNCKeymaps];

    [buttonOnPowerOff addItemsWithTitles:TNLibvirtDomainLifeCycles];
    [buttonPreferencesOnPowerOff addItemsWithTitles:TNLibvirtDomainLifeCycles];

    [buttonOnReboot addItemsWithTitles:TNLibvirtDomainLifeCycles];
    [buttonPreferencesOnReboot addItemsWithTitles:TNLibvirtDomainLifeCycles];

    [buttonOnCrash addItemsWithTitles:TNLibvirtDomainLifeCycles];
    [buttonPreferencesOnCrash addItemsWithTitles:TNLibvirtDomainLifeCycles];

    [buttonClocks addItemsWithTitles:TNLibvirtDomainClockClocks];
    [buttonPreferencesClockOffset addItemsWithTitles:TNLibvirtDomainClockClocks];

    [buttonPreferencesInput addItemsWithTitles:TNLibvirtDeviceInputTypes];

    [buttonPreferencesDriveCache addItemsWithTitles:TNLibvirtDeviceDiskDriverCaches];

    // switch
    [switchPAE setOn:NO animated:YES sendAction:NO];
    [switchAPIC setOn:NO animated:YES sendAction:NO];
    [switchACPI setOn:NO animated:YES sendAction:NO];

    //CPUStepper
    [stepperNumberCPUs setMaxValue:[defaults integerForKey:@"TNDescMaxNumberCPU"]];
    [stepperNumberCPUs setMinValue:1];
    [stepperNumberCPUs setDoubleValue:1];
    [stepperNumberCPUs setValueWraps:NO];
    [stepperNumberCPUs setAutorepeat:NO];

    _imageEdited = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"edited.png"] size:CPSizeMake(16.0, 16.0)];
    _imageDefining = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"spinner.gif"] size:CPSizeMake(16.0, 16.0)];
    [buttonDefine setEnabled:NO];

    [viewParametersStandard applyShadow];
    [viewParametersAdvanced applyShadow];
    [viewParametersDrives applyShadow];
    [viewParametersNICs applyShadow];
    [viewParametersCharacterDevices applyShadow];

    [labelVirtualMachineIsRunning setValue:[CPColor colorWithHexString:@"f4f4f4"] forThemeAttribute:@"text-shadow-color"];
    [labelVirtualMachineIsRunning setValue:CGSizeMake(0.0, 1.0) forThemeAttribute:@"text-shadow-offset"];
}


#pragma mark -
#pragma mark TNModule overrides

/*! called when module is loaded
*/
- (BOOL)willLoad
{
    if (![super willLoad])
        return NO;

    _definitionRecovered = NO;
    [self handleDefinitionEdition:NO];

    var center = [CPNotificationCenter defaultCenter];

    [center addObserver:self selector:@selector(_didUpdatePresence:) name:TNStropheContactPresenceUpdatedNotification object:_entity];
    [center addObserver:self selector:@selector(_didEditDefinition:) name:CPControlTextDidChangeNotification object:fieldMemory];

    [self registerSelector:@selector(_didReceivePush:) forPushNotificationType:TNArchipelPushNotificationDefinitition];

    [tableDrives setDelegate:nil];
    [tableDrives setDelegate:self];
    [tableInterfaces setDelegate:nil];
    [tableInterfaces setDelegate:self];
    [tableCharacterDevices setDelegate:nil];
    [tableCharacterDevices setDelegate:self];
    [tableInputDevices setDelegate:nil];
    [tableInputDevices setDelegate:self];
    [tableGraphicsDevices setDelegate:nil];
    [tableGraphicsDevices setDelegate:self];

    [driveController setEntity:_entity];
    [interfaceController setEntity:_entity];

    [self setDefaultValues];

    [fieldStringXMLDesc setStringValue:@""];

    [self getCapabilities];

    // seems to be necessary
    [tableDrives reloadData];
    [tableInterfaces reloadData];

    return YES;
}

/*! called when module is unloaded
*/
- (void)willUnload
{
    [self setDefaultValues];
    _libvirtDomain = nil;
    [super willUnload];
}

/*! called when module becomes visible
*/
- (BOOL)willShow
{
    if (![super willShow])
        return NO;

    [self checkIfRunning];
    [self enableGUI:([_entity XMPPShow] == TNStropheContactStatusBusy)];

    return YES;
}

/*! called when module is hidden
*/
- (void)willHide
{
    [interfaceController closeWindow:nil];
    [driveController closeWindow:nil];
    [inputDeviceController closeWindow:nil];
    [graphicDeviceController closeWindow:nil];
    [characterDeviceController closeWindow:nil];

    [popoverXMLEditor close];

    [super willHide];
}

/*! return YES if module can be hidden
*/
- (BOOL)shouldHideAndSelectItem:(anItem)nextItem ofObject:(id)anObject
{
    if (_definitionEdited)
    {
        var alert = [TNAlert alertWithMessage:CPBundleLocalizedString(@"Unsaved changes", @"Unsaved changes")
                                    informative:CPBundleLocalizedString(@"You have made some changes in the virtual machine definition. Would you like save these changes?", @"You have made some changes in the virtual machine definition. Would you like save these changes?")
                                     target:self
                                     actions:[[CPBundleLocalizedString(@"Validate", @"Validate"), @selector(saveChanges:)], [CPBundleLocalizedString(@"Discard", @"Discard"), @selector(discardChanges:)]]];

        [alert setUserInfo:[CPArray arrayWithObjects:nextItem, anObject]];

        [interfaceController closeWindow:nil];
        [driveController closeWindow:nil];
        [popoverXMLEditor close];
        [characterDeviceController closeWindow:nil];
        [inputDeviceController closeWindow:nil];
        [graphicDeviceController closeWindow:nil];

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
    [[_menu addItemWithTitle:CPBundleLocalizedString(@"Undefine", @"Undefine") action:@selector(undefineXML:) keyEquivalent:@""] setTarget:self];
    [_menu addItem:[CPMenuItem separatorItem]];
    [[_menu addItemWithTitle:@"Open XML editor" action:@selector(openXMLEditor:) keyEquivalent:@""] setTarget:self];
}

/*! called when user permissions changed
*/
- (void)permissionsChanged
{
    [super permissionsChanged];
    if ([self isVisible])
    {
        [self checkIfRunning];
        [self enableGUI:([_entity XMPPShow] == TNStropheContactStatusBusy)];
    }
}

/*! called when the UI needs to be updated according to the permissions
*/
- (void)setUIAccordingToPermissions
{
    [self setControl:buttonBoot enabledAccordingToPermission:@"define"];
    [self setControl:buttonClocks enabledAccordingToPermission:@"define"];
    [self setControl:buttonDomainType enabledAccordingToPermission:@"define"];
    [self setControl:buttonGuests enabledAccordingToPermission:@"define"];
    [self setControl:buttonMachines enabledAccordingToPermission:@"define"];
    [self setControl:buttonOnCrash enabledAccordingToPermission:@"define"];
    [self setControl:buttonOnPowerOff enabledAccordingToPermission:@"define"];
    [self setControl:buttonOnReboot enabledAccordingToPermission:@"define"];
    [self setControl:buttonUndefine enabledAccordingToPermission:@"undefine"];
    [self setControl:buttonXMLEditor enabledAccordingToPermission:@"define"];
    [self setControl:fieldMemory enabledAccordingToPermission:@"define"];
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
    [self setControl:_plusButtonCharacter enabledAccordingToPermission:@"define"];
    [self setControl:_minusButtonCharacterDevice enabledAccordingToPermission:@"define"];
    [self setControl:_editButtonCharacterDevice enabledAccordingToPermission:@"define"];
    [self setControl:fieldMemoryTuneSoftLimit enabledAccordingToPermission:@"define"];
    [self setControl:fieldMemoryTuneHardLimit enabledAccordingToPermission:@"define"];
    [self setControl:fieldMemoryTuneGuarantee enabledAccordingToPermission:@"define"];
    [self setControl:fieldMemoryTuneSwapHardLimit enabledAccordingToPermission:@"define"];
    [self setControl:fieldBlockIOTuningWeight enabledAccordingToPermission:@"define"];
    [self setControl:fieldOSLoader enabledAccordingToPermission:@"define"];
    [self setControl:fieldOSKernel enabledAccordingToPermission:@"define"];
    [self setControl:fieldOSInitrd enabledAccordingToPermission:@"define"];
    [self setControl:fieldOSCommandLine enabledAccordingToPermission:@"define"];

    if (![self currentEntityHasPermission:@"define"])
    {
        [interfaceController closeWindow:nil];
        [driveController closeWindow:nil];
        [characterDeviceController closeWindow:nil];
        [graphicDeviceController closeWindow:nil];
        [inputDeviceController closeWindow:nil];
    }

    [interfaceController updateAfterPermissionChanged];
    [driveController updateAfterPermissionChanged];
}

/*! this message is used to flush the UI
*/
- (void)flushUI
{
    [_characterDevicesDatasource removeAllObjects];
    [_drivesDatasource removeAllObjects];
    [_graphicDevicesDatasource removeAllObjects];
    [_inputDevicesDatasource removeAllObjects];
    [_nicsDatasource removeAllObjects];

    [tableCharacterDevices reloadData];
    [tableDrives reloadData];
    [tableGraphicsDevices reloadData];
    [tableInputDevices reloadData];
    [tableInterfaces reloadData];
}


#pragma mark -
#pragma mark Notification handlers

/*! called if entity changes it presence
    @param aNotification the notification
*/
- (void)_didUpdatePresence:(CPNotification)aNotification
{
    [self checkIfRunning];
    [self enableGUI:([_entity XMPPShow] == TNStropheContactStatusBusy)];
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

    [self getXMLDesc];

    return YES;
}

/*! called when a basic definition field has changed
    @param aNotification the notification
*/
- (void)_didEditDefinition:(CPNotification)aNotification
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

    if ([object isKindOfClass:TNTabView])
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

    if ([object isKindOfClass:TNTabView])
        [object selectTabViewItem:item];
    else
    {
        var idx = [CPIndexSet indexSetWithIndex:[object rowForItem:item]];
        [object selectRowIndexes:idx byExtendingSelection:NO]
    }
}

/*! handle definition changes. If all values match ones stored in
    @param shouldSetEdited if yes, will try to set GUI in edited mode
*/
- (void)handleDefinitionEdition:(BOOL)shouldSetEdited
{
    if (shouldSetEdited)
    {
        if (!_definitionRecovered)
            return;

        _definitionEdited = YES;
        [buttonDefine setThemeState:CPThemeStateDefault];
        [buttonDefine setEnabled:YES];
        [buttonDefine setImage:_imageEdited];
    }
    else
    {
        _definitionEdited = NO;
        [buttonDefine setImage:nil];
        [buttonDefine setEnabled:NO];
        [buttonDefine unsetThemeState:CPThemeStateDefault];
    }
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
        inputType   = [defaults objectForKey:@"TNDescDefaultInputType"],
        inputBus    = [defaults objectForKey:@"TNDescDefaultInputBus"];

    [stepperNumberCPUs setDoubleValue:cpu];
    [fieldMemory setStringValue:mem];
    [fieldStringXMLDesc setStringValue:@""];
    [buttonOnPowerOff selectItemWithTitle:opo];
    [buttonOnReboot selectItemWithTitle:or];
    [buttonOnCrash selectItemWithTitle:oc];
    [buttonClocks selectItemWithTitle:clock];
    [switchPAE setOn:((pae == 1) ? YES : NO) animated:YES sendAction:NO];
    [switchACPI setOn:((acpi == 1) ? YES : NO) animated:YES sendAction:NO];
    [switchAPIC setOn:((apic == 1) ? YES : NO) animated:YES sendAction:NO];
    [switchHugePages setOn:((hp == 1) ? YES : NO) animated:YES sendAction:NO];
    [buttonMachines removeAllItems];
    [buttonDomainType removeAllItems];

    [_nicsDatasource removeAllObjects];
    [_drivesDatasource removeAllObjects];
    [_inputDevicesDatasource removeAllObjects];
    [_graphicDevicesDatasource removeAllObjects];

    [tableInterfaces reloadData];
    [tableDrives reloadData];
    [tableInputDevices reloadData];
    [tableGraphicsDevices reloadData];
}

/*! checks if virtual machine is running. if yes, display the masking view
*/
- (void)checkIfRunning
{
    var XMPPShow = [_entity XMPPShow];

    if (XMPPShow != TNStropheContactStatusBusy)
    {
        [driveController closeWindow:nil];
        [inputDeviceController closeWindow:nil];
        [interfaceController closeWindow:nil];
        [graphicDeviceController closeWindow:nil];
        [characterDeviceController closeWindow:nil];

        if (_definitionEdited)
            [TNAlert showAlertWithMessage:CPBundleLocalizedString(@"Definition edited", @"Definition edited")
                              informative:CPBundleLocalizedString(@"You started the virtual machine, but you haven't save the current changes.", @"You started the virtual machine, but you haven't save the current changes.")];
    }
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
    if ([_libvirtDomain type] == TNLibvirtDomainTypeXen && (aType == "linux"))
        aType = "xen";

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
        if (defaultDomainType && [buttonDomainType itemWithTitle:defaultDomainType])
            [buttonDomainType selectItemWithTitle:defaultDomainType];
        else
            [buttonDomainType selectItemAtIndex:0];
        [self setControl:buttonDomainType enabledAccordingToPermission:@"define"];
        [buttonDomainType setEnabled:YES];

        [buttonMachines setEnabled:NO];
        [buttonMachines removeAllItems];

        [self updateMachinesAccordingToDomainType];
    }

    if ([capabilities containsChildrenWithName:@"features"])
    {
        var features = [capabilities firstChildWithName:@"features"];

        [switchPAE setEnabled:NO];
        if ([features containsChildrenWithName:@"nonpae"] && [features containsChildrenWithName:@"pae"] )
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

/*! update the GUI according to selected Domain Type
*/
- (void)updateMachinesAccordingToDomainType
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
    if (defaultMachine && [buttonMachines itemWithTitle:defaultMachine])
        [buttonMachines selectItemWithTitle:defaultMachine];
    else
        [buttonMachines selectItemAtIndex:0];

    [self handleDefinitionEdition:YES];
}

/*! make the GUI in disabled mode
    @param shouldEnableGUI set if GUI should be enabled or disabled
*/
- (void)enableGUI:(BOOL)shouldEnableGUI
{
    [buttonBoot setEnabled:shouldEnableGUI];
    [buttonClocks setEnabled:shouldEnableGUI];
    [buttonDefine setEnabled:shouldEnableGUI];
    [buttonDomainType setEnabled:shouldEnableGUI];
    [buttonGuests setEnabled:shouldEnableGUI];
    [buttonMachines setEnabled:shouldEnableGUI];
    [buttonOnCrash setEnabled:shouldEnableGUI];
    [buttonOnPowerOff setEnabled:shouldEnableGUI];
    [buttonOnReboot setEnabled:shouldEnableGUI];
    [buttonUndefine setEnabled:shouldEnableGUI];
    [buttonXMLEditorDefine setEnabled:shouldEnableGUI];
    [fieldBlockIOTuningWeight setEnabled:shouldEnableGUI];
    [fieldFilterNics setEnabled:shouldEnableGUI];
    [fieldMemory setEnabled:shouldEnableGUI];
    [fieldMemoryTuneGuarantee setEnabled:shouldEnableGUI];
    [fieldMemoryTuneHardLimit setEnabled:shouldEnableGUI];
    [fieldMemoryTuneSoftLimit setEnabled:shouldEnableGUI];
    [fieldMemoryTuneSwapHardLimit setEnabled:shouldEnableGUI];
    [fieldStringXMLDesc setEnabled:shouldEnableGUI];
    [stepperNumberCPUs setEnabled:shouldEnableGUI];
    [tableDrives setEnabled:shouldEnableGUI];
    [tableGraphicsDevices setEnabled:shouldEnableGUI];
    [tableInputDevices setEnabled:shouldEnableGUI];
    [tableInterfaces setEnabled:shouldEnableGUI];
    [tableCharacterDevices setEnabled:shouldEnableGUI];
    [_editButtonDrives setEnabled:shouldEnableGUI];
    [_editButtonGraphicDevice setEnabled:shouldEnableGUI];
    [_editButtonInputDevice setEnabled:shouldEnableGUI];
    [_editButtonNics setEnabled:shouldEnableGUI];
    [_editButtonCharacterDevice setEnabled:shouldEnableGUI];
    [_minusButtonDrives setEnabled:shouldEnableGUI];
    [_minusButtonGraphicDevice setEnabled:shouldEnableGUI];
    [_minusButtonInputDevice setEnabled:shouldEnableGUI];
    [_minusButtonNics setEnabled:shouldEnableGUI];
    [_minusButtonCharacterDevice setEnabled:shouldEnableGUI];
    [_plusButtonDrives setEnabled:shouldEnableGUI];
    [_plusButtonGraphics setEnabled:shouldEnableGUI];
    [_plusButtonInputs setEnabled:shouldEnableGUI];
    [_plusButtonNics setEnabled:shouldEnableGUI];
    [_plusButtonCharacter setEnabled:shouldEnableGUI];
    [switchACPI setEnabled:shouldEnableGUI];
    [switchAPIC setEnabled:shouldEnableGUI];
    [switchHugePages setEnabled:shouldEnableGUI];
    [switchPAE setEnabled:shouldEnableGUI];
    [fieldOSCommandLine setEnabled:shouldEnableGUI];
    [fieldOSKernel setEnabled:shouldEnableGUI];
    [fieldOSInitrd setEnabled:shouldEnableGUI];
    [fieldOSLoader setEnabled:shouldEnableGUI];

    [buttonBoot setNeedsDisplay:YES];
    [buttonClocks setNeedsDisplay:YES];
    [buttonDefine setNeedsDisplay:YES];
    [buttonDomainType setNeedsDisplay:YES];
    [buttonGuests setNeedsDisplay:YES];
    [buttonMachines setNeedsDisplay:YES];
    [buttonOnCrash setNeedsDisplay:YES];
    [buttonOnPowerOff setNeedsDisplay:YES];
    [buttonOnReboot setNeedsDisplay:YES];
    [buttonUndefine setNeedsDisplay:YES];
    [buttonXMLEditorDefine setNeedsDisplay:YES];
    [fieldBlockIOTuningWeight setNeedsDisplay:YES];
    [fieldFilterNics setNeedsDisplay:YES];
    [fieldMemory setNeedsDisplay:YES];
    [fieldMemoryTuneGuarantee setNeedsDisplay:YES];
    [fieldMemoryTuneHardLimit setNeedsDisplay:YES];
    [fieldMemoryTuneSoftLimit setNeedsDisplay:YES];
    [fieldMemoryTuneSwapHardLimit setNeedsDisplay:YES];
    [fieldOSCommandLine setNeedsDisplay:YES];
    [fieldOSKernel setNeedsDisplay:YES];
    [fieldOSInitrd setNeedsDisplay:YES];
    [fieldOSLoader setNeedsDisplay:YES];

    [fieldStringXMLDesc setNeedsDisplay:YES];
    [stepperNumberCPUs setNeedsDisplay:YES];
    [tableDrives setNeedsDisplay:YES];
    [tableGraphicsDevices setNeedsDisplay:YES];
    [tableInputDevices setNeedsDisplay:YES];
    [tableInterfaces setNeedsDisplay:YES];
    [_editButtonDrives setNeedsDisplay:YES];
    [_editButtonGraphicDevice setNeedsDisplay:YES];
    [_editButtonInputDevice setNeedsDisplay:YES];
    [_editButtonNics setNeedsDisplay:YES];
    [_minusButtonDrives setNeedsDisplay:YES];
    [_minusButtonGraphicDevice setNeedsDisplay:YES];
    [_minusButtonInputDevice setNeedsDisplay:YES];
    [_minusButtonNics setNeedsDisplay:YES];
    [_plusButtonDrives setNeedsDisplay:YES];
    [_plusButtonGraphics setNeedsDisplay:YES];
    [_plusButtonInputs setNeedsDisplay:YES];
    [_plusButtonNics setNeedsDisplay:YES];
    [switchACPI setNeedsDisplay:YES];
    [switchAPIC setNeedsDisplay:YES];
    [switchHugePages setNeedsDisplay:YES];
    [switchPAE setNeedsDisplay:YES];

    // if (shouldEnableGUI)
    //     [self buildGUIAccordingToCurrentGuest];
    [self handleDefinitionEdition:NO];

    [labelVirtualMachineIsRunning setHidden:shouldEnableGUI];
}

/*! Configure the Nuage Networking if needed
    according to the current _libvirtDomain
*/
- (void)_configureNuageIfNeeded
{
    if ([_libvirtDomain metadata] && [[[_libvirtDomain metadata] content] firstChildWithName:@"nuage"])
    {
        var nuageNetworks = [[[[_libvirtDomain metadata] content] firstChildWithName:@"nuage"] childrenWithName:@"nuage_network"];
        for (var i = 0; i < [nuageNetworks count]; i++)
        {
            var nuageNetwork = [nuageNetworks objectAtIndex:i],
                interface_mac = [[nuageNetwork firstChildWithName:@"interface_mac"] valueForAttribute:@"address"];

            for (var j = 0; j < [[[_libvirtDomain devices] interfaces] count]; j++)
            {
                var nic = [[[_libvirtDomain devices] interfaces] objectAtIndex:j];
                if ([[nic MAC] uppercaseString] == [interface_mac uppercaseString])
                {
                    [nic setType:TNLibvirtDeviceInterfaceTypeNuage];
                    [nic setNuageNetworkName:[nuageNetwork valueForAttribute:@"name"]];
                }
            }
        }
    }
}

#pragma mark -
#pragma mark Actions

/*! add a new input device
    @param aSender the sender of the action
*/
- (IBAction)addInputDevice:(id)aSender
{
    var inputDevice = [[TNLibvirtDeviceInput alloc] init];
    [inputDevice setType:[buttonPreferencesInput title]];

    if (![_libvirtDomain devices])
        [_libvirtDomain setDevices:[[TNLibvirtDevices alloc] init]];

    [inputDeviceController setInputDevice:inputDevice];
    [inputDeviceController openWindow:aSender];
}

/*! edit current selected input device or create a new one
    @param aSender the sender of the action
*/
- (IBAction)editInputDevice:(id)aSender
{
    if (![self currentEntityHasPermission:@"define"])
        return;

    if ([tableInputDevices numberOfSelectedRows] <= 0)
    {
         [self addInputDevice:_plusButtonInputs];
         return;
    }

    var inputDevice = [_inputDevicesDatasource objectAtIndex:[tableInputDevices selectedRow]];

    [inputDeviceController setInputDevice:inputDevice];
    [inputDeviceController openWindow:aSender];
}

/*! remove the selected input device
    @param aSender the sender of the action
*/
- (IBAction)deleteInputDevice:(id)aSender
{
    if ([tableInputDevices numberOfSelectedRows] <= 0)
        return;

    [_inputDevicesDatasource removeObjectAtIndex:[tableInputDevices selectedRow]];
    [tableInputDevices reloadData];
    [self makeDefinitionEdited:YES];
}


/*! add graphic device
    @param aSender the sender of the action
*/
- (IBAction)addGraphicDevice:(id)aSender
{
    var graphicDevice = [[TNLibvirtDeviceGraphic alloc] init];

    if (![_libvirtDomain devices])
        [_libvirtDomain setDevices:[[TNLibvirtDevices alloc] init]];

    [graphicDeviceController setGraphicDevice:graphicDevice];
    [graphicDeviceController openWindow:aSender];
}

/*! edit the selected graphic device
    @param aSender the sender of the action
*/
- (IBAction)editGraphicDevice:(id)aSender
{
    if (![self currentEntityHasPermission:@"define"])
        return;

    if ([tableGraphicsDevices numberOfSelectedRows] <= 0)
    {
         [self addGraphicDevice:_plusButtonGraphics];
         return;
    }

    var graphicDevice = [_graphicDevicesDatasource objectAtIndex:[tableGraphicsDevices selectedRow]];

    [graphicDeviceController setGraphicDevice:graphicDevice];
    [graphicDeviceController openWindow:aSender];
}

/*! remove the selected graphic device
    @param aSender the sender of the action
*/
- (IBAction)deleteGraphicDevice:(id)aSender
{
    if ([tableGraphicsDevices numberOfSelectedRows] <= 0)
        return;

    [_graphicDevicesDatasource removeObjectAtIndex:[tableGraphicsDevices selectedRow]];
    [tableGraphicsDevices reloadData];
    [self makeDefinitionEdited:YES];
}

/*! add character device
    @param aSender the sender of the action
*/
- (IBAction)addCharacterDevice:(id)aSender
{
    var characterDevice = [[TNLibvirtDeviceCharacter alloc] init];

    [characterDevice setKind:TNLibvirtDeviceCharacterKindSerial];

    if (![_libvirtDomain devices])
        [_libvirtDomain setDevices:[[TNLibvirtDevices alloc] init]];

    [characterDeviceController setCharacterDevice:characterDevice];
    [characterDeviceController openWindow:aSender];
}

/*! edit the selected character device
    @param aSender the sender of the action
*/
- (IBAction)editCharacterDevice:(id)aSender
{
    if (![self currentEntityHasPermission:@"define"])
        return;

    if ([tableCharacterDevices numberOfSelectedRows] <= 0)
    {
         [self addCharacterDevice:_plusButtonCharacter];
         return;
    }

    var characterDevice = [_characterDevicesDatasource objectAtIndex:[tableCharacterDevices selectedRow]];

    [characterDeviceController setCharacterDevice:characterDevice];
    [characterDeviceController openWindow:aSender];
}

/*! remove the selected character device
    @param aSender the sender of the action
*/
- (IBAction)deleteCharacterDevice:(id)aSender
{
    if ([tableCharacterDevices numberOfSelectedRows] <= 0)
        return;

    [_characterDevicesDatasource removeObjectAtIndex:[tableCharacterDevices selectedRow]];
    [tableCharacterDevices reloadData];
    [self makeDefinitionEdited:YES];
}

/*! open the manual XML editor
    @param sender the sender of the action
*/
- (IBAction)openXMLEditor:(id)aSender
{
    [self requestVisible];
    if (![self isVisible])
        return;

    [popoverXMLEditor close];
    [popoverXMLEditor showRelativeToRect:nil ofView:buttonXMLEditor preferredEdge:nil];
    [popoverXMLEditor setDefaultButton:buttonXMLEditorDefine];
    [fieldStringXMLDesc setNeedsDisplay:YES];
}

/*! close the manual XML editor
    @param sender the sender of the action
*/
- (IBAction)closeXMLEditor:(id)aSender
{
    [popoverXMLEditor close];
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
    var newNic = [[TNLibvirtDeviceInterface alloc] init],
        newNicSource = [[TNLibvirtDeviceInterfaceSource alloc] init];

    [newNic setType:TNLibvirtDeviceInterfaceTypeBridge];
    [newNic setModel:TNLibvirtDeviceInterfaceModelRTL8139];
    [newNic setMAC:[self generateMacAddr]];
    [newNic setSource:newNicSource];
    [interfaceController setNic:newNic];
    if ([_libvirtDomain metadata])
        [interfaceController setMetadata:[_libvirtDomain metadata]];
    [interfaceController openWindow:_plusButtonNics];

    [self makeDefinitionEdited:YES];
}

/*! open the network editor
    @param sender the sender of the action
*/
- (IBAction)editInterface:(id)aSender
{
    if (![self currentEntityHasPermission:@"define"])
        return;

    if ([tableInterfaces numberOfSelectedRows] <= 0)
    {
         [self addNetworkCard:_plusButtonNics];
         return;
    }

    var nicObject = [_nicsDatasource objectAtIndex:[tableInterfaces selectedRow]];

    [interfaceController setNic:nicObject];
    if ([_libvirtDomain metadata])
        [interfaceController setMetadata:[_libvirtDomain metadata]];

    if ([aSender isKindOfClass:CPMenuItem])
        aSender = _editButtonNics;

    [interfaceController openWindow:aSender];
}

/*! delete a network card
    @param sender the sender of the action
*/
- (IBAction)deleteNetworkCard:(id)aSender
{
    if (![self currentEntityHasPermission:@"define"])
        return;


    if (![self isVisible])
        return;

    if ([tableInterfaces numberOfSelectedRows] <= 0)
    {
         [TNAlert showAlertWithMessage:CPBundleLocalizedString(@"Error", @"Error")
                           informative:CPBundleLocalizedString(@"You must select a network interface", @"You must select a network interface")];
         return;
    }

     var selectedIndexes = [tableInterfaces selectedRowIndexes];

     [_nicsDatasource removeObjectsAtIndexes:selectedIndexes];

     [tableInterfaces reloadData];
     [tableInterfaces deselectAll];
     [self handleDefinitionEdition:YES];
}

/*! add a drive
    @param sender the sender of the action
*/
- (IBAction)addDrive:(id)aSender
{
    if (![self currentEntityHasPermission:@"define"])
        return;

    var newDrive = [[TNLibvirtDeviceDisk alloc] init],
        newDriveSource = [[TNLibvirtDeviceDiskSource alloc] init],
        newDriveTarget = [[TNLibvirtDeviceDiskTarget alloc] init],
        newDriveDriver = [[TNLibvirtDeviceDiskDriver alloc] init];

    [newDriveDriver setCache:TNLibvirtDeviceDiskDriverCacheDefault];

    [newDriveTarget setBus:TNLibvirtDeviceDiskTargetBusIDE];
    [newDriveTarget setDevice:nil];

    [newDriveSource setFile:@"/dev/null"];

    [newDrive setType:TNLibvirtDeviceDiskTypeFile];
    [newDrive setDevice:TNLibvirtDeviceDiskDeviceDisk];
    [newDrive setSource:newDriveSource];
    [newDrive setTarget:newDriveTarget];
    [newDrive setDriver:newDriveDriver];
    [driveController setDrive:newDrive];

    [driveController openWindow:_plusButtonDrives];
    [self makeDefinitionEdited:YES];
}

/*! open the drive editor
    @param sender the sender of the action
*/
- (IBAction)editDrive:(id)aSender
{
    if (![self currentEntityHasPermission:@"define"])
        return;

    if ([tableDrives numberOfSelectedRows] <= 0)
    {
         [self addDrive:_plusButtonDrives];
         return;
    }

    var driveObject = [_drivesDatasource objectAtIndex:[tableDrives selectedRow]];

    [driveController setDrive:driveObject];

    if ([aSender isKindOfClass:CPMenuItem])
        aSender = _minusButtonDrives;

    [driveController openWindow:aSender];
}

/*! delete a drive
    @param sender the sender of the action
*/
- (IBAction)deleteDrive:(id)aSender
{
    if (![self currentEntityHasPermission:@"define"])
        return;

    if ([tableDrives numberOfSelectedRows] <= 0)
    {
        [TNAlert showAlertWithMessage:CPBundleLocalizedString(@"Error", @"Error")
                          informative:CPBundleLocalizedString(@"You must select a drive", @"You must select a drive")];
        return;
    }

     var selectedIndexes = [tableDrives selectedRowIndexes];

     [_drivesDatasource removeObjectsAtIndexes:selectedIndexes];

     [tableDrives reloadData];
     [tableDrives deselectAll];
     [self handleDefinitionEdition:YES];
}

/*! perpare the interface according to the selected guest
    @param aSender the sender of the action
*/
- (IBAction)didChangeGuest:(id)aSender
{
    var guest       = [[aSender selectedItem] XMLGuest],
        osType      = [[guest firstChildWithName:@"os_type"] text],
        arch        = [[guest firstChildWithName:@"arch"] valueForAttribute:@"name"];

    [[[_libvirtDomain OS] type] setArchitecture:arch];
    [[[_libvirtDomain OS] type] setType:osType];

    if ([guest firstChildWithName:@"loader"])
        [[_libvirtDomain OS] setLoader:[[guest firstChildWithName:@"loader"] text]];

    [self buildGUIAccordingToCurrentGuest];

    [self didChangeDomainType:buttonDomainType];
    [self didChangeMachine:buttonMachines];
}

/*! update the value for domain type
    @param aSender the sender of the action
*/
- (IBAction)didChangeDomainType:(id)aSender
{
    [_libvirtDomain setType:[aSender title]];
    [[_libvirtDomain devices] setEmulator:nil];
    [self updateMachinesAccordingToDomainType];
    [self makeDefinitionEdited:aSender];
}

/*! update the value for boot
    @param aSender the sender of the action
*/
- (IBAction)didChangeBoot:(id)aSender
{
    if (![_libvirtDomain OS])
        [_libvirtDomain setOS:[[TNLibvirtDomainOS alloc] init]];
    [[_libvirtDomain OS] setBoot:[aSender title]];
    [self makeDefinitionEdited:aSender];
}

/*! update the value for kernel
    @param aSender the sender of the action
*/
- (IBAction)didChangeOSKernel:(id)aSender
{
    if (![_libvirtDomain OS])
        [_libvirtDomain setOS:[[TNLibvirtDomainOS alloc] init]];
    [[_libvirtDomain OS] setKernel:[aSender stringValue]];
    [self makeDefinitionEdited:aSender];
}

/*! update the value for initrd
    @param aSender the sender of the action
*/
- (IBAction)didChangeOSInitrd:(id)aSender
{
    if (![_libvirtDomain OS])
        [_libvirtDomain setOS:[[TNLibvirtDomainOS alloc] init]];
    [[_libvirtDomain OS] setInitrd:[aSender stringValue]];
    [self makeDefinitionEdited:aSender];
}

/*! update the value for cmdline
    @param aSender the sender of the action
*/
- (IBAction)didChangeOSCommandLine:(id)aSender
{
    if (![_libvirtDomain OS])
        [_libvirtDomain setOS:[[TNLibvirtDomainOS alloc] init]];
    [[_libvirtDomain OS] setCommandLine:[aSender stringValue]];
    [self makeDefinitionEdited:aSender];
}

/*! update the value for loader
    @param aSender the sender of the action
*/
- (IBAction)didChangeOSLoader:(id)aSender
{
    if (![_libvirtDomain OS])
        [_libvirtDomain setOS:[[TNLibvirtDomainOS alloc] init]];
    [[_libvirtDomain OS] setLoader:[aSender stringValue]];
    [self makeDefinitionEdited:aSender];
}

/*! update the value for onPowerOff
    @param aSender the sender of the action
*/
- (IBAction)didChangeOnPowerOff:(id)aSender
{
    [_libvirtDomain setOnPowerOff:[aSender title]];
    [self makeDefinitionEdited:aSender];
}

/*! update the value for onReboot
    @param aSender the sender of the action
*/
- (IBAction)didChangeOnReboot:(id)aSender
{
    [_libvirtDomain setOnReboot:[aSender title]];
    [self makeDefinitionEdited:aSender];
}

/*! update the value for onCrash
    @param aSender the sender of the action
*/
- (IBAction)didChangeOnCrash:(id)aSender
{
    [_libvirtDomain setOnCrash:[aSender title]];
    [self makeDefinitionEdited:aSender];
}

/*! update the value for PAE
    @param aSender the sender of the action
*/
- (IBAction)didChangePAE:(id)aSender
{
    if (![_libvirtDomain features])
        [_libvirtDomain setFeatures:[[TNLibvirtDomainFeatures alloc] init]];
    [[_libvirtDomain features] setPAE:[aSender isOn]];
    [self makeDefinitionEdited:aSender];
}

/*! update the value for ACPI
    @param aSender the sender of the action
*/
- (IBAction)didChangeACPI:(id)aSender
{
    if (![_libvirtDomain features])
        [_libvirtDomain setFeatures:[[TNLibvirtDomainFeatures alloc] init]];
    [[_libvirtDomain features] setACPI:[aSender isOn]];
    [self makeDefinitionEdited:aSender];
}

/*! update the value for APIC
    @param aSender the sender of the action
*/
- (IBAction)didChangeAPIC:(id)aSender
{
    if (![_libvirtDomain features])
        [_libvirtDomain setFeatures:[[TNLibvirtDomainFeatures alloc] init]];
    [[_libvirtDomain features] setAPIC:[aSender isOn]];
    [self makeDefinitionEdited:aSender];
}

/*! update the value for hugae page
    @param aSender the sender of the action
*/
- (IBAction)didChangeHugePages:(id)aSender
{
    if (![_libvirtDomain memoryBacking])
        [_libvirtDomain setMemoryBacking:[TNLibvirtDomainMemoryBacking new]];

    [[_libvirtDomain memoryBacking] setUseHugePages:[aSender isOn]];
    [self makeDefinitionEdited:aSender];
}

/*! update the value for clock
    @param aSender the sender of the action
*/
- (IBAction)didChangeClock:(id)aSender
{
    if (![_libvirtDomain clock])
        [_libvirtDomain setClock:[[TNLibvirtDomainClock alloc] init]];

    [[_libvirtDomain clock] setOffset:[aSender title]];
    [self makeDefinitionEdited:aSender];
}

/*! update the value for machine
    @param aSender the sender of the action
*/
- (IBAction)didChangeMachine:(id)aSender
{
    if (![_libvirtDomain OS])
        [_libvirtDomain setOS:[[TNLibvirtDomainOS alloc] init]];

    [[[_libvirtDomain OS] type] setMachine:[aSender title]];
    [self makeDefinitionEdited:aSender];
}

/*! update the value for memory
    @param aSender the sender of the action
*/
- (IBAction)didChangeMemory:(id)aSender
{
    [_libvirtDomain setMemory:([aSender intValue] * 1024)];
    [self makeDefinitionEdited:aSender];
}

/*! update the value for VNC Password
    @param aSender the sender of the action
*/
- (IBAction)didChangeVCPU:(id)aSender
{
    [_libvirtDomain setVCPU:[aSender intValue]];
    [self makeDefinitionEdited:aSender];
}

/*! update the value for memory tuning soft limit
    @param aSender the sender of the action
*/
- (IBAction)didChangeMemoryTuneSoftLimit:(id)aSender
{
    if ([aSender intValue] > 0)
    {
        if (![_libvirtDomain memoryTuning])
            [_libvirtDomain setMemoryTuning:[[TNLibvirtDomainMemoryTune alloc] init]];

        [[_libvirtDomain memoryTuning] setSoftLimit:[aSender intValue] * 1024];
    }
    else
        [[_libvirtDomain memoryTuning] setSoftLimit:nil];

    [self makeDefinitionEdited:aSender];
}

/*! update the value for memory tuning hard limit
    @param aSender the sender of the action
*/
- (IBAction)didChangeMemoryTuneHardLimit:(id)aSender
{
    if ([aSender intValue] > 0)
    {
        if (![_libvirtDomain memoryTuning])
            [_libvirtDomain setMemoryTuning:[[TNLibvirtDomainMemoryTune alloc] init]];

        [[_libvirtDomain memoryTuning] setHardLimit:[aSender intValue] * 1024];
    }
    else
        [[_libvirtDomain memoryTuning] setHardLimit:nil];

    [self makeDefinitionEdited:aSender];
}

/*! update the value for memory tuning guarantee
    @param aSender the sender of the action
*/
- (IBAction)didChangeMemoryTuneGuarantee:(id)aSender
{
    if ([aSender intValue] > 0)
    {
        if (![_libvirtDomain memoryTuning])
            [_libvirtDomain setMemoryTuning:[[TNLibvirtDomainMemoryTune alloc] init]];
        [[_libvirtDomain memoryTuning] setMinGuarantee:[aSender intValue] * 1024];
    }
    else
        [[_libvirtDomain memoryTuning] setMinGuarantee:nil];

    [self makeDefinitionEdited:aSender];
}

/*! update the value for memory tuning swap hard limit
    @param aSender the sender of the action
*/
- (IBAction)didChangeMemoryTuneSwapHardLimit:(id)aSender
{
    if ([aSender intValue] > 0)
    {
        if (![_libvirtDomain memoryTuning])
            [_libvirtDomain setMemoryTuning:[[TNLibvirtDomainMemoryTune alloc] init]];

        [[_libvirtDomain memoryTuning] setSwapHardLimit:[aSender intValue] * 1024];
    }
    else
        [[_libvirtDomain memoryTuning] setSwapHardLimit:nil];

    [self makeDefinitionEdited:aSender];
}

/*! update the value for block IO tuning weight
    @param aSender the sender of the action
*/
- (IBAction)didChangeBlockIOTuningWeight:(id)aSender
{
    if ([aSender intValue] > 0)
    {
        if (![_libvirtDomain blkiotune])
            [_libvirtDomain setBlkiotune:[[TNLibvirtDomainBlockIOTune alloc] init]];
        [[_libvirtDomain blkiotune] setWeight:[aSender intValue]];
    }
    else
        [[_libvirtDomain blkiotune] setWeight:nil];

    [self makeDefinitionEdited:aSender];
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

    [_entity sendStanza:stanza andRegisterSelector:@selector(_didGetXMLCapabilities:) ofObject:self];
}

/*! compute hypervisor capabilities
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)_didGetXMLCapabilities:(TNStropheStanza)aStanza
{
    [self enableGUI:NO];

    if ([aStanza type] == @"result")
    {
        [buttonGuests removeAllItems];

        var host = [aStanza firstChildWithName:@"host"],
            guests = [aStanza childrenWithName:@"guest"],
            _libvirtCapabilities = [CPDictionary dictionary];

        if ([guests count] == 0)
        {
            [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[_entity nickname]
                                                             message:CPBundleLocalizedString(@"Your hypervisor have not pushed any guest support. For some reason, you can't create domains. Sorry.", @"Your hypervisor have not pushed any guest support. For some reason, you can't create domains. Sorry.")
                                                                icon:TNGrowlIconError];
            [self enableGUI:NO];
        }

        [_libvirtCapabilities setObject:host forKey:@"host"];
        [_libvirtCapabilities setObject:[CPArray array] forKey:@"guests"];

        for (var i = 0; i < [guests count]; i++)
        {
            var guestItem   = [[TNVirtualMachineGuestItem alloc] init],
                guest       = [guests objectAtIndex:i],
                osType      = [[guest firstChildWithName:@"os_type"] text],
                arch        = [[guest firstChildWithName:@"arch"] valueForAttribute:@"name"];

            [guestItem setXMLGuest:guest];
            [guestItem setTitle:osType + @" (" + arch + @")"];
            [buttonGuests addItem:guestItem];

            [[_libvirtCapabilities objectForKey:@"guests"] addObject:guest];
        }

        var defaultGuest = [[CPUserDefaults standardUserDefaults] objectForKey:@"TNDescDefaultGuest"];
        if (defaultGuest && [buttonGuests itemWithTitle:defaultGuest])
            [buttonGuests selectItemWithTitle:defaultGuest];
        else
            [buttonGuests selectItemAtIndex:0];

        CPLog.trace(_libvirtCapabilities);
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
    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeVirtualMachineControl}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeVirtualMachineControlXMLDesc}];

    _libvirtDomain = nil;
    [_entity sendStanza:stanza andRegisterSelector:@selector(_didGetXMLDescription:) ofObject:self];
}

/*! compute hypervisor description
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)_didGetXMLDescription:(TNStropheStanza)aStanza
{
    var defaults = [CPUserDefaults standardUserDefaults];

    if ([aStanza type] == @"error")
    {
        [self handleIqErrorFromStanza:aStanza];
        return;
    }

    if ([aStanza firstChildWithName:@"not-defined"])
    {
        _libvirtDomain = [TNLibvirtDomain defaultDomainWithType:TNLibvirtDomainTypeKVM];
        [_libvirtDomain setName:[_entity nickname]];
        [_libvirtDomain setUUID:[[_entity JID] node]];
        [[[_libvirtDomain devices] inputs] addObject:[[TNLibvirtDeviceInput alloc] init]];
        [[[_libvirtDomain devices] graphics] addObject:[[TNLibvirtDeviceGraphic alloc] init]];

        // simulate controls changes
        [self didChangeMemory:fieldMemory];
        [self didChangeGuest:buttonGuests];
        [self didChangeVCPU:stepperNumberCPUs];
        [self didChangeAPIC:switchAPIC];
        [self didChangeACPI:switchACPI];
        [self didChangePAE:switchPAE];
        [self didChangeHugePages:switchHugePages];
        [self didChangeClock:buttonClocks];
        [self didChangeOnCrash:buttonOnCrash];
        [self didChangeOnReboot:buttonOnReboot];
        [self didChangeOnPowerOff:buttonOnPowerOff];
        [self didChangeMemoryTuneHardLimit:fieldMemoryTuneHardLimit];
        [self didChangeMemoryTuneSoftLimit:fieldMemoryTuneSoftLimit];
        [self didChangeMemoryTuneGuarantee:fieldMemoryTuneGuarantee];
        [self didChangeBlockIOTuningWeight:fieldBlockIOTuningWeight];
        [self didChangeBoot:buttonBoot];
        [self didChangeOSKernel:fieldOSKernel];
        [self didChangeOSInitrd:fieldOSInitrd];
        [self didChangeOSLoader:fieldOSLoader];
        [self didChangeOSCommandLine:fieldOSCommandLine];

        [_inputDevicesDatasource setContent:[[_libvirtDomain devices] inputs]];
        [tableInputDevices reloadData];

        [_graphicDevicesDatasource setContent:[[_libvirtDomain devices] graphics]];
        [tableGraphicsDevices reloadData];

        [_drivesDatasource setContent:[[_libvirtDomain devices] disks]];
        [tableDrives reloadData];

        [_nicsDatasource setContent:[[_libvirtDomain devices] interfaces]];
        [tableInterfaces reloadData];

        [_characterDevicesDatasource setContent:[[_libvirtDomain devices] characters]];
        [tableCharacterDevices reloadData];

        [self buildGUIAccordingToCurrentGuest];
        _definitionRecovered = YES;

        [self handleDefinitionEdition:([fieldMemory stringValue] != @"")];
        return;
    }

    _libvirtDomain = [[TNLibvirtDomain alloc] initWithXMLNode:[aStanza firstChildWithName:@"domain"]];

    [self selectGuestWithType:[[[_libvirtDomain OS] type] type] architecture:[[[_libvirtDomain OS] type] architecture]];
    [self buildGUIAccordingToCurrentGuest];

    // button domainType
    [buttonDomainType selectItemWithTitle:[_libvirtDomain type]];

    // button Machine
    [buttonMachines selectItemWithTitle:[[[_libvirtDomain OS] type] machine]];

    // Memory
    [fieldMemory setIntValue:([_libvirtDomain memory] / 1024)];

    // CPUs
    [stepperNumberCPUs setDoubleValue:[_libvirtDomain VCPU]];

    // button BOOT
    [self setControl:buttonBoot enabledAccordingToPermission:@"define"];
    [buttonBoot selectItemWithTitle:[[_libvirtDomain OS] boot]];

    // LIFECYCLE
    [buttonOnPowerOff selectItemWithTitle:[_libvirtDomain onPowerOff]];
    [buttonOnReboot selectItemWithTitle:[_libvirtDomain onReboot]];
    [buttonOnCrash selectItemWithTitle:[_libvirtDomain onCrash]];

    // APIC
    [switchAPIC setOn:NO animated:NO sendAction:NO];
    [switchAPIC setOn:[[_libvirtDomain features] isAPIC] animated:NO sendAction:NO];

    // ACPI
    [switchACPI setOn:NO animated:NO sendAction:NO];
    [switchACPI setOn:[[_libvirtDomain features] isACPI] animated:NO sendAction:NO];

    // PAE
    [switchPAE setOn:NO animated:NO sendAction:NO];
    [switchPAE setOn:[[_libvirtDomain features] isPAE] animated:NO sendAction:NO];

    // huge pages
    [switchHugePages setOn:NO animated:NO sendAction:NO];
    if ([_libvirtDomain memoryBacking] && [[_libvirtDomain memoryBacking] isUsingHugePages])
        [switchHugePages setOn:YES animated:NO sendAction:NO];

    //clock
    [self setControl:buttonClocks enabledAccordingToPermission:@"define"];
    [buttonClocks selectItemWithTitle:[[_libvirtDomain clock] offset]];

    // DRIVES
    [_drivesDatasource setContent:[[_libvirtDomain devices] disks]];
    [tableDrives reloadData];

    // NICS

    // Nuage hook
    [self _configureNuageIfNeeded];
    [_nicsDatasource setContent:[[_libvirtDomain devices] interfaces]];
    [tableInterfaces reloadData];

    // INPUT DEVICES
    [_inputDevicesDatasource setContent:[[_libvirtDomain devices] inputs]];
    [tableInputDevices reloadData];

    // GRAPHIC DEVICES
    [_graphicDevicesDatasource setContent:[[_libvirtDomain devices] graphics]];
    [tableGraphicsDevices reloadData];

    // CHARACTERS DEVICES
    [_characterDevicesDatasource setContent:[[_libvirtDomain devices] characters]];
    [tableCharacterDevices reloadData];

    // MEMORY TUNING
    if ([[_libvirtDomain memoryTuning] softLimit])
        [fieldMemoryTuneSoftLimit setIntValue:[[_libvirtDomain memoryTuning] softLimit] / 1024];
    else
        [fieldMemoryTuneSoftLimit setStringValue:@""];
    if ([[_libvirtDomain memoryTuning] hardLimit])
        [fieldMemoryTuneHardLimit setIntValue:[[_libvirtDomain memoryTuning] hardLimit] / 1024];
    else
        [fieldMemoryTuneHardLimit setStringValue:@""];
    if ([[_libvirtDomain memoryTuning] minGuarantee])
        [fieldMemoryTuneGuarantee setIntValue:[[_libvirtDomain memoryTuning] minGuarantee] / 1024];
    else
        [fieldMemoryTuneGuarantee setStringValue:@""];
    if ([[_libvirtDomain memoryTuning] swapHardLimit])
        [fieldMemoryTuneSwapHardLimit setIntValue:[[_libvirtDomain memoryTuning] swapHardLimit] / 1024];
    else
        [fieldMemoryTuneSwapHardLimit setStringValue:@""];

    // DIRECT KERNEL BOOT
    if ([[_libvirtDomain OS] kernel])
        [fieldOSKernel setStringValue:[[_libvirtDomain OS] kernel]];
    else
        [fieldOSKernel setStringValue:@""];
    if ([[_libvirtDomain OS] initrd])
        [fieldOSInitrd setStringValue:[[_libvirtDomain OS] initrd]];
    else
        [fieldOSInitrd setStringValue:@""];
    if ([[_libvirtDomain OS] commandLine])
        [fieldOSCommandLine setStringValue:[[_libvirtDomain OS] commandLine]];
    else
        [fieldOSCommandLine setStringValue:@""];
    if ([[_libvirtDomain OS] loader])
        [fieldOSLoader setStringValue:[[_libvirtDomain OS] loader]];
    else
        [fieldOSLoader setStringValue:@""];

    // BLOCK IO TUNING
    if ([[_libvirtDomain blkiotune] weight])
        [fieldBlockIOTuningWeight setIntValue:[[_libvirtDomain blkiotune] weight]];
    else
        [fieldBlockIOTuningWeight setStringValue:@""];

    // MANUAL
    _stringXMLDesc = [[aStanza firstChildWithName:@"domain"] stringValue];
    [fieldStringXMLDesc setStringValue:@""];
    if (_stringXMLDesc)
    {
        _stringXMLDesc  = _stringXMLDesc.replace("\n  \n", "\n");
        _stringXMLDesc  = _stringXMLDesc.replace("xmlns='http://www.gajim.org/xmlns/undeclared' ", "");
        [fieldStringXMLDesc setStringValue:_stringXMLDesc];
    }

    _definitionRecovered = YES;
    [self handleDefinitionEdition:NO];
    [self enableGUI:([_entity XMPPShow] == TNStropheContactStatusBusy)];

    return NO;
}

/*! ask hypervisor to define XML
*/
- (void)defineXML
{
    var stanza = [TNStropheStanza iqWithType:@"set"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeVirtualMachineDefinition}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeVirtualMachineDefinitionDefine}];

    // dirty way to avoid having zombie consoles.
    // As we don't support adding console, we'll see a better
    // way later.
    [[[_libvirtDomain devices] characters] filterUsingPredicate:_consoleFilterPredicate];

    CPLog.info("XML Definition is : " + [[_libvirtDomain XMLNode] stringValue]);
    [stanza addNode:[_libvirtDomain XMLNode]];
    [buttonDefine setImage:_imageDefining];
    [buttonDefine setStringValue:CPLocalizedString(@"Sending...", @"Sending...")];
    [self enableGUI:NO];
    [self sendStanza:stanza andRegisterSelector:@selector(_didDefineXML:)];
}

/*! ask hypervisor to define XML from string
*/
- (void)defineXMLString
{
    var desc;
    try
    {
        desc = (new DOMParser()).parseFromString(unescape(""+[fieldStringXMLDesc stringValue]+""), "text/xml").getElementsByTagName("domain")[0];
        if (!desc || typeof(desc) == "undefined")
            [CPException raise:CPInternalInconsistencyException reason:@"Not valid XML"];
    }
    catch (e)
    {
        [TNAlert showAlertWithMessage:CPLocalizedString(@"Error", @"Error")
                          informative:CPLocalizedString(@"Unable to parse the given XML", @"Unable to parse the given XML")
                          style:CPCriticalAlertStyle];
        [popoverXMLEditor close];
        return;
    }
    var stanza      = [TNStropheStanza iqWithType:@"get"],
        descNode    = [TNXMLNode nodeWithXMLNode:desc];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeVirtualMachineDefinition}];
    [stanza addChildWithName:@"archipel" andAttributes:{"action": TNArchipelTypeVirtualMachineDefinitionDefine}];
    [stanza addNode:descNode];

    [buttonDefine setImage:_imageDefining];
    [self enableGUI:NO];
    [self sendStanza:stanza andRegisterSelector:@selector(_didDefineXML:)];
    [popoverXMLEditor close];
}

/*! compute hypervisor answer about the definition
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)_didDefineXML:(TNStropheStanza)aStanza
{
    var responseType    = [aStanza type],
        responseFrom    = [aStanza from];

    [buttonDefine setStringValue:CPLocalizedString(@"Validate", @"Validate")];
    if (responseType == @"result")
    {
        CPLog.info(@"Definition of virtual machine " + [_entity nickname] + " sucessfuly updated")
        [[CPNotificationCenter defaultCenter] postNotificationName:TNArchipelDefinitionUpdatedNotification object:self];
        [self handleDefinitionEdition:NO];
    }
    else if (responseType == @"error")
    {
        [self handleIqErrorFromStanza:aStanza];
    }

    [self enableGUI:YES];
    return NO;
}

/*! ask hypervisor to undefine virtual machine. but before ask for a confirmation
*/
- (void)undefineXML
{
        var alert = [TNAlert alertWithMessage:CPBundleLocalizedString(@"Are you sure you want to undefine this virtual machine ?", @"Are you sure you want to undefine this virtual machine ?")
                                informative:CPBundleLocalizedString(@"All your changes will be definitly lost.", @"All your changes will be definitly lost.")
                                     target:self
                                     actions:[[CPBundleLocalizedString(@"Undefine", @"Undefine"), @selector(performUndefineXML:)], [CPBundleLocalizedString(@"Cancel", @"Cancel"), nil]]];
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
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[_entity nickname]
                                                         message:CPBundleLocalizedString(@"Virtual machine has been undefined", @"Virtual machine has been undefined")];
        _libvirtDomain = nil;
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

    switch ([aNotification object])
    {
        case tableDrives:
            [driveController closeWindow:nil];
            if ([[aNotification object] numberOfSelectedRows] > 0)
            {
                [self setControl:_minusButtonDrives enabledAccordingToPermission:@"define"];
                [self setControl:_editButtonDrives enabledAccordingToPermission:@"define"];
            }
            break;

        case tableInterfaces:
            [interfaceController closeWindow:nil];
            if ([[aNotification object] numberOfSelectedRows] > 0)
            {
                [self setControl:_minusButtonDrives enabledAccordingToPermission:@"define"];
                [self setControl:_editButtonDrives enabledAccordingToPermission:@"define"];
            }
            break;

        case tableCharacterDevices:
            [characterDeviceController closeWindow:nil];
            if ([[aNotification object] numberOfSelectedRows] > 0)
            {
                [self setControl:_minusButtonCharacterDevice enabledAccordingToPermission:@"define"];
                [self setControl:_editButtonCharacterDevice enabledAccordingToPermission:@"define"];
            }
            break;

        case tableGraphicsDevices:
            [graphicDeviceController closeWindow:nil];
            break;

        case tableInputDevices:
            [inputDeviceController closeWindow:nil];
            break;
    }
}

/*! tabview delegate
*/
- (void)tabView:(TNTabView)aTabView didSelectTabViewItem:(CPTabViewItem)anItem
{
    [interfaceController closeWindow:nil];
    [driveController closeWindow:nil];
    [inputDeviceController closeWindow:nil];
    [graphicDeviceController closeWindow:nil];
    [characterDeviceController closeWindow:nil];
    [popoverXMLEditor close];
}

@end



// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNVirtualMachineDefinitionController], comment);
}
