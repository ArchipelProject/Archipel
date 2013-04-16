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
@import <AppKit/CPScrollView.j>
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

@import "../../Model/TNModule.j"
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

@class TNTabView
@global CPLocalizedString
@global CPLocalizedStringFromTableInBundle
@global CPApp

function _generateMacAddr()
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

var TNModuleControlForDriveAdd                          = @"DriveAdd",
    TNModuleControlForDriveRemove                       = @"DriveRemove",
    TNModuleControlForDriveEdit                         = @"DriveEdit",
    TNModuleControlForNicAdd                            = @"NicAdd",
    TNModuleControlForNicRemove                         = @"NicRemove",
    TNModuleControlForNicEdit                           = @"NicEdit",
    TNModuleControlForCharacterDeviceAdd                = @"CharacterDeviceAdd",
    TNModuleControlForCharacterDeviceRemove             = @"CharacterDeviceRemove",
    TNModuleControlForCharacterDeviceEdit               = @"CharacterDeviceEdit",
    TNModuleControlForGraphicDeviceAdd                  = @"GraphicDeviceAdd",
    TNModuleControlForGraphicDeviceRemove               = @"GraphicDeviceRemove",
    TNModuleControlForGraphicDeviceEdit                 = @"GraphicDeviceEdit",
    TNModuleControlForInputDeviceAdd                    = @"InputDeviceAdd",
    TNModuleControlForInputDeviceRemove                 = @"InputDeviceRemove",
    TNModuleControlForInputDeviceEdit                   = @"InputDeviceEdit";

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
    @outlet CPPopUpButton               buttonDomainType;
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
    @outlet CPTextField                 fieldBootloader;
    @outlet CPTextField                 fieldMemory;
    @outlet CPTextField                 fieldMemoryTuneGuarantee;
    @outlet CPTextField                 fieldMemoryTuneHardLimit;
    @outlet CPTextField                 fieldMemoryTuneSoftLimit;
    @outlet CPTextField                 fieldMemoryTuneSwapHardLimit;
    @outlet CPTextField                 fieldName;
    @outlet CPTextField                 fieldOSInitrd;
    @outlet CPTextField                 fieldOSKernel;
    @outlet CPTextField                 fieldOSLoader;
    @outlet CPTextField                 fieldPreferencesDomainType;
    @outlet CPTextField                 fieldPreferencesGuest;
    @outlet CPTextField                 fieldPreferencesMachine;
    @outlet CPTextField                 fieldPreferencesMemory;
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
    @outlet LPMultiLineTextField        fieldBootloaderArgs;
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
    @outlet CPCheckbox                  checkboxACPI;
    @outlet CPCheckbox                  checkboxAPIC;
    @outlet CPCheckbox                  checkboxHugePages;
    @outlet CPCheckbox                  checkboxNestedVirtualization;
    @outlet CPCheckbox                  checkboxPAE;
    @outlet CPCheckbox                  checkboxPreferencesHugePages;
    @outlet CPCheckbox                  checkboxEnableUSB;
    @outlet TNTabView                   tabViewParameters;
    @outlet TNTextFieldStepper          stepperNumberCPUs;

    BOOL                                _definitionEdited              @accessors(setter=setDefinitionEdited:);

    CPPredicate                         _consoleFilterPredicate;
    CPString                            _stringXMLDesc;
    TNTableViewDataSource               _characterDevicesDatasource;
    TNTableViewDataSource               _drivesDatasource;
    TNTableViewDataSource               _graphicDevicesDatasource;
    TNTableViewDataSource               _inputDevicesDatasource;
    TNTableViewDataSource               _nicsDatasource;
    TNXMLNode                           _libvirtCapabilities;
    TNXMLNode                           _libvirtDomain;
}


#pragma mark -
#pragma mark Initialization

