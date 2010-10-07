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
@import <StropheCappuccino/StropheCappuccino.j>
@import <GrowlCappuccino/GrowlCappuccino.j>
@import <VNCCappuccino/VNCCappuccino.j>
@import <LPKit/LPKit.j>
@import <LPKit/LPMultiLineTextField.j>
@import <iTunesTabView/iTunesTabView.j>
@import <MessageBoard/MessageBoard.j>

//@import <LPKit/LPCrashReporter.j>

@import "TNAvatarManager.j";
@import "TNCategoriesAndGlobalSubclasses.j";
@import "TNDatasourceRoster.j";
@import "TNOutlineViewRoster.j";
@import "TNToolbar.j";
@import "TNModuleLoader.j";
@import "TNViewProperties.j";
@import "TNWindowAddContact.j";
@import "TNWindowAddGroup.j";
@import "TNWindowConnection.j";
@import "TNModule.j";
@import "TNViewLineable.j";
@import "TNUserDefaults.j";
@import "TNTableViewDataSource.j";
@import "TNSearchField.j";
@import "TNStepper.j";
@import "TNSwitch.j";
@import "TNWindowPreferences.j";
@import "TNAnimation.j";
@import "TNTagView.j";

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




/*! @ingroup archipelcore
    This is the main application controller. It is loaded from MainMenu.cib.
    Anyone that is interessted in the way of Archipel is working should begin
    to read this class. This is the main application entry point.
*/
@implementation AppController : CPObject
{
    @outlet CPButtonBar         buttonBarLeft;
    @outlet CPImageView         ledIn;
    @outlet CPImageView         ledOut;
    @outlet CPSplitView         leftSplitView;
    @outlet CPSplitView         mainHorizontalSplitView;
    @outlet CPSplitView         splitViewTagsContents;
    @outlet CPTextField         textFieldAboutVersion;
    @outlet CPTextField         textFieldLoadingModuleLabel;
    @outlet CPTextField         textFieldLoadingModuleTitle;
    @outlet CPView              filterView;
    @outlet CPView              leftView;
    @outlet CPView              rightView;
    @outlet CPView              statusBar;
    @outlet CPView              viewLoadingModule;
    @outlet TNTagView           viewTags;
    @outlet CPWebView           helpView;
    @outlet CPWebView           webViewAboutCredits;
    @outlet CPWindow            theWindow;
    @outlet CPWindow            windowAboutArchipel;
    @outlet TNAvatarManager     windowAvatarManager;
    @outlet TNSearchField       filterField;
    @outlet TNViewProperties    propertiesView;
    @outlet TNWhiteWindow       windowModuleLoading;
    @outlet TNWindowAddContact  addContactWindow;
    @outlet TNWindowAddGroup    addGroupWindow;
    @outlet TNWindowConnection  connectionWindow;
    @outlet TNWindowPreferences windowPreferences;

    BOOL                        _tagsVisible;
    BOOL                        _shouldShowHelpView;
    CPImage                     _imageLedInData;
    CPImage                     _imageLedNoData;
    CPImage                     _imageLedOutData;
    CPMenu                      _mainMenu;
    CPMenu                      _modulesMenu;
    CPPlatformWindow            _platformHelpWindow;
    CPScrollView                _outlineScrollView;
    TNiTunesTabView             _moduleTabView;
    CPTextField                 _rightViewTextField;
    CPTimer                     _ledInTimer;
    CPTimer                     _ledOutTimer;
    CPTimer                     _moduleLoadingDelay;
    CPWindow                    _helpWindow;
    int                         _tempNumberOfReadyModules;
    TNDatasourceRoster          _mainRoster;
    TNModuleLoader              _moduleLoader;
    TNOutlineViewRoster         _rosterOutlineView;
    TNToolbar                   _mainToolbar;
    TNViewHypervisorControl     _currentRightViewContent;
}


