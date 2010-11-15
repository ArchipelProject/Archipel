/*
 * AppController.j
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
@import <TNKit/TNKit.j>
@import <StropheCappuccino/StropheCappuccino.j>
@import <GrowlCappuccino/GrowlCappuccino.j>
@import <VNCCappuccino/VNCCappuccino.j>
@import <iTunesTabView/iTunesTabView.j>
@import <MessageBoard/MessageBoard.j>
@import <LPKit/LPKit.j>
@import <LPKit/LPMultiLineTextField.j>

// @import <LPKit/LPCrashReporter.j>

@import "Model/TNCategoriesAndGlobalSubclasses.j"
@import "Model/TNDatasourceRoster.j"
@import "Model/TNModule.j"
@import "Views/TNOutlineViewRoster.j"
@import "Views/TNRosterDataViews.j"
@import "Views/TNSearchField.j"
@import "Views/TNSwitch.j"
@import "Views/TNCalendarView.j"
@import "Views/TNModalWindow.j"
@import "Controllers/TNAvatarController.j"
@import "Controllers/TNConnectionController.j"
@import "Controllers/TNContactsController.j"
@import "Controllers/TNGroupsController.j"
@import "Controllers/TNModuleController.j"
@import "Controllers/TNPreferencesController.j"
@import "Controllers/TNPropertiesController.j"
@import "Controllers/TNTagsController.j"


/*! @global
    @group TNArchipelEntityType
    This represent a Hypervisor XMPP entity
*/
TNArchipelEntityTypeHypervisor      = @"hypervisor";

/*! @global
    @group TNArchipelEntityType
    This represent a virtual machine XMPP entity
*/
TNArchipelEntityTypeVirtualMachine  = @"virtualmachine";


/*! @global
    @group TNArchipelEntityType
    This represent a user XMPP entity
*/
TNArchipelEntityTypeUser            = @"user";

/*! @global
    @group TNArchipelEntityType
    This represent a group XMPP entity
*/
TNArchipelEntityTypeGroup           = @"group";


/*! @global
    @group TNArchipelStatus
    This string represent a status Available
*/
TNArchipelStatusAvailableLabel      = @"Available";

/*! @global
    @group TNArchipelStatus
    This string represent a status Away
*/
TNArchipelStatusAwayLabel           = @"Away";

/*! @global
    @group TNArchipelStatus
    This string represent a status Busy
*/
TNArchipelStatusBusyLabel           = @"Busy";

/*! @global
    @group TNArchipelStatus
    This string represent a status DND
*/
TNArchipelStatusDNDLabel            = @"Do not disturb";


/*! @global
    @group TNArchipelNotification
    ask for removing the current roster item
*/
TNArchipelActionRemoveSelectedRosterEntityNotification  = @"TNArchipelActionRemoveSelectedRosterEntityNotification";

/*! @global
    @group TNArchipelNotification
    Sent when two groups has been merged
*/
TNArchipelGroupMergedNotification                       = @"TNArchipelGroupMergedNotification";


/*! @global
    @group TNArchipelAction
    notification send when item selection changes in roster
*/
TNArchipelNotificationRosterSelectionChanged            = @"TNArchipelNotificationRosterSelectionChanged";

/*! @global
    @group UserDefaultsKeys
    base key of opened group save. will be TNArchipelRememberOpenedGroup_+JID
*/
TNArchipelRememberOpenedGroup                           = @"TNArchipelRememberOpenedGroup_";


/*! @global
    @group TNToolBarItem
    identifier for item logout
*/
TNToolBarItemLogout         = @"TNToolBarItemLogout";


/*! @global
    @group TNToolBarItem
    identifier for item tags
*/
TNToolBarItemTags        = @"TNToolBarItemTags";


/*! @global
    @group TNToolBarItem
    identifier for item help
*/
TNToolBarItemHelp           = @"TNToolBarItemHelp";

/*! @global
    @group TNToolBarItem
    identifier for item status
*/
TNToolBarItemStatus             = @"TNToolBarItemStatus";


/*! @defgroup  archipelcore Archipel Core
    @desc Core contains all basic and low level Archipel classes
*/


/*! @ingroup archipelcore
    This is the main application controller. It is loaded from MainMenu.cib.
    Anyone that is interessted in the way of Archipel is working should begin
    to read this class. This is the main application entry point.
*/
@implementation AppController : CPObject
{
    @outlet CPButtonBar             buttonBarLeft;
    @outlet CPImageView             ledIn;
    @outlet CPImageView             ledOut;
    @outlet CPSplitView             leftSplitView;
    @outlet CPSplitView             mainHorizontalSplitView;
    @outlet CPSplitView             splitViewTagsContents;
    @outlet CPTextField             textFieldAboutVersion;
    @outlet CPTextField             textFieldLoadingModuleLabel;
    @outlet CPTextField             textFieldLoadingModuleTitle;
    @outlet CPView                  filterView;
    @outlet CPView                  leftView;
    @outlet CPView                  rightView;
    @outlet CPView                  statusBar;
    @outlet CPWebView               helpView;
    @outlet CPWebView               webViewAboutCredits;
    @outlet CPWindow                theWindow;
    @outlet CPWindow                windowAboutArchipel;
    @outlet TNAvatarController      avatarController;
    @outlet TNConnectionController  connectionController;
    @outlet TNContactsController    contactsController;
    @outlet TNGroupsController      groupsController;
    @outlet TNPreferencesController preferencesController;
    @outlet TNPropertiesController  propertiesController;
    @outlet TNSearchField           filterField;
    @outlet TNTagsController        tagsController;
    @outlet TNModalWindow           windowModuleLoading;

    BOOL                            _shouldShowHelpView;
    BOOL                            _tagsVisible;
    CPImage                         _imageLedInData;
    CPImage                         _imageLedNoData;
    CPImage                         _imageLedOutData;
    CPMenu                          _mainMenu;
    CPMenu                          _modulesMenu;
    CPPlatformWindow                _platformHelpWindow;
    CPScrollView                    _outlineScrollView;
    CPTextField                     _rightViewTextField;
    CPTimer                         _ledInTimer;
    CPTimer                         _ledOutTimer;
    CPTimer                         _moduleLoadingDelay;
    CPWindow                        _helpWindow;
    int                             _tempNumberOfReadyModules;
    TNDatasourceRoster              _mainRoster;
    TNiTunesTabView                 _moduleTabView;
    TNModuleController              _moduleController;
    TNOutlineViewRoster             _rosterOutlineView;
    TNRosterDataViewContact         _rosterDataViewForContacts;
    TNRosterDataViewGroup           _rosterDataViewForGroups;
    TNToolbar                       _mainToolbar;
    TNViewHypervisorControl         _currentRightViewContent;
    TNPubSubController              _pubSubController;
}