/*! called at cib awaking
*/
- (void)awakeFromCib
{
    var bundle      = [CPBundle bundleForClass:[self class]],
        mainBundle  = [CPBundle mainBundle],
        defaults    = [CPUserDefaults standardUserDefaults],
        imageBg     = CPImageInBundle(@"bg-controls.png", nil, bundle);

    [scrollViewContentView setDocumentView:viewMainContent];
    [scrollViewContentView setAutohidesScrollers:YES];
    var frameSize = [scrollViewContentView contentSize];
    [viewMainContent setFrameOrigin:CGPointMake(0.0, 0.0)];
    [viewMainContent setFrameSize:frameSize];
    [viewMainContent setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [viewBottomControl setBackgroundColor:[CPColor colorWithPatternImage:imageBg]];

     var inset = CGInsetMake(2, 2, 2, 5);
    [buttonUndefine setImage:CPImageInBundle(@"undefine.png", CGSizeMake(16, 16), bundle)];
    [buttonUndefine setValue:inset forThemeAttribute:@"content-inset"];
    [buttonXMLEditor setImage:CPImageInBundle(@"IconsButtons/editxml.png", CGSizeMake(16, 16), mainBundle)];
    [buttonXMLEditor setValue:inset forThemeAttribute:@"content-inset"];

    // set theme of buttonXMLEditorDefine to default
    [buttonXMLEditorDefine setThemeState:CPThemeStateDefault];

    // paramaters tabView
    var tabViewItemStandard = [[CPTabViewItem alloc] initWithIdentifier:@"standard"],
        tabViewItemAdvanced = [[CPTabViewItem alloc] initWithIdentifier:@"advanced"],
        tabViewItemDrives = [[CPTabViewItem alloc] initWithIdentifier:@"IDtabViewItemDrives"],
        tabViewItemNics = [[CPTabViewItem alloc] initWithIdentifier:@"IDtabViewItemNics"],
        tabViewItemCharacter = [[CPTabViewItem alloc] initWithIdentifier:@"IDtabViewItemCharacters"];

    [tabViewParameters setContentBackgroundColor:[CPColor colorWithHexString:@"f5f5f5"]];

    var scrollViewParametersStandard = [[CPScrollView alloc] initWithFrame:[tabViewParameters bounds]],
        scrollViewParametersAdvanced = [[CPScrollView alloc] initWithFrame:[tabViewParameters bounds]];

    [viewParametersStandard setAutoresizingMask:CPViewWidthSizable];
    [viewParametersStandard setFrameSize:CGSizeMake([scrollViewParametersStandard frameSize].width, [viewParametersStandard frameSize].height)];

    [viewParametersAdvanced setAutoresizingMask:CPViewWidthSizable];
    [viewParametersAdvanced setFrameSize:CGSizeMake([scrollViewParametersAdvanced frameSize].width, [viewParametersAdvanced frameSize].height)];

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

    var shadowTop    = CPImageInBundle(@"shadow-top.png", CGSizeMake(1.0, 10.0), bundle),
        shadowBottom = CPImageInBundle(@"shadow-bottom.png", CGSizeMake(1.0, 10.0), bundle);

    [viewParametersEffectTop setBackgroundColor:[CPColor colorWithPatternImage:shadowTop]];
    [viewParametersEffectBottom setBackgroundColor:[CPColor colorWithPatternImage:shadowBottom]];

    [fieldStringXMLDesc setTextColor:[CPColor blackColor]];
    [fieldStringXMLDesc setFont:[CPFont fontWithName:@"Andale Mono, Courier New" size:12]];

    _stringXMLDesc = @"";

    // register defaults defaults
    [defaults registerDefaults:@{
            @"TNDescDefaultNumberCPU"     : [bundle objectForInfoDictionaryKey:@"TNDescDefaultNumberCPU"],
            @"TNDescDefaultMemory"        : [bundle objectForInfoDictionaryKey:@"TNDescDefaultMemory"],
            @"TNDescDefaultBoot"          : [bundle objectForInfoDictionaryKey:@"TNDescDefaultBoot"],
            @"TNDescDefaultVNCKeymap"     : [bundle objectForInfoDictionaryKey:@"TNDescDefaultVNCKeymap"],
            @"TNDescDefaultOnPowerOff"    : [bundle objectForInfoDictionaryKey:@"TNDescDefaultOnPowerOff"],
            @"TNDescDefaultOnReboot"      : [bundle objectForInfoDictionaryKey:@"TNDescDefaultOnReboot"],
            @"TNDescDefaultOnCrash"       : [bundle objectForInfoDictionaryKey:@"TNDescDefaultOnCrash"],
            @"TNDescDefaultClockOffset"   : [bundle objectForInfoDictionaryKey:@"TNDescDefaultClockOffset"],
            @"TNDescDefaultHugePages"     : [bundle objectForInfoDictionaryKey:@"TNDescDefaultHugePages"],
            @"TNDescDefaultEnableVNC"     : [bundle objectForInfoDictionaryKey:@"TNDescDefaultEnableVNC"],
            @"TNDescDefaultInputType"     : [bundle objectForInfoDictionaryKey:@"TNDescDefaultInputType"],
            @"TNDescDefaultDomainType"    : [bundle objectForInfoDictionaryKey:@"TNDescDefaultDomainType"],
            @"TNDescDefaultGuest"         : [bundle objectForInfoDictionaryKey:@"TNDescDefaultGuest"],
            @"TNDescDefaultMachine"       : [bundle objectForInfoDictionaryKey:@"TNDescDefaultMachine"],
            @"TNDescDefaultDriveCacheMode": [bundle objectForInfoDictionaryKey:@"TNDescDefaultDriveCacheMode"],
            @"TNDescMaxNumberCPU"         : [bundle objectForInfoDictionaryKey:@"TNDescMaxNumberCPU"]
    }];

    // DRIVES
    _drivesDatasource = [[TNTableViewDataSource alloc] init];
    [_drivesDatasource setTable:tableDrives];
    [_drivesDatasource setSearchableKeyPaths:[@"type", @"driver.type", @"target.device", @"source.sourceObject", @"target.bus", @"driver.cache"]];
    [[tableDrives tableColumnWithIdentifier:@"self"] setDataView:[dataViewDrivesPrototype duplicate]];
    [tableDrives setDataSource:_drivesDatasource];
    [tableDrives setTarget:self];
    [tableDrives setDoubleAction:@selector(editDrive:)];
    [tableDrives setBackgroundColor:TNArchipelDefaultColorsTableView];

    [viewDrivesContainer setBorderedWithHexColor:@"#C0C7D2"];

    [driveController setDelegate:self];

    [fieldFilterDrives setTarget:_drivesDatasource];
    [fieldFilterDrives setAction:@selector(filterObjects:)];

    [self addControlsWithIdentifier:TNModuleControlForDriveAdd
                              title:CPBundleLocalizedString(@"Add a new drive", @"Add a new drive")
                             target:self
                             action:@selector(addDrive:)
                              image:CPImageInBundle(@"IconsButtons/plus.png",nil, mainBundle)];

    [self addControlsWithIdentifier:TNModuleControlForDriveRemove
                              title:CPBundleLocalizedString(@"Remove selected drive(s)", @"Remove selected drive(s)")
                             target:self
                             action:@selector(deleteDrive:)
                              image:CPImageInBundle(@"IconsButtons/minus.png",nil, mainBundle)];

    [self addControlsWithIdentifier:TNModuleControlForDriveEdit
                              title:CPBundleLocalizedString(@"Edit selected drive", @"Edit selected drive")
                             target:self
                             action:@selector(editDrive:)
                              image:CPImageInBundle(@"IconsButtons/edit.png",nil, mainBundle)];

    [buttonBarControlDrives setButtons:[
        [self buttonWithIdentifier:TNModuleControlForDriveAdd],
        [self buttonWithIdentifier:TNModuleControlForDriveRemove],
        [self buttonWithIdentifier:TNModuleControlForDriveEdit]]];

    [driveController setTable:tableDrives];

    // NICs
    _nicsDatasource = [[TNTableViewDataSource alloc] init];
    [_nicsDatasource setTable:tableInterfaces];
    [_nicsDatasource setSearchableKeyPaths:[@"type", @"model", @"MAC", @"source.bridge"]];
    [[tableInterfaces tableColumnWithIdentifier:@"self"] setDataView:[dataViewNICsPrototype duplicate]];
    [tableInterfaces setDataSource:_nicsDatasource];
    [tableInterfaces setTarget:self];
    [tableInterfaces setDoubleAction:@selector(editInterface:)];
    [tableInterfaces setBackgroundColor:TNArchipelDefaultColorsTableView];

    [viewNicsContainer setBorderedWithHexColor:@"#C0C7D2"];

    [interfaceController setDelegate:self];

    [fieldFilterNics setTarget:_nicsDatasource];
    [fieldFilterNics setAction:@selector(filterObjects:)];

    [self addControlsWithIdentifier:TNModuleControlForNicAdd
                              title:CPBundleLocalizedString(@"Add a new network interface", @"Add a new network interface")
                             target:self
                             action:@selector(addInterface:)
                              image:CPImageInBundle(@"IconsButtons/plus.png",nil, mainBundle)];

    [self addControlsWithIdentifier:TNModuleControlForNicRemove
                              title:CPBundleLocalizedString(@"Remove selected network interface(s)", @"Remove selected network interface(s)")
                             target:self
                             action:@selector(deleteInterface:)
                              image:CPImageInBundle(@"IconsButtons/minus.png",nil, mainBundle)];

    [self addControlsWithIdentifier:TNModuleControlForNicEdit
                              title:CPBundleLocalizedString(@"Edit selected network interface", @"Edit selected network interface")
                             target:self
                             action:@selector(editInterface:)
                              image:CPImageInBundle(@"IconsButtons/edit.png",nil, mainBundle)];

    [buttonBarControlNics setButtons:[
        [self buttonWithIdentifier:TNModuleControlForNicAdd],
        [self buttonWithIdentifier:TNModuleControlForNicRemove],
        [self buttonWithIdentifier:TNModuleControlForNicEdit]]];

    [interfaceController setTable:tableInterfaces];

    // Input Devices
    _inputDevicesDatasource = [[TNTableViewDataSource alloc] init];
    [[tableInputDevices tableColumnWithIdentifier:@"self"] setDataView:[dataViewInputDevicePrototype duplicate]];
    [tableInputDevices setTarget:self];
    [tableInputDevices setDoubleAction:@selector(editInputDevice:)];
    [tableInputDevices setBackgroundColor:TNArchipelDefaultColorsTableView];

    [_inputDevicesDatasource setTable:tableInputDevices];
    [tableInputDevices setDataSource:_inputDevicesDatasource];
    [viewInputDevicesContainer setBorderedWithHexColor:@"#C0C7D2"];

    [self addControlsWithIdentifier:TNModuleControlForInputDeviceAdd
                              title:CPBundleLocalizedString(@"Add a new input device", @"Add a new input device")
                             target:self
                             action:@selector(addInputDevice:)
                              image:CPImageInBundle(@"IconsButtons/plus.png",nil, mainBundle)];

    [self addControlsWithIdentifier:TNModuleControlForInputDeviceRemove
                              title:CPBundleLocalizedString(@"Remove selected input device(s)", @"Remove selected input device(s)")
                             target:self
                             action:@selector(deleteInputDevice:)
                              image:CPImageInBundle(@"IconsButtons/minus.png",nil, mainBundle)];

    [self addControlsWithIdentifier:TNModuleControlForInputDeviceEdit
                              title:CPBundleLocalizedString(@"Edit selected input device", @"Edit selected input device")
                             target:self
                             action:@selector(editInputDevice:)
                              image:CPImageInBundle(@"IconsButtons/edit.png",nil, mainBundle)];

    [buttonBarInputDevices setButtons:[
        [self buttonWithIdentifier:TNModuleControlForInputDeviceAdd],
        [self buttonWithIdentifier:TNModuleControlForInputDeviceRemove],
        [self buttonWithIdentifier:TNModuleControlForDriveEdit]]];

    [inputDeviceController setDelegate:self];
    [inputDeviceController setTable:tableInputDevices];

    // Graphic Devices
    _graphicDevicesDatasource = [[TNTableViewDataSource alloc] init];
    [[tableGraphicsDevices tableColumnWithIdentifier:@"self"] setDataView:[dataViewGraphicDevicePrototype duplicate]];
    [tableGraphicsDevices setTarget:self];
    [tableGraphicsDevices setDoubleAction:@selector(editGraphicDevice:)];
    [tableGraphicsDevices setBackgroundColor:TNArchipelDefaultColorsTableView];

    [_graphicDevicesDatasource setTable:tableGraphicsDevices];
    [tableGraphicsDevices setDataSource:_graphicDevicesDatasource];
    [viewGraphicDevicesContainer setBorderedWithHexColor:@"#C0C7D2"];

    [self addControlsWithIdentifier:TNModuleControlForGraphicDeviceAdd
                              title:CPBundleLocalizedString(@"Add a new Graphic device", @"Add a new Graphic device")
                             target:self
                             action:@selector(addGraphicDevice:)
                              image:CPImageInBundle(@"IconsButtons/plus.png",nil, mainBundle)];

    [self addControlsWithIdentifier:TNModuleControlForGraphicDeviceRemove
                              title:CPBundleLocalizedString(@"Remove selected Graphic device(s)", @"Remove selected Graphic device(s)")
                             target:self
                             action:@selector(deleteGraphicDevice:)
                              image:CPImageInBundle(@"IconsButtons/minus.png",nil, mainBundle)];

    [self addControlsWithIdentifier:TNModuleControlForGraphicDeviceEdit
                              title:CPBundleLocalizedString(@"Edit selected Graphic device", @"Edit selected Graphic device")
                             target:self
                             action:@selector(editGraphicDevice:)
                              image:CPImageInBundle(@"IconsButtons/edit.png",nil, mainBundle)];

    [buttonBarGraphicDevices setButtons:[
        [self buttonWithIdentifier:TNModuleControlForGraphicDeviceAdd],
        [self buttonWithIdentifier:TNModuleControlForGraphicDeviceRemove],
        [self buttonWithIdentifier:TNModuleControlForGraphicDeviceEdit]]];

    [graphicDeviceController setDelegate:self];
    [graphicDeviceController setTable:tableGraphicsDevices];


    // Character devices
    _consoleFilterPredicate = [CPPredicate predicateWithFormat:@"not kind like %@", TNLibvirtDeviceCharacterKindConsole];
    _characterDevicesDatasource = [[TNTableViewDataSource alloc] init];
    [_characterDevicesDatasource setDisplayFilter:_consoleFilterPredicate];

    [[tableCharacterDevices tableColumnWithIdentifier:@"self"] setDataView:[dataViewCharacterDevicePrototype duplicate]];
    [tableCharacterDevices setTarget:self];
    [tableCharacterDevices setDoubleAction:@selector(editCharacterDevice:)];
    [tableCharacterDevices setBackgroundColor:TNArchipelDefaultColorsTableView];


    [_characterDevicesDatasource setTable:tableCharacterDevices];
    [tableCharacterDevices setDataSource:_characterDevicesDatasource];
    [viewCharacterDevicesContainer setBorderedWithHexColor:@"#C0C7D2"];
    [_characterDevicesDatasource setSearchableKeyPaths:[@"type", @"kind", @"protocol.type", @"target.type", @"target.address", @"target.port", @"target.name", @"source.path", @"source.mode", @"source.host", @"source.service"]]
    [fieldFilterCharacters setTarget:_characterDevicesDatasource];
    [fieldFilterCharacters setAction:@selector(filterObjects:)];

    [self addControlsWithIdentifier:TNModuleControlForCharacterDeviceAdd
                              title:CPBundleLocalizedString(@"Add a new Character device", @"Add a new Character device")
                             target:self
                             action:@selector(addCharacterDevice:)
                              image:CPImageInBundle(@"IconsButtons/plus.png",nil, mainBundle)];

    [self addControlsWithIdentifier:TNModuleControlForCharacterDeviceRemove
                              title:CPBundleLocalizedString(@"Remove selected Character device(s)", @"Remove selected Character device(s)")
                             target:self
                             action:@selector(deleteCharacterDevice:)
                              image:CPImageInBundle(@"IconsButtons/minus.png",nil, mainBundle)];

    [self addControlsWithIdentifier:TNModuleControlForCharacterDeviceEdit
                              title:CPBundleLocalizedString(@"Edit selected Character device", @"Edit selected Character device")
                             target:self
                             action:@selector(editCharacterDevice:)
                              image:CPImageInBundle(@"IconsButtons/edit.png",nil, mainBundle)];

    [buttonBarCharacterDevices setButtons:[
        [self buttonWithIdentifier:TNModuleControlForCharacterDeviceAdd],
        [self buttonWithIdentifier:TNModuleControlForCharacterDeviceRemove],
        [self buttonWithIdentifier:TNModuleControlForCharacterDeviceEdit]]];

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

    // checkboxes
    [checkboxPAE setState:CPOffState];
    [checkboxAPIC setState:CPOffState];
    [checkboxACPI setState:CPOffState];

    //CPUStepper
    [stepperNumberCPUs setMaxValue:[defaults integerForKey:@"TNDescMaxNumberCPU"]];
    [stepperNumberCPUs setMinValue:1];
    [stepperNumberCPUs setDoubleValue:1];
    [stepperNumberCPUs setValueWraps:NO];
    [stepperNumberCPUs setAutorepeat:NO];
    [stepperNumberCPUs setTarget:self];
    [stepperNumberCPUs setAction:@selector(didChangeVCPU:)];
}


#pragma mark -
#pragma mark TNModule overrides

/*! called when module is loaded
*/
- (BOOL)willLoad
{
    if (![super willLoad])
        return NO;

    var center = [CPNotificationCenter defaultCenter];

    [center addObserver:self selector:@selector(_didUpdatePresence:) name:TNStropheContactPresenceUpdatedNotification object:_entity];

    [self registerSelector:@selector(_didReceivePush:) forPushNotificationType:TNArchipelPushNotificationDefinitition];

    // rebind delegates after removing all observers
    [tableDrives setDelegate:nil];
    [tableDrives setDelegate:self];
    [self _updateControlsStateForTable:tableDrives];

    [tableInterfaces setDelegate:nil];
    [tableInterfaces setDelegate:self];
    [self _updateControlsStateForTable:tableInterfaces];

    [tableCharacterDevices setDelegate:nil];
    [tableCharacterDevices setDelegate:self];
    [self _updateControlsStateForTable:tableCharacterDevices];

    [tableInputDevices setDelegate:nil];
    [tableInputDevices setDelegate:self];
    [self _updateControlsStateForTable:tableInputDevices];

    [tableGraphicsDevices setDelegate:nil];
    [tableGraphicsDevices setDelegate:self];
    [self _updateControlsStateForTable:tableGraphicsDevices];

    [driveController setEntity:_entity];
    [interfaceController setEntity:_entity];

    [fieldStringXMLDesc setStringValue:@""];
}

/*! called when module is unloaded
*/
- (void)willUnload
{
    _libvirtDomain = nil;
    _definitionEdited = NO;
    [self flushUI];
    [self setEnableAllControls:NO];

    [super willUnload];
}

/*! called when module becomes visible
*/
- (BOOL)willShow
{
    if (![super willShow])
        return NO;

    [[CPApp mainWindow] setDefaultButton:buttonDefine];

    [self getCapabilities];
    [self _updateUIForCurrentEntityStatus];

    _definitionEdited = NO;

    return YES;
}

/*! called when module is hidden
*/
- (void)willHide
{
    [[CPApp mainWindow] setDefaultButton:nil];

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
                                     actions:[[CPBundleLocalizedString(@"Validate", @"Validate"), @selector(_saveEditionChanges:)], [CPBundleLocalizedString(@"Discard", @"Discard"), @selector(_discardEditionChanges:)]]];

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

    [defaults setBool:[checkboxPreferencesHugePages state] forKey:@"TNDescDefaultHugePages"];
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
    [checkboxPreferencesHugePages setState:[defaults boolForKey:@"TNDescDefaultHugePages"]];
}