#pragma mark -
#pragma mark Initialization

/*! This method initialize the content of the GUI when the CIB file
    as finished to load.
*/
- (void)awakeFromCib
{
    [connectionWindow orderOut:nil];

    var bundle      = [CPBundle mainBundle],
        defaults    = [TNUserDefaults standardUserDefaults],
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
    var gradBG = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"gradientbg.png"]];
    [viewTags setBackgroundColor:[CPColor colorWithPatternImage:gradBG]];
    [splitViewTagsContents setIsPaneSplitter:YES];
    [splitViewTagsContents setValue:0.0 forThemeAttribute:@"pane-divider-thickness"]

    _tagsVisible = [defaults boolForKey:@"TNArchipelTagsVisible"];

    if (_tagsVisible)
        [splitViewTagsContents setPosition:33.0 ofDividerAtIndex:0];
    else
        [splitViewTagsContents setPosition:0.0 ofDividerAtIndex:0];

    [viewTags setFrame:[[[splitViewTagsContents subviews] objectAtIndex:0] frame]];
    [viewTags setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [[[splitViewTagsContents subviews] objectAtIndex:0] addSubview:viewTags];

    [viewLoadingModule setBackgroundColor:[CPColor colorWithHexString:@"D3DADF"]];

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
    _mainToolbar = [[TNToolbar alloc] initWithTarget:self];
    [theWindow setToolbar:_mainToolbar];

    /* properties view */
    CPLog.trace(@"initializing the leftSplitView");
    [leftSplitView setIsPaneSplitter:YES];
    [leftSplitView setBackgroundColor:[CPColor colorWithHexString:@"D8DFE8"]];
    [[leftSplitView subviews][1] removeFromSuperview];
    [leftSplitView addSubview:propertiesView];
    [leftSplitView setPosition:[leftSplitView bounds].size.height ofDividerAtIndex:0];
    [propertiesView setAvatarManager:windowAvatarManager];

    /* outlineview */
    CPLog.trace(@"initializing _rosterOutlineView");
    _rosterOutlineView = [[TNOutlineViewRoster alloc] initWithFrame:[leftView bounds]];
    [_rosterOutlineView setDelegate:self];
    [_rosterOutlineView registerForDraggedTypes:[TNDragTypeContact]];
    [_rosterOutlineView setSearchField:filterField];
    [_rosterOutlineView setEntityRenameField:[propertiesView entryName]];
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
    [textFieldLoadingModuleTitle setValue:[CPColor colorWithHexString:@"C4CAD6"] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
    [textFieldLoadingModuleTitle setTextColor:[CPColor colorWithHexString:@"000000"]];

    [textFieldLoadingModuleLabel setTextShadowOffset:CGSizeMake(0.0, 1.0)];
    [textFieldLoadingModuleLabel setValue:[CPColor colorWithHexString:@"C4CAD6"] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
    [textFieldLoadingModuleLabel setTextColor:[CPColor colorWithHexString:@"6A7087"]];


    CPLog.trace(@"initializing _moduleLoader");
    _moduleLoader = [[TNModuleLoader alloc] init]

    [_moduleLoader setDelegate:self];
    [_moduleTabView setDelegate:_moduleLoader];
    [_moduleLoader setMainToolbar:_mainToolbar];
    [_moduleLoader setMainTabView:_moduleTabView];
    [_moduleLoader setInfoTextField:_rightViewTextField];
    [_moduleLoader setModulesPath:@"Modules/"]
    [_moduleLoader setMainModuleView:rightView];
    [_moduleLoader setModulesMenu:_modulesMenu];
    [_rosterOutlineView setModulesTabView:_moduleTabView];

    CPLog.trace(@"Starting loading all modules");
    [_moduleLoader load];

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

    CPLog.info(@"Initialization of AppController OK");

    _tempNumberOfReadyModules = -1;
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
    var defaults = [TNUserDefaults standardUserDefaults];

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
    [addContactWindow setRoster:_mainRoster];
    [addContactWindow makeKeyAndOrderFront:nil];
}

/*! will ask for deleting the selected contact
    @param the sender of the action
*/
- (IBAction)deleteContact:(id)sender
{
    var index   = [[_rosterOutlineView selectedRowIndexes] firstIndex],
        item    = [_rosterOutlineView itemAtRow:index],
        growl   = [TNGrowlCenter defaultCenter];
        alert;

    if ([item class] != TNStropheContact)
    {
        [growl pushNotificationWithTitle:@"User supression" message:@"You must choose a contact" icon:TNGrowlIconError];
        return;
    }

    alert = [TNAlert alertWithTitle:@"Delete contact"
                                message:@"Are you sure you want to delete this contact?"
                                delegate:self
                                 actions:[["Delete", @selector(performDeleteContact:)], ["Cancel", nil]]];
    [alert setUserInfo:item];
    [alert runModal];
}

/*! Action for the deleteContact:'s confirmation TNAlert.
    It will delete the contact
    @param the sender of the action
*/
- (void)performDeleteContact:(id)userInfo
{
    var growl   = [TNGrowlCenter defaultCenter],
        contact = userInfo;

    [_mainRoster removeContactWithJID:[contact JID]];

    CPLog.info(@"contact " + [contact JID] + "removed");
    [growl pushNotificationWithTitle:@"Contact" message:@"Contact " + [contact JID] + @" has been removed"];

    [propertiesView hide];
    [_rosterOutlineView deselectAll];

    [self unregisterFromEventNodeOfJID:[contact JID] ofServer:@"pubsub." + [contact domain]];
}

/*! Opens the add group window
    @param the sender of the action
*/
- (IBAction)addGroup:(id)sender
{
    [addGroupWindow setRoster:_mainRoster];
    [addGroupWindow makeKeyAndOrderFront:nil];
}

/*! will ask for deleting the selected group
    @param the sender of the action
*/
- (IBAction)deleteGroup:(id)sender
{
    var growl       = [TNGrowlCenter defaultCenter],
        index       = [[_rosterOutlineView selectedRowIndexes] firstIndex],
        item        = [_rosterOutlineView itemAtRow:index],
        defaults    = [TNUserDefaults standardUserDefaults],
        alert;

    if ([item class] != TNStropheGroup)
    {
        [growl pushNotificationWithTitle:@"Group supression" message:@"You must choose a group" icon:TNGrowlIconError];
        return;
    }

    if ([[item contacts] count] != 0)
    {
        [growl pushNotificationWithTitle:@"Group supression" message:@"The group must be empty" icon:TNGrowlIconError];
        return;
    }

    alert = [TNAlert alertWithTitle:@"Delete group"
                                message:@"Are you sure you want to delete this group?"
                                delegate:self
                                 actions:[["Delete", @selector(performDeleteGroup:)], ["Cancel", nil]]];
    [alert setUserInfo:item]
    [alert runModal];
}

/*! Action for the deleteGroup:'s confirmation TNAlert.
    It will delete the group
    @param the sender of the action
*/
- (void)performDeleteGroup:(id)userInfo
{
    var group   = userInfo,
        key     = TNArchipelRememberOpenedGroup + [group name];

    [_mainRoster removeGroup:group];
    [_rosterOutlineView reloadData];
    [growl pushNotificationWithTitle:@"Group supression" message:@"The group has been removed"];

    [defaults removeObjectForKey:key];

    [propertiesView hide];
    [_rosterOutlineView deselectAll];
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
    [[propertiesView entryName] mouseDown:nil];
}

/*! Make the property view rename field active
    @param the sender of the action
*/
- (IBAction)renameGroup:(id)sender
{
    [[propertiesView entryName] mouseDown:nil];
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
    [windowPreferences makeKeyAndOrderFront:sender];
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
            defaults        = [TNUserDefaults standardUserDefaults],
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
    var defaults = [TNUserDefaults standardUserDefaults];

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
        defaults        = [TNUserDefaults standardUserDefaults];

    [splitViewTagsContents setPosition:dividerPosition ofDividerAtIndex:0];

    [defaults setBool:_tagsVisible forKey:@"TNArchipelTagsVisible"];
}

/*! Delegate of TNOutlineView
    will be performed when when item will expands and save this state in TNUserDefaults

    @param aNotification the received notification
*/
- (void)outlineViewItemWillExpand:(CPNotification)aNotification
{
    var item        = [[aNotification userInfo] valueForKey:@"CPObject"],
        defaults    = [TNUserDefaults standardUserDefaults],
        key         = TNArchipelRememberOpenedGroup + [item name];

    [defaults setObject:"expanded" forKey:key];
}

/*! Delegate of TNOutlineView
    will be performed when when item will collapses and save this state in TNUserDefaults

    @param aNotification the received notification
*/
- (void)outlineViewItemWillCollapse:(CPNotification)aNotification
{
    var item        = [[aNotification userInfo] valueForKey:@"CPObject"],
        defaults    = [TNUserDefaults standardUserDefaults],
        key         = TNArchipelRememberOpenedGroup + [item name];

    [defaults setObject:"collapsed" forKey:key];

    return YES;
}

/*! Delegate of mainSplitView. This will save the positionning of splitview in TNUserDefaults
*/
- (void)splitViewDidResizeSubviews:(CPNotification)aNotification
{
    var defaults    = [TNUserDefaults standardUserDefaults],
        splitView   = [aNotification object],
        newWidth    = [splitView rectOfDividerAtIndex:0].origin.x;

    CPLog.info(@"setting the mainSplitViewPosition value in defaults");
    [defaults setInteger:newWidth forKey:@"mainSplitViewPosition"];
}


#pragma mark -
#pragma mark Strophe Connection Management

/*! Notification responder of TNStropheConnection
    will be performed on login
    @param aNotification the received notification. This notification will contains as object the TNStropheConnection
*/
- (void)loginStrophe:(CPNotification)aNotification
{
    [CPMenu setMenuBarVisible:YES];
    [connectionWindow orderOut:nil];
    [theWindow makeKeyAndOrderFront:nil];


    _mainRoster = [[TNDatasourceRoster alloc] initWithConnection:[aNotification object]];

    [_mainRoster setDelegate:self];
    [_mainRoster setFilterField:filterField];
    [_mainRoster setTagsRegistry:[viewTags tagsRegistry]];
    [[_mainRoster connection] rawInputRegisterSelector:@selector(stropheConnectionRawIn:) ofObject:self];
    [[_mainRoster connection] rawOutputRegisterSelector:@selector(stropheConnectionRawOut:) ofObject:self];
    [_mainRoster getRoster];

    [viewTags setConnection:[aNotification object]];

    [propertiesView setRoster:_mainRoster];

    [windowPreferences setConnection:[aNotification object]];

    [_moduleLoader setRosterForToolbarItems:_mainRoster andConnection:[aNotification object]];
}

/*! Notification responder of TNStropheConnection
    will be performed on logout
    @param aNotification the received notification. This notification will contains as object the TNStropheConnection
*/
- (void)logoutStrophe:(CPNotification)aNotification
{
    [theWindow orderOut:nil];
    [connectionWindow makeKeyAndOrderFront:nil];
}


#pragma mark -
#pragma mark Traffic LED

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

/*! Notification responder for CPApplicationWillTerminateNotification
*/
- (void)onApplicationTerminate:(CPNotification)aNotification
{
    [_mainRoster disconnect];
}


#pragma mark -
#pragma mark XMPP Subscriptions / PubSub Management

/*! Delegate method of main TNStropheRoster.
    will be performed when a subscription request is sent
    @param requestStanza TNStropheStanza cotainining the subscription request
*/
- (void)didReceiveSubscriptionRequest:(id)requestStanza
{
    var nick;

    if ([requestStanza firstChildWithName:@"nick"])
        nick = [[requestStanza firstChildWithName:@"nick"] text];
    else
        nick = [requestStanza from];

    var alert = [TNAlert alertWithTitle:@"Subscription request"
                                message:nick + " is asking you subscription. Do you want to add it ?"
                                delegate:self
                                 actions:[["Accept", @selector(performSubscribe:)],
                                            ["Decline", @selector(performUnsubscribe:)]]];

    [alert setUserInfo:requestStanza]
    [alert runModal];
}

/*! Action of didReceiveSubscriptionRequest's confirmation alert.
    Will accept the subscription and try to register to Archipel pubsub nodes
*/
- (void)performSubscribe:(id)userInfo
{
    var bundle  = [CPBundle mainBundle],
        stanza  = userInfo;

    [_mainRoster answerAuthorizationRequest:stanza answer:YES];

    // evenually subscribe to event node of the entity
    [self registerToEventNodeOfJID:[stanza from] ofServer:@"pubsub." + [stanza fromDomain]];
}

/*! Action of performSubscribe's confirmation alert.
    Will register to Archipel pub sub nodes of the new contact
*/
- (void)registerToEventNodeOfJID:(CPString)aJID ofServer:(CPString)aServer
{
    var pubSubServer        = aServer,
        uid                 = [[_mainRoster connection] getUniqueId],
        nodeSubscribeStanza = [TNStropheStanza iqWithAttributes:{"type": "set", "id": uid}],
        params              = [[CPDictionary alloc] init];

    [nodeSubscribeStanza setTo:pubSubServer];
    [nodeSubscribeStanza addChildWithName:@"pubsub" andAttributes:{"xmlns": "http://jabber.org/protocol/pubsub"}];
    [nodeSubscribeStanza addChildWithName:@"subscribe" andAttributes:{
        "node": "/archipel/" + aJID.split("/")[0] + "/events",
        "jid": [[_mainRoster connection] JID],
    }];

    [params setValue:uid forKey:@"id"];

    [[_mainRoster connection] registerSelector:@selector(didPubSubSubscribe:) ofObject:self withDict:params]
    [[_mainRoster connection] send:nodeSubscribeStanza];

}

/*! Message sent by registerToEventNodeOfJID:ofServer: that will
    log if pubsub subscription is OK
*/
- (void)didPubSubSubscribe:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        CPLog.info("Sucessfully subscribed to pubsub event node of " + [aStanza from]);
    }
    else
    {
        CPLog.error("unable to subscribe to pubsub");
    }

    return NO;
}

