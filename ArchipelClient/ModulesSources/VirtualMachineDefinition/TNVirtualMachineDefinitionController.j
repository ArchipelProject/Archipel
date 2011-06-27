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

@import "TNDriveController.j"
@import "TNNetworkController.j"
@import "TNVirtualMachineGuestItem.j"
@import "Model/TNLibvirt.j"


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
    @outlet CPButton                buttonClocks;
    @outlet CPButton                buttonDefine;
    @outlet CPButton                buttonDomainType;
    @outlet CPButton                buttonOnCrash;
    @outlet CPButton                buttonOnPowerOff;
    @outlet CPButton                buttonOnReboot;
    @outlet CPButton                buttonUndefine;
    @outlet CPButton                buttonXMLEditor;
    @outlet CPButton                buttonXMLEditorDefine;
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
    @outlet CPTextField             fieldVNCListen;
    @outlet CPTextField             fieldVNCPort;
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
    @outlet TNSwitch                switchEnableVNC;
    @outlet TNSwitch                switchHugePages;
    @outlet TNSwitch                switchPAE;
    @outlet TNSwitch                switchPreferencesHugePages;
    @outlet TNSwitch                switchPreferencesEnableVNC;
    @outlet TNTextFieldStepper      stepperNumberCPUs;
    @outlet TNUIKitScrollView       scrollViewContentView;
    @outlet TNUIKitScrollView       scrollViewForDrives;
    @outlet TNUIKitScrollView       scrollViewForNics;
    @outlet CPTableView             tableDrives;
    @outlet CPTableView             tableInterfaces;

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

    TNTableViewDataSource           _drivesDatasource;
    TNTableViewDataSource           _nicsDatasource;
    TNLibvirtDomain                 _libvirtDomain;
}


#pragma mark -
#pragma mark Initialization