/*! called when user permissions changed
*/
- (void)permissionsChanged
{
    [super permissionsChanged];
    [self _updateUIForCurrentEntityStatus];
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
    [self setControl:checkboxACPI enabledAccordingToPermission:@"define"];
    [self setControl:checkboxAPIC enabledAccordingToPermission:@"define"];
    [self setControl:checkboxHugePages enabledAccordingToPermission:@"define"];
    [self setControl:checkboxEnableUSB enabledAccordingToPermission:@"define"];
    [self setControl:checkboxNestedVirtualization enabledAccordingToPermission:@"define"];
    [self setControl:checkboxPAE enabledAccordingToPermission:@"define"];
    [self setControl:fieldMemoryTuneSoftLimit enabledAccordingToPermission:@"define"];
    [self setControl:fieldMemoryTuneHardLimit enabledAccordingToPermission:@"define"];
    [self setControl:fieldMemoryTuneGuarantee enabledAccordingToPermission:@"define"];
    [self setControl:fieldMemoryTuneSwapHardLimit enabledAccordingToPermission:@"define"];
    [self setControl:fieldBlockIOTuningWeight enabledAccordingToPermission:@"define"];
    [self setControl:fieldOSLoader enabledAccordingToPermission:@"define"];
    [self setControl:fieldOSKernel enabledAccordingToPermission:@"define"];
    [self setControl:fieldOSInitrd enabledAccordingToPermission:@"define"];
    [self setControl:fieldOSCommandLine enabledAccordingToPermission:@"define"];
    [self setControl:fieldBootloader enabledAccordingToPermission:@"define"];
    [self setControl:fieldBootloaderArgs enabledAccordingToPermission:@"define"];

    [self _updateControlsStateForTable:tableGraphicsDevices];
    [self _updateControlsStateForTable:tableInputDevices];
    [self _updateControlsStateForTable:tableInterfaces];
    [self _updateControlsStateForTable:tableDrives];
    [self _updateControlsStateForTable:tableCharacterDevices];

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
    [self _updateUIForCurrentEntityStatus];
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


#pragma mark -
#pragma mark Utilities

/*! Called when module should hide and user wants to discard changes
    @param someUserInfo CPArray containing the next item and the object (the tabview or the roster outlineview)
*/
- (void)_discardEditionChanges:(id)someUserInfo
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
- (void)_saveEditionChanges:(id)someUserInfo
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

/*! make the GUI in disabled mode
    @param shouldEnableGUI set if GUI should be enabled or disabled
*/
- (void)setEnableAllControls:(BOOL)shouldEnableGUI
{
    [buttonDefine setEnabled:shouldEnableGUI];

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
    [checkboxACPI setEnabled:shouldEnableGUI];
    [checkboxAPIC setEnabled:shouldEnableGUI];
    [checkboxHugePages setEnabled:shouldEnableGUI];
    [checkboxEnableUSB setEnabled:shouldEnableGUI];
    [checkboxNestedVirtualization setEnabled:shouldEnableGUI];
    [checkboxPAE setEnabled:shouldEnableGUI];
    [fieldOSCommandLine setEnabled:shouldEnableGUI];
    [fieldOSKernel setEnabled:shouldEnableGUI];
    [fieldOSInitrd setEnabled:shouldEnableGUI];
    [fieldOSLoader setEnabled:shouldEnableGUI];
    [fieldBootloader setEnabled:shouldEnableGUI];
    [fieldBootloaderArgs setEnabled:shouldEnableGUI];
    [fieldName setEnabled:shouldEnableGUI];

    if (shouldEnableGUI)
    {
        [self _updateControlsStateForTable:tableGraphicsDevices];
        [self _updateControlsStateForTable:tableInputDevices];
        [self _updateControlsStateForTable:tableInterfaces];
        [self _updateControlsStateForTable:tableDrives];
        [self _updateControlsStateForTable:tableCharacterDevices];
    }
    else
    {
        [[self buttonWithIdentifier:TNModuleControlForDriveEdit] setEnabled:shouldEnableGUI];
        [[self buttonWithIdentifier:TNModuleControlForGraphicDeviceEdit] setEnabled:shouldEnableGUI];
        [[self buttonWithIdentifier:TNModuleControlForDriveEdit] setEnabled:shouldEnableGUI];
        [[self buttonWithIdentifier:TNModuleControlForNicEdit] setEnabled:shouldEnableGUI];
        [[self buttonWithIdentifier:TNModuleControlForCharacterDeviceEdit] setEnabled:shouldEnableGUI];
        [[self buttonWithIdentifier:TNModuleControlForDriveRemove] setEnabled:shouldEnableGUI];
        [[self buttonWithIdentifier:TNModuleControlForGraphicDeviceRemove] setEnabled:shouldEnableGUI];
        [[self buttonWithIdentifier:TNModuleControlForInputDeviceRemove] setEnabled:shouldEnableGUI];
        [[self buttonWithIdentifier:TNModuleControlForNicRemove] setEnabled:shouldEnableGUI];
        [[self buttonWithIdentifier:TNModuleControlForCharacterDeviceRemove] setEnabled:shouldEnableGUI];
        [[self buttonWithIdentifier:TNModuleControlForDriveAdd] setEnabled:shouldEnableGUI];
        [[self buttonWithIdentifier:TNModuleControlForGraphicDeviceAdd] setEnabled:shouldEnableGUI];
        [[self buttonWithIdentifier:TNModuleControlForInputDeviceAdd] setEnabled:shouldEnableGUI];
        [[self buttonWithIdentifier:TNModuleControlForNicAdd] setEnabled:shouldEnableGUI];
        [[self buttonWithIdentifier:TNModuleControlForCharacterDeviceAdd] setEnabled:shouldEnableGUI];
    }
}


#pragma mark -
#pragma mark Domains and Capabilities UI building

/*! set the default value of all widgets
*/
- (void)_updateUIWithDefaultDomainValues
{
    var defaults    = [CPUserDefaults standardUserDefaults],
        cpu         = [defaults integerForKey:@"TNDescDefaultNumberCPU"],
        mem         = [defaults objectForKey:@"TNDescDefaultMemory"],
        vnck        = [defaults objectForKey:@"TNDescDefaultVNCKeymap"],
        opo         = [defaults objectForKey:@"TNDescDefaultOnPowerOff"],
        or          = [defaults objectForKey:@"TNDescDefaultOnReboot"],
        oc          = [defaults objectForKey:@"TNDescDefaultOnCrash"],
        hp          = [defaults boolForKey:@"TNDescDefaultHugePages"],
        nv          = [defaults boolForKey:@"TNDescDefaultNestedVirtualization"],
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
    [checkboxPAE setState:((pae == 1) ? CPOnState : CPOffState)];
    [checkboxACPI setState:((acpi == 1) ? CPOnState : CPOffState)];
    [checkboxAPIC setState:((apic == 1) ? CPOnState : CPOffState)];
    [checkboxHugePages setState:((hp == 1) ? CPOnState : CPOffState)];
    [checkboxEnableUSB setState:CPOnState];
    [checkboxNestedVirtualization setState:((nv == 1) ? CPOnState : CPOffState)];
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

    [fieldOSKernel setStringValue:@""];
    [fieldOSInitrd setStringValue:@""];
    [fieldOSLoader setStringValue:@""];
    [fieldBootloaderArgs setStringValue:@""];
    [fieldOSCommandLine setStringValue:@""];
    [fieldBootloader setStringValue:@""];
    [fieldMemoryTuneSoftLimit setStringValue:@""];
    [fieldMemoryTuneHardLimit setStringValue:@""];
    [fieldMemoryTuneGuarantee setStringValue:@""];
    [fieldMemoryTuneSwapHardLimit setStringValue:@""];
    [fieldBlockIOTuningWeight setStringValue:@""];

    [fieldName setStringValue:[_entity name]];
}

/*! get the domain of the current guest with given type
    @param aType the type of the domain
    @return the TNXMLNode of the domain with given type
*/
- (TNXMLNode)_domainOfCurrentGuestWithType:(CPString)aType
{
    var currentSelectedGuest = [buttonGuests selectedItem],
        capabilities = [currentSelectedGuest representedObject],
        domains = [capabilities childrenWithName:@"domain"];

    for (var i = 0; i < [domains count]; i++)
    {
        var domain = [domains objectAtIndex:i];
        if ([domain valueForAttribute:@"type"] == aType)
            return domain
    }

    return nil;
}

/*! will select the item macthing given type and architecture
    @param aType the guest type
    @param anArch the architecture
*/
- (void)_selectGuestWithType:(CPString)aType architecture:(CPString)anArch
{
    var guests = [buttonGuests itemArray];

    for (var i = 0; i < [guests count]; i++)
    {
        var guest = [[guests objectAtIndex:i] representedObject];
        if (([[guest firstChildWithName:@"os_type"] text] == aType)
            && ([[guest firstChildWithName:@"arch"] valueForAttribute:@"name"] == anArch))
            [buttonGuests selectItemAtIndex:i];
    }
}

/*! checks if virtual machine is running. if yes, display the masking view
*/
- (void)_updateUIForCurrentEntityStatus
{
    var entityXMPPShow = [_entity XMPPShow];

    [self setEnableAllControls:(entityXMPPShow == TNStropheContactStatusBusy)];

    if (entityXMPPShow != TNStropheContactStatusBusy)
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

/*! set the value on controls, according to the selected guest
*/
- (void)_updateUIForCurrentGuest
{
    var currentSelectedGuest    = [buttonGuests selectedItem],
        capabilities            = [currentSelectedGuest representedObject],
        domains                 = [capabilities childrenWithName:@"domain"];

    // strips Tables devices if using XEN
    if (_libvirtDomain && [[domains firstObject] valueForAttribute:@"type"] == TNLibvirtDomainTypeXen)
    {
        var tablets = [];
        for (var i = 0; i < [[[_libvirtDomain devices] inputs] count]; i++)
        {
            var input = [[[_libvirtDomain devices] inputs] objectAtIndex:i];
            if ([input type] == TNLibvirtDeviceInputTypesTypeTablet)
                [tablets addObject:input];
        }

        [[[_libvirtDomain devices] inputs] removeObjectsInArray:tablets];
    }

    if (domains && [domains count] > 0)
    {
        [buttonDomainType removeAllItems];

        for (var i = 0; i < [domains count]; i++)
        {
            var domain = [domains objectAtIndex:i];
            [buttonDomainType addItemWithTitle:[domain valueForAttribute:@"type"]];
        }

        if (_libvirtDomain && [_libvirtDomain type])
        {
            [buttonDomainType selectItemWithTitle:[_libvirtDomain type]];
        }
        else
        {
            var defaultDomainType = [[CPUserDefaults standardUserDefaults] objectForKey:@"TNDescDefaultDomainType"];
            if (defaultDomainType && [buttonDomainType itemWithTitle:defaultDomainType])
                [buttonDomainType selectItemWithTitle:defaultDomainType];
            else
                [buttonDomainType selectItemAtIndex:0];
        }

        [self _updateUIFromDomainType];
    }

    if ([capabilities containsChildrenWithName:@"features"])
    {
        var features = [capabilities firstChildWithName:@"features"];

        [checkboxPAE setEnabled:NO];

        if ([features containsChildrenWithName:@"nonpae"] && [features containsChildrenWithName:@"pae"])
            [checkboxPAE setEnabled:([_entity XMPPShow] == TNStropheContactStatusBusy)];

        if (![features containsChildrenWithName:@"nonpae"] && [features containsChildrenWithName:@"pae"])
            [checkboxPAE setState:CPOnState];

        if ([features containsChildrenWithName:@"nonpae"] && ![features containsChildrenWithName:@"pae"])
            [checkboxPAE setState:CPOffState];

        [checkboxACPI setEnabled:NO];
        if ([features containsChildrenWithName:@"acpi"])
        {
            [checkboxACPI setEnabled:([_entity XMPPShow] == TNStropheContactStatusBusy) && [[features firstChildWithName:@"acpi"] valueForAttribute:@"toggle"] == "yes"];
            [checkboxACPI setState:[[features firstChildWithName:@"acpi"] valueForAttribute:@"default"] == "on" ? CPOnState : CPOffState];
        }

        [checkboxAPIC setEnabled:NO];
        if ([features containsChildrenWithName:@"apic"])
        {
            [checkboxAPIC setEnabled:([_entity XMPPShow] == TNStropheContactStatusBusy) && [[features firstChildWithName:@"apic"] valueForAttribute:@"toggle"] == "yes"];
            [checkboxAPIC setState:[[features firstChildWithName:@"apic"] valueForAttribute:@"default"] == "on" ? CPOnState : CPOffState];
        }
    }
}

/*! update the GUI according to selected Domain Type
*/
- (void)_updateUIFromDomainType
{
    var currentSelectedGuest = [buttonGuests selectedItem],
        capabilities = [currentSelectedGuest representedObject],
        currentDomain = [self _domainOfCurrentGuestWithType:[buttonDomainType title]],
        machines = [currentDomain childrenWithName:@"machine"];

    [buttonMachines removeAllItems];

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

    if (_libvirtDomain && [[_libvirtDomain OS] type] && [[[_libvirtDomain OS] type] machine])
    {
        [buttonMachines selectItemWithTitle:[[[_libvirtDomain OS] type] machine]];
    }
    else
    {
        [buttonMachines selectItemAtIndex:0];

        var defaultMachine = [[CPUserDefaults standardUserDefaults] objectForKey:@"TNDescDefaultMachine"];
        if (defaultMachine && [buttonMachines itemWithTitle:defaultMachine])
            [buttonMachines selectItemWithTitle:defaultMachine];
    }
}

/*! Simulates that al controls has changed
*/
- (void)_simulateControlsChanges
{
    [self didChangeName:fieldName];
    [self didChangeMemory:fieldMemory];
    [self didChangeGuest:buttonGuests];
    [self didChangeVCPU:stepperNumberCPUs];
    [self didChangeAPIC:checkboxAPIC];
    [self didChangeACPI:checkboxACPI];
    [self didChangePAE:checkboxPAE];
    [self didChangeHugePages:checkboxHugePages];
    [self didChangeEnableUSB:checkboxEnableUSB];
    [self didChangeNestedVirtualization:checkboxNestedVirtualization];
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
    [self didChangeBootloader:fieldBootloader];
    [self didChangeBootloaderArgs:fieldBootloaderArgs];
}

/*! Update the states of the controls button for given table view
    @param aTableView the tableView to consider
*/
- (void)_updateControlsStateForTable:(CPTabViewItem)aTableView
{
    var currentController,
        currentAddButton,
        currentDeleteButton,
        currentEditButton;

    switch (aTableView)
    {
        case tableDrives:
            currentController = driveController;
            currentAddButton = [self buttonWithIdentifier:TNModuleControlForDriveAdd];
            currentDeleteButton = [self buttonWithIdentifier:TNModuleControlForDriveRemove];
            currentEditButton = [self buttonWithIdentifier:TNModuleControlForDriveEdit];
            break;

        case tableInterfaces:
            currentController = interfaceController;
            currentAddButton = [self buttonWithIdentifier:TNModuleControlForNicAdd];
            currentDeleteButton = [self buttonWithIdentifier:TNModuleControlForNicRemove];
            currentEditButton = [self buttonWithIdentifier:TNModuleControlForNicEdit];
            break;

        case tableCharacterDevices:
            currentController = characterDeviceController;
            currentAddButton = [self buttonWithIdentifier:TNModuleControlForCharacterDeviceAdd];
            currentDeleteButton = [self buttonWithIdentifier:TNModuleControlForCharacterDeviceRemove];
            currentEditButton = [self buttonWithIdentifier:TNModuleControlForCharacterDeviceEdit];
            break;

        case tableGraphicsDevices:
            currentController = graphicDeviceController;
            currentAddButton = [self buttonWithIdentifier:TNModuleControlForGraphicDeviceAdd];
            currentDeleteButton = [self buttonWithIdentifier:TNModuleControlForGraphicDeviceRemove];
            currentEditButton = [self buttonWithIdentifier:TNModuleControlForGraphicDeviceEdit];
            break;

        case tableInputDevices:
            currentController = inputDeviceController;
            currentAddButton = [self buttonWithIdentifier:TNModuleControlForInputDeviceAdd];
            currentDeleteButton = [self buttonWithIdentifier:TNModuleControlForInputDeviceRemove];
            currentEditButton = [self buttonWithIdentifier:TNModuleControlForDriveEdit];
            break;
    }

    [currentController closeWindow:nil];

    [currentAddButton setEnabled:NO];
    [currentDeleteButton setEnabled:NO];
    [currentEditButton setEnabled:NO];

    [self setControl:currentAddButton enabledAccordingToPermission:@"define"];
    if ([aTableView numberOfSelectedRows] > 0)
    {
        [self setControl:currentDeleteButton enabledAccordingToPermission:@"define"];
        [self setControl:currentEditButton enabledAccordingToPermission:@"define"];
    }
}

/*! Prepare the UI according to received capabilities stanza
    @param aStanza the capabilities reply
*/
- (void)_prepareCapabilitiesFromStanza:(TNStropheStanza)aStanza
{
    [buttonGuests removeAllItems];

    var host = [aStanza firstChildWithName:@"host"],
        guests = [aStanza childrenWithName:@"guest"];

    _libvirtCapabilities = [CPDictionary dictionary];

    if ([guests count] == 0)
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[_entity name]
                                                         message:CPBundleLocalizedString(@"Your hypervisor have not pushed any guest support. For some reason, you can't create domains. Sorry.", @"Your hypervisor have not pushed any guest support. For some reason, you can't create domains. Sorry.")
                                                            icon:TNGrowlIconError];
    }

    [_libvirtCapabilities setObject:host forKey:@"host"];
    [_libvirtCapabilities setObject:[CPArray array] forKey:@"guests"];

    for (var i = 0; i < [guests count]; i++)
    {
        var guestItem = [[CPMenuItem alloc] init],
            guest = [guests objectAtIndex:i],
            osType = [[guest firstChildWithName:@"os_type"] text],
            arch = [[guest firstChildWithName:@"arch"] valueForAttribute:@"name"];

        [guestItem setRepresentedObject:guest];
        [guestItem setTitle:osType + @" (" + arch + @")"];
        [buttonGuests addItem:guestItem];

        [[_libvirtCapabilities objectForKey:@"guests"] addObject:guest];
    }

    [buttonGuests selectItemAtIndex:0]

    var defaultGuest = [[CPUserDefaults standardUserDefaults] objectForKey:@"TNDescDefaultGuest"];
    if (defaultGuest && [buttonGuests itemWithTitle:defaultGuest])
        [buttonGuests selectItemWithTitle:defaultGuest];
}