/*! Action of didReceiveSubscriptionRequest's confirmation alert.
    Will refuse the subscription and try to unregister to Archipel pubsub nodes
*/
- (BOOL)performUnsubscribe:(id)userInfo
{
    var stanza = userInfo;
    [_mainRoster answerAuthorizationRequest:stanza answer:NO];

    // evenually unsubscribe to event node of the entity
   [self unregisterFromEventNodeOfJID:[stanza from] ofServer:@"pubsub." + [stanza fromDomain]];
}

/*! Action of performUnsubscribe's confirmation alert.
    Will unregister from Archipel pubSub nodes of the new contact
*/
- (void)unregisterFromEventNodeOfJID:(CPString)aJID ofServer:(CPString)aServer
{
    var pubSubServer            = aServer,
        uid                     = [[_mainRoster connection] getUniqueId],
        nodeUnsubscribeStanza   = [TNStropheStanza iqWithAttributes:{"type": "set", "id": uid}],
        params                  = [[CPDictionary alloc] init];

    [nodeUnsubscribeStanza setTo:pubSubServer];
    [nodeUnsubscribeStanza addChildWithName:@"pubsub" andAttributes:{"xmlns": "http://jabber.org/protocol/pubsub"}];
    [nodeUnsubscribeStanza addChildWithName:@"unsubscribe" andAttributes:{
        "node": "/archipel/" + aJID.split("/")[0] + "/events",
        "jid": [[_mainRoster connection] JID],
    }];

    [params setValue:uid forKey:@"id"];

    [[_mainRoster connection] registerSelector:@selector(didPubSubUnsubscribe:) ofObject:self withDict:params]
    [[_mainRoster connection] send:nodeUnsubscribeStanza];
}

