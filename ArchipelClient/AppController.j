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

@import "Resources/lang/localization.js"

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

@import "Categories/TNCategories.j"
@import "Controllers/TNAvatarController.j"
@import "Controllers/TNConnectionController.j"
@import "Controllers/TNContactsController.j"
@import "Controllers/TNGroupsController.j"
@import "Controllers/TNModuleController.j"
@import "Controllers/TNPermissionsCenter.j"
@import "Controllers/TNPreferencesController.j"
@import "Controllers/TNPropertiesController.j"
@import "Controllers/TNTagsController.j"
@import "Controllers/TNUpdateController.j"
@import "Controllers/TNUserAvatarController.j"
@import "Model/TNDatasourceRoster.j"
@import "Model/TNModule.j"
@import "Model/TNVersion.j"
@import "Views/TNButtonBarPopUpButton.j"
@import "Views/TNCalendarView.j"
@import "Views/TNEditableLabel.j"
@import "Views/TNMenuItem.j"
@import "Views/TNModalWindow.j"
@import "Views/TNOutlineViewRoster.j"
@import "Views/TNRosterDataViews.j"
@import "Views/TNSearchField.j"
@import "Views/TNSwitch.j"



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
    @group TNArchipelAction
    notification send when item selection changes in roster
*/
TNArchipelNotificationRosterSelectionChanged            = @"TNArchipelNotificationRosterSelectionChanged";

/*! @global
    @group UserDefaultsKeys
    base key of opened group save. will be TNArchipelRememberOpenedGroup_+JID
*/
TNArchipelRememberOpenedGroup                           = @"TNArchipelRememberOpenedGroup_";


TNUserAvatarSize            = CPSizeMake(50.0, 50.0);