/*! Prepare the UI according to received undefined domain
    @param aStanza the getXML reply
*/
- (void)_prepareUndefinedDomainFromStanza:(TNStropheStanza)aStanza
{
    [self _updateUIWithDefaultDomainValues];

    _libvirtDomain = [TNLibvirtDomain defaultDomainWithType:[buttonDomainType title] osType:[buttonMachines title]];

    [_libvirtDomain setName:[fieldName stringValue]];

    [_libvirtDomain setUUID:[[_entity JID] node]];

    [[[_libvirtDomain devices] inputs] addObject:[[TNLibvirtDeviceInput alloc] init]];
    [[[_libvirtDomain devices] graphics] addObject:[[TNLibvirtDeviceGraphic alloc] init]];

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

    [self setEnableAllControls:YES];
    [fieldName setEnabled:NO];
}

/*! Prepare the UI according to received defined domain
    @param aStanza the getXML reply
*/
- (void)_prepareDefinedDomainFromStanza:(TNStropheStanza)aStanza
{
    _libvirtDomain = [[TNLibvirtDomain alloc] initWithXMLNode:[aStanza firstChildWithName:@"domain"]];

    [self _selectGuestWithType:[[[_libvirtDomain OS] type] type] architecture:[[[_libvirtDomain OS] type] architecture]];

    // VM Name
    [fieldName setStringValue:[_libvirtDomain name]];
    [fieldName setEnabled:YES];

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
    if ([[_libvirtDomain OS] boot])
        [buttonBoot selectItemWithTitle:[[_libvirtDomain OS] boot]];
    else
        [buttonBoot selectItemAtIndex:0];

    // LIFECYCLE
    [buttonOnPowerOff selectItemWithTitle:[_libvirtDomain onPowerOff]];
    [buttonOnReboot selectItemWithTitle:[_libvirtDomain onReboot]];
    [buttonOnCrash selectItemWithTitle:[_libvirtDomain onCrash]];

    // APIC
    [checkboxAPIC setState:[[_libvirtDomain features] isAPIC]];

    // ACPI
    [checkboxACPI setState:[[_libvirtDomain features] isACPI]];

    // PAE
    [checkboxPAE setState:[[_libvirtDomain features] isPAE]];

    // huge pages
    [checkboxHugePages setState:CPOffState]
    if ([_libvirtDomain memoryBacking] && [[_libvirtDomain memoryBacking] isUsingHugePages])
        [checkboxHugePages setState:YES];

    // Enable USB
    [checkboxEnableUSB setState:CPOnState];
    if ([_libvirtDomain devices])
    {
        var controllers = [[_libvirtDomain devices] controllers];

        for (var i = 0; i < [controllers count]; i++)
        {
            var type = [[controllers objectAtIndex:i] type],
                model = [[controllers objectAtIndex:i] model];

            if (type == TNLibvirtDeviceControllerTypeUSB && model == TNLibvirtDeviceControllerModelNONE)
            {
                [checkboxEnableUSB setState:CPOffState];
                break;
            }
        }
    }

    // nested virtualization
    [checkboxNestedVirtualization setState:[self _isNestedVirtualizationEnabled] ? CPOnState : CPOffState];

    //clock
    [self setControl:buttonClocks enabledAccordingToPermission:@"define"];
    [buttonClocks selectItemWithTitle:[[_libvirtDomain clock] offset]];

    // DRIVES
    [_drivesDatasource setContent:[[_libvirtDomain devices] disks]];
    [tableDrives reloadData];

    // NICS
    if ([_libvirtDomain metadata] && [[[_libvirtDomain metadata] content] firstChildWithName:@"nuage"])
    {
        // NUAGE MANAGEMENT
        var nuageNetworks = [[[[_libvirtDomain metadata] content] firstChildWithName:@"nuage"] childrenWithName:@"nuage_network"];

        for (var i = 0; i < [nuageNetworks count]; i++)
        {
            var nuageNetwork = [nuageNetworks objectAtIndex:i],
                interface_mac = [[nuageNetwork firstChildWithName:@"interface"] valueForAttribute:@"mac"],
                interface_ip = [[nuageNetwork firstChildWithName:@"interface"] valueForAttribute:@"address"];

            for (var j = 0; j < [[[_libvirtDomain devices] interfaces] count]; j++)
            {
                var nic = [[[_libvirtDomain devices] interfaces] objectAtIndex:j];
                if ([[nic MAC] uppercaseString] == [interface_mac uppercaseString])
                {
                    [nic setType:TNLibvirtDeviceInterfaceTypeNuage];
                    [nic setNuageNetworkName:[nuageNetwork valueForAttribute:@"name"]];
                    [nic setNuageNetworkInterfaceIP:interface_ip];
                }
            }
        }
    }

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
    [fieldMemoryTuneSoftLimit setIntValue:[[_libvirtDomain memoryTuning] softLimit] / 1024 || @""];
    [fieldMemoryTuneHardLimit setIntValue:[[_libvirtDomain memoryTuning] hardLimit] / 1024  || @""];
    [fieldMemoryTuneGuarantee setIntValue:[[_libvirtDomain memoryTuning] minGuarantee] / 1024 || @""];
    [fieldMemoryTuneSwapHardLimit setIntValue:[[_libvirtDomain memoryTuning] swapHardLimit] / 1024 || @""];

    // DIRECT KERNEL BOOT
    [fieldOSKernel setStringValue:[[_libvirtDomain OS] kernel] || @""];
    [fieldOSInitrd setStringValue:[[_libvirtDomain OS] initrd] || @""];
    [fieldOSCommandLine setStringValue:[[_libvirtDomain OS] commandLine] || @""];
    [fieldOSLoader setStringValue:[[_libvirtDomain OS] loader] || @""];

    // HOST BOOTLOADER
    [fieldBootloader setStringValue:[_libvirtDomain bootloader] || @""];
    [fieldBootloaderArgs setStringValue:[_libvirtDomain bootloaderArgs] || @""];

    // BLOCK IO TUNING
    [fieldBlockIOTuningWeight setIntValue:[[_libvirtDomain blkiotune] weight] || @""];

    // MANUAL XML
    _stringXMLDesc = [[aStanza firstChildWithName:@"domain"] stringValue];
    [fieldStringXMLDesc setStringValue:@""];
    if (_stringXMLDesc)
    {
        _stringXMLDesc  = _stringXMLDesc.replace("\n  \n", "\n");
        _stringXMLDesc  = _stringXMLDesc.replace("xmlns='http://www.gajim.org/xmlns/undeclared' ", "");
        _stringXMLDesc  = _stringXMLDesc.replace("xmlns=\"http://www.gajim.org/xmlns/undeclared\" ", "");
        [fieldStringXMLDesc setStringValue:_stringXMLDesc];
    }

    [self setEnableAllControls:([_entity XMPPShow] == TNStropheContactStatusBusy)];
}


