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

@import <AppKit/CPButton.j>
@import <AppKit/CPImage.j>
@import <AppKit/CPImageView.j>
@import <AppKit/CPMenu.j>
@import <AppKit/CPMenuItem.j>
@import <AppKit/CPPlatformWindow.j>
@import <AppKit/CPProgressIndicator.j>
@import <AppKit/CPScrollView.j>
@import <AppKit/CPScrollView.j>
@import <AppKit/CPSplitView.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPView.j>
@import <AppKit/CPWindow.j>
@import <AppKit/CPWebView.j>
@import <AppKit/_CPToolTip.j>

@import <GrowlCappuccino/GrowlCappuccino.j>
@import <LPKit/LPMultiLineTextField.j>
@import <LPKit/LPCrashReporter.j>
@import <TNKit/TNToolbar.j>
@import <TNKit/TNFlipView.j>
@import <TNKit/TNTabView.j>

@import "Categories/TNCategories.j"
@import "Controllers/TNAvatarController.j"
@import "Controllers/TNConnectionController.j"
@import "Controllers/TNContactsController.j"
@import "Controllers/TNGroupsController.j"
@import "Controllers/TNHintController.j"
@import "Controllers/TNModuleController.j"
@import "Controllers/TNNotificationHistoryController.j"
@import "Controllers/TNPermissionsCenter.j"
@import "Controllers/TNPreferencesController.j"
@import "Controllers/TNPropertiesController.j"
@import "Controllers/TNPushCenter.j"
@import "Controllers/TNTagsController.j"
@import "Controllers/TNUpdateController.j"
@import "Controllers/TNUserAvatarController.j"
@import "Controllers/TNXMPPAccountController.j"
@import "Model/TNVersion.j"
@import "Views/TNButtonBarPopUpButton.j"
@import "Views/TNOutlineViewRoster.j"
@import "Views/TNRosterDataViews.j"
@import "Views/TNSearchField.j"

@global CPLocalizedString
@global CPApplicationWillTerminateNotification
@global CPApp

CPFontDefaultSystemFontFace = @"Courier";

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
    @group TNArchipelEntityType
    This is the dictionary that holds the registered
    XMPP entity types and their description.
*/
TNArchipelEntityTypes               = nil;

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

TNArchipelEntityTypeGeneral                             = @"general";

// this doesn't work with xcodecapp for some mysterious reasons
TNUserAvatarSize            = nil;

var TNArchipelStatusAvailableLabel  = @"Available",
    TNArchipelStatusAwayLabel       = @"Away",
    TNArchipelStatusBusyLabel       = @"Busy",
    TNArchipelStatusDNDLabel        = @"Do not disturb",
    TNToolBarItemLogout             = @"TNToolBarItemLogout",
    TNToolBarItemTags               = @"TNToolBarItemTags",
    TNToolBarItemHelp               = @"TNToolBarItemHelp",
    TNToolBarItemStatus             = @"TNToolBarItemStatus",
    TNArchipelTagViewHeight         = 33.0;

__COPYRIGHT__ = "Copyright 2010-2013 Antoine Mercadal";

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
    @outlet CPButtonBar                         buttonBarLeft;
    @outlet CPImageView                         imageViewLogoAbout;
    @outlet CPImageView                         ledIn;
    @outlet CPImageView                         ledOut;
    @outlet CPProgressIndicator                 progressIndicatorModulesLoading;
    @outlet CPSplitView                         splitViewHorizontalRoster;
    @outlet CPSplitView                         splitViewMain;
    @outlet CPSplitView                         splitViewTagsContents;
    @outlet CPTextField                         fieldVersion;
    @outlet CPTextField                         labelCurrentUser;
    @outlet CPTextField                         textFieldAboutVersion;
    @outlet CPView                              filterView;
    @outlet CPView                              statusBar;
    @outlet CPView                              viewAboutWindowLogoContainer;
    @outlet CPView                              viewLoading;
    @outlet CPWebView                           webViewAboutCredits;
    @outlet CPWindow                            theWindow;
    @outlet CPWindow                            windowAboutArchipel;
    @outlet TNAvatarController                  avatarController;
    @outlet TNConnectionController              connectionController;
    @outlet TNContactsController                contactsController;
    @outlet CPView                              leftView;
    @outlet CPView                              rightView;
    @outlet TNGroupsController                  groupsController;
    @outlet TNHintController                    hintController;
    @outlet TNModuleController                  moduleController;
    @outlet TNNotificationHistoryController     notificationHistoryController;
    @outlet TNPreferencesController             preferencesController;
    @outlet TNPropertiesController              propertiesController;
    @outlet TNSearchField                       filterField;
    @outlet TNTagsController                    tagsController;
    @outlet TNUpdateController                  updateController;
    @outlet TNUserAvatarController              userAvatarController;
    @outlet TNXMPPAccountController             XMPPAccountController;
    @outlet TNRosterDataViewContact             rosterDataViewForContacts;
    @outlet TNRosterDataViewGroup               rosterDataViewForGroups;

    BOOL                                        _tagsVisible;
    CPButton                                    _hideButton;
    CPButton                                    _plusButton;
    CPButton                                    _userAvatarButton;
    CPImage                                     _hideButtonImageDisable;
    CPImage                                     _hideButtonImageEnable;
    CPImage                                     _imageLedInData;
    CPImage                                     _imageLedNoData;
    CPImage                                     _imageLedOutData;
    CPMenu                                      _mainMenu;
    CPMenu                                      _rosterMenuForContacts;
    CPMenu                                      _rosterMenuForGroups;
    CPPlatformWindow                            _platformHelpWindow;
    CPScrollView                                _outlineScrollView;
    CPTextField                                 _rightViewTextField;
    CPTimer                                     _ledInTimer;
    CPTimer                                     _ledOutTimer;
    CPTimer                                     _moduleLoadingDelay;
    CPWindow                                    _helpWindow;
    TNOutlineViewRoster                         _rosterOutlineView;
    TNPubSubController                          _pubSubController;
    TNStropheGroup                              _stropheGroupSelection;
    TNTabView                                   _moduleTabView;
    TNToolbar                                   _mainToolbar;
    TNVersion                                   _currentVersion;
    TNViewHypervisorControl                     _currentRightViewContent;
}


#pragma mark -
#pragma mark Initialization