/*! called at cib awaking
*/
- (void)awakeFromCib
{
    [windowXMLEditor setDefaultButton:buttonXMLEditorDefine];

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
            [bundle objectForInfoDictionaryKey:@"TNDescDefaultEnableVNC"], @"TNDescDefaultEnableVNC",
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


    // DRIVES
    _drivesDatasource = [[TNTableViewDataSource alloc] init];
    [_drivesDatasource setTable:tableDrives];
    [_drivesDatasource setSearchableKeyPaths:[@"type", @"driver.type", @"target.device", @"source.sourceObject", @"target.bus", @"driver.cache"]];
    [tableDrives setDataSource:_drivesDatasource];

    [viewDrivesContainer setBorderedWithHexColor:@"#C0C7D2"];

    [driveController setDelegate:self];

    [fieldFilterDrives setTarget:_drivesDatasource];
    [fieldFilterDrives setAction:@selector(filterObjects:)];

    _plusButtonDrives = [CPButtonBar plusButton];
    [_plusButtonDrives setTarget:self];
    [_plusButtonDrives setAction:@selector(addDrive:)];
    [_plusButtonDrives setToolTip:CPBundleLocalizedString(@"Add a virtual drive", @"Add a virtual drive")];

    _minusButtonDrives = [CPButtonBar minusButton];
    [_minusButtonDrives setTarget:self];
    [_minusButtonDrives setAction:@selector(deleteDrive:)];
    [_minusButtonDrives setEnabled:NO];
    [_minusButtonDrives setToolTip:CPBundleLocalizedString(@"Delete selected drives", @"Delete selected drives")];

    _editButtonDrives = [CPButtonBar plusButton];
    [_editButtonDrives setImage:[[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"IconsButtons/edit.png"] size:CPSizeMake(16, 16)]];
    [_editButtonDrives setTarget:self];
    [_editButtonDrives setAction:@selector(editDrive:)];
    [_editButtonDrives setEnabled:NO];
    [_editButtonDrives setToolTip:CPBundleLocalizedString(@"Edit selected drive", @"Edit selected drive")];

    [buttonBarControlDrives setButtons:[_plusButtonDrives, _minusButtonDrives, _editButtonDrives]];


    // NICs
    _nicsDatasource = [[TNTableViewDataSource alloc] init];
    [_nicsDatasource setTable:tableInterfaces];
    [_nicsDatasource setSearchableKeyPaths:[@"type", @"model", @"MAC", @"source.bridge"]];
    [tableInterfaces setDataSource:_nicsDatasource];

    [viewNicsContainer setBorderedWithHexColor:@"#C0C7D2"];

    [networkController setDelegate:self];

    [fieldFilterNics setTarget:_nicsDatasource];
    [fieldFilterNics setAction:@selector(filterObjects:)];

    _plusButtonNics = [CPButtonBar plusButton];
    [_plusButtonNics setTarget:self];
    [_plusButtonNics setAction:@selector(addNetworkCard:)];
    [_plusButtonNics setToolTip:CPBundleLocalizedString(@"Add a virtual network card", @"Add a virtual network card")];

    _minusButtonNics = [CPButtonBar minusButton];
    [_minusButtonNics setTarget:self];
    [_minusButtonNics setAction:@selector(deleteNetworkCard:)];
    [_minusButtonNics setEnabled:NO];
    [_minusButtonNics setToolTip:CPBundleLocalizedString(@"Remove selected virtual network card", @"Remove selected virtual network card")];

    _editButtonNics = [CPButtonBar plusButton];
    [_editButtonNics setImage:[[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"IconsButtons/edit.png"] size:CPSizeMake(16, 16)]];
    [_editButtonNics setTarget:self];
    [_editButtonNics setAction:@selector(editInterface:)];
    [_editButtonNics setEnabled:NO];
    [_editButtonNics setToolTip:CPBundleLocalizedString(@"Edit selected virtual network card", @"Edit selected virtual network card")];

    [buttonBarControlNics setButtons:[_plusButtonNics, _minusButtonNics, _editButtonNics]];

    // device tabView
    [tabViewDevices setAutoresizingMask:CPViewWidthSizable];
    var tabViewItemDrives = [[CPTabViewItem alloc] initWithIdentifier:@"IDtabViewItemDrives"],
        tabViewItemNics = [[CPTabViewItem alloc] initWithIdentifier:@"IDtabViewItemNics"];

    [tabViewItemDrives setLabel:CPBundleLocalizedString(@"Virtual Medias", @"Virtual Medias")];
    [tabViewItemDrives setView:viewDeviceVirtualDrives];
    [tabViewDevices addTabViewItem:tabViewItemDrives];

    [tabViewItemNics setLabel:CPBundleLocalizedString(@"Virtual Nics", @"Virtual Nics")];
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

    [buttonBoot addItemsWithTitles:TNLibvirtDomainOSBoots];
    [buttonPreferencesBoot addItemsWithTitles:TNLibvirtDomainOSBoots];

    [buttonPreferencesNumberOfCPUs addItemsWithTitles:[@"1", @"2", @"3", @"4"]];

    [buttonVNCKeymap addItemsWithTitles:TNLibvirtDeviceGraphicsVNCKeymaps];
    [buttonPreferencesVNCKeyMap addItemsWithTitles:TNLibvirtDeviceGraphicsVNCKeymaps];

    [buttonOnPowerOff addItemsWithTitles:TNLibvirtDomainLifeCycles];
    [buttonPreferencesOnPowerOff addItemsWithTitles:TNLibvirtDomainLifeCycles];

    [buttonOnReboot addItemsWithTitles:TNLibvirtDomainLifeCycles];
    [buttonPreferencesOnReboot addItemsWithTitles:TNLibvirtDomainLifeCycles];

    [buttonOnCrash addItemsWithTitles:TNLibvirtDomainLifeCycles];
    [buttonPreferencesOnCrash addItemsWithTitles:TNLibvirtDomainLifeCycles];

    [buttonClocks addItemsWithTitles:TNLibvirtDomainClockClocks];
    [buttonPreferencesClockOffset addItemsWithTitles:TNLibvirtDomainClockClocks];

    [buttonInputType addItemsWithTitles:TNLibvirtDeviceInputTypes];
    [buttonPreferencesInput addItemsWithTitles:TNLibvirtDeviceInputTypes];

    [buttonPreferencesDriveCache addItemsWithTitles:TNLibvirtDeviceDiskDriverCaches];

    var menuNet = [[CPMenu alloc] init],
        menuDrive = [[CPMenu alloc] init];

    [menuNet addItemWithTitle:CPBundleLocalizedString(@"Create new network interface", @"Create new network interface") action:@selector(addNetworkCard:) keyEquivalent:@""];
    [menuNet addItem:[CPMenuItem separatorItem]];
    [menuNet addItemWithTitle:CPBundleLocalizedString(@"Edit", @"Edit") action:@selector(editInterface:) keyEquivalent:@""];
    [menuNet addItemWithTitle:CPBundleLocalizedString(@"Delete", @"Delete") action:@selector(deleteNetworkCard:) keyEquivalent:@""];
    [tableInterfaces setMenu:menuNet];

    [menuDrive addItemWithTitle:CPBundleLocalizedString(@"Create new drive", @"Create new drive") action:@selector(addDrive:) keyEquivalent:@""];
    [menuDrive addItem:[CPMenuItem separatorItem]];
    [menuDrive addItemWithTitle:CPBundleLocalizedString(@"Edit", @"Edit") action:@selector(editDrive:) keyEquivalent:@""];
    [menuDrive addItemWithTitle:CPBundleLocalizedString(@"Delete", @"Delete") action:@selector(deleteDrive:) keyEquivalent:@""];
    [tableDrives setMenu:menuDrive];

    [fieldVNCPassword setSecure:YES];

    [driveController setTable:tableDrives];
    [networkController setTable:tableInterfaces];

    // switch
    [switchPAE setOn:NO animated:YES sendAction:NO];
    [switchPAE setTarget:self];
    [switchPAE setAction:@selector(didChangeAPIC:)];

    [switchAPIC setOn:NO animated:YES sendAction:NO];
    [switchAPIC setTarget:self];
    [switchAPIC setAction:@selector(didChangeAPIC:)];

    [switchACPI setOn:NO animated:YES sendAction:NO];
    [switchACPI setTarget:self];
    [switchACPI setAction:@selector(didChangeACPI:)];
    [switchAPIC setToolTip:CPBundleLocalizedString(@"Enable or disable PAE", @"Enable or disable PAE")];

    [switchHugePages setTarget:self];
    [switchHugePages setAction:@selector(didChangeHugePages:)];
    [switchHugePages setToolTip:CPBundleLocalizedString(@"Enable or disable usage of huge pages backed memory", @"Enable or disable usage of huge pages backed memory")];

    [switchEnableVNC setTarget:self];
    [switchEnableVNC setAction:@selector(didChangeVNCEnabled:)];
    [switchEnableVNC setToolTip:CPLocalizedString(@"Enable or disable the VNC screen for this virtual machine", @"Enable or disable the VNC screen for this virtual machine")];

    //CPUStepper
    [stepperNumberCPUs setMaxValue:4];
    [stepperNumberCPUs setMinValue:1];
    [stepperNumberCPUs setDoubleValue:1];
    [stepperNumberCPUs setValueWraps:NO];
    [stepperNumberCPUs setAutorepeat:NO];
    [stepperNumberCPUs setTarget:self];
    [stepperNumberCPUs setAction:@selector(didChangeVCPU:)];
    [stepperNumberCPUs setToolTip:CPBundleLocalizedString(@"Set the number of virtual CPUs", @"Set the number of virtual CPUs")];

    _imageEdited = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"edited.png"] size:CPSizeMake(16.0, 16.0)];
    _imageDefining = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"spinner.gif"] size:CPSizeMake(16.0, 16.0)];
    [buttonDefine setEnabled:NO];
    [buttonDefine setToolTip:CPBundleLocalizedString(@"Save changes", @"Save changes")];

    [buttonXMLEditor setToolTip:CPBundleLocalizedString(@"Open the XML editor", @"Open the XML editor")];
    [buttonBoot setToolTip:CPBundleLocalizedString(@"Set boot origin", @"Set boot origin")];
    [buttonClocks setToolTip:CPBundleLocalizedString(@"Set the mode of the virtual machine clock", @"Set the mode of the virtual machine clock")];
    [buttonDomainType setToolTip:CPBundleLocalizedString(@"Set the domain type", @"Set the domain type")];
    [buttonGuests setToolTip:CPBundleLocalizedString(@"Set the guest type", @"Set the guest type")];
    [buttonInputType setToolTip:CPBundleLocalizedString(@"Set the input device", @"Set the input device")];
    [buttonMachines setToolTip:CPBundleLocalizedString(@"Set the domain machine type", @"Set the domain machine type")];
    [buttonOnCrash setToolTip:CPBundleLocalizedString(@"Set what to do when virtual machine crashes", @"Set what to do when virtual machine crashes")];
    [buttonOnPowerOff setToolTip:CPBundleLocalizedString(@"Set what to do when virtual machine is stopped", @"Set what to do when virtual machine is stopped")];
    [buttonOnReboot setToolTip:CPBundleLocalizedString(@"Set what to do when virtual machine is rebooted", @"Set what to do when virtual machine is rebooted")];
    [buttonUndefine setToolTip:CPBundleLocalizedString(@"Undefine the domain", @"Undefine the domain")];
    [buttonVNCKeymap setToolTip:CPBundleLocalizedString(@"Set the VNC keymap to use", @"Set the VNC keymap to use")];
    [switchPAE setToolTip:CPBundleLocalizedString(@"Enable usage of PAE", @"Enable usage of PAE")];
    [switchAPIC setToolTip:CPBundleLocalizedString(@"Enable usage of APIC", @"Enable usage of APIC")];
    [switchACPI setToolTip:CPBundleLocalizedString(@"Enable usage of ACPI (allow to use 'shutdown' control)", @"Enable usage of ACPI (allow to use 'shutdown' control)")];
    [fieldMemory setToolTip:CPBundleLocalizedString(@"Set amount of memort (in Mb)", @"Set amount of memort (in Mb)")];
    [fieldVNCPassword setToolTip:CPBundleLocalizedString(@"Set the VNC password (no password if blank)", @"Set the VNC password (no password if blank)")];
    [fieldVNCListen setToolTip:CPLocalizedString(@"Set the real VNC Server (not the websocket proxy) listen addr. Leave blank for qemu default (127.0.0.1)", @"Set the real VNC Server (not the websocket proxy) listen addr. Leave blank for qemu default (127.0.0.1)")];
    [fieldVNCPort setToolTip:CPLocalizedString(@"Set the real VNC server listen port. leave it to blank for autoport", @"Set the real VNC server listen port. leave it to blank for autoport")];
    [buttonPreferencesBoot setToolTip:CPBundleLocalizedString(@"Set the default boot device for new domains", @"Set the default boot device for new domains")];
    [buttonPreferencesClockOffset setToolTip:CPBundleLocalizedString(@"Set the default clock offset for new domains", @"Set the default clock offset for new domains")];
    [buttonPreferencesInput setToolTip:CPBundleLocalizedString(@"Set the default input type for new domains", @"Set the default input type for new domains")];
    [buttonPreferencesNumberOfCPUs setToolTip:CPBundleLocalizedString(@"Set the default number of CPUs for new domains", @"Set the default number of CPUs for new domains")];
    [buttonPreferencesOnCrash setToolTip:CPBundleLocalizedString(@"Set the default behaviour on crash for new domains", @"Set the default behaviour on crash for new domains")];
    [buttonPreferencesOnPowerOff setToolTip:CPBundleLocalizedString(@"Set the default behaviour on power off for new domains", @"Set the default behaviour on power off for new domains")];
    [buttonPreferencesOnReboot setToolTip:CPBundleLocalizedString(@"Set the default behaviour on reboot for new domains", @"Set the default behaviour on reboot for new domains")];
    [buttonPreferencesVNCKeyMap setToolTip:CPBundleLocalizedString(@"Set the default VNC keymap for new domains", @"Set the default VNC keymap for new domains")];
    [buttonPreferencesDriveCache setToolTip:CPBundleLocalizedString(@"Set the default drive cache for new drives", @"Set the default drive cache for new drives")];
    [fieldPreferencesDomainType setToolTip:CPBundleLocalizedString(@"Set the default domain type for new domains", @"Set the default domain type for new domains")];
    [fieldPreferencesGuest setToolTip:CPBundleLocalizedString(@"Set the default guest for new domains", @"Set the default guest for new domains")];
    [fieldPreferencesMachine setToolTip:CPBundleLocalizedString(@"Set the default machine type for new domains", @"Set the default machine type for new domains")];
    [fieldPreferencesMemory setToolTip:CPBundleLocalizedString(@"Set the default amount of memory for new domains", @"Set the default amount of memory for new domains")];
    [switchPreferencesHugePages setToolTip:CPBundleLocalizedString(@"Set the default usage of huge pages for new domains", @"Set the default usage of huge pages for new domains")];
    [switchPreferencesEnableVNC setToolTip:CPBundleLocalizedString(@"Set the defaulut usage of VNC for new domains", @"Set the defaulut usage of VNC for new domains")];
}