var TNArchipelStatusAvailableLabel  = @"Available",
    TNArchipelStatusAwayLabel       = @"Away",
    TNArchipelStatusBusyLabel       = @"Busy",
    TNArchipelStatusDNDLabel        = @"Do not disturb",
    TNToolBarItemLogout             = @"TNToolBarItemLogout",
    TNToolBarItemTags               = @"TNToolBarItemTags",
    TNToolBarItemHelp               = @"TNToolBarItemHelp",
    TNToolBarItemStatus             = @"TNToolBarItemStatus",
    TNArchipelTagViewHeight         = 33.0;


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
    @outlet CPProgressIndicator     progressIndicatorModulesLoading;
    @outlet CPSplitView             leftSplitView;
    @outlet CPSplitView             mainHorizontalSplitView;
    @outlet CPSplitView             splitViewTagsContents;
    @outlet CPTextField             labelCurrentUser;
    @outlet CPTextField             labelModulesLoadingName;
    @outlet CPTextField             textFieldAboutVersion;
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
    @outlet TNModuleController      moduleController;
    @outlet TNPreferencesController preferencesController;
    @outlet TNPropertiesController  propertiesController;
    @outlet TNSearchField           filterField;
    @outlet TNTagsController        tagsController;
    @outlet TNUpdateController      updateController;
    @outlet TNUserAvatarController  userAvatarController;

    BOOL                            _shouldShowHelpView;
    BOOL                            _tagsVisible;
    CPButton                        _hideButton;
    CPButton                        _userAvatarButton;
    CPImage                         _hideButtonImageDisable;
    CPImage                         _hideButtonImageEnable;
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
    CPView                          _viewRosterMask;
    CPWindow                        _helpWindow;
    int                             _tempNumberOfReadyModules;
    TNiTunesTabView                 _moduleTabView;
    TNOutlineViewRoster             _rosterOutlineView;
    TNPubSubController              _pubSubController;
    TNRosterDataViewContact         _rosterDataViewForContacts;
    TNRosterDataViewGroup           _rosterDataViewForGroups;
    TNToolbar                       _mainToolbar;
    TNViewHypervisorControl         _currentRightViewContent;
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

    /* register defaults defaults */
    [defaults registerDefaults:[CPDictionary dictionaryWithObjectsAndKeys:
            [bundle objectForInfoDictionaryKey:@"TNArchipelHelpWindowURL"], @"TNArchipelHelpWindowURL",
            [bundle objectForInfoDictionaryKey:@"TNArchipelVersionHuman"], @"TNArchipelVersionHuman",
            [bundle objectForInfoDictionaryKey:@"TNArchipelVersion"], @"TNArchipelVersion",
            [bundle objectForInfoDictionaryKey:@"TNArchipelModuleLoadingDelay"], @"TNArchipelModuleLoadingDelay",
            [bundle objectForInfoDictionaryKey:@"TNArchipelConsoleDebugLevel"], @"TNArchipelConsoleDebugLevel",
            [bundle objectForInfoDictionaryKey:@"TNArchipelBOSHService"], @"TNArchipelBOSHService",
            [bundle objectForInfoDictionaryKey:@"TNArchipelBOSHResource"], @"TNArchipelBOSHResource",
            [bundle objectForInfoDictionaryKey:@"TNArchipelCopyright"], @"TNArchipelCopyright",
            [bundle objectForInfoDictionaryKey:@"TNArchipelUseAnimations"], @"TNArchipelUseAnimations",
            [bundle objectForInfoDictionaryKey:@"TNArchipelAutoCheckUpdate"], @"TNArchipelAutoCheckUpdate"
    ]];

    /* register logs */
    CPLogRegister(CPLogConsole, [defaults objectForKey:@"TNArchipelConsoleDebugLevel"]);

    /* main split views */
    [mainHorizontalSplitView setIsPaneSplitter:NO];

    /* tags split views */
    [splitViewTagsContents setIsPaneSplitter:NO];
    [splitViewTagsContents setValue:0.0 forThemeAttribute:@"divider-thickness"]

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

    /* avatar chooser */
    [self makeAvatarChooser];

    /* properties controller */
    CPLog.trace(@"initializing the leftSplitView");
    [leftSplitView setIsPaneSplitter:NO];
    [leftSplitView setBackgroundColor:[CPColor colorWithHexString:@"D8DFE8"]];
    [[leftSplitView subviews][1] removeFromSuperview];
    [leftSplitView addSubview:[propertiesController mainView]];
    [leftSplitView setPosition:[leftSplitView bounds].size.height ofDividerAtIndex:0];
    [propertiesController setAvatarManager:avatarController];
    [propertiesController setEnabled:[defaults boolForKey:@"TNArchipelPropertyControllerEnabled"]];

    /* outlineview */
    CPLog.trace(@"initializing _rosterOutlineView");
    _rosterOutlineView = [[TNOutlineViewRoster alloc] initWithFrame:[leftView bounds]];
    [_rosterOutlineView setDelegate:self];
    [_rosterOutlineView registerForDraggedTypes:[TNDragTypeContact]];
    [_rosterOutlineView setSearchField:filterField];
    [_rosterOutlineView setEntityRenameField:[propertiesController entryName]];
    [filterField setOutlineView:_rosterOutlineView];
    [filterField setMaximumRecents:10];
    [filterField setToolTip:@"Filter contacts by name or tags"];

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
    [filterView setBackgroundColor:[CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"Backgrounds/background-filter.png"]]]];

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


    CPLog.trace(@"initializing moduleController");
    _tempNumberOfReadyModules = -1;

    [moduleController setDelegate:self];
    [moduleController setMainToolbar:_mainToolbar];
    [moduleController setMainTabView:_moduleTabView];
    [moduleController setInfoTextField:_rightViewTextField];
    [moduleController setModulesPath:@"Modules/"]
    [moduleController setMainModuleView:rightView];
    [moduleController setModulesMenu:_modulesMenu];

    [_moduleTabView setDelegate:moduleController];
    [_rosterOutlineView setModulesTabView:_moduleTabView];

    var progressBarSize = CPSizeMake(CGRectGetWidth([leftView frame]) - 15, 16.0);
    CPLog.trace(@"Starting loading all modules");
    [CPProgressIndicator initialize];
    [progressIndicatorModulesLoading setStyle:CPProgressIndicatorBarStyle];
    [progressIndicatorModulesLoading setMinValue:0.0];
    [progressIndicatorModulesLoading setMaxValue:1.0];
    [progressIndicatorModulesLoading setDoubleValue:0.0];
    [progressIndicatorModulesLoading setFrameSize:progressBarSize];
    [labelModulesLoadingName setFrameSize:progressBarSize];
    [progressIndicatorModulesLoading setBackgroundColor:[CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"ProgressBarBezel.png"]]]];
    [labelModulesLoadingName setAlignment:CPCenterTextAlignment];

    CPLog.trace(@"Display _helpWindow");
    _shouldShowHelpView = YES;
    [helpView setScrollMode:CPWebViewScrollNative];

    CPLog.trace(@"initializing Growl");
    [growl setView:rightView];

    CPLog.trace(@"Initializing the traffic status LED");
    [statusBar setBackgroundColor:[CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"Backgrounds/background-statusbar.png"]]]];
    _imageLedInData     = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"IconsDataLEDs/data-in.png"]];
    _imageLedOutData    = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"IconsDataLEDs/data-out.png"]];
    _imageLedNoData     = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"IconsDataLEDs/data-no.png"]];

    /* buttonBar */
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
        plusButton              = [[TNButtonBarPopUpButton alloc] initWithFrame:CPRectMake(0, 0, 35, 25)],
        plusMenu                = [[CPMenu alloc] init],
        minusButton             = [CPButtonBar minusButton];

    _hideButton             = [CPButtonBar minusButton];
    _hideButtonImageEnable  = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"IconsButtonBar/show.png"] size:CPSizeMake(16, 16)];
    _hideButtonImageDisable = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"IconsButtonBar/hide.png"] size:CPSizeMake(16, 16)];

    [buttonBarLeft setValue:bezelColor forThemeAttribute:"bezel-color"];
    [buttonBarLeft setValue:buttonBezel forThemeAttribute:"button-bezel-color"];
    [buttonBarLeft setValue:buttonBezelHighlighted forThemeAttribute:"button-bezel-color" inState:CPThemeStateHighlighted];

    [plusButton setTarget:self];
    [plusButton setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"IconsButtonBar/plus.png"] size:CPSizeMake(16, 16)]];
    [plusMenu addItemWithTitle:@"Add a contact" action:@selector(addContact:) keyEquivalent:@""];
    [plusMenu addItemWithTitle:@"Add a group" action:@selector(addGroup:) keyEquivalent:@""];
    [plusButton setMenu:plusMenu];
    [plusButton setToolTip:@"Add a new contact or group. Contacts can be a hypervisor, a virtual machine or a user."];

    [minusButton setTarget:self];
    [minusButton setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"IconsButtonBar/minus.png"] size:CPSizeMake(16, 16)]];
    [minusButton setAction:@selector(toogleRemoveEntity:)];
    [minusButton setToolTip:@"Remove the selected contact. It will only remove it from your roster."];

    [_hideButton setTarget:self];
    [_hideButton setImage:([defaults boolForKey:@"TNArchipelPropertyControllerEnabled"]) ? _hideButtonImageDisable : _hideButtonImageEnable];
    [_hideButton setAction:@selector(toggleShowPropertiesView:)];
    [_hideButton setToolTip:@"Display or hide the properties view"];

    var buttons = [CPArray array];

    if ([bundle objectForInfoDictionaryKey:@"TNArchipelDisplayXMPPManageContactsButton"] == 1)
    {
        [buttons addObject:plusButton]
        [buttons addObject:minusButton]
    }

    [buttons addObject:_hideButton];
    [buttonBarLeft setButtons:buttons];

    /* copyright */
    [self copyright];

    /* connection label */
    [labelCurrentUser setFont:[CPFont systemFontOfSize:9.0]];
    [labelCurrentUser setStringValue:@""];
    [labelCurrentUser setTextColor:[CPColor colorWithHexString:@"6C707F"]];
    [labelCurrentUser setAlignment:CPRightTextAlignment];
    [labelCurrentUser setTextShadowOffset:CGSizeMake(0.0, 1.0)];
    [labelCurrentUser setValue:[CPColor colorWithHexString:@"C6CAD9"] forThemeAttribute:@"text-shadow-color"];
    [labelCurrentUser setToolTip:@"The current logged account"];

    /* about window */
    [webViewAboutCredits setScrollMode:CPWebViewScrollNative];
    [webViewAboutCredits setMainFrameURL:[bundle pathForResource:@"credits.html"]];
    [webViewAboutCredits setBorderedWithHexColor:@"#C0C7D2"];
    [textFieldAboutVersion setStringValue:[defaults objectForKey:@"TNArchipelVersionHuman"]];

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

    CPLog.trace(@"registering for notification TNStropheContactMessageReceivedNotification");
    [center addObserver:self selector:@selector(didReceiveUserMessage:) name:TNStropheContactMessageReceivedNotification object:nil];

    CPLog.trace(@"registering for notification TNStropheContactMessageReceivedNotification");
    [center addObserver:self selector:@selector(didRetrieveRoster:) name:TNStropheRosterRetrievedNotification object:nil];

    CPLog.trace(@"registering for notification TNStropheContactMessageReceivedNotification");
    [center addObserver:self selector:@selector(didRetreiveUserVCard:) name:TNConnectionControllerCurrentUserVCardRetreived object:nil];

    CPLog.trace(@"registering for notification TNConnectionControllerConnectionStarted");
    [center addObserver:self selector:@selector(didConnectionStart:) name:TNConnectionControllerConnectionStarted object:connectionController];

    CPLog.trace(@"registering for notification TNPreferencesControllerRestoredNotification");
    [center addObserver:self selector:@selector(didRetrieveConfiguration:) name:TNPreferencesControllerRestoredNotification object:preferencesController];

    /* Placing the connection window */
    _moduleLoadingStarted = NO;
    [[connectionController mainWindow] center];
    [[connectionController mainWindow] makeKeyAndOrderFront:nil];
    [connectionController initCredentials];

    /* roster view mask */
    var maskBackgroundImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"Backgrounds/background-stripes.png"]];
    _viewRosterMask = [[CPView alloc] initWithFrame:[leftView bounds]];
    [_viewRosterMask setBackgroundColor:[CPColor colorWithPatternImage:maskBackgroundImage]];
    [_viewRosterMask setAlphaValue:0.5];
    [_viewRosterMask setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [leftView addSubview:_viewRosterMask];

    [ledOut setToolTip:@"This LED is ON when XMPP data are sent"];
    [ledIn setToolTip:@"This LED is ON when XMPP data are received"];


    /* Version checking */
    var major = [[bundle objectForInfoDictionaryKey:@"TNArchipelVersion"] objectForKey:@"major"],
        minor = [[bundle objectForInfoDictionaryKey:@"TNArchipelVersion"] objectForKey:@"minor"],
        revision = [[bundle objectForInfoDictionaryKey:@"TNArchipelVersion"] objectForKey:@"revision"],
        currentVersion = [TNVersion versionWithMajor:major minor:minor revision:revision];

    CPLog.info(@"current version is " + currentVersion);
    [updateController setCurrentVersion:currentVersion]
    [updateController setURL:[CPURL URLWithString:[bundle objectForInfoDictionaryKey:@"TNArchipelUpdateServerURL"]]];

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
    if ([[CPBundle mainBundle] objectForInfoDictionaryKey:@"TNArchipelDisplayXMPPManageContactsButton"] == 1)
    {
        [groupsMenu addItemWithTitle:@"Add group" action:@selector(addGroup:) keyEquivalent:@"G"];
        [groupsMenu addItemWithTitle:@"Delete group" action:@selector(deleteGroup:) keyEquivalent:@"D"];
        [groupsMenu addItem:[CPMenuItem separatorItem]];
    }

    [groupsMenu addItemWithTitle:@"Rename group" action:@selector(renameGroup:) keyEquivalent:@""];
    [_mainMenu setSubmenu:groupsMenu forItem:groupsItem];

    // Contacts
    if ([[CPBundle mainBundle] objectForInfoDictionaryKey:@"TNArchipelDisplayXMPPManageContactsButton"] == 1)
    {
        [contactsMenu addItemWithTitle:@"Add contact" action:@selector(addContact:) keyEquivalent:@""];
        [contactsMenu addItemWithTitle:@"Delete contact" action:@selector(deleteContact:) keyEquivalent:@""];
        [contactsMenu addItem:[CPMenuItem separatorItem]];
    }

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
    [helpMenu addItemWithTitle:@"Archipel Help" action:@selector(openWiki:) keyEquivalent:@""];
    [helpMenu addItemWithTitle:@"Release note" action:@selector(openReleaseNotes:) keyEquivalent:@""];
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
    var bundle = [CPBundle bundleForClass:self];

    // ok the next following line is a terrible awfull hack.
    [_mainToolbar addItemWithIdentifier:@"CUSTOMSPACE" label:@"              "/* incredible huh ?*/ view:nil target:nil action:nil];
    [_mainToolbar addItemWithIdentifier:TNToolBarItemLogout label:@"Log out" icon:[bundle pathForResource:@"IconsToolbar/logout.png"] target:self action:@selector(toolbarItemLogoutClick:) toolTip:@"Log out from the application"];
    [_mainToolbar addItemWithIdentifier:TNToolBarItemHelp label:@"Help" icon:[bundle pathForResource:@"IconsToolbar/help.png"] target:self action:@selector(toolbarItemHelpClick:) toolTip:@"Detach the welcome view in an external window"];
    [_mainToolbar addItemWithIdentifier:TNToolBarItemTags label:@"Tags" icon:[bundle pathForResource:@"IconsToolbar/tags.png"] target:self action:@selector(toolbarItemTagsClick:) toolTip:@"Show or hide the tags field"];

    var statusSelector  = [[CPPopUpButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 120.0, 24.0)],
        availableItem   = [[CPMenuItem alloc] init],
        awayItem        = [[CPMenuItem alloc] init],
        busyItem        = [[CPMenuItem alloc] init],
        DNDItem         = [[CPMenuItem alloc] init],
        statusItem      = [_mainToolbar addItemWithIdentifier:TNToolBarItemStatus label:@"Status" view:statusSelector target:self action:@selector(toolbarItemPresenceStatusClick:)];


    [statusSelector setToolTip:@"Update your current XMPP status"];
    [availableItem setTitle:TNArchipelStatusAvailableLabel];
    [availableItem setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"IconsStatus/available.png"]]];
    [statusSelector addItem:availableItem];

    [awayItem setTitle:TNArchipelStatusAwayLabel];
    [awayItem setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"IconsStatus/away.png"]]];
    [statusSelector addItem:awayItem];

    [busyItem setTitle:TNArchipelStatusBusyLabel];
    [busyItem setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"IconsStatus/busy.png"]]];
    [statusSelector addItem:busyItem];

    [DNDItem setTitle:TNArchipelStatusDNDLabel];
    [DNDItem setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"IconsStatus/dnd.png"]]];
    [statusSelector addItem:DNDItem];

    [statusItem setMinSize:CGSizeMake(120.0, 24.0)];
    [statusItem setMaxSize:CGSizeMake(120.0, 24.0)];

    [_mainToolbar setPosition:0 forToolbarItemIdentifier:@"CUSTOMSPACE"];
    [_mainToolbar setPosition:1 forToolbarItemIdentifier:TNToolBarItemStatus];
    [_mainToolbar setPosition:2 forToolbarItemIdentifier:CPToolbarSeparatorItemIdentifier];
    [_mainToolbar setPosition:499 forToolbarItemIdentifier:CPToolbarFlexibleSpaceItemIdentifier];
    [_mainToolbar setPosition:901 forToolbarItemIdentifier:CPToolbarSeparatorItemIdentifier];
    [_mainToolbar setPosition:902 forToolbarItemIdentifier:TNToolBarItemTags];
    [_mainToolbar setPosition:903 forToolbarItemIdentifier:TNToolBarItemHelp];
    [_mainToolbar setPosition:904 forToolbarItemIdentifier:TNToolBarItemLogout];

    [_mainToolbar reloadToolbarItems];
}