#pragma mark -
#pragma mark Initialization

/*! This method initialize the content of the GUI when the CIB file
    as finished to load.
*/
- (void)awakeFromCib
{
    [[connectionController mainWindow] orderOut:nil];

    var bundle      = [CPBundle mainBundle],
        defaults    = [CPUserDefaults standardUserDefaults],
        growl       = [TNGrowlCenter defaultCenter],
        center      = [CPNotificationCenter defaultCenter],
        posx;

    // register defaults defaults
    [defaults registerDefaults:[CPDictionary dictionaryWithObjectsAndKeys:
            [bundle objectForInfoDictionaryKey:@"TNArchipelHelpWindowURL"], @"TNArchipelHelpWindowURL",
            [bundle objectForInfoDictionaryKey:@"TNArchipelVersion"], @"TNArchipelVersion",
            [bundle objectForInfoDictionaryKey:@"TNArchipelModuleLoadingDelay"], @"TNArchipelModuleLoadingDelay",
            [bundle objectForInfoDictionaryKey:@"TNArchipelConsoleDebugLevel"], @"TNArchipelConsoleDebugLevel",
            [bundle objectForInfoDictionaryKey:@"TNArchipelBOSHService"], @"TNArchipelBOSHService",
            [bundle objectForInfoDictionaryKey:@"TNArchipelBOSHResource"], @"TNArchipelBOSHResource",
            [bundle objectForInfoDictionaryKey:@"TNArchipelConsoleDebugLevel"], @"TNArchipelConsoleDebugLevel",
            [bundle objectForInfoDictionaryKey:@"TNArchipelCopyright"], @"TNArchipelCopyright",
            [bundle objectForInfoDictionaryKey:@"TNArchipelUseAnimations"], @"TNArchipelUseAnimations"
    ]];

    // register logs
    CPLogRegister(CPLogConsole, [defaults objectForKey:@"TNArchipelConsoleDebugLevel"]);

    // main split views
    [mainHorizontalSplitView setIsPaneSplitter:YES];

    // tags split views
    [splitViewTagsContents setIsPaneSplitter:YES];
    [splitViewTagsContents setValue:0.0 forThemeAttribute:@"pane-divider-thickness"]

    _tagsVisible = [defaults boolForKey:@"TNArchipelTagsVisible"];

    [[tagsController mainView] setFrame:[[[splitViewTagsContents subviews] objectAtIndex:0] frame]];
    [[[splitViewTagsContents subviews] objectAtIndex:0] addSubview:[tagsController mainView]];


    if (posx = [defaults integerForKey:@"mainSplitViewPosition"])
    {
        CPLog.trace("recovering with of main vertical CPSplitView from last state");
        [mainHorizontalSplitView setPosition:posx ofDividerAtIndex:0];

        var bounds = [leftView bounds];
        bounds.size.width = posx;
        [leftView setFrame:bounds];
    }
    [mainHorizontalSplitView setDelegate:self];

    /* hide main window */
    [theWindow orderOut:nil];

    /* toolbar */
    CPLog.trace("initializing mianToolbar");
    _mainToolbar = [[TNToolbar alloc] init];
    [theWindow setToolbar:_mainToolbar];
    [self makeToolbar];

    /* properties controller */
    CPLog.trace(@"initializing the leftSplitView");
    [leftSplitView setIsPaneSplitter:YES];
    [leftSplitView setBackgroundColor:[CPColor colorWithHexString:@"D8DFE8"]];
    [[leftSplitView subviews][1] removeFromSuperview];
    [leftSplitView addSubview:[propertiesController mainView]];
    [leftSplitView setPosition:[leftSplitView bounds].size.height ofDividerAtIndex:0];
    [propertiesController setAvatarManager:avatarController];

    /* outlineview */
    CPLog.trace(@"initializing _rosterOutlineView");
    _rosterOutlineView = [[TNOutlineViewRoster alloc] initWithFrame:[leftView bounds]];
    [_rosterOutlineView setDelegate:self];
    [_rosterOutlineView registerForDraggedTypes:[TNDragTypeContact]];
    [_rosterOutlineView setSearchField:filterField];
    [_rosterOutlineView setEntityRenameField:[propertiesController entryName]];
    [filterField setOutlineView:_rosterOutlineView];

    /* init scroll view of the outline view */
    CPLog.trace(@"initializing _outlineScrollView");
    _outlineScrollView = [[CPScrollView alloc] initWithFrame:[leftView bounds]];
    [_outlineScrollView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [_outlineScrollView setAutohidesScrollers:YES];
    [[_outlineScrollView contentView] setBackgroundColor:[CPColor colorWithHexString:@"D8DFE8"]];
    [_outlineScrollView setDocumentView:_rosterOutlineView];

    CPLog.trace(@"adding _outlineScrollView as subview of leftView");
    [leftView addSubview:_outlineScrollView];

    /* right view */
    CPLog.trace(@"initializing rightView");
    [rightView setBackgroundColor:[CPColor colorWithHexString:@"EEEEEE"]];
    [rightView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];

    /* filter view. */
    CPLog.trace(@"initializing the filterView");
    [filterView setBackgroundColor:[CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"gradientGray.png"]]]];

    /* tab module view */
    CPLog.trace(@"initializing the _moduleTabView");
    _moduleTabView = [[TNiTunesTabView alloc] initWithFrame:[rightView bounds]];
    [_moduleTabView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [_moduleTabView setBackgroundColor:[CPColor whiteColor]];
    [rightView addSubview:_moduleTabView];

    /* message in _moduleTabView */
    _rightViewTextField = [CPTextField labelWithTitle:@""];
    var bounds  = [_moduleTabView bounds];

    [_rightViewTextField setFrame:CGRectMake(bounds.size.width / 2 - 300, 153, 600, 200)];
    [_rightViewTextField setAutoresizingMask: CPViewMaxXMargin | CPViewMinXMargin];
    [_rightViewTextField setAlignment:CPCenterTextAlignment]
    [_rightViewTextField setFont:[CPFont boldSystemFontOfSize:18]];
    [_rightViewTextField setTextColor:[CPColor grayColor]];
    [_moduleTabView addSubview:_rightViewTextField];

    /* main menu */
    [self makeMainMenu];

    /* module Loader */
    [windowModuleLoading center];
    [windowModuleLoading makeKeyAndOrderFront:nil];
    [textFieldLoadingModuleTitle setTextShadowOffset:CGSizeMake(0.0, 1.0)];
    [textFieldLoadingModuleTitle setValue:[CPColor whiteColor] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
    [textFieldLoadingModuleTitle setTextColor:[CPColor colorWithHexString:@"000000"]];

    [textFieldLoadingModuleLabel setTextShadowOffset:CGSizeMake(0.0, 1.0)];
    [textFieldLoadingModuleLabel setValue:[CPColor whiteColor] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];


    CPLog.trace(@"initializing _moduleController");
    _tempNumberOfReadyModules = -1;

    _moduleController = [[TNModuleController alloc] init]

    [_moduleController setDelegate:self];
    [_moduleController setMainToolbar:_mainToolbar];
    [_moduleController setMainTabView:_moduleTabView];
    [_moduleController setInfoTextField:_rightViewTextField];
    [_moduleController setModulesPath:@"Modules/"]
    [_moduleController setMainModuleView:rightView];
    [_moduleController setModulesMenu:_modulesMenu];

    [_moduleTabView setDelegate:_moduleController];
    [_rosterOutlineView setModulesTabView:_moduleTabView];

    CPLog.trace(@"Starting loading all modules");
    [_moduleController load];

    CPLog.trace(@"Display _helpWindow");
    _shouldShowHelpView = YES;
    [self showHelpView];

    CPLog.trace(@"initializing Growl");
    [growl setView:rightView];

    CPLog.trace(@"Initializing the traffic status LED");
    [statusBar setBackgroundColor:[CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"statusBarBg.png"]]]];
    _imageLedInData     = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"data-in.png"]];
    _imageLedOutData    = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"data-out.png"]];
    _imageLedNoData     = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"data-no.png"]];

    // buttonBar
    CPLog.trace(@"Initializing the roster button bar");
    [mainHorizontalSplitView setButtonBar:buttonBarLeft forDividerAtIndex:0];

    var bezelColor              = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"TNButtonBar/buttonBarBackground.png"] size:CGSizeMake(1, 27)]],
        leftBezel               = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"TNButtonBar/buttonBarLeftBezel.png"] size:CGSizeMake(2, 26)],
        centerBezel             = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"TNButtonBar/buttonBarCenterBezel.png"] size:CGSizeMake(1, 26)],
        rightBezel              = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"TNButtonBar/buttonBarRightBezel.png"] size:CGSizeMake(2, 26)],
        buttonBezel             = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:[leftBezel, centerBezel, rightBezel] isVertical:NO]],
        leftBezelHighlighted    = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"TNButtonBar/buttonBarLeftBezelHighlighted.png"] size:CGSizeMake(2, 26)],
        centerBezelHighlighted  = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"TNButtonBar/buttonBarCenterBezelHighlighted.png"] size:CGSizeMake(1, 26)],
        rightBezelHighlighted   = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"TNButtonBar/buttonBarRightBezelHighlighted.png"] size:CGSizeMake(2, 26)],
        buttonBezelHighlighted  = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:[leftBezelHighlighted, centerBezelHighlighted, rightBezelHighlighted] isVertical:NO]],
        plusButton              = [[TNButtonBarPopUpButton alloc] initWithFrame:CPRectMake(0,0,30, 30)],
        plusMenu                = [[CPMenu alloc] init],
        minusButton             = [CPButtonBar minusButton];

    [buttonBarLeft setValue:bezelColor forThemeAttribute:"bezel-color"];
    [buttonBarLeft setValue:buttonBezel forThemeAttribute:"button-bezel-color"];
    [buttonBarLeft setValue:buttonBezelHighlighted forThemeAttribute:"button-bezel-color" inState:CPThemeStateHighlighted];

    [plusButton setTarget:self];
    [plusButton setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"plus-menu.png"] size:CPSizeMake(20, 20)]];
    [plusButton setBordered:NO];
    [plusButton setImagePosition:CPImageOnly];

    [plusMenu addItemWithTitle:@"Add a contact" action:@selector(addContact:) keyEquivalent:@""];
    [plusMenu addItemWithTitle:@"Add a group" action:@selector(addGroup:) keyEquivalent:@""];
    [plusButton setMenu:plusMenu];

    [minusButton setTarget:self];
    [minusButton setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"minus.png"] size:CPSizeMake(20, 20)]];
    [minusButton setAction:@selector(didMinusBouttonClicked:)];

    [buttonBarLeft setButtons:[plusButton, minusButton]];

    // copyright;
    [self copyright];

    // about window
    [webViewAboutCredits setMainFrameURL:[bundle pathForResource:@"credits.html"]];
    [webViewAboutCredits setBorderedWithHexColor:@"#C0C7D2"];
    [textFieldAboutVersion setStringValue:[defaults objectForKey:@"TNArchipelVersion"]];

    /* dataviews for roster */
    _rosterDataViewForContacts  = [[TNRosterDataViewContact alloc] init];
    _rosterDataViewForGroups    = [[TNRosterDataViewGroup alloc] init];

    /* notifications */
    CPLog.trace(@"registering for notification TNStropheConnectionSuccessNotification");
    [center addObserver:self selector:@selector(loginStrophe:) name:TNStropheConnectionStatusConnected object:nil];

    CPLog.trace(@"registering for notification TNStropheDisconnectionNotification");
    [center addObserver:self selector:@selector(logoutStrophe:) name:TNStropheConnectionStatusDisconnecting object:nil];

    CPLog.trace(@"registering for notification CPApplicationWillTerminateNotification");
    [center addObserver:self selector:@selector(onApplicationTerminate:) name:CPApplicationWillTerminateNotification object:nil];

    CPLog.trace(@"registering for notification TNArchipelModulesAllReadyNotification");
    [center addObserver:self selector:@selector(allModuleReady:) name:TNArchipelModulesAllReadyNotification object:nil];

    CPLog.trace(@"registering for notification TNArchipelActionRemoveSelectedRosterEntityNotification");
    [center addObserver:self selector:@selector(didMinusBouttonClicked:) name:TNArchipelActionRemoveSelectedRosterEntityNotification object:nil];

    CPLog.trace(@"registering for notification TNStropheContactMessageReceivedNotification");
    [center addObserver:self selector:@selector(didReceiveUserMessage:) name:TNStropheContactMessageReceivedNotification object:nil];

    CPLog.info(@"Initialization of AppController OK");
}