#pragma mark -
#pragma mark TNModule overrides

/*! called when module is loaded
*/
- (void)willLoad
{
    [super willLoad];

    _definitionRecovered = NO;
    [self handleDefinitionEdition:NO];

    var center = [CPNotificationCenter defaultCenter];

    [center addObserver:self selector:@selector(_didUpdatePresence:) name:TNStropheContactPresenceUpdatedNotification object:_entity];
    [center addObserver:self selector:@selector(_didEditDefinition:) name:CPControlTextDidChangeNotification object:fieldMemory];
    [center addObserver:self selector:@selector(_didEditDefinition:) name:CPControlTextDidChangeNotification object:fieldVNCPassword];
    [center addObserver:self selector:@selector(_didEditDefinition:) name:CPControlTextDidChangeNotification object:fieldVNCListen];
    [center addObserver:self selector:@selector(_didEditDefinition:) name:CPControlTextDidChangeNotification object:fieldVNCPort];

    [self registerSelector:@selector(_didReceivePush:) forPushNotificationType:TNArchipelPushNotificationDefinitition];

    [center postNotificationName:TNArchipelModulesReadyNotification object:self];

    [tableDrives setDelegate:nil];
    [tableDrives setDelegate:self];
    [tableInterfaces setDelegate:nil];
    [tableInterfaces setDelegate:self];

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
    [tableDrives reloadData];
    [tableInterfaces reloadData];
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

    return YES;
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
    [defaults setBool:[switchPreferencesEnableVNC isOn] forKey:@"TNDescDefaultEnableVNC"];
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
    [switchPreferencesEnableVNC setOn:[defaults boolForKey:@"TNDescDefaultEnableVNC"] animated:YES sendAction:NO];
}