#pragma mark -
#pragma mark Nested Virtualization Helpers

/*! returns the value of cpu argument (if any)
*/
- (id)_getCommandLineArgumentOfCPU
{
    var commandLine             = [_libvirtDomain commandLine],
        ValueOfCPUArgument      = nil,
        isValueOfCPUArgument    = NO;
    if (commandLine)
    {
        for (var i = 0; i < [commandLine count]; i++)
        {
            for (var j = 0; j < [[[commandLine objectAtIndex:i] args] count]; j++)
            {
                var argumentValue = [[[commandLine objectAtIndex:i] args] objectAtIndex:j];
                if ([argumentValue value] == "-cpu")
                {
                    isValueOfCPUArgument = YES;
                    continue;
                }
                if (isValueOfCPUArgument)
                {
                    ValueOfCPUArgument   = argumentValue;
                    isValueOfCPUArgument = NO;
                }
                // we want last values that get passed to last -cpu
                // so don't stop iteration after finding one
            }
        }
    }
    return ValueOfCPUArgument;
}

/*! returns YES if finds vmx extension in cpu argument
*/
- (void)_isNestedVirtualizationEnabled
{
    return (([[self _getCommandLineArgumentOfCPU] value] || "").indexOf("+vmx") > -1);
}

/*! adds "+vmx" to cpu argument if finds any cpu argument, else will
  create one like: -cpu qemu64,+vmx
*/
- (void)_addNestedVirtualization
{
    var valueOfCPUArgument = [self _getCommandLineArgumentOfCPU];
    CPLog.info("found cpu argument? " + valueOfCPUArgument);
    if (!valueOfCPUArgument)
    {
        // we don't have any -cpu argument let's create one
        // first check the commandLine
        var commandLineObjects = [_libvirtDomain commandLine],
            commandLine        = nil;
        if (!commandLineObjects || [commandLineObjects count] === 0)
        {
            // hmm, we need commandLine too
            var tmpCommandLine = [CPArray array];
            commandLine = [[TNLibvirtDomainQEMUCommandLine alloc] init];
            [tmpCommandLine addObject:commandLine];
            [_libvirtDomain setCommandLine:tmpCommandLine];
        }
        else
            commandLine = [commandLineObjects objectAtIndex:0];
        // get arguments
        var theArguments = [commandLine args];
        [theArguments addObject:[[TNLibvirtDomainQEMUCommandLineArgument alloc] initWithValue:"-cpu"]];
        valueOfCPUArgument = [[TNLibvirtDomainQEMUCommandLineArgument alloc] initWithValue:"qemu64"];
        [theArguments addObject:valueOfCPUArgument];
    }
    var theValue = [valueOfCPUArgument value];
    if (theValue.indexOf("+vmx") == -1)
    {
        theValue += ",+vmx";
        [valueOfCPUArgument setValue:theValue];
    }
}