/*! Creates the mainmenu. it called by awakeFromCib
*/
- (void)makeMainMenu
{
    CPLog.trace(@"Creating the main menu");

    _mainMenu = [[CPMenu alloc] init];

    var archipelItem    = [_mainMenu addItemWithTitle:@"Archipel" action:nil keyEquivalent:@""],
        editMenu        = [_mainMenu addItemWithTitle:@"Edit" action:nil keyEquivalent:@""],
        contactsItem    = [_mainMenu addItemWithTitle:@"Contacts" action:nil keyEquivalent:@""],
        groupsItem      = [_mainMenu addItemWithTitle:@"Groups" action:nil keyEquivalent:@""],
        statusItem      = [_mainMenu addItemWithTitle:@"Status" action:nil keyEquivalent:@""],
        navigationItem  = [_mainMenu addItemWithTitle:@"Navigation" action:nil keyEquivalent:@""],
        moduleItem      = [_mainMenu addItemWithTitle:@"Modules" action:nil keyEquivalent:@""],
        helpItem        = [_mainMenu addItemWithTitle:@"Help" action:nil keyEquivalent:@""],
        archipelMenu    = [[CPMenu alloc] init],
        editMenuItem    = [[CPMenu alloc] init],
        groupsMenu      = [[CPMenu alloc] init],
        contactsMenu    = [[CPMenu alloc] init],
        statusMenu      = [[CPMenu alloc] init],
        navigationMenu  = [[CPMenu alloc] init],
        helpMenu        = [[CPMenu alloc] init];

    // Archipel
    [archipelMenu addItemWithTitle:@"About Archipel" action:@selector(showAboutWindow:) keyEquivalent:@""];
    [archipelMenu addItem:[CPMenuItem separatorItem]];
    [archipelMenu addItemWithTitle:@"Preferences" action:@selector(showPreferencesWindow:) keyEquivalent:@","];
    [archipelMenu addItem:[CPMenuItem separatorItem]];
    [archipelMenu addItemWithTitle:@"Log out" action:@selector(logout:) keyEquivalent:@"Q"];
    [archipelMenu addItemWithTitle:@"Quit" action:nil keyEquivalent:@""];
    [_mainMenu setSubmenu:archipelMenu forItem:archipelItem];

    //Edit
    [editMenuItem addItemWithTitle:@"Undo" action:@selector(undo:) keyEquivalent:@"z"];
    [editMenuItem addItemWithTitle:@"Redo" action:@selector(redo:) keyEquivalent:@"Z"];
    [editMenuItem addItem:[CPMenuItem separatorItem]];
    [editMenuItem addItemWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@"c"];
    [editMenuItem addItemWithTitle:@"Cut" action:@selector(cut:) keyEquivalent:@"x"];
    [editMenuItem addItemWithTitle:@"Paste" action:@selector(paste:) keyEquivalent:@"v"];
    [editMenuItem addItemWithTitle:@"Select all" action:@selector(selectAll:) keyEquivalent:@"a"];
    [_mainMenu setSubmenu:editMenuItem forItem:editMenu];

    // Groups
    [groupsMenu addItemWithTitle:@"Add group" action:@selector(addGroup:) keyEquivalent:@"G"];
    [groupsMenu addItemWithTitle:@"Delete group" action:@selector(deleteGroup:) keyEquivalent:@"D"];
    [groupsMenu addItem:[CPMenuItem separatorItem]];
    [groupsMenu addItemWithTitle:@"Rename group" action:@selector(renameGroup:) keyEquivalent:@""];
    [_mainMenu setSubmenu:groupsMenu forItem:groupsItem];

    // Contacts
    [contactsMenu addItemWithTitle:@"Add contact" action:@selector(addContact:) keyEquivalent:@"n"];
    [contactsMenu addItemWithTitle:@"Delete contact" action:@selector(deleteContact:) keyEquivalent:@"d"];
    [contactsMenu addItem:[CPMenuItem separatorItem]];
    [contactsMenu addItemWithTitle:@"Rename contact" action:@selector(renameContact:) keyEquivalent:@"R"];
    [_mainMenu setSubmenu:contactsMenu forItem:contactsItem];

    // Status
    [statusMenu addItemWithTitle:@"Set status available" action:nil keyEquivalent:@"1"];
    [statusMenu addItemWithTitle:@"Set status away" action:nil keyEquivalent:@"2"];
    [statusMenu addItemWithTitle:@"Set status busy" action:nil keyEquivalent:@"3"];
    [statusMenu addItem:[CPMenuItem separatorItem]];
    [statusMenu addItemWithTitle:@"Set custom status" action:nil keyEquivalent:@""];
    [_mainMenu setSubmenu:statusMenu forItem:statusItem];

    // navigation
    [navigationMenu addItemWithTitle:@"Hide main menu" action:@selector(switchMainMenu:) keyEquivalent:@"U"];
    [navigationMenu addItemWithTitle:@"Search entity" action:@selector(focusFilter:) keyEquivalent:@"F"];
    [navigationMenu addItem:[CPMenuItem separatorItem]];
    [navigationMenu addItemWithTitle:@"Select next entity" action:@selector(selectNextEntity:) keyEquivalent:nil];
    [navigationMenu addItemWithTitle:@"Select previous entity" action:@selector(selectPreviousEntity:) keyEquivalent:nil];
    [navigationMenu addItem:[CPMenuItem separatorItem]];
    [navigationMenu addItemWithTitle:@"Expand group" action:@selector(expandGroup:) keyEquivalent:@""];
    [navigationMenu addItemWithTitle:@"Collapse group" action:@selector(collapseGroup:) keyEquivalent:@""];
    [navigationMenu addItem:[CPMenuItem separatorItem]];
    [navigationMenu addItemWithTitle:@"Expand all groups" action:@selector(expandAllGroups:) keyEquivalent:@""];
    [navigationMenu addItemWithTitle:@"Collapse all groups" action:@selector(collapseAllGroups:) keyEquivalent:@""];
    [_mainMenu setSubmenu:navigationMenu forItem:navigationItem];

    // Modules
    _modulesMenu = [[CPMenu alloc] init];
    [_mainMenu setSubmenu:_modulesMenu forItem:moduleItem];

    // help
    [helpMenu addItemWithTitle:@"Archipel Help" action:nil keyEquivalent:@""];
    [helpMenu addItemWithTitle:@"Release note" action:nil keyEquivalent:@""];
    [helpMenu addItem:[CPMenuItem separatorItem]];
    [helpMenu addItemWithTitle:@"Go to website" action:@selector(openWebsite:) keyEquivalent:@""];
    [helpMenu addItemWithTitle:@"Report a bug" action:@selector(openBugTracker:) keyEquivalent:@""];
    [helpMenu addItem:[CPMenuItem separatorItem]];
    [helpMenu addItemWithTitle:@"Make a donation" action:@selector(openDonationPage:) keyEquivalent:@""];
    [_mainMenu setSubmenu:helpMenu forItem:helpItem];

    [CPApp setMainMenu:_mainMenu];
    [CPMenu setMenuBarVisible:NO];

    CPLog.trace(@"Main menu created");
}