/*! This method initialize the content of the GUI when the CIB file
    as finished to load.
*/
- (void)awakeFromCib
{
    if (typeof(LPCrashReporter) != "undefined")
        [LPCrashReporter sharedErrorLogger];

    // initialize the singleton.
    [TNPushCenter defaultCenter];

    [theWindow setFullPlatformWindow:YES];

    TNUserAvatarSize = CGSizeMake(50.0, 50.0);

    var bundle      = [CPBundle mainBundle],
        defaults    = [CPUserDefaults standardUserDefaults],
        center      = [CPNotificationCenter defaultCenter];

    /* register logs */
    CPLogRegister(CPLogConsole, [defaults objectForKey:@"TNArchipelConsoleDebugLevel"]);

    /* notifications */
    CPLog.trace(@"registering for notification TNStropheConnectionSuccessNotification");
    [center addObserver:self selector:@selector(loginStrophe:) name:TNStropheConnectionStatusConnectedNotification object:nil];
    CPLog.trace(@"registering for notification TNStropheDisconnectionNotification");
    [center addObserver:self selector:@selector(XMPPDisconnecting:) name:TNStropheConnectionStatusDisconnectingNotification object:nil];
    CPLog.trace(@"registering for notification TNStropheConnectionStatusDisconnectedNotification");
    [center addObserver:self selector:@selector(XMPPDisconnected:) name:TNStropheConnectionStatusDisconnectedNotification object:nil];
    CPLog.trace(@"registering for notification CPApplicationWillTerminateNotification");
    [center addObserver:self selector:@selector(onApplicationTerminate:) name:CPApplicationWillTerminateNotification object:nil];
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


    var commonImageModuleBackground = [CPColor colorWithHexString:@"F6F6F6"];

    /* register defaults defaults */
    [defaults registerDefaults:@{
        @"TNArchipelVersion"                  :[bundle objectForInfoDictionaryKey:@"TNArchipelVersion"],
        @"TNArchipelModuleLoadingDelay"       :[bundle objectForInfoDictionaryKey:@"TNArchipelModuleLoadingDelay"],
        @"TNArchipelConsoleDebugLevel"        :[bundle objectForInfoDictionaryKey:@"TNArchipelConsoleDebugLevel"],
        @"TNArchipelXMPPResource"             :[bundle objectForInfoDictionaryKey:@"TNArchipelXMPPResource"],
        @"TNArchipelUseAnimations"            :[bundle objectForInfoDictionaryKey:@"TNArchipelUseAnimations"],
        @"TNArchipelAutoCheckUpdate"          :[bundle objectForInfoDictionaryKey:@"TNArchipelAutoCheckUpdate"],
        @"TNArchipelMonitorStanza"            :[bundle objectForInfoDictionaryKey:@"TNArchipelMonitorStanza"],
        @"TNHideOfflineContacts"              :[bundle objectForInfoDictionaryKey:@"TNHideOfflineContacts"],
        @"CPBundleLocale"                     :[bundle objectForInfoDictionaryKey:@"CPBundleLocale"],
        @"TNArchipelPropertyControllerEnabled":[bundle objectForInfoDictionaryKey:@"TNArchipelPropertyControllerEnabled"],
        @"TNArchipelScrollersStyle"           :[bundle objectForInfoDictionaryKey:@"TNArchipelScrollersStyle"],
        @"TNOutlineViewsExpandedGroups"       :[CPDictionary dictionary]
    }];

    /* images */
    [imageViewLogoAbout setImage:CPImageInBundle(@"Backgrounds/background-icon.png", nil, bundle)];
    [viewAboutWindowLogoContainer setBackgroundColor:[CPColor blackColor]];

    /* main split views */
    var posx = 230;
    [splitViewMain setPosition:posx ofDividerAtIndex:0];
    var bounds = [leftView bounds];
    bounds.size.width = posx;
    [leftView setFrame:bounds];

    [splitViewMain setIsPaneSplitter:NO];
    [splitViewMain setDelegate:self];

    /* tags split views */
    _tagsVisible = [defaults boolForKey:@"TNArchipelTagsVisible"];

    [splitViewTagsContents setValue:0.0 forThemeAttribute:@"divider-thickness"]
    [splitViewTagsContents setDelegate:self];
    [[tagsController mainView] setFrame:[[[splitViewTagsContents subviews] objectAtIndex:0] frame]];
    [[[splitViewTagsContents subviews] objectAtIndex:0] addSubview:[tagsController mainView]];

    /* properties controller */
    CPLog.trace(@"initializing the splitViewHorizontalRoster");
    [splitViewHorizontalRoster setPosition:[splitViewHorizontalRoster bounds].size.height ofDividerAtIndex:0];
    [splitViewHorizontalRoster setDelegate:self];
    [propertiesController setAvatarManager:avatarController];
    [propertiesController setEnabled:[defaults boolForKey:@"TNArchipelPropertyControllerEnabled"]];

    /* preferences controller */
    [preferencesController setAppController:self];

    /* outlineview */
    CPLog.trace(@"initializing _rosterOutlineView");
    _rosterOutlineView = [[TNOutlineViewRoster alloc] initWithFrame:[leftView bounds]];
    [_rosterOutlineView setDelegate:self];
    [_rosterOutlineView setEnabled:NO];
    [_rosterOutlineView registerForDraggedTypes:[TNDragTypeContact]];
    [_rosterOutlineView setSearchField:filterField];
    _rosterOutlineView._DOMElement.style.backgroundImage = "-webkit-linear-gradient(top, #E0E4EA, #D1D8E0)";
    _rosterOutlineView._DOMElement.style.backgroundImage = "-moz-linear-gradient(-90deg, #E0E4EA, #D1D8E0)";


    /* init scroll view of the outline view */
    CPLog.trace(@"initializing _outlineScrollView");
    _outlineScrollView = [[CPScrollView alloc] initWithFrame:[leftView bounds]];
    //[_rosterOutlineView setBackgroundColor:[CPColor colorWithHexString:@"E0E4EA"]];
    [_outlineScrollView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [_outlineScrollView setAutohidesScrollers:YES];
    [_outlineScrollView setDocumentView:_rosterOutlineView];
    [_outlineScrollView setDelegate:_rosterOutlineView];


    /* left view */
    [leftView addSubview:_outlineScrollView];
    [leftView setBackgroundColor:CPColorWithImages(@"Backgrounds/dark-bg.png", nil, nil, bundle)];

    /* right view */
    CPLog.trace(@"initializing rightView");
    [rightView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [rightView setBackgroundColor:commonImageModuleBackground];

    /* tab module view */
    CPLog.trace(@"initializing the _moduleTabView");
    _moduleTabView = [[TNTabView alloc] initWithFrame:CGRectMakeZero()];
    [_moduleTabView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [_moduleTabView setContentBackgroundColor:commonImageModuleBackground];


    /* loading view */
    [viewLoading setFrame:[rightView bounds]];
    [viewLoading setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    viewLoading._DOMElement.style.background = "url(Resources/Backgrounds/dark-bg.png)";
    viewLoading._DOMElement.style.background = "-webkit-gradient(radial, 50% 50%, 0, 50% 50%, 650, from(transparent), to(rgba(0, 0, 0, 1))), url(Resources/Backgrounds/dark-bg.png)";
    [rightView addSubview:viewLoading];

    [progressIndicatorModulesLoading setMinValue:0.0];
    [progressIndicatorModulesLoading setMaxValue:1.0];
    [progressIndicatorModulesLoading setDoubleValue:0.0];

    /* message in _moduleTabView */
    var bounds  = [_moduleTabView bounds];

    _rightViewTextField = [CPTextField labelWithTitle:@""];
    [_rightViewTextField setFrame:CGRectMake(bounds.size.width / 2 - 300, 153, 600, 200)];
    [_rightViewTextField setAutoresizingMask: CPViewMaxXMargin | CPViewMinXMargin];
    [_rightViewTextField setAlignment:CPCenterTextAlignment]
    [_rightViewTextField setFont:[CPFont boldSystemFontOfSize:26]];
    [_rightViewTextField setTextColor:[CPColor grayColor]];
    [_rightViewTextField setHidden:YES];
    [_moduleTabView addSubview:_rightViewTextField];

    /* filter view. */
    CPLog.trace(@"initializing the filterView");

    [filterView setBackgroundColor:CPColorWithImages(@"Backgrounds/background-filter.png", nil, nil, bundle)];
    [filterField setOutlineView:_rosterOutlineView];
    [filterField setMaximumRecents:10];

    /* Growl */
    CPLog.trace(@"initializing Growl");
    [[TNGrowlCenter defaultCenter] setView:[theWindow contentView]];

    /* traffic LEDs */
    CPLog.trace(@"Initializing the traffic status LED");
    _imageLedInData = CPImageInBundle(@"IconsStatus/green.png", CGSizeMake(8.0, 8.0), bundle);
    _imageLedOutData = CPImageInBundle(@"IconsStatus/orange.png", CGSizeMake(8.0, 8.0), bundle);
    _imageLedNoData = CPImageInBundle(@"IconsStatus/gray.png", CGSizeMake(8.0, 8.0), bundle);

    /* Version checking */
    var major = [[bundle objectForInfoDictionaryKey:@"TNArchipelVersion"] objectForKey:@"major"],
        minor = [[bundle objectForInfoDictionaryKey:@"TNArchipelVersion"] objectForKey:@"minor"],
        revision = [[bundle objectForInfoDictionaryKey:@"TNArchipelVersion"] objectForKey:@"revision"],
        codeName = [[bundle objectForInfoDictionaryKey:@"TNArchipelVersion"] objectForKey:@"codeName"];

    _currentVersion = [TNVersion versionWithMajor:major minor:minor revision:revision codeName:codeName];

    if (typeof(LPCrashReporter) != "undefined")
        [[LPCrashReporter sharedErrorLogger] setVersion:[_currentVersion description]];
    CPLog.info(@"current version is " + _currentVersion);
    [updateController setCurrentVersion:_currentVersion]
    [updateController setURL:[CPURL URLWithString:[bundle objectForInfoDictionaryKey:@"TNArchipelUpdateServerURL"]]];

    /* about window */
    [webViewAboutCredits setScrollMode:CPWebViewScrollNative];
    [webViewAboutCredits setMainFrameURL:[bundle pathForResource:@"credits.html"]];
    [webViewAboutCredits setBorderedWithHexColor:@"#C0C7D2"];
    [textFieldAboutVersion setStringValue:_currentVersion];


    /* makers */
    [self makeToolbar];
    [self makeAvatarChooser];
    [self makeMainMenu];
    [self makeRosterMenu];
    [self makeButtonBar];


    /* module controller */
    CPLog.trace(@"initializing moduleController");
    [moduleController setDelegate:self];
    [moduleController setMainToolbar:_mainToolbar];
    [moduleController setMainTabView:_moduleTabView];
    [moduleController setInfoTextField:_rightViewTextField];
    [moduleController setModulesPath:@"Modules/"]
    [moduleController setMainModuleView:rightView];
    [moduleController setRosterGroupsMenu:_rosterMenuForGroups];
    [moduleController setRosterContactsMenu:_rosterMenuForContacts];
    [moduleController setToolbarModuleBackgroundColor:commonImageModuleBackground];
    [_moduleTabView setDelegate:moduleController];
    [_rosterOutlineView setModulesTabView:_moduleTabView];


    /* status bar */
    [statusBar setBackgroundColor:CPColorWithImages(@"Backgrounds/statusbar-bg.png", nil, nil, bundle)];
    [statusBar applyShadow:[CPColor colorWithHexString:@"f3f3f3"] offset:CGSizeMake(0.0, 1.0)];

    [labelCurrentUser setFont:[CPFont systemFontOfSize:9.0]];
    [labelCurrentUser setStringValue:@""];

    [fieldVersion setFont:[CPFont systemFontOfSize:9.0]];
    [fieldVersion setStringValue:@""];
    [fieldVersion setSelectable:YES];
    [fieldVersion setStringValue:[CPString stringWithFormat:@"Archipel UI Version %@ - %@", _currentVersion, __COPYRIGHT__]];

    /* Placing the connection window */
    [connectionController showWindow:nil];
    [connectionController initCredentials];


    /* Initialize the Entity Types global variable */
    TNArchipelEntityTypes = [CPDictionary dictionary];
    [TNArchipelEntityTypes setObject:CPLocalizedString(@"Virtual machine", @"Virtual machine")
                              forKey:TNArchipelEntityTypeVirtualMachine];
    [TNArchipelEntityTypes setObject:CPLocalizedString(@"Hypervisor", @"Hypervisor")
                              forKey:TNArchipelEntityTypeHypervisor];
}

/*! Creates the mainmenu. it called by awakeFromCib
*/
- (void)makeMainMenu
{
    CPLog.trace(@"Creating the main menu");

    _mainMenu = [[CPMenu alloc] init];

    var archipelItem    = [_mainMenu addItemWithTitle:CPLocalizedString(@"Archipel", @"Archipel") action:nil keyEquivalent:@""],
        editMenu        = [_mainMenu addItemWithTitle:CPLocalizedString(@"Edit", @"Edit")  action:nil keyEquivalent:@""],
        contactsItem    = [_mainMenu addItemWithTitle:CPLocalizedString(@"Contacts", @"Contact") action:nil keyEquivalent:@""],
        groupsItem      = [_mainMenu addItemWithTitle:CPLocalizedString(@"Groups", @"Groups") action:nil keyEquivalent:@""],
        navigationItem  = [_mainMenu addItemWithTitle:CPLocalizedString(@"Navigation", @"Navigation") action:nil keyEquivalent:@""],
        helpItem        = [_mainMenu addItemWithTitle:CPLocalizedString(@"Help", @"Help") action:nil keyEquivalent:@""],
        archipelMenu    = [[CPMenu alloc] init],
        editMenuItem    = [[CPMenu alloc] init],
        groupsMenu      = [[CPMenu alloc] init],
        contactsMenu    = [[CPMenu alloc] init],
        statusMenu      = [[CPMenu alloc] init],
        navigationMenu  = [[CPMenu alloc] init],
        helpMenu        = [[CPMenu alloc] init],
        defaults        = [CPUserDefaults standardUserDefaults];

    // Archipel
    [[archipelMenu addItemWithTitle:CPLocalizedString(@"About Archipel", @"About Archipel") action:@selector(showAboutWindow:) keyEquivalent:@"?"] setTarget:self];
    [archipelMenu addItem:[CPMenuItem separatorItem]];
    [[archipelMenu addItemWithTitle:CPLocalizedString(@"Preferences", @"Preferences") action:@selector(showPreferencesWindow:) keyEquivalent:@","] setTarget:self];
    [[archipelMenu addItemWithTitle:CPLocalizedString(@"XMPP Account", @"XMPP Account") action:@selector(showXMPPAccountWindow:) keyEquivalent:@";"] setTarget:self];
    [archipelMenu addItem:[CPMenuItem separatorItem]];
    [[archipelMenu addItemWithTitle:CPLocalizedString(@"Notifications", @"Notification") action:@selector(showNotificationWindow:) keyEquivalent:@">"] setTarget:self];
    [archipelMenu addItem:[CPMenuItem separatorItem]];
    [[archipelMenu addItemWithTitle:CPLocalizedString(@"Log out", @"Log out") action:@selector(logout:) keyEquivalent:@"Q"] setTarget:self];
    [[archipelMenu addItemWithTitle:CPLocalizedString(@"Quit", @"Quit") action:nil keyEquivalent:@""] setTarget:self];
    [_mainMenu setSubmenu:archipelMenu forItem:archipelItem];

    //Edit
    [editMenuItem addItemWithTitle:CPLocalizedString(@"Undo", @"Undo") action:@selector(undo:) keyEquivalent:@"z"];
    [editMenuItem addItemWithTitle:CPLocalizedString(@"Redo", @"Undo") action:@selector(redo:) keyEquivalent:@"Z"];
    [editMenuItem addItem:[CPMenuItem separatorItem]];
    [editMenuItem addItemWithTitle:CPLocalizedString(@"Copy", @"Copy") action:@selector(copy:) keyEquivalent:@"c"];
    [editMenuItem addItemWithTitle:CPLocalizedString(@"Cut", @"Cut") action:@selector(cut:) keyEquivalent:@"x"];
    [editMenuItem addItemWithTitle:CPLocalizedString(@"Paste", @"Paste") action:@selector(paste:) keyEquivalent:@"v"];
    [editMenuItem addItemWithTitle:CPLocalizedString(@"Select all", @"Select all") action:@selector(selectAll:) keyEquivalent:@"a"];
    [_mainMenu setSubmenu:editMenuItem forItem:editMenu];

    // Groups
    if ([[CPBundle mainBundle] objectForInfoDictionaryKey:@"TNArchipelDisplayXMPPManageContactsButton"] == 1)
    {
        [[groupsMenu addItemWithTitle:CPLocalizedString(@"Add group", @"Add group") action:@selector(addGroup:) keyEquivalent:@"G"] setTarget:self];
        [[groupsMenu addItemWithTitle:CPLocalizedString(@"Delete group", @"Delete group") action:@selector(deleteEntities:) keyEquivalent:@"D"] setTarget:self];
    }

    [_mainMenu setSubmenu:groupsMenu forItem:groupsItem];

    // Contacts
    if ([[CPBundle mainBundle] objectForInfoDictionaryKey:@"TNArchipelDisplayXMPPManageContactsButton"] == 1)
    {
        [[contactsMenu addItemWithTitle:CPLocalizedString(@"Add contact", @"Add contact") action:@selector(addContact:) keyEquivalent:@"C"] setTarget:self];
        [[contactsMenu addItemWithTitle:CPLocalizedString(@"Delete contact", @"Delete contacts") action:@selector(deleteEntities:) keyEquivalent:@"D"] setTarget:self];
        [contactsMenu addItem:[CPMenuItem separatorItem]]
        [[contactsMenu addItemWithTitle:CPLocalizedString(@"Ask subscribtion", @"Ask subscribtion") action:@selector(askSubscription:) keyEquivalent:@"'"] setTarget:self];
        [[contactsMenu addItemWithTitle:CPLocalizedString(@"Remove subscribtion", @"Remove subscribtion") action:@selector(removeSubscription:) keyEquivalent:@"\""] setTarget:self];
    }

    [_mainMenu setSubmenu:contactsMenu forItem:contactsItem];

    // navigation
    [[navigationMenu addItemWithTitle:CPLocalizedString(@"Hide main menu", @"Hide main menu") action:@selector(switchMainMenu:) keyEquivalent:@"U"] setTarget:self];
    [[navigationMenu addItemWithTitle:CPLocalizedString(@"Search entity", @"Search entity") action:@selector(focusFilter:) keyEquivalent:@"F"] setTarget:self];
    [navigationMenu addItem:[CPMenuItem separatorItem]];
    [[navigationMenu addItemWithTitle:CPLocalizedString(@"Select next entity", @"Select next entity") action:@selector(selectNextEntity:) keyEquivalent:CPDownArrowFunctionKey] setTarget:self];
    [[navigationMenu addItemWithTitle:CPLocalizedString(@"Select previous entity", @"Select previous entity") action:@selector(selectPreviousEntity:) keyEquivalent:CPUpArrowFunctionKey] setTarget:self];
    [navigationMenu addItem:[CPMenuItem separatorItem]];
    var nextModuleItem = [[navigationMenu addItemWithTitle:CPLocalizedString(@"Select next module", @"Select next module") action:@selector(selectNextModule:) keyEquivalent:CPRightArrowFunctionKey] setKeyEquivalentModifierMask:CPCommandKeyMask | CPAlternateKeyMask],
        previousModuleItem = [[navigationMenu addItemWithTitle:CPLocalizedString(@"Select previous module", @"Select previous module") action:@selector(selectPreviousModule:) keyEquivalent:CPLeftArrowFunctionKey] setKeyEquivalentModifierMask:CPCommandKeyMask | CPAlternateKeyMask];
    [nextModuleItem setTarget:self];
    [previousModuleItem setTarget:self];
    [navigationMenu addItem:[CPMenuItem separatorItem]];
    [[navigationMenu addItemWithTitle:CPLocalizedString(@"Expand group", @"Expand group") action:@selector(expandGroup:) keyEquivalent:@"["] setTarget:self];
    [[navigationMenu addItemWithTitle:CPLocalizedString(@"Collapse group", @"Expand group") action:@selector(collapseGroup:) keyEquivalent:@"]"] setTarget:self];
    [navigationMenu addItem:[CPMenuItem separatorItem]];
    [[navigationMenu addItemWithTitle:CPLocalizedString(@"Expand all groups", @"Expand all groups") action:@selector(expandAllGroups:) keyEquivalent:@"{"] setTarget:self];
    [[navigationMenu addItemWithTitle:CPLocalizedString(@"Collapse all groups", @"Collapse all groups") action:@selector(collapseAllGroups:) keyEquivalent:@"}"] setTarget:self];
    [navigationMenu addItem:[CPMenuItem separatorItem]];
    [[navigationMenu addItemWithTitle:CPLocalizedString(@"Toggle tag view", @"Toggle tag view") action:@selector(toolbarItemTagsClick:) keyEquivalent:@"T"] setTarget:self];

    [_mainMenu setSubmenu:navigationMenu forItem:navigationItem];

    // help
    [[helpMenu addItemWithTitle:CPLocalizedString(@"Archipel Help", @"Archipel Help") action:@selector(openWiki:) keyEquivalent:@"?"] setTarget:self];
    [[helpMenu addItemWithTitle:CPLocalizedString(@"Release note", @"Release note") action:@selector(openReleaseNotes:) keyEquivalent:@""] setTarget:self];
    [helpMenu addItem:[CPMenuItem separatorItem]];
    [[helpMenu addItemWithTitle:CPLocalizedString(@"Go to website", @"Go to website") action:@selector(openWebsite:) keyEquivalent:@""] setTarget:self];
    [[helpMenu addItemWithTitle:CPLocalizedString(@"Report a bug", @"Report a bug") action:@selector(openBugTracker:) keyEquivalent:@""] setTarget:self];
    [helpMenu addItem:[CPMenuItem separatorItem]];
    [[helpMenu addItemWithTitle:CPLocalizedString(@"Make a donation", @"Make a donation") action:@selector(openDonationPage:) keyEquivalent:@""] setTarget:self];
    [_mainMenu setSubmenu:helpMenu forItem:helpItem];

    [CPApp setMainMenu:_mainMenu];
    [CPMenu setMenuBarVisible:NO];

    CPLog.trace(@"Main menu created");
}

- (void)makeRosterMenu
{
    _rosterMenuForContacts = [[CPMenu alloc] init];
    [[_rosterMenuForContacts addItemWithTitle:CPLocalizedString(@"Delete contact", @"Delete contact") action:@selector(deleteEntities:) keyEquivalent:@"D"] setTarget:self];
    [_rosterMenuForContacts addItem:[CPMenuItem separatorItem]];
    [[_rosterMenuForContacts addItemWithTitle:CPLocalizedString(@"Ask subscribtion", @"Ask subscribtion") action:@selector(askSubscription:) keyEquivalent:@"'"] setTarget:self];
    [[_rosterMenuForContacts addItemWithTitle:CPLocalizedString(@"Remove subscribtion", @"Remove subscribtion") action:@selector(removeSubscription:) keyEquivalent:@"\""] setTarget:self];

    _rosterMenuForGroups = [[CPMenu alloc] init];
    [[_rosterMenuForGroups addItemWithTitle:@"Delete group" action:@selector(deleteEntities:) keyEquivalent:@"D"] setTarget:self];
    [_rosterMenuForGroups addItem:[CPMenuItem separatorItem]];
    [[_rosterMenuForGroups addItemWithTitle:@"Expand group" action:@selector(expandGroup:) keyEquivalent:@"["] setTarget:self];
    [[_rosterMenuForGroups addItemWithTitle:@"Collapse group" action:@selector(collapseAllGroups:) keyEquivalent:@"]"] setTarget:self];
}

/*! initialize the toolbar with default items
*/
- (void)makeToolbar
{
    var bundle = [CPBundle bundleForClass:self];

    CPLog.trace("initializing mianToolbar");

    _mainToolbar = [[TNToolbar alloc] init];

    [theWindow setToolbar:_mainToolbar];

    // ok the next following line is a terrible awfull hack.
    [_mainToolbar addItemWithIdentifier:@"CUSTOMSPACE"
                                  label:@"              "/* incredible huh ?*/
                                   view:nil
                                 target:nil
                                 action:nil];

    [_mainToolbar addItemWithIdentifier:TNToolBarItemLogout
                                  label:CPLocalizedString(@"Log out", @"Log out")
                                   icon:[bundle pathForResource:@"IconsToolbar/logout.png"]
                                   altIcon:[bundle pathForResource:@"IconsToolbar/logout-alt.png"]
                                 target:self action:@selector(toolbarItemLogoutClick:)
                                toolTip:@"Log out from the application"];

    [_mainToolbar addItemWithIdentifier:TNToolBarItemTags
                                  label:CPLocalizedString(@"Tags", @"Tags")
                                   icon:[bundle pathForResource:@"IconsToolbar/tags.png"]
                                   altIcon:[bundle pathForResource:@"IconsToolbar/tags-alt.png"]
                                 target:self action:@selector(toolbarItemTagsClick:)
                                toolTip:@"Show or hide the tags field"];

    var statusSelector  = [[CPPopUpButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 130.0, 25.0)],
        availableItem   = [[CPMenuItem alloc] init],
        awayItem        = [[CPMenuItem alloc] init],
        busyItem        = [[CPMenuItem alloc] init],
        DNDItem         = [[CPMenuItem alloc] init],
        statusItem      = [_mainToolbar addItemWithIdentifier:TNToolBarItemStatus label:CPLocalizedString(@"Status", @"Status") view:statusSelector target:self action:@selector(toolbarItemPresenceStatusClick:)];


    // localize the status label
    TNArchipelStatusAvailableLabel  = CPLocalizedString(@"Available", @"Available"),
    TNArchipelStatusAwayLabel       = CPLocalizedString(@"Away", @"Away"),
    TNArchipelStatusBusyLabel       = CPLocalizedString(@"Busy", @"Busy"),
    TNArchipelStatusDNDLabel        = CPLocalizedString(@"Do not disturb", @"Do not disturb"),

    [availableItem setTitle:TNArchipelStatusAvailableLabel];
    [availableItem setImage:CPImageInBundle(@"IconsStatus/green-large.png", CGSizeMake(10.0, 8.0), bundle)];
    [statusSelector addItem:availableItem];

    [awayItem setTitle:TNArchipelStatusAwayLabel];
    [awayItem setImage:CPImageInBundle(@"IconsStatus/orange-large.png", CGSizeMake(10.0, 8.0), bundle)];
    [statusSelector addItem:awayItem];

    [busyItem setTitle:TNArchipelStatusBusyLabel];
    [busyItem setImage:CPImageInBundle(@"IconsStatus/red-large.png", CGSizeMake(10.0, 8.0), bundle)];
    [statusSelector addItem:busyItem];

    [DNDItem setTitle:TNArchipelStatusDNDLabel];
    [DNDItem setImage:CPImageInBundle(@"IconsStatus/black-large.png", CGSizeMake(10.0, 8.0), bundle)];
    [statusSelector addItem:DNDItem];

    [statusItem setMinSize:CGSizeMake(123.0, 25.0)];
    [statusItem setMaxSize:CGSizeMake(123.0, 25.0)];

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

    _userAvatarButton = [[CPButton alloc] initWithFrame:CGRectMake(5.0, 4.0, TNUserAvatarSize.width - 5, TNUserAvatarSize.height - 5)],

    [_userAvatarButton setBordered:NO];
    [_userAvatarButton setBorderedWithHexColor:@"#a8a8a8"];
    [_userAvatarButton setBackgroundColor:[CPColor blackColor]];
    [_userAvatarButton setTarget:self];
    [_userAvatarButton setAction:@selector(toolbarItemAvatarClick:)];
    [_userAvatarButton setMenu:userAvatarMenu];
    [_userAvatarButton setValue:CPScaleProportionally forThemeAttribute:@"image-scaling"];
    [_userAvatarButton setImage:CPImageInBundle(@"user-unknown.png", TNUserAvatarSize, bundle)];

    [[_mainToolbar customSubViews] addObject:_userAvatarButton];
    [_mainToolbar reloadToolbarItems];
}

/*! initializ the button bar
*/
- (void)makeButtonBar
{
    var bundle = [CPBundle mainBundle],
        defaults  = [CPUserDefaults standardUserDefaults];

    CPLog.trace(@"Initializing the roster button bar");
    [splitViewMain setButtonBar:buttonBarLeft forDividerAtIndex:0];

    var bezelColor              = CPColorWithImages(@"TNButtonBar/buttonBarBackground.png", CGSizeMake(1, 27), bundle),
        leftBezel               = CPImageInBundle(@"TNButtonBar/buttonBarLeftBezel.png", CGSizeMake(1, 26), bundle),
        centerBezel             = CPImageInBundle(@"TNButtonBar/buttonBarCenterBezel.png", CGSizeMake(1, 26), bundle),
        rightBezel              = CPImageInBundle(@"TNButtonBar/buttonBarRightBezel.png", CGSizeMake(1, 26), bundle),
        buttonBezel             = CPColorWithImages([leftBezel, centerBezel, rightBezel]),
        leftBezelHighlighted    = CPImageInBundle(@"TNButtonBar/buttonBarLeftBezelHighlighted.png", CGSizeMake(1, 26), bundle),
        centerBezelHighlighted  = CPImageInBundle(@"TNButtonBar/buttonBarCenterBezelHighlighted.png", CGSizeMake(1, 26), bundle),
        rightBezelHighlighted   = CPImageInBundle(@"TNButtonBar/buttonBarRightBezelHighlighted.png", CGSizeMake(1, 26), bundle),
        buttonBezelHighlighted  = CPColorWithImages([leftBezelHighlighted, centerBezelHighlighted, rightBezelHighlighted]),
        plusMenu                = [[CPMenu alloc] init],
        minusButton             = [CPButtonBar minusButton];

    _hideButton             = [CPButtonBar minusButton];
    _hideButtonImageEnable  = CPImageInBundle(@"IconsButtonBar/show.png", CGSizeMake(20, 20), bundle);
    _hideButtonImageDisable = CPImageInBundle(@"IconsButtonBar/hide.png", CGSizeMake(20, 20), bundle);

    [buttonBarLeft setValue:bezelColor forThemeAttribute:"bezel-color"];
    [buttonBarLeft setValue:buttonBezel forThemeAttribute:"button-bezel-color"];
    [buttonBarLeft setValue:buttonBezelHighlighted forThemeAttribute:"button-bezel-color" inState:CPThemeStateHighlighted];

    _plusButton = [[TNButtonBarPopUpButton alloc] initWithFrame:CGRectMake(0, 0, 35, 25)],
    [_plusButton setTarget:self];
    [_plusButton setImage:CPImageInBundle(@"IconsButtonBar/plus.png", CGSizeMake(20, 20), bundle)];
    [[plusMenu addItemWithTitle:CPLocalizedString(@"Add a contact", @"Add a contact") action:@selector(addContact:) keyEquivalent:@"C"] setTarget:self];
    [[plusMenu addItemWithTitle:CPLocalizedString(@"Add a group", @"Add a group") action:@selector(addGroup:) keyEquivalent:@"D"] setTarget:self];
    [_plusButton setMenu:plusMenu];
    [_plusButton setToolTip:CPLocalizedString(@"Add a new contact or group", @"Add a new contact or group")];

    [minusButton setTarget:self];
    [minusButton setImage:CPImageInBundle(@"IconsButtonBar/minus.png", CGSizeMake(20, 20), bundle)];
    [minusButton setAction:@selector(deleteEntities:)];
    [minusButton setToolTip:CPLocalizedString(@"Delete selected contacts or groups", @"Delete selected contacts or groups")];

    [_hideButton setTarget:self];
    [_hideButton setImage:([defaults boolForKey:@"TNArchipelPropertyControllerEnabled"]) ? _hideButtonImageDisable : _hideButtonImageEnable];
    [_hideButton setAction:@selector(toggleShowPropertiesView:)];
    [_hideButton setToolTip:CPLocalizedString(@"Show or hide properties view", @"Show or hide properties view")];

    var buttons = [CPArray array];

    if ([bundle objectForInfoDictionaryKey:@"TNArchipelDisplayXMPPManageContactsButton"] == 1)
    {
        [buttons addObject:_plusButton]
        [buttons addObject:minusButton]
    }

    [buttons addObject:_hideButton];
    [buttonBarLeft setButtons:buttons];
}


#pragma mark -
#pragma mark Notifications handlers

/*! called when connectionController starts connection
    it will eventually start to loads the modules
    @param aNotification the notification
*/
- (void)didConnectionStart:(CPNotification)aNotification
{
    // if (![moduleController isModuleLoadingStarted])
    // {
    //     CPLog.trace(@"Starting loading all modules");
    //     [moduleController load];
    // }
}

/*! Notification responder of TNStropheConnection
    will be performed on login
    @param aNotification the received notification. This notification will contains as object the TNStropheConnection
*/
- (void)loginStrophe:(CPNotification)aNotification
{
    [[TNPushCenter defaultCenter] setConnection:[[TNStropheIMClient defaultClient] connection]];
    _pubSubController = [TNPubSubController pubSubControllerWithConnection:[[TNStropheIMClient defaultClient] connection]];

    [preferencesController initXMPPStorage];
    [preferencesController recoverFromXMPPServer];
}

/*! called when TNPreferencesControllerRestoredNotification is received
    @param aNotification the notification
*/
- (void)didRetrieveConfiguration:(CPNotification)aNotification
{
    [CPMenu setMenuBarVisible:YES];

    [[[TNStropheIMClient defaultClient] roster] getRoster];

    [connectionController hideWindow:nil];
    [theWindow makeKeyAndOrderFront:nil];
    [self updateOverallScrollersStyle];

    [[[TNStropheIMClient defaultClient] roster] setDelegate:contactsController];
    [[[TNStropheIMClient defaultClient] roster] setFilterField:filterField];
    [[[TNStropheIMClient defaultClient] roster] setHideOfflineContacts:[[CPUserDefaults standardUserDefaults] boolForKey:@"TNHideOfflineContacts"]];

    if ([[CPUserDefaults standardUserDefaults] boolForKey:@"TNArchipelMonitorStanza"])
        [self monitorXMPP:YES];

    [tagsController setPubSubController:_pubSubController];
    [propertiesController setPubSubController:_pubSubController];
    [contactsController setPubSubController:_pubSubController];

    [_rosterOutlineView setDataSource:[[TNStropheIMClient defaultClient] roster]];
    [_rosterOutlineView recoverExpandedWithBaseKey:TNArchipelRememberOpenedGroup itemKeyPath:@"name"];
    [_rosterOutlineView deselectAll];
    [[TNPermissionsCenter defaultCenter] watchPubSubs];

    if (_tagsVisible)
        [splitViewTagsContents setPosition:TNArchipelTagViewHeight ofDividerAtIndex:0];
    else
        [splitViewTagsContents setPosition:0.0 ofDividerAtIndex:0];

    [labelCurrentUser setStringValue:CPLocalizedString(@"Connected as ", @"Connected as ") + [[[TNStropheIMClient defaultClient] JID] bare]];

    if (![moduleController isModuleLoadingStarted])
    {
        CPLog.trace(@"Starting loading all modules");
        [moduleController load];
    }
}

/*! Notification responder of TNStropheConnection
    will be performed on logout
    @param aNotification the received notification. This notification will contains as object the TNStropheConnection
*/
- (void)XMPPDisconnecting:(CPNotification)aNotification
{
    [[TNPushCenter defaultCenter] flush];
    CPLog.info("disconnecting...");
}

/*! Notification responder of TNStropheConnection
    will be performed on logout
    @param aNotification the received notification. This notification will contains as object the TNStropheConnection
*/
- (void)XMPPDisconnected:(CPNotification)aNotification
{
    CPLog.info("Successfuly disconnected.");
    [theWindow close];
    [connectionController showWindow:nil];
    [labelCurrentUser setStringValue:@""];
    [CPMenu setMenuBarVisible:NO];
}

/*! Notification responder for TNStropheRosterRetrievedNotification
    @param aNotification the notification
*/
- (void)didRetrieveRoster:(CPNotification)aNotification
{
    var servers = [CPArray array],
        roster  = [aNotification object];

    if ([[roster content] count] == 0)
    {
        [self displayFirstConnectionInterface];
    }
    else
    {
        for (var i = 0; i < [[roster content] count]; i++)
        {
            if ([[[roster content] objectAtIndex:i] isKindOfClass:TNStropheContact])
            {
                var contact = [[roster content] objectAtIndex:i];
                if (![_pubSubController containsServerJID:[TNStropheJID stropheJIDWithString:"pubsub." + [[contact JID] domain]]])
                    [[_pubSubController servers] addObject:[TNStropheJID stropheJIDWithString:"pubsub." + [[contact JID] domain]]];
            }
        }
    }

    [_pubSubController retrieveSubscriptions];
}

/*! Notification responder for CPApplicationWillTerminateNotification
    @param aNotification the notification
*/
- (void)onApplicationTerminate:(CPNotification)aNotification
{
    [[TNStropheIMClient defaultClient] disconnect];
}

- (void)didReceiveUserMessage:(CPNotification)aNotification
{
    // var user            = [[[aNotification userInfo] objectForKey:@"stanza"] fromUser],
    //     message         = [[[[aNotification userInfo] objectForKey:@"stanza"] firstChildWithName:@"body"] text],
    //     bundle          = [CPBundle bundleForClass:[self class]],
    //     customIcon      = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"message-icon.png"]],
    //     currentContact  = [aNotification object];

    [_rosterOutlineView reloadData];
}


#pragma mark -
#pragma mark Utilities

/*! Enable or disable the XMPP monitoring
    @param shouldMonitor YES or NO
*/
- (void)monitorXMPP:(BOOL)shouldMonitor
{
    if (shouldMonitor)
    {
        [[[TNStropheIMClient defaultClient] connection] rawInputRegisterSelector:@selector(stropheConnectionRawIn:) ofObject:self];
        [[[TNStropheIMClient defaultClient] connection] rawOutputRegisterSelector:@selector(stropheConnectionRawOut:) ofObject:self];
        [ledIn setHidden:NO];
        [ledOut setHidden:NO];
    }
    else
    {
        [[[TNStropheIMClient defaultClient] connection] removeRawInputSelector];
        [[[TNStropheIMClient defaultClient] connection] removeRawOutputSelector];
        [ledIn setHidden:YES];
        [ledOut setHidden:YES];
        if (_ledInTimer)
            [_ledInTimer invalidate];
        if (_ledOutTimer)
            [_ledInTimer invalidate];
    }
}

/*! Display the hint window
*/
- (void)displayFirstConnectionInterface
{
    [hintController showWindow:nil];
}

/*! Update the scroller style according to the defaults
*/
- (void)updateOverallScrollersStyle
{
    var defaults = [CPUserDefaults standardUserDefaults];

    if ([[defaults objectForKey:@"TNArchipelScrollersStyle"] lowercaseString] == @"legacy")
        [CPScrollView setGlobalScrollerStyle:CPScrollerStyleLegacy];
    else
        [CPScrollView setGlobalScrollerStyle:CPScrollerStyleOverlay];
}


#pragma mark -
#pragma mark Actions

/*! will remove the selected roster item according to its type
    @param the sender of the action
*/
- (IBAction)deleteEntities:(id)sender
{
    if ([_rosterOutlineView numberOfSelectedRows] == 0)
        return;

    var alert = [TNAlert alertWithMessage:CPLocalizedString(@"Delete items", @"Delete items")
                                informative:CPLocalizedString(@"Are you sure you want to delete selected items?", @"Are you sure you want to delete selected items?")
                                 target:self
                                 actions:[[CPLocalizedString("Delete", "Delete"), @selector(_performDeleteEntity)], [CPLocalizedString("Cancel", "Cancel"), nil]]];

    [alert setHelpTarget:self action:@selector(showHelpForDelete:)];
    [alert runModal];
}

/*! @ignore
*/
- (void)_performDeleteEntity
{
    var indexes = [_rosterOutlineView selectedRowIndexes],
        contactToRemove = [CPArray array],
        groupsToRemove = [CPArray array];

    while ([indexes count] > 0)
    {
        var item = [_rosterOutlineView itemAtRow:[indexes firstIndex]];

        switch ([item class])
        {
            case TNStropheContact:
                [contactToRemove addObject:item];
                break;

            case TNStropheGroup:
                [groupsToRemove addObject:item];
                break;
        }

        [indexes removeIndex:[indexes firstIndex]];
    }

    for (var i = 0; i < [contactToRemove count]; i++)
        [contactsController deleteContact:[contactToRemove objectAtIndex:i]];
    for (var i = 0; i < [groupsToRemove count]; i++)
        [groupsController deleteGroup:[groupsToRemove objectAtIndex:i]];
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
    @param the aSender of the action
*/
- (IBAction)logout:(id)aSender
{
    var defaults = [CPUserDefaults standardUserDefaults];
    CPLog.info(@"starting to disconnect");
    [[TNStropheIMClient defaultClient] disconnect];
}

/*! will opens the add contact window
    @param the aSender of the action
*/
- (IBAction)addContact:(id)aSender
{
    [contactsController showWindow:_plusButton];
}

/*! will ask contact subscription request
    @param the aSender of the action
*/
- (IBAction)askSubscription:(id)aSender
{
    if ([_rosterOutlineView numberOfSelectedRows] == 0)
        return;

    var indexes = [_rosterOutlineView selectedRowIndexes];

    while ([indexes count] > 0)
    {
        var contact = [_rosterOutlineView itemAtRow:[indexes firstIndex]];
        if ([contact isKindOfClass:TNStropheContact])
            [contactsController askSubscription:[contact JID]];
        [indexes removeIndex:[indexes firstIndex]];
    }
}

/*! will ask contact subscription request
    @param the aSender of the action
*/
- (IBAction)removeSubscription:(id)aSender
{
    if ([_rosterOutlineView numberOfSelectedRows] == 0)
        return;

    var indexes = [_rosterOutlineView selectedRowIndexes];

    while ([indexes count] > 0)
    {
        var contact = [_rosterOutlineView itemAtRow:[indexes firstIndex]];
        if ([contact isKindOfClass:TNStropheContact])
            [contactsController removeSubscription:[contact JID]];
        [indexes removeIndex:[indexes firstIndex]];
    }
}


/*! Opens the add group window
    @param the sender of the action
*/
- (IBAction)addGroup:(id)sender
{
    [groupsController showWindow:_plusButton];
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

/*! Select the next module
    @param aSender the sender of the action
*/
- (IBAction)selectNextModule:(id)aSender
{
    [_rosterOutlineView moveRight];
}

/*! Select the previous module
    @param aSender the sender of the action
*/
- (IBAction)selectPreviousModule:(id)aSender
{
    [_rosterOutlineView moveLeft];
}

/*! simulate a click on the focus filter
    @param the sender of the action
*/
- (IBAction)focusFilter:(id)sender
{
    [theWindow makeFirstResponder:filterField];
}

/*! Expands the current group
    @param the sender of the action
*/
- (IBAction)expandGroup:(id)sender
{
    var index = [_rosterOutlineView selectedRowIndexes];

    if ([index firstIndex] == -1)
        return;

    var item = [_rosterOutlineView itemAtRow:[index firstIndex]];

    if ([item isKindOfClass:TNStropheGroup])
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
    window.open("https://github.com/archipelproject/archipel/wiki");
}

/*! Opens the archipel commit line
    @param the sender of the action
*/
- (IBAction)openReleaseNotes:(id)sender
{
    window.open("https://github.com/archipelproject/Archipel/commits/master");
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
    window.open("https://github.com/archipelproject/archipel/issues/");
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
    [windowAboutArchipel center];
    [windowAboutArchipel makeKeyAndOrderFront:sender];
}

/*! shows the Preferences window
    @param the sender of the action
*/
- (IBAction)showPreferencesWindow:(id)sender
{
    [preferencesController showWindow:sender];
}

/*! shows the Notification history window
    @param the sender of the action
*/
- (IBAction)showNotificationWindow:(id)aSender
{
    [notificationHistoryController showWindow:aSender];
}

/*! shows the XMPP Account window
    @param aSender the sender of the action
*/
- (IBAction)showXMPPAccountWindow:(id)aSender
{
    [XMPPAccountController showWindow:aSender];
}


#pragma mark -
#pragma mark Toolbar Actions

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

    [growl pushNotificationWithTitle:CPLocalizedString(@"Status", @"Status") message:CPLocalizedString(@"Your status is now ", @"Your status is now ") + statusLabel];
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
    _tagsVisible = !_tagsVisible;
    [splitViewTagsContents setPosition:(_tagsVisible ? TNArchipelTagViewHeight : 0) ofDividerAtIndex:0];
    [[CPUserDefaults standardUserDefaults] setBool:_tagsVisible forKey:@"TNArchipelTagsVisible"];
}

/*! Action of toolbar imutables toolbar items.
    Trigger on avatar item click
    To have more information about the toolbar, see TNToolbar
    @param sender the sender of the action (the CPToolbarItem)
*/
- (IBAction)toolbarItemAvatarClick:(id)aSender
{
    var wp = CGPointMake(16, 12);

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
    var vCard = [connectionController userVCard];

    if ([vCard photo])
    {
        var currentAvatar = [vCard photo];

        [currentAvatar setDelegate:self];

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
        _helpWindow = nil;
}

/*! Delegate of TNOutlineView
    will be performed when when item will expands and save this state in CPUserDefaults

    @param aNotification the received notification
*/
- (void)outlineViewItemDidExpand:(CPNotification)aNotification
{
    var item        = [[aNotification userInfo] valueForKey:@"CPObject"],
        defaults    = [CPUserDefaults standardUserDefaults],
        key         = TNArchipelRememberOpenedGroup + [item name];

    [_rosterOutlineView getVCardsForVisibleEntitiesIfNeeded];
    [[defaults objectForKey:@"TNOutlineViewsExpandedGroups"] setObject:@"expanded" forKey:key];
}

/*! Delegate of TNOutlineView
    will be performed when when item will collapses and save this state in CPUserDefaults

    @param aNotification the received notification
*/
- (void)outlineViewItemDidCollapse:(CPNotification)aNotification
{
    var item        = [[aNotification userInfo] valueForKey:@"CPObject"],
        defaults    = [CPUserDefaults standardUserDefaults],
        key         = TNArchipelRememberOpenedGroup + [item name];

    [[defaults objectForKey:@"TNOutlineViewsExpandedGroups"] setObject:@"collapsed" forKey:key];
}

/*! called the roster outlineView to ask the dataView it should use for given item.
*/
- (void)outlineView:(CPOutlineView)anOutlineView viewForTableColumn:(CPTableColumn)aColumn item:(id)anItem
{
    var key = [anItem className],
        view = [_rosterOutlineView makeViewWithIdentifier:key owner:self];

    if (!view)
    {
        view = (key == TNStropheGroup) ? [rosterDataViewForGroups duplicate] : [rosterDataViewForContacts duplicate];
        [view setIdentifier:key];
        [view setAutoresizingMask:CPViewNotSizable];
    }

    return view;
}

/*! called the roster outlineView to ask the height of row for given item
*/
- (int)outlineView:(CPOutlineView)outlineView heightOfRowByItem:(id)anItem
{
    switch ([anItem class])
    {
        case TNStropheGroup:
            return [rosterDataViewForGroups frameSize].height;
        case TNStropheContact:
            return [rosterDataViewForContacts frameSize].height;
    }
}

/*! Delegate of TNOutlineView
    it will check if all loaded module are ok to be hidden, otherwise
    it will disallow to change selection
*/
- (BOOL)outlineView:(CPOutlineView)anOutlineView shouldSelectItem:(id)anItem
{
    var tabsModules = [moduleController tabModules];

    for (var i = 0; i < [tabsModules count]; i++)
    {
        var module = [tabsModules objectAtIndex:i];
        if (module && ![module shouldHideAndSelectItem:anItem ofObject:anOutlineView])
            return NO;
    }
    return YES;
}

/*! Delegate of TNOutlineView
    will be performed when selection changes. Tab Modules displaying
    @param aNotification the received notification
*/
- (void)outlineViewSelectionDidChange:(CPNotification)notification
{
    var loadDelay = [[CPUserDefaults standardUserDefaults] floatForKey:@"TNArchipelModuleLoadingDelay"],
        item;

    if ([_rosterOutlineView numberOfSelectedRows] > 1)
    {
        if (_stropheGroupSelection)
            [_stropheGroupSelection flush];

        var selectedRowIndexes = [_rosterOutlineView selectedRowIndexes];

        _stropheGroupSelection = [TNStropheGroup stropheGroupWithName:CPLocalizedString(@"Current Selection", @"Current Selection")];

        while ([selectedRowIndexes count] > 0)
        {
            var itemAtRow = [_rosterOutlineView itemAtRow:[selectedRowIndexes firstIndex]];
            if ([itemAtRow isKindOfClass:TNStropheContact])
            {
                if (![[_stropheGroupSelection contacts] containsObject:itemAtRow])
                    [[_stropheGroupSelection contacts] addObject:itemAtRow];
            }
            else
            {
                var contacts = [[[TNStropheIMClient defaultClient] roster] getAllContactsTreeFromGroup:itemAtRow];
                for (var i = 0; i < [contacts count]; i++)
                    if (![[_stropheGroupSelection contacts] containsObject:[contacts objectAtIndex:i]])
                        [[_stropheGroupSelection contacts] addObject:[contacts objectAtIndex:i]];
            }
            [selectedRowIndexes removeIndex:[selectedRowIndexes firstIndex]];
        }
        item = _stropheGroupSelection;
    }
    else
    {
        item = [_rosterOutlineView itemAtRow:[_rosterOutlineView selectedRow]];
    }

    if (_moduleLoadingDelay)
    {
        [_moduleLoadingDelay invalidate];
        _moduleLoadingDelay = null;
    }

    [propertiesController setEntity:item];
    [propertiesController reload];

    if (loadDelay == 0)
        [self performModuleChange:@{@"userInfo":item}]; // fake the timer
    else
       _moduleLoadingDelay = [CPTimer scheduledTimerWithTimeInterval:loadDelay target:self selector:@selector(performModuleChange:) userInfo:item repeats:NO];
}

/*! This method is called by delegate outlineViewSelectionDidChange: after a small delay by a timer
    in order to really process the modules swappoing. this avoid overloading if up key is maintained for example.
*/
- (void)performModuleChange:(CPTimer)aTimer
{
    var item = [aTimer valueForKey:@"userInfo"];

    switch ([item class])
    {
        case TNStropheGroup:
            [moduleController setEntity:item ofType:@"group"];
            [moduleController setCurrentEntityForToolbarModules:nil];
            break;

        case TNStropheContact:
            var vCard       = [item vCard],
                entityType  = [[[TNStropheIMClient defaultClient] roster] analyseVCard:vCard];
            [[TNPermissionsCenter defaultCenter] cachePermissionsForEntityIfNeeded:item];
            [moduleController setEntity:item ofType:entityType];
            [moduleController setCurrentEntityForToolbarModules:item];
            break;

        default:
            [moduleController setEntity:nil ofType:TNArchipelEntityTypeGeneral];
            [moduleController setCurrentEntityForToolbarModules:nil];
            [propertiesController hideView];
    }

    // post a system wide notification about the changes
    [[CPNotificationCenter defaultCenter] postNotificationName:TNArchipelNotificationRosterSelectionChanged object:item];
}

/*! Delegate of CPOutlineView
*/
- (CPMenu)outlineView:(CPOutlineView)anOutlineView menuForTableColumn:(CPTableColumn)aTableColumn item:(int)anItem
{
    if (anOutlineView != _rosterOutlineView)
        return;

    if ([anOutlineView numberOfSelectedRows] == 0)
        return;

    var itemRow = [_rosterOutlineView rowForItem:anItem];
    if ([_rosterOutlineView selectedRow] != itemRow)
        [_rosterOutlineView selectRowIndexes:[CPIndexSet indexSetWithIndex:itemRow] byExtendingSelection:NO];

    if ([anItem isKindOfClass:TNStropheContact])
        return _rosterMenuForContacts;
    else if ([anItem isKindOfClass:TNStropheGroup])
        return _rosterMenuForGroups;
}

/* Delegate of CPOutlineView for delete key event
*/
- (void)outlineViewDeleteKeyPressed:(CPOutlineView)anOutlineView
{
    if (anOutlineView != _rosterOutlineView)
        return;

    if ([anOutlineView numberOfSelectedRows] == 0)
        return;

    [self deleteEntities:anOutlineView];
}

/*! Delegate of splitViewTagsContents. This will save the positionning of splitview in CPUserDefaults
*/
- (float)splitView:(CPSlipView)aSplitView constrainMaxCoordinate:(int)position ofSubviewAt:(int)index
{
    if ((aSplitView === splitViewTagsContents) && (index == 0))
        return (_tagsVisible) ? 33 : 0;

    return position;
}

/*! Delegate of splitViewTagsContents and splitViewMain.
*/
- (float)splitView:(CPSlipView)aSplitView constrainMinCoordinate:(int)position ofSubviewAt:(int)index
{
    if ((aSplitView === splitViewTagsContents) && (index == 0))
        return (_tagsVisible) ? 33 : 0;

    if ((aSplitView === splitViewMain) && (index == 0))
        return 200;

    return 0;
}

/*! called when module controller has loaded a module
*/
- (void)moduleLoader:(TNModuleController)aLoader loadedBundle:(CPBundle)aBundle progress:(float)percent
{
    var defaults = [CPUserDefaults standardUserDefaults],
        moduleLabel = [aBundle objectForInfoDictionaryKey:@"PluginDisplayName"];

    if ([moduleLabel isKindOfClass:CPDictionary] && [aBundle objectForInfoDictionaryKey:@"CPBundleLocale"])
        moduleLabel = [moduleLabel objectForKey:[defaults objectForKey:@"CPBundleLocale"]];

    if (!moduleLabel)
        moduleLabel = [[aBundle objectForInfoDictionaryKey:@"PluginDisplayName"] objectForKey:@"en"];

    [progressIndicatorModulesLoading setDoubleValue:percent];
    [[viewLoading viewWithTag:1] setStringValue:moduleLabel];
}

/*! delegate of TNModuleController sent when all modules are loaded
*/
- (void)moduleLoaderLoadingComplete:(TNModuleController)aLoader
{
    CPLog.info(@"All modules have been loaded");
    [_mainToolbar reloadToolbarItems];
    [_rosterOutlineView setEnabled:YES];

    [viewLoading removeFromSuperview];
    [_moduleTabView setFrame:[viewLoading frame]];
    [rightView addSubview:_moduleTabView];

    [updateController check];
    [self performModuleChange:nil];
    [[[CPApp mainMenu] itemWithTitle:CPLocalizedString(@"Modules", @"Modules")] setEnabled:YES];
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