/*! removes any "+vmx" arguments that has been passed to value of -cpu argument
  also removes if it can match exactly -cpu qemu64,+vmx
*/
- (void)_removeNestedVirtualization
{
    var commandLine             = [_libvirtDomain commandLine],
        isValueOfCPUArgument    = NO;
    if (commandLine)
    {
        // remove any "+vmx"
        for (var i = 0; i < [commandLine count]; i++)
        {
            var shouldBeRemoved = [CPArray array];
            for (var j = 0; j < [[[commandLine objectAtIndex:i] args] count]; j++)
            {
                var argumentValue = [[[commandLine objectAtIndex:i] args] objectAtIndex:j];
                if ([argumentValue value] == "-cpu")
                {
                    isValueOfCPUArgument = YES;
                    continue;
                }
                if (isValueOfCPUArgument)
                {
                    var tmpValue = [argumentValue value];
                    // remove it, if it's exactly what we add
                    if (tmpValue == "qemu64,+vmx")
                    {
                        [shouldBeRemoved addObject:j];
                        [shouldBeRemoved addObject:(j - 1)];
                    }
                    // just remove +vmx
                    else
                    {
                        tmpValue = tmpValue.replace(new RegExp(",?\\+vmx", 'g'), '');
                        [argumentValue setValue:tmpValue];
                        isValueOfCPUArgument = NO;
                    }
                }
            }
            if ([shouldBeRemoved count] > 0)
            {
                var tmpArguments = [CPArray array];
                for (var j = 0; j < [[[commandLine objectAtIndex:i] args] count]; j++)
                {
                    if ([shouldBeRemoved indexOfObject:j] !== CPNotFound)
                        // skip it
                        continue;
                    [tmpArguments addObject:[[[commandLine objectAtIndex:i] args] objectAtIndex:j]];
                }
                [[commandLine objectAtIndex:i] setArgs:tmpArguments];
            }
        }
    }
}


#pragma mark -
#pragma mark XMPP Controls

/*! ask hypervisor for its capabilities
*/
- (void)getCapabilities
{
    [self setEnableAllControls:NO];

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
    if ([aStanza type] != @"result")
    {
        [self handleIqErrorFromStanza:aStanza];
        return NO;
    }

    [self _prepareCapabilitiesFromStanza:aStanza];

    [self getXMLDesc];

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
        [self _prepareUndefinedDomainFromStanza:aStanza];
    else
        [self _prepareDefinedDomainFromStanza:aStanza];

    [self _updateUIForCurrentGuest];

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

    [self _simulateControlsChanges];

    // dirty way to avoid having zombie consoles.
    // As we don't support adding console, we'll see a better
    // way later.
    [[[_libvirtDomain devices] characters] filterUsingPredicate:_consoleFilterPredicate];

    CPLog.info("XML Definition is : " + [[_libvirtDomain XMLNode] stringValue]);
    [stanza addNode:[_libvirtDomain XMLNode]];

    [buttonDefine setStringValue:CPLocalizedString(@"Sending...", @"Sending...")];

    [self setEnableAllControls:NO];

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
    var stanza = [TNStropheStanza iqWithType:@"get"];
    try
    {
        var descNode = [TNXMLNode nodeWithXMLNode:desc];
        [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeVirtualMachineDefinition}];
        [stanza addChildWithName:@"archipel" andAttributes:{"action": TNArchipelTypeVirtualMachineDefinitionDefine}];
        [stanza addNode:descNode];
    }
    catch (e)
    {
        [TNAlert showAlertWithMessage:CPLocalizedString(@"Error", @"Error")
                          informative:CPLocalizedString(@"Unable to parse the given XML", @"Unable to parse the given XML")+("\n"+e)
                                style:CPCriticalAlertStyle];
        [popoverXMLEditor close];
        return;
    }

    [self setEnableAllControls:NO];
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
        CPLog.info(@"Definition of virtual machine " + [_entity name] + " sucessfuly updated")
        [[CPNotificationCenter defaultCenter] postNotificationName:TNArchipelDefinitionUpdatedNotification object:self];
    }
    else if (responseType == @"error")
    {
        [self handleIqErrorFromStanza:aStanza];
    }

    [self setEnableAllControls:YES];

    _definitionEdited = NO;

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
    if ([aStanza type] == @"error")
    {
        [self handleIqErrorFromStanza:aStanza];
        return NO;
    }


    [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[_entity name]
                                                     message:CPBundleLocalizedString(@"Virtual machine has been undefined", @"Virtual machine has been undefined")];
    _libvirtDomain = nil;
    [self getXMLDesc];

    return NO;
}


#pragma mark -
#pragma mark Delegates

/*! table view delegate
*/
- (void)tableViewSelectionDidChange:(CPNotification)aNotification
{
    [self _updateControlsStateForTable:[aNotification object]];
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

/*! Delegate of CPTableView - This will be called when context menu is triggered with right click
*/
- (CPMenu)tableView:(CPTableView)aTableView menuForTableColumn:(CPTableColumn)aColumn row:(int)aRow;
{

    [_contextualMenu removeAllItems];

    var itemRow = [aTableView rowAtPoint:aRow];
    if ([aTableView selectedRow] != aRow)
        [aTableView selectRowIndexes:[CPIndexSet indexSetWithIndex:aRow] byExtendingSelection:NO];

    switch (aTableView)
    {
        case tableDrives:
            if ([aTableView numberOfSelectedRows] == 0)
                [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForDriveAdd]];
            else if ([aTableView numberOfSelectedRows] == 1)
                {
                [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForDriveEdit]];
                [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForDriveRemove]];
                }
            else
            {
                [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForDriveRemove]];
            }

            break;

        case tableInterfaces:
            if ([aTableView numberOfSelectedRows] == 0)
                [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForNicAdd]];
            else if ([aTableView numberOfSelectedRows] == 1)
                {
                [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForNicEdit]];
                [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForNicRemove]];
                }
            else
            {
                [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForNicRemove]];
            }

            break;

        case tableGraphicsDevices:
            if ([aTableView numberOfSelectedRows] == 0)
                [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForGraphicDeviceAdd]];
            else if ([aTableView numberOfSelectedRows] == 1)
                {
                [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForGraphicDeviceEdit]];
                [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForGraphicDeviceRemove]];
                }
            else
            {
                [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForGraphicDeviceRemove]];
            }

            break;

        case tableInputDevices:
            if ([aTableView numberOfSelectedRows] == 0)
                [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForInputDeviceAdd]];
            else if ([aTableView numberOfSelectedRows] == 1)
                {
                [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForInputDeviceEdit]];
                [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForInputDeviceRemove]];
                }
            else
            {
                [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForGraphicDeviceRemove]];
            }

            break;

        case tableCharacterDevices:
            if ([aTableView numberOfSelectedRows] == 0)
                [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForCharacterDeviceAdd]];
            else if ([aTableView numberOfSelectedRows] == 1)
                {
                [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForCharacterDeviceEdit]];
                [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForCharacterDeviceRemove]];
                }
            else
            {
                [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForGraphicDeviceRemove]];
            }

            break;


        default:
            return;
    }

    return _contextualMenu;
}

/* Delegate of CPTableView - this will be triggered on delete key events
*/
- (void)tableViewDeleteKeyPressed:(CPTableView)aTableView
{
    if ([aTableView numberOfSelectedRows] == 0)
        return;

    switch (aTableView)
    {
        case tableDrives:
            [self deleteDrive:aTableView];
            break;

        case tableInterfaces:
            [self deleteInterface:aTableView];
            break;

        case tableGraphicsDevices:
            [self deleteGraphicDevice:aTableView];
            break;

        case tableInputDevices:
            [self deleteInputDevice:aTableView];
            break;

        case tableCharacterDevices:
            [self deleteCharacterDevice:aTableView];
            break;

        default:
            return;
    }
}

@end



/*! Implements all the controls add remove edit devices actions
*/
@implementation TNVirtualMachineDefinitionController (AddRemoveDevicesActions)


#pragma mark -
#pragma mark Graphics Devices

/*! add graphic device
    @param aSender the sender of the action
*/
- (IBAction)addGraphicDevice:(id)aSender
{
    var graphicDevice = [[TNLibvirtDeviceGraphic alloc] init];

    if (![_libvirtDomain devices])
        [_libvirtDomain setDevices:[[TNLibvirtDevices alloc] init]];

    if ([[[_libvirtDomain devices] graphics] count] != 0)
    {
        [TNAlert showAlertWithMessage:CPBundleLocalizedString(@"Error", @"Error")
                          informative:CPBundleLocalizedString(@"You can only set one graphic device", @"You can only set one graphic device")];

        return;
    }

    [graphicDeviceController setGraphicDevice:graphicDevice];
    [graphicDeviceController openWindow:([aSender isKindOfClass:CPMenuItem]) ? tableGraphicsDevices : aSender];
}

/*! edit the selected graphic device
    @param aSender the sender of the action
*/
- (IBAction)editGraphicDevice:(id)aSender
{
    if (![self currentEntityHasPermission:@"define"])
        return;

    if ([tableGraphicsDevices numberOfSelectedRows] <= 0)
         return;

    var graphicDevice = [_graphicDevicesDatasource objectAtIndex:[tableGraphicsDevices selectedRow]];

    [graphicDeviceController setGraphicDevice:graphicDevice];
    [graphicDeviceController openWindow:([aSender isKindOfClass:CPMenuItem]) ? tableGraphicsDevices : aSender];
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

    _definitionEdited = YES;
}