/*! initialize the toolbar with default items
*/
- (void)makeToolbar
{
    var bundle  = [CPBundle bundleForClass:self];

    [_mainToolbar addItemWithIdentifier:TNToolBarItemLogout label:@"Log out" icon:[bundle pathForResource:@"logout.png"] target:self action:@selector(toolbarItemLogoutClick:)];
    [_mainToolbar addItemWithIdentifier:TNToolBarItemHelp label:@"Help" icon:[bundle pathForResource:@"help.png"] target:self action:@selector(toolbarItemHelpClick:)];
    [_mainToolbar addItemWithIdentifier:TNToolBarItemTags label:@"Tags" icon:[bundle pathForResource:@"tags.png"] target:self action:@selector(toolbarItemTagsClick:)];

    var statusSelector = [[CPPopUpButton alloc] initWithFrame:CGRectMake(8.0, 8.0, 120.0, 24.0)],
        availableItem = [[CPMenuItem alloc] init],
        awayItem = [[CPMenuItem alloc] init],
        busyItem = [[CPMenuItem alloc] init],
        DNDItem = [[CPMenuItem alloc] init],
        statusItem = [_mainToolbar addItemWithIdentifier:TNToolBarItemStatus label:@"Status" view:statusSelector target:self action:@selector(toolbarItemPresenceStatusClick:)];

    [availableItem setTitle:TNArchipelStatusAvailableLabel];
    [availableItem setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"Available.png"]]];
    [statusSelector addItem:availableItem];

    [awayItem setTitle:TNArchipelStatusAwayLabel];
    [awayItem setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"Away.png"]]];
    [statusSelector addItem:awayItem];

    [busyItem setTitle:TNArchipelStatusBusyLabel];
    [busyItem setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"Busy.png"]]];
    [statusSelector addItem:busyItem];

    [DNDItem setTitle:TNArchipelStatusDNDLabel];
    [DNDItem setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"DND.png"]]];
    [statusSelector addItem:DNDItem];

    [statusItem setMinSize:CGSizeMake(120.0, 24.0)];
    [statusItem setMaxSize:CGSizeMake(120.0, 24.0)];

    [_mainToolbar setPosition:0 forToolbarItemIdentifier:TNToolBarItemStatus];
    [_mainToolbar setPosition:1 forToolbarItemIdentifier:CPToolbarSeparatorItemIdentifier];
    [_mainToolbar setPosition:499 forToolbarItemIdentifier:CPToolbarFlexibleSpaceItemIdentifier];
    [_mainToolbar setPosition:901 forToolbarItemIdentifier:CPToolbarSeparatorItemIdentifier];
    [_mainToolbar setPosition:902 forToolbarItemIdentifier:TNToolBarItemTags];
    [_mainToolbar setPosition:903 forToolbarItemIdentifier:TNToolBarItemHelp];
    [_mainToolbar setPosition:904 forToolbarItemIdentifier:TNToolBarItemLogout];
}