/*! called when MainMenu is ready
*/
- (void)menuReady
{
    [[_menu addItemWithTitle:CPBundleLocalizedString(@"Undefine", @"Undefine") action:@selector(undefineXML:) keyEquivalent:@""] setTarget:self];
    [_menu addItem:[CPMenuItem separatorItem]];
    [[_menu addItemWithTitle:CPBundleLocalizedString(@"Add drive", @"Add drive") action:@selector(addDrive:) keyEquivalent:@""] setTarget:self];
    [[_menu addItemWithTitle:CPBundleLocalizedString(@"Edit selected drive", @"Edit selected drive") action:@selector(editDrive:) keyEquivalent:@""] setTarget:self];
    [_menu addItem:[CPMenuItem separatorItem]];
    [[_menu addItemWithTitle:CPBundleLocalizedString(@"Add network card", @"Add network card") action:@selector(addNetworkCard:) keyEquivalent:@""] setTarget:self];
    [[_menu addItemWithTitle:CPBundleLocalizedString(@"Edit selected network card", @"Edit selected network card") action:@selector(editInterface:) keyEquivalent:@""] setTarget:self];
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

    if ([switchEnableVNC isOn])
    {
        [self setControl:fieldVNCPassword enabledAccordingToPermission:@"define"];
        [self setControl:buttonVNCKeymap enabledAccordingToPermission:@"define"];
        [self setControl:fieldVNCListen enabledAccordingToPermission:@"define"];
        [self setControl:fieldVNCPort enabledAccordingToPermission:@"define"];
    }
    else
    {
        [buttonVNCKeymap setEnabled:NO];
        [fieldVNCPassword setEnabled:NO];
        [fieldVNCListen setEnabled:NO];
        [fieldVNCPort setEnabled:NO];
    }

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
    @param shouldSetEdited if yes, will try to set GUI in edited mode
*/
- (void)handleDefinitionEdition:(BOOL)shouldSetEdited
{
    if (shouldSetEdited)
    {
        if (!_definitionRecovered)
            return;

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
        vnc         = [defaults boolForKey:@"TNDescDefaultEnableVNC"],
        clock       = [defaults objectForKey:@"TNDescDefaultClockOffset"],
        pae         = [defaults boolForKey:@"TNDescDefaultPAE"],
        acpi        = [defaults boolForKey:@"TNDescDefaultACPI"],
        apic        = [defaults boolForKey:@"TNDescDefaultAPIC"],
        input       = [defaults objectForKey:@"TNDescDefaultInputType"];

    [stepperNumberCPUs setDoubleValue:cpu];
    [fieldMemory setStringValue:mem];
    [fieldVNCPassword setStringValue:@""];
    [fieldVNCListen setStringValue:@""];
    [fieldVNCPort setStringValue:@""];
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
    [switchEnableVNC setOn:((vnc == 1) ? YES : NO) animated:YES sendAction:NO];
    [buttonMachines removeAllItems];
    [buttonDomainType removeAllItems];

    if (vnc == 1)
    {
        [buttonVNCKeymap setEnabled:YES];
        [fieldVNCPassword setEnabled:YES];
        [fieldVNCListen setEnabled:YES];
        [fieldVNCPort setEnabled:YES];
    }
    else
    {
        [buttonVNCKeymap setEnabled:NO];
        [fieldVNCPassword setEnabled:NO];
        [fieldVNCListen setEnabled:NO];
        [fieldVNCPort setEnabled:NO];
    }

    [_nicsDatasource removeAllObjects];
    [_drivesDatasource removeAllObjects];
    [tableInterfaces reloadData];
    [tableDrives reloadData];

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
            [TNAlert showAlertWithMessage:CPBundleLocalizedString(@"Definition edited", @"Definition edited")
                              informative:CPBundleLocalizedString(@"You started the virtual machine, but you haven't save the current changes.", @"You started the virtual machine, but you haven't save the current changes.")];
    }
    else
    {
        [self showMaskView:NO];
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
    var newNic = [[TNLibvirtDeviceInterface alloc] init],
        newNicSource = [[TNLibvirtDeviceInterfaceSource alloc] init];

    [newNic setType:TNLibvirtDeviceInterfaceTypeBridge];
    [newNic setModel:TNLibvirtDeviceInterfaceModelPCNET];
    [newNic setMAC:[self generateMacAddr]];
    [newNic setSource:newNicSource];

    [_nicsDatasource addObject:newNic];
    [tableInterfaces reloadData];
    [networkController setNic:newNic];
    [networkController showWindow:aSender];
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
         [self addNetworkCard:aSender];
         return;
    }

    var nicObject = [_nicsDatasource objectAtIndex:[tableInterfaces selectedRow]];

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
        newDriveDriver = [[TNLibvirtDeviceDiskDriver alloc] init]

    [newDriveDriver setCache:TNLibvirtDeviceDiskDriverCacheNone];

    [newDriveTarget setBus:TNLibvirtDeviceDiskTargetBusIDE];
    [newDriveTarget setDevice:TNLibvirtDeviceDiskTargetDeviceHda];

    [newDriveSource setFile:@"/dev/null"];

    [newDrive setType:TNLibvirtDeviceDiskTypeFile];
    [newDrive setDevice:TNLibvirtDeviceDiskDeviceDisk];
    [newDrive setSource:newDriveSource];
    [newDrive setTarget:newDriveTarget];
    [newDrive setDriver:newDriveDriver];

    [_drivesDatasource addObject:newDrive];
    [tableDrives reloadData];
    [driveController setDrive:newDrive];

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

    if ([tableDrives numberOfSelectedRows] <= 0)
    {
         [self addDrive:aSender];
         return;
    }

    var driveObject = [_drivesDatasource objectAtIndex:[tableDrives selectedRow]];

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
    [self updateMachinesAccordingToDomainType];
    [self makeDefinitionEdited:aSender];
}

/*! update the value for boot
    @param aSender the sender of the action
*/
- (IBAction)didChangeBoot:(id)aSender
{
    [[_libvirtDomain OS] setBoot:[aSender title]];
    [self makeDefinitionEdited:aSender];
}

/*! update the value for boot
    @param aSender the sender of the action
*/
- (IBAction)didChangeBoot:(id)aSender
{
    [[_libvirtDomain OS] setBoot:[aSender title]];
    [self makeDefinitionEdited:aSender];
}

/*! update the value for VNC activation
    @param aSender the sender of the action
*/
- (IBAction)didChangeVNCEnabled:(id)aSender
{
    if ([aSender isOn])
    {
        if ([[[_libvirtDomain devices] graphics] count] == 0)
        {
            var graphicVNC = [[TNLibvirtDeviceGraphics alloc] init];
            [graphicVNC setType:TNLibvirtDeviceGraphicsTypeVNC];
            [[[_libvirtDomain devices] graphics] addObject:graphicVNC];

        }
    }
    else
    {
        [[[_libvirtDomain devices] graphics] removeAllObjects];
    }

    [fieldVNCPassword setEnabled:[aSender isOn]];
    [buttonVNCKeymap setEnabled:[aSender isOn]];
    [fieldVNCListen setEnabled:[aSender isOn]];
    [fieldVNCPort setEnabled:[aSender isOn]];

    [self makeDefinitionEdited:aSender];
}

/*! update the value for VNC keymap
    @param aSender the sender of the action
*/
- (IBAction)didChangeVNCKeymap:(id)aSender
{
    var vnc = [[[_libvirtDomain devices] graphics] firstObject];
    [vnc setKeymap:[aSender title]];
    [self makeDefinitionEdited:aSender];
}

/*! update the value for VNC Password
    @param aSender the sender of the action
*/
- (IBAction)didChangeVNCPassword:(id)aSender
{
    var vnc = [[[_libvirtDomain devices] graphics] firstObject];
    [vnc setPassword:[aSender stringValue]];

    [self makeDefinitionEdited:aSender];
}

/*! update the value for VNC Password
    @param aSender the sender of the action
*/
- (IBAction)didChangeVNCListen:(id)aSender
{
    var vnc = [[[_libvirtDomain devices] graphics] firstObject];
    [vnc setListen:[aSender stringValue]];

    [self makeDefinitionEdited:aSender];
}

/*! update the value for VNC Password
    @param aSender the sender of the action
*/
- (IBAction)didChangeVNCPort:(id)aSender
{
    var vnc = [[[_libvirtDomain devices] graphics] firstObject];

    if ([aSender stringValue] != @"")
    {
        [vnc setPort:[aSender stringValue]];
        [vnc setAutoPort:NO];
    }
    else
    {
        [vnc setPort:nil];
        [vnc setAutoPort:YES];
    }
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
    [_libvirtDomain setOnCrash:[aSender title]];
    [self makeDefinitionEdited:aSender];
}

/*! update the value for ACPI
    @param aSender the sender of the action
*/
- (IBAction)didChangeACPI:(id)aSender
{
    [[_libvirtDomain features] setACPI:[aSender isOn]];
    [self makeDefinitionEdited:aSender];
}

/*! update the value for APIC
    @param aSender the sender of the action
*/
- (IBAction)didChangeAPIC:(id)aSender
{
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
    [[_libvirtDomain clock] setOffset:[aSender title]];
    [self makeDefinitionEdited:aSender];
}

/*! update the value for input Type
    @param aSender the sender of the action
*/
- (IBAction)didChangeInputType:(id)aSender
{
    if ([[[_libvirtDomain devices] inputs] count] == 0)
    {
        var input = [[TNLibvirtDeviceInput alloc] init];
        [[[_libvirtDomain devices] inputs] addObject:input];
    }

    [[[[_libvirtDomain devices] inputs] firstObject] setType:[aSender title]];
    [self makeDefinitionEdited:aSender];
}

/*! update the value for machine
    @param aSender the sender of the action
*/
- (IBAction)didChangeMachine:(id)aSender
{
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
    if ([aStanza type] == @"result")
    {
        [buttonGuests removeAllItems];

        var host = [aStanza firstChildWithName:@"host"],
            guests = [aStanza childrenWithName:@"guest"],
            supportedCapabilities = [CPDictionary dictionary];

        if ([guests count] == 0)
        {
            [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:CPBundleLocalizedString(@"Capabilities", @"Capabilities")
                                                             message:CPBundleLocalizedString(@"Your hypervisor have not pushed any guest support. For some reason, you can't create domains. Sorry.", @"Your hypervisor have not pushed any guest support. For some reason, you can't create domains. Sorry.")
                                                                icon:TNGrowlIconError];
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
        _libvirtDomain = [TNLibvirtDomain defaultDomainWithType:TNLibvirtDomainTypeKVM];
        [_libvirtDomain setName:[_entity nickname]];
        [_libvirtDomain setUUID:[[_entity JID] node]];
        if ([[[aStanza firstChildWithName:@"error"] firstChildWithName:@"text"] text] != "not-defined")
            [self handleIqErrorFromStanza:aStanza];

        [self buildGUIAccordingToCurrentGuest];
        _definitionRecovered = YES;
        [self handleDefinitionEdition:NO];

        return;
    }

    _libvirtDomain = [[TNLibvirtDomain alloc] initWithXMLNode:[aStanza firstChildWithName:@"domain"]];


    [self selectGuestWithType:[[[_libvirtDomain OS] type] type] architecture:[[[_libvirtDomain OS] type] architecture]];
    [self buildGUIAccordingToCurrentGuest];

    // button domainType
    [buttonDomainType selectItemWithTitle:[_libvirtDomain type]];

    // button Machine
    [self updateMachinesAccordingToDomainType];
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

    // graphics
    [self setControl:switchEnableVNC enabledAccordingToPermission:@"define"];
    [switchEnableVNC setOn:([[[_libvirtDomain devices] graphics] count] > 0) animated:YES sendAction:NO];

    if ([switchEnableVNC isOn])
    {
        [self setControl:fieldVNCPassword enabledAccordingToPermission:@"define"];
        [self setControl:buttonVNCKeymap enabledAccordingToPermission:@"define"];
        [self setControl:fieldVNCListen enabledAccordingToPermission:@"define"];
        [self setControl:fieldVNCPort enabledAccordingToPermission:@"define"];
    }
    else
    {
        [fieldVNCPassword setEnabled:NO];
        [buttonVNCKeymap setEnabled:NO];
        [fieldVNCListen setEnabled:NO];
        [fieldVNCPort setEnabled:NO];
    }

    for (var i = 0; i < [[[_libvirtDomain devices] graphics] count]; i++)
    {
        var graphic = [[[_libvirtDomain devices] graphics] objectAtIndex:i];
        if ([graphic type] == "vnc")
        {
            [buttonVNCKeymap selectItemWithTitle:[graphic keymap]];

            [fieldVNCPassword setStringValue:[graphic password]];
            [fieldVNCListen setStringValue:[graphic listen]];
            [fieldVNCPort setStringValue:([graphic port] != -1) ? [graphic port] : @""];
        }
    }

    [self setControl:buttonInputType enabledAccordingToPermission:@"define"];
    [buttonInputType selectItemWithTitle:[[[[_libvirtDomain devices] inputs] lastObject] type]];

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
    [_nicsDatasource setContent:[[_libvirtDomain devices] interfaces]];
    [tableInterfaces reloadData];

    // MANUAL
    _stringXMLDesc  = [[aStanza firstChildWithName:@"domain"] stringValue];
    [fieldStringXMLDesc setStringValue:@""];
    if (_stringXMLDesc)
    {
        _stringXMLDesc  = _stringXMLDesc.replace("\n  \n", "\n");
        _stringXMLDesc  = _stringXMLDesc.replace("xmlns='http://www.gajim.org/xmlns/undeclared' ", "");
        [fieldStringXMLDesc setStringValue:_stringXMLDesc];
    }


    _definitionRecovered = YES;
    [self handleDefinitionEdition:NO];
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

    [stanza addNode:[_libvirtDomain XMLNode]];
    [buttonDefine setImage:_imageDefining];
    [self sendStanza:stanza andRegisterSelector:@selector(_didDefineXML:)];
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
        [[CPNotificationCenter defaultCenter] postNotificationName:TNArchipelDefinitionUpdatedNotification object:self];
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
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:CPBundleLocalizedString(@"Virtual machine", @"Virtual machine")
                                                         message:CPBundleLocalizedString(@"Virtual machine has been undefined", @"Virtual machine has been undefined")];
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

    if ([aNotification object] == tableDrives)
    {
        if ([[aNotification object] numberOfSelectedRows] > 0)
        {
            [self setControl:_minusButtonDrives enabledAccordingToPermission:@"define"];
            [self setControl:_editButtonDrives enabledAccordingToPermission:@"define"];
        }
    }
    else if ([aNotification object] == tableInterfaces)
    {
        if ([[aNotification object] numberOfSelectedRows] > 0)
        {
            [self setControl:_minusButtonDrives enabledAccordingToPermission:@"define"];
            [self setControl:_editButtonDrives enabledAccordingToPermission:@"define"];
        }
    }
}

@end



// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNVirtualMachineDefinitionController], comment);
}