#pragma mark -
#pragma mark Input Devices

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
    [inputDeviceController openWindow:([aSender isKindOfClass:CPMenuItem]) ? tableInputDevices : aSender];
}

/*! edit current selected input device or create a new one
    @param aSender the sender of the action
*/
- (IBAction)editInputDevice:(id)aSender
{
    if (![self currentEntityHasPermission:@"define"])
        return;

    if ([tableInputDevices numberOfSelectedRows] <= 0)
         return;

    var inputDevice = [_inputDevicesDatasource objectAtIndex:[tableInputDevices selectedRow]];

    [inputDeviceController setInputDevice:inputDevice];
    [inputDeviceController openWindow:([aSender isKindOfClass:CPMenuItem]) ? tableInputDevices : aSender];
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

    _definitionEdited = YES;
}


#pragma mark -
#pragma mark Drives Devices

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

    if ([_libvirtDomain devices])
        [driveController setOtherDrives:[[_libvirtDomain devices] disks]];
    else
        [driveController setOtherDrives:nil];

    [driveController openWindow:([aSender isKindOfClass:CPMenuItem]) ? tableDrives : aSender];
}

/*! open the drive editor
    @param sender the sender of the action
*/
- (IBAction)editDrive:(id)aSender
{
    if (![self currentEntityHasPermission:@"define"])
        return;

    if ([tableDrives numberOfSelectedRows] <= 0)
         return;

    var driveObject = [_drivesDatasource objectAtIndex:[tableDrives selectedRow]];

    [driveController setDrive:driveObject];

    if ([_libvirtDomain devices])
        [driveController setOtherDrives:[[_libvirtDomain devices] disks]];
    else
        [driveController setOtherDrives:nil];

    [driveController openWindow:([aSender isKindOfClass:CPMenuItem]) ? tableDrives : aSender];
}

/*! delete a drive
    @param sender the sender of the action
*/
- (IBAction)deleteDrive:(id)aSender
{
    if (![self currentEntityHasPermission:@"define"])
        return;

    if ([tableDrives numberOfSelectedRows] <= 0)
        return;

     var selectedIndexes = [tableDrives selectedRowIndexes];

     [_drivesDatasource removeObjectsAtIndexes:selectedIndexes];

     [tableDrives reloadData];
     [tableDrives deselectAll];

     _definitionEdited = YES;
}


#pragma mark -
#pragma mark Interfaces Devices

/*! add a network card
    @param sender the sender of the action
*/
- (IBAction)addInterface:(id)aSender
{
    var newNic = [[TNLibvirtDeviceInterface alloc] init],
        newNicSource = [[TNLibvirtDeviceInterfaceSource alloc] init];

    [newNic setType:TNLibvirtDeviceInterfaceTypeBridge];
    [newNic setModel:TNLibvirtDeviceInterfaceModelRTL8139];
    [newNic setMAC:_generateMacAddr()];
    [newNic setSource:newNicSource];
    [interfaceController setNic:newNic];

    if ([_libvirtDomain metadata])
        [interfaceController setMetadata:[_libvirtDomain metadata]];
    [interfaceController openWindow:([aSender isKindOfClass:CPMenuItem]) ? tableInterfaces : aSender];
}

/*! open the network editor
    @param sender the sender of the action
*/
- (IBAction)editInterface:(id)aSender
{
    if (![self currentEntityHasPermission:@"define"])
        return;

    if ([tableInterfaces numberOfSelectedRows] <= 0)
         return;

    var nicObject = [_nicsDatasource objectAtIndex:[tableInterfaces selectedRow]];

    [interfaceController setNic:nicObject];
    if ([_libvirtDomain metadata])
        [interfaceController setMetadata:[_libvirtDomain metadata]];

    [interfaceController openWindow:([aSender isKindOfClass:CPMenuItem]) ? tableInterfaces : aSender];
}

/*! delete a network card
    @param sender the sender of the action
*/
- (IBAction)deleteInterface:(id)aSender
{
    if (![self currentEntityHasPermission:@"define"])
        return;

    if (![self isVisible])
        return;

    if ([tableInterfaces numberOfSelectedRows] <= 0)
        return;

     var selectedIndexes = [tableInterfaces selectedRowIndexes];

     [_nicsDatasource removeObjectsAtIndexes:selectedIndexes];

     [tableInterfaces reloadData];
     [tableInterfaces deselectAll];

     _definitionEdited = YES;
}


#pragma mark -
#pragma mark Characters Devices

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
    [characterDeviceController openWindow:([aSender isKindOfClass:CPMenuItem]) ? tableCharacterDevices : aSender];
}

/*! edit the selected character device
    @param aSender the sender of the action
*/
- (IBAction)editCharacterDevice:(id)aSender
{
    if (![self currentEntityHasPermission:@"define"])
        return;

    if ([tableCharacterDevices numberOfSelectedRows] <= 0)
         return;

    var characterDevice = [_characterDevicesDatasource objectAtIndex:[tableCharacterDevices selectedRow]];

    [characterDeviceController setCharacterDevice:characterDevice];
    [characterDeviceController openWindow:([aSender isKindOfClass:CPMenuItem]) ? tableCharacterDevices : aSender];
}

/*! remove the selected character device
    @param aSender the sender of the action
*/
- (IBAction)deleteCharacterDevice:(id)aSender
{
    if ([tableCharacterDevices numberOfSelectedRows] <= 0)
        return;

    var selectedIndexes = [tableCharacterDevices selectedRowIndexes];

    [_characterDevicesDatasource removeObjectsAtIndexes:selectedIndexes];

    [tableCharacterDevices reloadData];
    [tableCharacterDevices deselectAll];

    _definitionEdited = YES;
}


#pragma mark -
#pragma mark XML Definition management

/*! open the manual XML editor
    @param sender the sender of the action
*/
- (IBAction)openXMLEditor:(id)aSender
{
    [self getXMLDesc];
    [self requestVisible];
    if (![self isVisible])
        return;

    [popoverXMLEditor close];
    [popoverXMLEditor showRelativeToRect:nil ofView:buttonXMLEditor preferredEdge:nil];
    [fieldStringXMLDesc setNeedsDisplay:YES];
}

/*! close the manual XML editor
    @param sender the sender of the action
*/
- (IBAction)closeXMLEditor:(id)aSender
{
    [popoverXMLEditor close];
}