#pragma mark -
#pragma mark Notifications handlers

/*! Notification responder of TNStropheConnection
    will be performed on login
    @param aNotification the received notification. This notification will contains as object the TNStropheConnection
*/
- (void)loginStrophe:(CPNotification)aNotification
{
    var connection = [aNotification object];

    [CPMenu setMenuBarVisible:YES];
    [[connectionController mainWindow] orderOut:nil];
    [theWindow makeKeyAndOrderFront:nil];

    _pubSubController = [TNPubSubController pubSubControllerWithConnection:connection];
    [_pubSubController retrieveSubscriptions];

    _mainRoster = [[TNDatasourceRoster alloc] initWithConnection:connection];

    [_mainRoster setDelegate:contactsController];
    [_mainRoster setFilterField:filterField];
    [[_mainRoster connection] rawInputRegisterSelector:@selector(stropheConnectionRawIn:) ofObject:self];
    [[_mainRoster connection] rawOutputRegisterSelector:@selector(stropheConnectionRawOut:) ofObject:self];
    [_mainRoster getRoster];

    [tagsController setConnection:connection];
    [tagsController setPubSubController:_pubSubController];

    [propertiesController setRoster:_mainRoster];
    [propertiesController setPubSubController:_pubSubController];

    [contactsController setRoster:_mainRoster];
    [contactsController setPubSubController:_pubSubController];

    [groupsController setRoster:_mainRoster];

    [_rosterOutlineView setDataSource:_mainRoster];
    [_rosterOutlineView recoverExpandedWithBaseKey:TNArchipelRememberOpenedGroup itemKeyPath:@"name"];

    [_moduleController setRoster:_mainRoster];
    [_moduleController setRosterForToolbarItems:_mainRoster andConnection:connection];

    if (_tagsVisible)
        [splitViewTagsContents setPosition:32.0 ofDividerAtIndex:0];
    else
        [splitViewTagsContents setPosition:0.0 ofDividerAtIndex:0];

}

/*! Notification responder of TNStropheConnection
    will be performed on logout
    @param aNotification the received notification. This notification will contains as object the TNStropheConnection
*/
- (void)logoutStrophe:(CPNotification)aNotification
{
    [theWindow orderOut:nil];
    [[connectionController mainWindow] makeKeyAndOrderFront:nil];
}

/*! Notification responder for CPApplicationWillTerminateNotification
*/
- (void)onApplicationTerminate:(CPNotification)aNotification
{
    [_mainRoster disconnect];
}