/*! Message sent by unregisterFromEventNodeOfJID:ofServer: that will
    log if pubsub unsubscription is OK
*/
- (BOOL)didPubSubUnsubscribe:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        CPLog.info("Sucessfully unsubscribed from pubsub event node of " + [aStanza from]);
    }
    else
    {
        CPLog.error("unable to unsubscribe to pubsub");
    }

    return NO;
}


#pragma mark -
#pragma mark Help view management

/*! Display the helpView in the rightView
*/
- (void)showHelpView
{
    var bundle      = [CPBundle mainBundle],
        defaults    = [TNUserDefaults standardUserDefaults],
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


#pragma mark -
#pragma mark Module Loading

/*! delegate of TNModuleLoader sent when all modules are loaded
*/
- (void)moduleLoaderLoadingComplete:(TNModuleLoader)aLoader
{
    CPLog.info(@"All modules have been loaded");
    CPLog.trace(@"Positionning the connection window");

    [windowModuleLoading orderOut:nil];
    [connectionWindow center];
    [connectionWindow makeKeyAndOrderFront:nil];
    [connectionWindow initCredentials];
}

/*! Triggered when TNModuleLoader send TNArchipelModulesAllReadyNotification.
*/
- (void)allModuleReady:(CPNotification)aNotification
{
    if ([viewLoadingModule superview])
        [viewLoadingModule removeFromSuperview];
}

/*! Delegate of TNOutlineView
    will be performed when selection changes. Tab Modules displaying

    @param aNotification the received notification
*/
- (void)outlineViewSelectionDidChange:(CPNotification)notification
{
    var defaults    = [TNUserDefaults standardUserDefaults],
        index       = [[_rosterOutlineView selectedRowIndexes] firstIndex],
        item        = [_rosterOutlineView itemAtRow:index],
        loadDelay   = [defaults objectForKey:@"TNArchipelModuleLoadingDelay"];

    if (_moduleLoadingDelay)
        [_moduleLoadingDelay invalidate];

    [viewLoadingModule setFrame:[rightView bounds]];

    [propertiesView setEntity:item];
    [propertiesView reload];

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
        [_mainRoster setCurrentItem:nil];
        [propertiesView hide];
    }
    else
    {
        var item        = [aTimer userInfo],
            defaults    = [TNUserDefaults standardUserDefaults];

        [_mainRoster setCurrentItem:item];

        [self hideHelpView];

        switch ([item class])
        {
            case TNStropheGroup:
                CPLog.info(@"setting the entity as " + item + " of type group");
                [_moduleLoader setEntity:item ofType:@"group" andRoster:_mainRoster];
                break;

            case TNStropheContact:
                var vCard       = [item vCard],
                    entityType  = [_moduleLoader analyseVCard:vCard];
                CPLog.info(@"setting the entity as " + item + " of type " + entityType);
                [_moduleLoader setEntity:item ofType:entityType andRoster:_mainRoster];
                break;
        }
    }

    // post a system wide notification about the changes
    [[CPNotificationCenter defaultCenter] postNotificationName:TNArchipelNotificationRosterSelectionChanged object:_mainRoster];
}



#pragma mark -
#pragma mark Divers

- (void)copyright
{
    var defaults    = [TNUserDefaults standardUserDefaults],
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

@end