/*! define XML
    @param sender the sender of the action
*/
- (IBAction)defineXML:(id)aSender
{
    [[CPApp mainWindow] makeFirstResponder:nil];

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

@end



/*! Implements all the controls update actions
*/
@implementation TNVirtualMachineDefinitionController (UpdateActions)

/*! perpare the interface according to the selected guest
    @param aSender the sender of the action
*/
- (IBAction)didChangeGuest:(id)aSender
{
    var guest       = [[aSender selectedItem] representedObject],
        osType      = [[guest firstChildWithName:@"os_type"] text],
        arch        = [[guest firstChildWithName:@"arch"] valueForAttribute:@"name"];

    [[[_libvirtDomain OS] type] setArchitecture:arch];
    [[[_libvirtDomain OS] type] setType:osType];

    if ([guest firstChildWithName:@"loader"])
        [[_libvirtDomain OS] setLoader:[[guest firstChildWithName:@"loader"] text]];


    [self didChangeDomainType:buttonDomainType];
    [self didChangeMachine:buttonMachines];
    [self _updateUIForCurrentGuest];
}

/*! update the value for domain type
    @param aSender the sender of the action
*/
- (IBAction)didChangeDomainType:(id)aSender
{
    [_libvirtDomain setType:[aSender title]];
    [[_libvirtDomain devices] setEmulator:nil];
    [self _updateUIFromDomainType];

    _definitionEdited = YES;
}

/*! update the value for boot
    @param aSender the sender of the action
*/
- (IBAction)didChangeName:(id)aSender
{
    if ([aSender stringValue] == [_libvirtDomain name])
        return;

    [_libvirtDomain setName:[aSender stringValue]];

    _definitionEdited = YES;
}

/*! update the value for boot
    @param aSender the sender of the action
*/
- (IBAction)didChangeBoot:(id)aSender
{
    if ([aSender title] == [[_libvirtDomain OS] boot])
        return;

    if (![_libvirtDomain OS])
        [_libvirtDomain setOS:[[TNLibvirtDomainOS alloc] init]];
    [[_libvirtDomain OS] setBoot:[aSender title]];

    _definitionEdited = YES;
}

/*! update the value for kernel
    @param aSender the sender of the action
*/
- (IBAction)didChangeOSKernel:(id)aSender
{
    if ([aSender stringValue] == ([[_libvirtDomain OS] kernel] || @""))
        return;

    if (![_libvirtDomain OS])
        [_libvirtDomain setOS:[[TNLibvirtDomainOS alloc] init]];
    [[_libvirtDomain OS] setKernel:[aSender stringValue]];

    _definitionEdited = YES;
}

/*! update the value for initrd
    @param aSender the sender of the action
*/
- (IBAction)didChangeOSInitrd:(id)aSender
{
    if ([aSender stringValue] == ([[_libvirtDomain OS] initrd] || @""))
        return;

    if (![_libvirtDomain OS])
        [_libvirtDomain setOS:[[TNLibvirtDomainOS alloc] init]];
    [[_libvirtDomain OS] setInitrd:[aSender stringValue]];

    _definitionEdited = YES;
}

/*! update the value for cmdline
    @param aSender the sender of the action
*/
- (IBAction)didChangeOSCommandLine:(id)aSender
{
    if ([aSender stringValue] == ([[_libvirtDomain OS] commandLine] || @""))
        return;

    if (![_libvirtDomain OS])
        [_libvirtDomain setOS:[[TNLibvirtDomainOS alloc] init]];
    [[_libvirtDomain OS] setCommandLine:[aSender stringValue]];

    _definitionEdited = YES;
}

/*! update the value for loader
    @param aSender the sender of the action
*/
- (IBAction)didChangeOSLoader:(id)aSender
{
    if ([aSender stringValue] == ([[_libvirtDomain OS] loader] || @""))
        return;

    if (![_libvirtDomain OS])
        [_libvirtDomain setOS:[[TNLibvirtDomainOS alloc] init]];
    [[_libvirtDomain OS] setLoader:[aSender stringValue]];

    _definitionEdited = YES;
}

/*! update the value for bootloader
    @param aSender the sender of the action
*/
- (IBAction)didChangeBootloader:(id)aSender
{
    if ([aSender stringValue] == ([_libvirtDomain bootloader] || @""))
        return;

    [_libvirtDomain setBootloader:[aSender stringValue]];

    _definitionEdited = YES;
}

/*! update the value for bootloaderArgs
    @param aSender the sender of the action
*/
- (IBAction)didChangeBootloaderArgs:(id)aSender
{
    if ([aSender stringValue] == ([_libvirtDomain bootloaderArgs] || @""))
        return;

    [_libvirtDomain setBootloaderArgs:[aSender stringValue]];

    _definitionEdited = YES;

}

/*! update the value for onPowerOff
    @param aSender the sender of the action
*/
- (IBAction)didChangeOnPowerOff:(id)aSender
{
    if ([aSender title] == [_libvirtDomain onPowerOff])
        return;

    [_libvirtDomain setOnPowerOff:[aSender title]];

    _definitionEdited = YES;
}

/*! update the value for onReboot
    @param aSender the sender of the action
*/
- (IBAction)didChangeOnReboot:(id)aSender
{
    if ([aSender title] == [_libvirtDomain onReboot])
        return;

    [_libvirtDomain setOnReboot:[aSender title]];

    _definitionEdited = YES;
}

/*! update the value for onCrash
    @param aSender the sender of the action
*/
- (IBAction)didChangeOnCrash:(id)aSender
{
    if ([aSender title] == [_libvirtDomain onCrash])
        return;

    [_libvirtDomain setOnCrash:[aSender title]];

    _definitionEdited = YES;
}

/*! update the value for PAE
    @param aSender the sender of the action
*/
- (IBAction)didChangePAE:(id)aSender
{
    if (![_libvirtDomain features])
        [_libvirtDomain setFeatures:[[TNLibvirtDomainFeatures alloc] init]];
    [[_libvirtDomain features] setPAE:[aSender state]];

    _definitionEdited = YES;
}

/*! update the value for ACPI
    @param aSender the sender of the action
*/
- (IBAction)didChangeACPI:(id)aSender
{
    if (![_libvirtDomain features])
        [_libvirtDomain setFeatures:[[TNLibvirtDomainFeatures alloc] init]];
    [[_libvirtDomain features] setACPI:[aSender state]];

    _definitionEdited = YES;
}

/*! update the value for APIC
    @param aSender the sender of the action
*/
- (IBAction)didChangeAPIC:(id)aSender
{
    if (![_libvirtDomain features])
        [_libvirtDomain setFeatures:[[TNLibvirtDomainFeatures alloc] init]];
    [[_libvirtDomain features] setAPIC:[aSender state]];

    _definitionEdited = YES;
}

/*! update the value for huge page
    @param aSender the sender of the action
*/
- (IBAction)didChangeHugePages:(id)aSender
{
    if (![_libvirtDomain memoryBacking])
        [_libvirtDomain setMemoryBacking:[TNLibvirtDomainMemoryBacking new]];

    [[_libvirtDomain memoryBacking] setUseHugePages:[aSender state]];

    _definitionEdited = YES;
}

/*! update the value for enable USB
    @param aSender the sender of the action
*/
- (IBAction)didChangeEnableUSB:(id)aSender
{
    if (![_libvirtDomain devices])
        [_libvirtDomain setDevices:[[TNLibvirtDevices alloc] init]];

    var USBController,
        controllers = [[_libvirtDomain devices] controllers];

    // first, let's find the USBController and remove it if any
    for (var i = 0; i < [controllers count]; i++)
    {
        var type = [[controllers objectAtIndex:i] type],
            model = [[controllers objectAtIndex:i] model];

        if (type == TNLibvirtDeviceControllerTypeUSB)
        {
            [controllers removeObject:[controllers objectAtIndex:i]];
            break;
        }
    }

    if (![aSender state])
    {
        USBController = [[TNLibvirtDeviceController alloc] init];
        [USBController setType:TNLibvirtDeviceControllerTypeUSB]
        [USBController setIndex:0] // Is that a good idea??
        [USBController setModel:TNLibvirtDeviceControllerModelNONE];
        [controllers addObject:USBController];

        // and remove tablets if any
        var devicesToRemove = [CPArray array];
        for (var i = 0; i < [_inputDevicesDatasource count]; i++)
        {
            var inputDevice = [_inputDevicesDatasource objectAtIndex:i];
            if ([inputDevice bus] == TNLibvirtDeviceInputBusUSB)
                [devicesToRemove addObject:inputDevice];
        }
        [_inputDevicesDatasource removeObjectsInArray:devicesToRemove];
        [tableInputDevices reloadData];
    }

    _definitionEdited = YES;
}

/*! update the value for nested virtualization
    @param aSender the sender of the action
*/
- (IBAction)didChangeNestedVirtualization:(id)aSender
{
    if ([aSender state])
    {
        // adds nested virtualization argument as qemu commandline
        [self _addNestedVirtualization];
    }
    else
    {
        // removes any +vmx flags from value of -cpu qemu arguments
        [self _removeNestedVirtualization];
    }

    _definitionEdited = YES;
}

/*! update the value for clock
    @param aSender the sender of the action
*/
- (IBAction)didChangeClock:(id)aSender
{
    if (![_libvirtDomain clock])
        [_libvirtDomain setClock:[[TNLibvirtDomainClock alloc] init]];

    [[_libvirtDomain clock] setOffset:[aSender title]];

    _definitionEdited = YES;
}

/*! update the value for machine
    @param aSender the sender of the action
*/
- (IBAction)didChangeMachine:(id)aSender
{
    if (![_libvirtDomain OS])
        [_libvirtDomain setOS:[[TNLibvirtDomainOS alloc] init]];

    [[[_libvirtDomain OS] type] setMachine:[aSender title]];

    _definitionEdited = YES;
}

/*! update the value for memory
    @param aSender the sender of the action
*/
- (IBAction)didChangeMemory:(id)aSender
{
    if (([aSender intValue] * 1024) == [_libvirtDomain memory])
        return;

    [_libvirtDomain setMemory:([aSender intValue] * 1024)];
    // we must set value of current memory too, for more info take a
    // look at https://github.com/ArchipelProject/Archipel/issues/591
    [_libvirtDomain setCurrentMemory:([aSender intValue] * 1024)];

    _definitionEdited = YES;
}

/*! update the value for VNC Password
    @param aSender the sender of the action
*/
- (IBAction)didChangeVCPU:(id)aSender
{
    if ([aSender doubleValue] == [_libvirtDomain VCPU])
        return;

    [_libvirtDomain setVCPU:parseInt([aSender doubleValue])];
    _definitionEdited = YES;
}

/*! update the value for memory tuning soft limit
    @param aSender the sender of the action
*/
- (IBAction)didChangeMemoryTuneSoftLimit:(id)aSender
{
    if ([aSender intValue] * 1024 == [[_libvirtDomain memoryTuning] softLimit])
        return;

    if ([aSender intValue] > 0)
    {
        if (![_libvirtDomain memoryTuning])
            [_libvirtDomain setMemoryTuning:[[TNLibvirtDomainMemoryTune alloc] init]];

        [[_libvirtDomain memoryTuning] setSoftLimit:[aSender intValue] * 1024];
    }
    else
        [[_libvirtDomain memoryTuning] setSoftLimit:nil];

    _definitionEdited = YES;
}

/*! update the value for memory tuning hard limit
    @param aSender the sender of the action
*/
- (IBAction)didChangeMemoryTuneHardLimit:(id)aSender
{
    if ([aSender intValue] * 1024 == [[_libvirtDomain memoryTuning] hardLimit])
        return;

    if ([aSender intValue] > 0)
    {
        if (![_libvirtDomain memoryTuning])
            [_libvirtDomain setMemoryTuning:[[TNLibvirtDomainMemoryTune alloc] init]];

        [[_libvirtDomain memoryTuning] setHardLimit:[aSender intValue] * 1024];
    }
    else
        [[_libvirtDomain memoryTuning] setHardLimit:nil];

    _definitionEdited = YES;
}

/*! update the value for memory tuning guarantee
    @param aSender the sender of the action
*/
- (IBAction)didChangeMemoryTuneGuarantee:(id)aSender
{
    if ([aSender intValue] * 1024 == [[_libvirtDomain memoryTuning] minGuarantee])
        return;

    if ([aSender intValue] > 0)
    {
        if (![_libvirtDomain memoryTuning])
            [_libvirtDomain setMemoryTuning:[[TNLibvirtDomainMemoryTune alloc] init]];
        [[_libvirtDomain memoryTuning] setMinGuarantee:[aSender intValue] * 1024];
    }
    else
        [[_libvirtDomain memoryTuning] setMinGuarantee:nil];

    _definitionEdited = YES;
}

/*! update the value for memory tuning swap hard limit
    @param aSender the sender of the action
*/
- (IBAction)didChangeMemoryTuneSwapHardLimit:(id)aSender
{
    if ([aSender intValue] * 1024 == [[_libvirtDomain memoryTuning] swapHardLimit])
        return;

    if ([aSender intValue] > 0)
    {
        if (![_libvirtDomain memoryTuning])
            [_libvirtDomain setMemoryTuning:[[TNLibvirtDomainMemoryTune alloc] init]];

        [[_libvirtDomain memoryTuning] setSwapHardLimit:[aSender intValue] * 1024];
    }
    else
        [[_libvirtDomain memoryTuning] setSwapHardLimit:nil];

    _definitionEdited = YES;
}

/*! update the value for block IO tuning weight
    @param aSender the sender of the action
*/
- (IBAction)didChangeBlockIOTuningWeight:(id)aSender
{
    if ([aSender intValue] == [[_libvirtDomain blkiotune] weight])
        return;

    if ([aSender intValue] > 0)
    {
        if (![_libvirtDomain blkiotune])
            [_libvirtDomain setBlkiotune:[[TNLibvirtDomainBlockIOTune alloc] init]];
        [[_libvirtDomain blkiotune] setWeight:[aSender intValue]];
    }
    else
        [[_libvirtDomain blkiotune] setWeight:nil];

    _definitionEdited = YES;
}

@end




// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNVirtualMachineDefinitionController], comment);
}