/*! Triggered when TNModuleController send TNArchipelModulesAllReadyNotification.
*/
- (void)allModuleReady:(CPNotification)aNotification
{
}


- (void)didReceiveUserMessage:(CPNotification)aNotification
{
    var user            = [[[aNotification userInfo] objectForKey:@"stanza"] fromUser],
        message         = [[[[aNotification userInfo] objectForKey:@"stanza"] firstChildWithName:@"body"] text],
        bundle          = [CPBundle bundleForClass:[self class]],
        customIcon      = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"message-icon.png"]],
        currentContact  = [aNotification object];

    if ([_rosterOutlineView selectedRow] != [_rosterOutlineView rowForItem:currentContact])
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:user
                                                         message:message
                                                      customIcon:customIcon
                                                          target:self
                                                          action:@selector(growlNotification:clickedWithUser:)
                                                actionParameters:currentContact];

    [_rosterOutlineView reloadData];
}



#pragma mark -
#pragma mark Utilities

/*! Display the helpView in the rightView
*/
- (void)showHelpView
{
    var bundle      = [CPBundle mainBundle],
        defaults    = [CPUserDefaults standardUserDefaults],
        url         = [defaults objectForKey:@"TNArchipelHelpWindowURL"],
        version     = [defaults objectForKey:@"TNArchipelVersion"];

    if (!url || (url == @"local"))
        url = @"help/index.html";

    [helpView setMainFrameURL:[bundle pathForResource:url] + "?version=" + version];

    [helpView setFrame:[rightView bounds]];
    [rightView addSubview:helpView];
}

/*! Hide the helpView from the rightView
*/
- (void)hideHelpView
{
    [helpView removeFromSuperview];
}

/*! display the copyright notice
*/
- (void)copyright
{
    var defaults    = [CPUserDefaults standardUserDefaults],
        copy = document.createElement("div");

    copy.style.position = "absolute";
    copy.style.fontSize = "10px";
    copy.style.color = "#6C707F";
    copy.style.width = "700px";
    copy.style.bottom = "8px";
    copy.style.left = "50%";
    copy.style.textAlign = "center";
    copy.style.marginLeft = "-350px";
    // copy.style.textShadow = "0px 1px 0px #C6CAD9";
    copy.innerHTML =  [defaults objectForKey:@"TNArchipelVersion"] + @" - " + [defaults objectForKey:@"TNArchipelCopyright"];
    document.body.appendChild(copy);

}


#pragma mark -
#pragma mark Actions

/*! will remove the selected roster item according to its type
    @param the sender of the action
*/
- (IBAction)didMinusBouttonClicked:(id)sender
{
    var index   = [[_rosterOutlineView selectedRowIndexes] firstIndex],
        item    = [_rosterOutlineView itemAtRow:index];

    if ([item class] == TNStropheContact)
        [self deleteContact:sender];
    else if ([item class] == TNStropheGroup)
        [self deleteGroup:sender];
}

/*! will log out from Archipel
    @param the sender of the action
*/
- (IBAction)logout:(id)sender
{
    var defaults = [CPUserDefaults standardUserDefaults];

    [defaults removeObjectForKey:@"TNArchipelBOSHJID"];
    [defaults removeObjectForKey:@"TNArchipelBOSHPassword"];
    [defaults setBool:NO forKey:@"TNArchipelBOSHRememberCredentials"];

    CPLog.info(@"starting to disconnect");
    [_mainRoster disconnect];

    [CPMenu setMenuBarVisible:NO];
}

/*! will opens the add contact window
    @param the sender of the action
*/
- (IBAction)addContact:(id)sender
{
    [contactsController showWindow:sender];
}

/*! will ask for deleting the selected contact
    @param the sender of the action
*/
- (IBAction)deleteContact:(id)sender
{
    var index   = [[_rosterOutlineView selectedRowIndexes] firstIndex],
        contact = [_rosterOutlineView itemAtRow:index];

    [contactsController deleteContact:contact];
}

/*! Opens the add group window
    @param the sender of the action
*/
- (IBAction)addGroup:(id)sender
{
    [groupsController showWindow:sender];
}

/*! will ask for deleting the selected group
    @param the sender of the action
*/
- (IBAction)deleteGroup:(id)sender
{
    var index       = [[_rosterOutlineView selectedRowIndexes] firstIndex],
        group       = [_rosterOutlineView itemAtRow:index];

    [groupsController deleteGroup:group];
}

/*! Will select the next entity in Roster
    @param the sender of the action
*/
- (IBAction)selectNextEntity:(id)sender
{
    var selectedIndex   = [[_rosterOutlineView selectedRowIndexes] firstIndex],
        nextIndex       = (selectedIndex + 1) > [_rosterOutlineView numberOfRows] - 1 ? 0 : (selectedIndex + 1);

    [_rosterOutlineView selectRowIndexes:[CPIndexSet indexSetWithIndex:nextIndex] byExtendingSelection:NO];
}

/*! Will select the previous entity in Roster
    @param the sender of the action
*/
- (IBAction)selectPreviousEntity:(id)sender
{
    var selectedIndex   = [[_rosterOutlineView selectedRowIndexes] firstIndex],
        nextIndex       = (selectedIndex - 1) < 0 ? [_rosterOutlineView numberOfRows] -1 : (selectedIndex - 1);

    [_rosterOutlineView selectRowIndexes:[CPIndexSet indexSetWithIndex:nextIndex] byExtendingSelection:NO];

}

/*! Make the property view rename field active
    @param the sender of the action
*/
- (IBAction)renameContact:(id)sender
{
    [[propertiesController entryName] mouseDown:nil];
}

/*! Make the property view rename field active
    @param the sender of the action
*/
- (IBAction)renameGroup:(id)sender
{
    [[propertiesController entryName] mouseDown:nil];
}

/*! simulate a click on the focus filter
    @param the sender of the action
*/
- (IBAction)focusFilter:(id)sender
{
    [filterField mouseDown:nil];
}

/*! Expands the current group
    @param the sender of the action
*/
- (IBAction)expandGroup:(id)sender
{
    var index       = [_rosterOutlineView selectedRowIndexes];

    if ([index firstIndex] == -1)
        return;

    var item        = [_rosterOutlineView itemAtRow:[index firstIndex]];

    [_rosterOutlineView expandItem:item];
}