/*! initialize the avatar button
*/
- (void)makeAvatarChooser
{
    var bundle              = [CPBundle mainBundle],
        userAvatar          = [[CPMenuItem alloc] init],
        userAvatarMenu      = [[CPMenu alloc] init];

    _userAvatarButton = [[CPButton alloc] initWithFrame:CPRectMake(7.0, 4.0, TNUserAvatarSize.width, TNUserAvatarSize.height)],

    [_userAvatarButton setToolTip:@"Change your current avatar. This picture will be visible by all your contacts"];
    [_userAvatarButton setBordered:NO];
    [_userAvatarButton setBorderedWithHexColor:@"#a8a8a8"];
    [_userAvatarButton setBackgroundColor:[CPColor blackColor]];
    [_userAvatarButton setTarget:self];
    [_userAvatarButton setAction:@selector(toolbarItemAvatarClick:)];
    [_userAvatarButton setMenu:userAvatarMenu];
    [_userAvatarButton setValue:CPScaleProportionally forThemeAttribute:@"image-scaling"];
    [_userAvatarButton setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"user-unknown.png"] size:TNUserAvatarSize]];

    [[_mainToolbar customSubViews] addObject:_userAvatarButton];
    [_mainToolbar reloadToolbarItems];
}


#pragma mark -
#pragma mark Notifications handlers