/*! Collapses the current group
    @param the sender of the action
*/
- (IBAction)collapseGroup:(id)sender
{
    var index = [_rosterOutlineView selectedRowIndexes];

    if ([index firstIndex] == -1)
        return;

    var item = [_rosterOutlineView itemAtRow:[index firstIndex]];

    [_rosterOutlineView collapseItem:item];
}

/*! Expands all groups
    @param the sender of the action
*/
- (IBAction)expandAllGroups:(id)sender
{
    [_rosterOutlineView expandAll];
}

/*! Collapses all groups
    @param the sender of the action
*/
- (IBAction)collapseAllGroups:(id)sender
{
    [_rosterOutlineView collapseAll];
}

/*! Opens the archipel website in a new window
    @param the sender of the action
*/
- (IBAction)openWebsite:(id)sender
{
    window.open("http://archipelproject.org");
}

/*! Opens the donation website in a new window
    @param the sender of the action
*/
- (IBAction)openDonationPage:(id)sender
{
    window.open("http://antoinemercadal.fr/archipelblog/donate/");
}

/*! Opens the archipel issues website in a new window
    @param the sender of the action
*/
- (IBAction)openBugTracker:(id)sender
{
    window.open("http://github.org/primalmotion/archipel/issues/new");
}

/*! hide or show the main menu
    @param the sender of the action
*/
- (IBAction)switchMainMenu:(id)sender
{
    if ([CPMenu menuBarVisible])
        [CPMenu setMenuBarVisible:NO];
    else
        [CPMenu setMenuBarVisible:YES];
}

/*! shows the About window
    @param the sender of the action
*/
- (IBAction)showAboutWindow:(id)sender
{
    [windowAboutArchipel makeKeyAndOrderFront:sender];
}

/*! shows the Preferences window
    @param the sender of the action
*/
- (IBAction)showPreferencesWindow:(id)sender
{
    [preferencesController showWindow:sender];
}


#pragma mark -
#pragma mark Toolbar Actions