/*! called when connectionController starts connection
    it will eventually start to loads the modules
    @param aNotification the notification
*/
- (void)didConnectionStart:(CPNotification)aNotification
{
    if (![moduleController isModuleLoadingStarted])
        [moduleController load];
}

/*! Notification responder of TNStropheConnection
    will be performed on login
    @param aNotification the received notification. This notification will contains as object the TNStropheConnection
*/
- (void)loginStrophe:(CPNotification)aNotification
{
    [preferencesController initXMPPStorage];
    [preferencesController recoverFromXMPPServer];
}

/*! called when TNPreferencesControllerRestoredNotification is received
    @param aNotification the notification
*/
- (void)didRetrieveConfiguration:(CPNotification)aNotification
{
    [CPMenu setMenuBarVisible:YES];
    [[connectionController mainWindow] orderOut:nil];
    [theWindow makeKeyAndOrderFront:nil];

    [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Configuration retrieved" message:@"Your client configuration has been retrieved from the XMPP server"];
    document.getElementById("copyright_label").style.textShadow = "0px 1px 0px #C6CAD9";

    _pubSubController = [TNPubSubController pubSubControllerWithConnection:[[TNStropheIMClient defaultClient] connection]];

    [[[TNStropheIMClient defaultClient] roster] setDelegate:contactsController];
    [[[TNStropheIMClient defaultClient] roster] setFilterField:filterField];

    [[[TNStropheIMClient defaultClient] connection] rawInputRegisterSelector:@selector(stropheConnectionRawIn:) ofObject:self];
    [[[TNStropheIMClient defaultClient] connection] rawOutputRegisterSelector:@selector(stropheConnectionRawOut:) ofObject:self];

    [tagsController setPubSubController:_pubSubController];
    [propertiesController setPubSubController:_pubSubController];
    [contactsController setPubSubController:_pubSubController];

    [_rosterOutlineView setDataSource:[[TNStropheIMClient defaultClient] roster]];
    [_rosterOutlineView recoverExpandedWithBaseKey:TNArchipelRememberOpenedGroup itemKeyPath:@"name"];

    [[TNPermissionsCenter defaultCenter] startWatching];


    if (_tagsVisible)
        [splitViewTagsContents setPosition:TNArchipelTagViewHeight ofDividerAtIndex:0];
    else
        [splitViewTagsContents setPosition:0.0 ofDividerAtIndex:0];

    [labelCurrentUser setStringValue:@"Connected as " + [[[TNStropheIMClient defaultClient] JID] bare]];

    [self showHelpView];
}

/*! Notification responder of TNStropheConnection
    will be performed on logout
    @param aNotification the received notification. This notification will contains as object the TNStropheConnection
*/
- (void)logoutStrophe:(CPNotification)aNotification
{
    [theWindow orderOut:nil];
    [[connectionController mainWindow] makeKeyAndOrderFront:nil];
    [labelCurrentUser setStringValue:@""];
    [CPMenu setMenuBarVisible:NO];
}

/*! Notification responder for TNStropheRosterRetrievedNotification
*/
- (void)didRetrieveRoster:(CPNotification)aNotification
{
    var servers = [CPArray array],
        roster  = [aNotification object];

    for (var i = 0; i < [[roster content] count]; i++)
    {
        if ([[[roster content] objectAtIndex:i] isKindOfClass:TNStropheContact])
        {
            var contact = [[roster content] objectAtIndex:i];
            if (![_pubSubController containsServerJID:[TNStropheJID stropheJIDWithString:"pubsub." + [[contact JID] domain]]])
                [[_pubSubController servers] addObject:[TNStropheJID stropheJIDWithString:"pubsub." + [[contact JID] domain]]];
        }
    }

    [_pubSubController retrieveSubscriptions];
}

/*! Notification responder for CPApplicationWillTerminateNotification
*/
- (void)onApplicationTerminate:(CPNotification)aNotification
{
    [[TNStropheIMClient defaultClient] disconnect];
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

    // if ([_rosterOutlineView selectedRow] != [_rosterOutlineView rowForItem:currentContact])
    //     [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:user
    //                                                      message:message
    //                                                   customIcon:customIcon
    //                                                       target:self
    //                                                       action:@selector(growlNotification:clickedWithUser:)
    //                                             actionParameters:currentContact];

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
        version     = [defaults objectForKey:@"TNArchipelVersionHuman"];

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

    copy.id = "copyright_label";
    copy.style.position = "absolute";
    copy.style.fontSize = "9px";
    copy.style.color = "#6C707F";
    copy.style.width = "700px";
    copy.style.bottom = "8px";
    copy.style.left = "50%";
    copy.style.textAlign = "center";
    copy.style.marginLeft = "-350px";
    // copy.style.textShadow = "0px 1px 0px #C6CAD9";
    copy.innerHTML =  [defaults objectForKey:@"TNArchipelVersionHuman"] + @" - " + [defaults objectForKey:@"TNArchipelCopyright"];
    document.body.appendChild(copy);

}


#pragma mark -
#pragma mark Actions

/*! will remove the selected roster item according to its type
    @param the sender of the action
*/
- (IBAction)toogleRemoveEntity:(id)sender
{
    var index   = [[_rosterOutlineView selectedRowIndexes] firstIndex],
        item    = [_rosterOutlineView itemAtRow:index];

    if ([item isKindOfClass:TNStropheContact])
        [self deleteContact:sender];
    else if ([item isKindOfClass:TNStropheGroup])
        [self deleteGroup:sender];
}

/*! will hide or show the properties views
    @param the sender of the action
*/
- (IBAction)toggleShowPropertiesView:(id)aSender
{
    var defaults = [CPUserDefaults standardUserDefaults];

    if ([propertiesController isEnabled])
    {
        [propertiesController setEnabled:NO];
        [_hideButton setImage:_hideButtonImageEnable];
        [defaults setBool:NO forKey:@"TNArchipelPropertyControllerEnabled"];
    }
    else
    {
        [propertiesController setEnabled:YES];
        [_hideButton setImage:_hideButtonImageDisable];
        [defaults setBool:YES forKey:@"TNArchipelPropertyControllerEnabled"];
    }

    [propertiesController reload];
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
    [[TNStropheIMClient defaultClient] disconnect];
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

/*! Opens the archipel wiki in a new window
    @param the sender of the action
*/
- (IBAction)openWiki:(id)sender
{
    window.open("http://github.org/primalmotion/archipel/wiki");
}

/*! Opens the archipel commit line
    @param the sender of the action
*/
- (IBAction)openReleaseNotes:(id)sender
{
    window.open("http://github.com/primalmotion/Archipel/commits/master");
}

/*! Opens the donation website in a new window
    @param the sender of the action
*/
- (IBAction)openDonationPage:(id)sender
{
    window.open("http://archipelproject.org/donate");
}

/*! Opens the archipel issues website in a new window
    @param the sender of the action
*/
- (IBAction)openBugTracker:(id)sender
{
    window.open("http://github.org/primalmotion/archipel/issues/");
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

/*! Action of toolbar imutables toolbar items.
    Trigger on delete help item click.
    This will show a window conataining the helpView
    To have more information about the toolbar, see TNToolbar
*/
- (IBAction)toolbarItemHelpClick:(id)sender
{
    if (_helpWindow)
    {
        if ([CPPlatform isBrowser])
            [_platformHelpWindow orderOut:nil];

        [_helpWindow close];
        _helpWindow = nil;
    }

    if ([CPPlatform isBrowser])
        _platformHelpWindow = [[CPPlatformWindow alloc] initWithContentRect:CGRectMake(0,0,950,600)];

    if ([CPPlatform isBrowser])
        _helpWindow     = [[CPWindow alloc] initWithContentRect:CGRectMake(0,0,950,600) styleMask:CPTitledWindowMask | CPClosableWindowMask | CPMiniaturizableWindowMask | CPResizableWindowMask | CPBorderlessBridgeWindowMask];
    else
        _helpWindow     = [[CPWindow alloc] initWithContentRect:CGRectMake(0,0,950,600) styleMask:CPTitledWindowMask | CPClosableWindowMask | CPMiniaturizableWindowMask | CPResizableWindowMask];

    var scrollView  = [[CPScrollView alloc] initWithFrame:[[_helpWindow contentView] bounds]];

    if ([CPPlatform isBrowser])
    {
        [_helpWindow setPlatformWindow:_platformHelpWindow];
        [_platformHelpWindow orderFront:nil];
    }

    [_helpWindow setDelegate:self];

    var bundle          = [CPBundle mainBundle],
        defaults        = [CPUserDefaults standardUserDefaults],
        newHelpView     = [[CPWebView alloc] initWithFrame:[[_helpWindow contentView] bounds]],
        url             = [defaults objectForKey:@"TNArchipelHelpWindowURL"],
        version         = [defaults objectForKey:@"TNArchipelVersionHuman"];

    if (!url || (url == @"local"))
        url = @"help/index.html";

    [newHelpView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [newHelpView setMainFrameURL:[bundle pathForResource:url] + "?version=" + version];

    [scrollView setAutohidesScrollers:YES];
    [scrollView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [scrollView setDocumentView:newHelpView];

    [_helpWindow setContentView:scrollView];
    [_helpWindow center];
    [_helpWindow makeKeyAndOrderFront:nil];
}

/*! Action of toolbar imutables toolbar items.
    Trigger presence item change.
    This will change your own XMPP status
*/
- (IBAction)toolbarItemPresenceStatusClick:(id)sender
{
    var XMPPShow,
        statusLabel = [sender title],
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

    [[TNStropheIMClient defaultClient] setPresenceShow:XMPPShow status:nil];

    [growl pushNotificationWithTitle:@"Status" message:@"Your status is now " + statusLabel];
}

/*! Action of toolbar imutables toolbar items.
    Trigger on logout item click
    To have more information about the toolbar, see TNToolbar
    @param sender the sender of the action (the CPToolbarItem)
*/
- (IBAction)toolbarItemLogoutClick:(id)sender
{
    [self logout:sender];
}

/*! Action of toolbar imutables toolbar items.
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

/*! Action of toolbar imutables toolbar items.
    Trigger on avatar item click
    To have more information about the toolbar, see TNToolbar
    @param sender the sender of the action (the CPToolbarItem)
*/
- (IBAction)toolbarItemAvatarClick:(id)aSender
{
    var wp = CPPointMake(16, 12);

    wp = [aSender convertPoint:wp toView:nil];

    var fake = [CPEvent mouseEventWithType:CPRightMouseDown
                        location:wp
                        modifierFlags:0 timestamp:nil
                        windowNumber:[theWindow windowNumber]
                        context:nil
                        eventNumber:0
                        clickCount:1
                        pressure:1];

    [CPMenu popUpContextMenu:[aSender menu] withEvent:fake forView:aSender];
}


#pragma mark -
#pragma mark User vCard management

/*! trigger by TNConnectionControllerCurrentUserVCardRetreived that indicates the controller has received
    the user vCard
    @param aNotification the notification that triggers the selector
*/
- (void)didRetreiveUserVCard:(CPNotification)aNotification
{

    var vCard = [connectionController userVCard],
        photoNode;

    if (photoNode = [vCard firstChildWithName:@"PHOTO"])
    {
        var contentType     = [[photoNode firstChildWithName:@"TYPE"] text],
            data            = [[photoNode firstChildWithName:@"BINVAL"] text],
            currentAvatar   = [TNBase64Image base64ImageWithContentType:contentType data:data delegate:self];

        [currentAvatar setSize:TNUserAvatarSize];
        [_userAvatarButton setImage:currentAvatar];
        [userAvatarController setCurrentAvatar:currentAvatar];
    }

    [userAvatarController setButtonAvatar:_userAvatarButton];
    [userAvatarController setMenuAvatarSelection:[_userAvatarButton menu]];

    [userAvatarController loadAvatarMetaInfos];
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
    var dividerPosition = _tagsVisible ?  (aValue * TNArchipelTagViewHeight) : TNArchipelTagViewHeight - (aValue * TNArchipelTagViewHeight),
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
    it will check if all loaded module are ok to be hidden, otherwise
    it will disallow to change selection
*/
- (BOOL)outlineView:(CPOutlineView)anOutlineView shouldSelectItem:(id)anItem
{
    for (var i = 0; i < [[moduleController loadedTabModules] count]; i++)
        if (![[[moduleController loadedTabModules] objectAtIndex:i] shouldHideAndSelectItem:anItem ofObject:anOutlineView])
            return NO;

    return YES;
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
    {
        [_moduleLoadingDelay invalidate];
        _moduleLoadingDelay = null;
    }

    [propertiesController setEntity:item];
    [propertiesController reload];

    if (loadDelay == 0)
        [self performModuleChange:[CPDictionary dictionaryWithObjectsAndKeys:item, @"userInfo"]]; // fake the timer
    else
       _moduleLoadingDelay = [CPTimer scheduledTimerWithTimeInterval:loadDelay target:self selector:@selector(performModuleChange:) userInfo:item repeats:NO];
}

/*! This method is called by delegate outlineViewSelectionDidChange: after a small delay by a timer
    in order to really process the modules swappoing. this avoid overloading if up key is maintained for example.
*/
- (void)performModuleChange:(CPTimer)aTimer
{
    if ([_rosterOutlineView numberOfSelectedRows] == 0)
    {
        [moduleController setEntity:nil ofType:nil];
        [moduleController setCurrentEntityForToolbarModules:nil];
        [self showHelpView];
        [propertiesController hideView];
    }
    else
    {
        var item        = [aTimer valueForKey:@"userInfo"],
            defaults    = [CPUserDefaults standardUserDefaults];

        [self hideHelpView];

        switch ([item class])
        {
            case TNStropheGroup:
                [moduleController setEntity:item ofType:@"group"];
                [moduleController setCurrentEntityForToolbarModules:nil];
                break;

            case TNStropheContact:
                var vCard       = [item vCard],
                    entityType  = [[[TNStropheIMClient defaultClient] roster] analyseVCard:vCard];
                [moduleController setEntity:item ofType:entityType];
                [moduleController setCurrentEntityForToolbarModules:item];
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

/*! called when module controller has loaded a module
*/
- (void)moduleLoader:(TNModuleController)aLoader loadedBundle:(CPBundle)aBundle progress:(float)percent
{
    [progressIndicatorModulesLoading setDoubleValue:percent];
    [labelModulesLoadingName setStringValue:@"Loaded " + [aBundle objectForInfoDictionaryKey:@"PluginDisplayName"]];
}

/*! delegate of TNModuleController sent when all modules are loaded
*/
- (void)moduleLoaderLoadingComplete:(TNModuleController)aLoader
{
    CPLog.info(@"All modules have been loaded");
    CPLog.trace(@"Positionning the connection window");

    [progressIndicatorModulesLoading setHidden:YES];
    [labelModulesLoadingName setHidden:YES];
    [_mainToolbar reloadToolbarItems];
    [_viewRosterMask removeFromSuperview];

    [updateController check];
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