/*! Delegate of toolbar imutables toolbar items.
    Trigger on delete help item click.
    This will show a window conataining the helpView
    To have more information about the toolbar, see TNToolbar
*/
- (IBAction)toolbarItemHelpClick:(id)sender
{
    if (!_helpWindow)
    {
        _platformHelpWindow = [[CPPlatformWindow alloc] initWithContentRect:CGRectMake(0,0,950,600)];

        _helpWindow     = [[CPWindow alloc] initWithContentRect:CGRectMake(0,0,950,600) styleMask:CPTitledWindowMask | CPClosableWindowMask | CPMiniaturizableWindowMask | CPResizableWindowMask | CPBorderlessBridgeWindowMask];
        var scrollView  = [[CPScrollView alloc] initWithFrame:[[_helpWindow contentView] bounds]];

        [_helpWindow setPlatformWindow:_platformHelpWindow];
        [_platformHelpWindow orderFront:nil];

        [_helpWindow setDelegate:self];

        var bundle          = [CPBundle mainBundle],
            defaults        = [CPUserDefaults standardUserDefaults],
            newHelpView     = [[CPWebView alloc] initWithFrame:[[_helpWindow contentView] bounds]],
            url             = [defaults objectForKey:@"TNArchipelHelpWindowURL"],
            version         = [defaults objectForKey:@"TNArchipelVersion"];

        if (!url || (url == @"local"))
            url = @"help/index.html";

        [newHelpView setMainFrameURL:[bundle pathForResource:url] + "?version=" + version];

        [scrollView setAutohidesScrollers:YES];
        [scrollView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
        [scrollView setDocumentView:newHelpView];

        [_helpWindow setContentView:scrollView];
        [_helpWindow center];
        [_helpWindow makeKeyAndOrderFront:nil];
    }
    else
    {
        [_helpWindow close];
        _helpWindow = nil;
    }
}

/*! Delegate of toolbar imutables toolbar items.
    Trigger presence item change.
    This will change your own XMPP status
*/
- (IBAction)toolbarItemPresenceStatusClick:(id)sender
{
    var XMPPShow,
        statusLabel = [sender title],
        presence    = [TNStropheStanza presenceWithAttributes:{}],
        growl       = [TNGrowlCenter defaultCenter];

    switch (statusLabel)
    {
        case TNArchipelStatusAvailableLabel:
            XMPPShow = TNStropheContactStatusOnline
            break;
        case TNArchipelStatusAwayLabel:
            XMPPShow = TNStropheContactStatusAway
            break;
        case TNArchipelStatusBusyLabel:
            XMPPShow = TNStropheContactStatusBusy
            break;
        case TNArchipelStatusDNDLabel:
            XMPPShow = TNStropheContactStatusDND
            break;
    }

    [presence addChildWithName:@"status"];
    [presence addTextNode:statusLabel];
    [presence up]
    [presence addChildWithName:@"show"];
    [presence addTextNode:XMPPShow];
    CPLog.info(@"Changing presence to " + statusLabel + ":" + XMPPShow);

    [growl pushNotificationWithTitle:@"Status" message:@"Your status is now " + statusLabel];

    [[_mainRoster connection] send:presence];
}

/*! Delegate of toolbar imutables toolbar items.
    Trigger on logout item click
    To have more information about the toolbar, see TNToolbar
    @param sender the sender of the action (the CPToolbarItem)
*/
- (IBAction)toolbarItemLogoutClick:(id)sender
{
    [self logout:sender];
}

/*! Delegate of toolbar imutables toolbar items.
    Trigger on tags item click
    To have more information about the toolbar, see TNToolbar
    @param sender the sender of the action (the CPToolbarItem)
*/
- (IBAction)toolbarItemTagsClick:(id)sender
{
    var defaults = [CPUserDefaults standardUserDefaults];

    _tagsVisible = !_tagsVisible;

    if ([defaults boolForKey:@"TNArchipelUseAnimations"])
    {
        var anim = [[TNAnimation alloc] initWithDuration:0.3 animationCurve:CPAnimationEaseInOut];

        [anim setDelegate:self];
        [anim setFrameRate:0.0];
        [anim startAnimation];
    }
    else
    {
        [self animation:nil valueForProgress:1.0];
    }
}


#pragma mark -
#pragma mark Delegates

/*! Delegate for CPWindow.
    Tipically set _helpWindow to nil on closes.
*/
- (void)windowWillClose:(CPWindow)aWindow
{
    if (aWindow === _helpWindow)
    {
        _helpWindow = nil;
    }
}

/*! delegate of CPAnimation
*/
- (void)animation:(CPAnimation)anAnimation valueForProgress:(float)aValue
{
    var dividerPosition = _tagsVisible ?  (aValue * 32.0) : 32.0 - (aValue * 32.0),
        defaults        = [CPUserDefaults standardUserDefaults];

    [splitViewTagsContents setPosition:dividerPosition ofDividerAtIndex:0];

    [defaults setBool:_tagsVisible forKey:@"TNArchipelTagsVisible"];
}

/*! Delegate of TNOutlineView
    will be performed when when item will expands and save this state in CPUserDefaults

    @param aNotification the received notification
*/
- (void)outlineViewItemWillExpand:(CPNotification)aNotification
{
    var item        = [[aNotification userInfo] valueForKey:@"CPObject"],
        defaults    = [CPUserDefaults standardUserDefaults],
        key         = TNArchipelRememberOpenedGroup + [item name];

    [defaults setObject:"expanded" forKey:key];
}

/*! Delegate of TNOutlineView
    will be performed when when item will collapses and save this state in CPUserDefaults

    @param aNotification the received notification
*/
- (void)outlineViewItemWillCollapse:(CPNotification)aNotification
{
    var item        = [[aNotification userInfo] valueForKey:@"CPObject"],
        defaults    = [CPUserDefaults standardUserDefaults],
        key         = TNArchipelRememberOpenedGroup + [item name];

    [defaults setObject:"collapsed" forKey:key];

    return YES;
}

/*! called the roster outlineView to ask the dataView it should use for given item.
*/
- (void)outlineView:(CPOutlineView)anOutlineView dataViewForTableColumn:(CPTableColumn)aColumn item:(id)anItem
{
    switch ([anItem class])
    {
        case TNStropheGroup:
            return _rosterDataViewForGroups;
        case TNStropheContact:
            return _rosterDataViewForContacts;
    }
}

/*! Delegate of TNOutlineView
    will be performed when selection changes. Tab Modules displaying
    @param aNotification the received notification
*/
- (void)outlineViewSelectionDidChange:(CPNotification)notification
{
    var defaults    = [CPUserDefaults standardUserDefaults],
        index       = [[_rosterOutlineView selectedRowIndexes] firstIndex],
        item        = [_rosterOutlineView itemAtRow:index],
        loadDelay   = [defaults objectForKey:@"TNArchipelModuleLoadingDelay"];

    if (_moduleLoadingDelay)
        [_moduleLoadingDelay invalidate];

    [propertiesController setEntity:item];
    [propertiesController reload];

    _moduleLoadingDelay = [CPTimer scheduledTimerWithTimeInterval:loadDelay target:self selector:@selector(performModuleChange:) userInfo:item repeats:NO];
}

/*! This method is called by delegate outlineViewSelectionDidChange: after a small delay by a timer
    in order to really process the modules swappoing. this avoid overloading if up key is maintained for example.
*/
- (void)performModuleChange:(CPTimer)aTimer
{
    if ([_rosterOutlineView numberOfSelectedRows] == 0)
    {
        [self showHelpView];
        //[_mainRoster setCurrentItem:nil];
        [propertiesController hideView];
    }
    else
    {
        var item        = [aTimer userInfo],
            defaults    = [CPUserDefaults standardUserDefaults];

        //[_mainRoster setCurrentItem:item];

        [self hideHelpView];

        switch ([item class])
        {
            case TNStropheGroup:
                CPLog.info(@"setting the entity as " + item + " of type group");
                [_moduleController setEntity:item ofType:@"group"];
                break;

            case TNStropheContact:
                var vCard       = [item vCard],
                    entityType  = [_moduleController analyseVCard:vCard];
                CPLog.info(@"setting the entity as " + item + " of type " + entityType);
                [_moduleController setEntity:item ofType:entityType];
                break;
        }
    }

    // post a system wide notification about the changes
    [[CPNotificationCenter defaultCenter] postNotificationName:TNArchipelNotificationRosterSelectionChanged object:item];
}

/*! Delegate of mainSplitView. This will save the positionning of splitview in CPUserDefaults
*/
- (void)splitViewDidResizeSubviews:(CPNotification)aNotification
{
    var defaults    = [CPUserDefaults standardUserDefaults],
        splitView   = [aNotification object],
        newWidth    = [splitView rectOfDividerAtIndex:0].origin.x;

    CPLog.info(@"setting the mainSplitViewPosition value in defaults");
    [defaults setInteger:newWidth forKey:@"mainSplitViewPosition"];
}

/*! delegate of TNModuleController sent when all modules are loaded
*/
- (void)moduleLoaderLoadingComplete:(TNModuleController)aLoader
{
    CPLog.info(@"All modules have been loaded");
    CPLog.trace(@"Positionning the connection window");

    [windowModuleLoading orderOut:nil];
    [[connectionController mainWindow] center];
    [[connectionController mainWindow] makeKeyAndOrderFront:nil];
    [connectionController initCredentials];

    [_mainToolbar reloadToolbarItems];
}

/*! delegate of StropheCappuccino that will be trigger on Raw input traffic
    This will light the in traffic light
*/
- (void)stropheConnectionRawIn:(TNStropheStanza)aStanza
{
    [ledIn setImage:_imageLedInData];

    if (_ledInTimer)
        [_ledInTimer invalidate];

    _ledInTimer = [CPTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(timeOutDataLed:) userInfo:ledIn repeats:NO];
}

/*! delegate of StropheCappuccino that will be trigger on Raw output traffic
    This will light the out traffic light
*/
- (void)stropheConnectionRawOut:(TNStropheStanza)aStanza
{
    [ledOut setImage:_imageLedOutData];

    if (_ledOutTimer)
        [_ledOutTimer invalidate];
    _ledOutTimer = [CPTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(timeOutDataLed:) userInfo:ledOut repeats:NO];
}

/*! This will light of traffic LED after a small delay
*/
- (void)timeOutDataLed:(CPTimer)aTimer
{
    [[aTimer userInfo] setImage:_imageLedNoData];
}


/*! Growl delegate
*/
- (void)growlNotification:(id)sender clickedWithUser:(TNStropheContact)aContact
{
    var row     = [_rosterOutlineView rowForItem:aContact],
        indexes = [CPIndexSet indexSetWithIndex:row];

    [_rosterOutlineView selectRowIndexes:indexes byExtendingSelection:NO];
}

@end
