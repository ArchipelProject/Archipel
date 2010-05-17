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
//@import <LPKit/LPCrashReporter.j>

@import "TNCategoriesAndGlobalSubclasses.j";
@import "TNAlertPresenceSubscription.j";
@import "TNAlertRemoveContact.j";
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
TNArchipelEntityTypeGroup            = @"group";


TNArchipelStatusAvailableLabel  = @"Available";
TNArchipelStatusAwayLabel       = @"Away";
TNArchipelStatusBusyLabel       = @"Busy";

/*! @ingroup archipelcore
    This is the main application controller. It is loaded from MainMenu.cib.
    Anyone that is interessted in the way of Archipel is working should begin
    to read this class. This is the main application entry point.
*/
@implementation AppController : CPObject
{
    @outlet CPView              leftView                    @accessors;
    @outlet CPView              filterView                  @accessors;
    @outlet TNSearchField       filterField                 @accessors;
    @outlet CPView              rightView                   @accessors;
    @outlet CPWebView           helpView                    @accessors;
    @outlet CPSplitView         leftSplitView               @accessors;
    @outlet CPWindow            theWindow                   @accessors;
    @outlet CPWindow            windowModuleLoading         @accessors;
    @outlet CPSplitView         mainHorizontalSplitView     @accessors;
    @outlet TNViewProperties    propertiesView              @accessors;
    @outlet CPImageView         ledOut                      @accessors;
    @outlet CPImageView         ledIn                       @accessors;
    @outlet CPView              statusBar                   @accessors;
    @outlet TNWindowAddContact  addContactWindow            @accessors;
    @outlet TNWindowAddGroup    addGroupWindow              @accessors;
    @outlet TNWindowConnection  connectionWindow            @accessors;
    @outlet CPButtonBar         buttonBarLeft               @accessors;
    @outlet CPView              viewLoadingModule           @accessors;


    TNModuleLoader              _moduleLoader;
    CPTabView                   _moduleTabView;
    
    TNDatasourceRoster          _mainRoster;
    TNOutlineViewRoster         _rosterOutlineView;
    TNToolbar                   _mainToolbar;
    TNViewHypervisorControl     _currentRightViewContent;
    CPScrollView                _outlineScrollView;
    BOOL                        _shouldShowHelpView;
    CPWindow                    _helpWindow;
    CPPlatformWindow            _platformHelpWindow;
    CPMenu                      _mainMenu;
    CPMenu                      _modulesMenu;
    
    CPImage                     _imageLedInData;
    CPImage                     _imageLedOutData;
    CPImage                     _imageLedNoData;
    CPTimer                     _ledInTimer;
    CPTimer                     _ledOutTimer;
    CPTimer                     _moduleLoadingDelay;
    
    int                         _tempNumberOfReadyModules;
}

/*! This method initialize the content of the GUI when the CIB file
    as finished to load.
*/
- (void)awakeFromCib
{
    [connectionWindow orderOut:nil];
    CPLogRegister(CPLogConsole);
    
    var bundle      = [CPBundle mainBundle];
    var defaults    = [TNUserDefaults standardUserDefaults];
    
    [mainHorizontalSplitView setIsPaneSplitter:YES];
    
    var posx;
    if (posx = [defaults integerForKey:@"mainSplitViewPosition"])
    {
        CPLog.trace("recovering with of main vertical CPSplitView from last state");
        [mainHorizontalSplitView setPosition:posx ofDividerAtIndex:0];

        var bounds = [leftView bounds];
        bounds.size.width = posx;
        [leftView setFrame:bounds];
        [leftView setBackgroundColor:[CPColor redColor]]
    }
    [mainHorizontalSplitView setDelegate:self];    
    
    /* hide main window */
    [theWindow orderOut:nil];
    
    /* toolbar */
    CPLog.trace("initializing mianToolbar");
    _mainToolbar = [[TNToolbar alloc] initWithTarget:self];
    [theWindow setToolbar:_mainToolbar];

    /* outlineview */
    CPLog.trace(@"initializing _rosterOutlineView");
    _rosterOutlineView = [[TNOutlineViewRoster alloc] initWithFrame:[leftView bounds]];
    [_rosterOutlineView setDelegate:self];
    [_rosterOutlineView registerForDraggedTypes:[TNDragTypeContact]];
    [_rosterOutlineView setSearchField:filterField];
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

    /* properties view */
    CPLog.trace(@"initializing the leftSplitView");
    [leftSplitView setIsPaneSplitter:YES];
    [leftSplitView setBackgroundColor:[CPColor colorWithHexString:@"D8DFE8"]];
    [[leftSplitView subviews][1] removeFromSuperview];
    [leftSplitView addSubview:propertiesView];
    [leftSplitView setPosition:[leftSplitView bounds].size.height ofDividerAtIndex:0];

    /* filter view. */
    CPLog.trace(@"initializing the filterView");
    [filterView setBackgroundColor:[CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"gradientGray.png"]]]];

    /* tab module view */
    CPLog.trace(@"initializing the _moduleTabView");
    _moduleTabView = [[CPTabView alloc] initWithFrame:[rightView bounds]];
    [_moduleTabView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [_moduleTabView setBackgroundColor:[CPColor whiteColor]];
    [rightView addSubview:_moduleTabView];

    /* message in _moduleTabView */
    var message = [CPTextField labelWithTitle:@"Entity is currently offline. You can't interract with it."];
    var bounds  = [_moduleTabView bounds];

    [message setFrame:CGRectMake(bounds.size.width / 2 - 300, 153, 600, 200)];
    [message setAutoresizingMask: CPViewMaxXMargin | CPViewMinXMargin];
    [message setAlignment:CPCenterTextAlignment]
    [message setFont:[CPFont boldSystemFontOfSize:18]];
    [message setTextColor:[CPColor grayColor]];
    [_moduleTabView addSubview:message];
    
    /* main menu */
    [self makeMainMenu];
    
    /* module Loader */
    var view    = [windowModuleLoading contentView];
    var frame   = [windowModuleLoading frame];
    windowModuleLoading = [[CPWindow alloc] initWithContentRect:frame styleMask:CPBorderlessWindowMask];
    [windowModuleLoading setContentView:view];
    //[windowModuleLoading setBackgroundColor:[CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"loginbg.png"]]]];
    [windowModuleLoading center]
    [windowModuleLoading makeKeyAndOrderFront:nil];
    
    CPLog.trace(@"initializing _moduleLoader");
    _moduleLoader = [[TNModuleLoader alloc] init]
    
    [_moduleLoader setDelegate:self];
    [_moduleTabView setDelegate:_moduleLoader];
    [_moduleLoader setMainToolbar:_mainToolbar];
    [_moduleLoader setMainTabView:_moduleTabView];
    [_moduleLoader setModulesPath:@"Modules/"]
    [_moduleLoader setMainRightView:rightView];
    [_moduleLoader setModulesMenu:_modulesMenu];
    [_rosterOutlineView setModulesTabView:_moduleTabView];

    CPLog.info(@"Starting loading all modules");
    [_moduleLoader load];


    _shouldShowHelpView = YES;
    [self showHelpView];
    
    /* notifications */
    var center = [CPNotificationCenter defaultCenter];

    CPLog.trace(@"registering for notification TNStropheConnectionSuccessNotification");
    [center addObserver:self selector:@selector(loginStrophe:) name:TNStropheConnectionStatusConnected object:nil];
    
    CPLog.trace(@"registering for notification TNStropheDisconnectionNotification");
    [center addObserver:self selector:@selector(logoutStrophe:) name:TNStropheConnectionStatusDisconnecting object:nil];
    
    CPLog.trace(@"registering for notification CPApplicationWillTerminateNotification");
    [center addObserver:self selector:@selector(onApplicationTerminate:) name:CPApplicationWillTerminateNotification object:nil];
    
    [center addObserver:self selector:@selector(allModuleReady:) name:TNArchipelModulesAllReadyNotification object:nil];
    
    
    CPLog.info(@"AppController initialized");
    
    var growl = [TNGrowlCenter defaultCenter];
    [growl setView:rightView];
    
    [statusBar setBackgroundColor:[CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"statusBarBg.png"]]]];
    
    _imageLedInData     = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"data-in.png"]];
    _imageLedOutData    = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"data-out.png"]];
    _imageLedNoData     = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"data-no.png"]];
    
    // trick
    var view    = [connectionWindow contentView];
    var frame   = [connectionWindow frame];
    connectionWindow = [[CPWindow alloc] initWithContentRect:frame styleMask:CPBorderlessWindowMask];
    [connectionWindow setContentView:view];
    [connectionWindow setBackgroundColor:[CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"loginbg.png"]]]];
    
    // buttonBar
    [mainHorizontalSplitView setButtonBar:buttonBarLeft forDividerAtIndex:0];
    
    var bezelColor = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"TNButtonBar/buttonBarBackground.png"] size:CGSizeMake(1, 27)]];
    var leftBezel = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"TNButtonBar/buttonBarLeftBezel.png"] size:CGSizeMake(2, 26)];
    var centerBezel = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"TNButtonBar/buttonBarCenterBezel.png"] size:CGSizeMake(1, 26)];
    var rightBezel = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"TNButtonBar/buttonBarRightBezel.png"] size:CGSizeMake(2, 26)];
    var buttonBezel = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:[leftBezel, centerBezel, rightBezel] isVertical:NO]];
    var leftBezelHighlighted = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"TNButtonBar/buttonBarLeftBezelHighlighted.png"] size:CGSizeMake(2, 26)];
    var centerBezelHighlighted = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"TNButtonBar/buttonBarCenterBezelHighlighted.png"] size:CGSizeMake(1, 26)];
    var rightBezelHighlighted = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"TNButtonBar/buttonBarRightBezelHighlighted.png"] size:CGSizeMake(2, 26)];
    var buttonBezelHighlighted = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:[leftBezelHighlighted, centerBezelHighlighted, rightBezelHighlighted] isVertical:NO]];
    
    [buttonBarLeft setValue:bezelColor forThemeAttribute:"bezel-color"];
    [buttonBarLeft setValue:buttonBezel forThemeAttribute:"button-bezel-color"];
    [buttonBarLeft setValue:buttonBezelHighlighted forThemeAttribute:"button-bezel-color" inState:CPThemeStateHighlighted];
    
    var plusButton  = [[TNButtonBarPopUpButton alloc] initWithFrame:CPRectMake(0,0,30, 30)];//[CPButtonBar plusButton];
    var plusMenu    = [[CPMenu alloc] init];
    [plusButton setTarget:self];
    [plusButton setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"gear.png"] size:CPSizeMake(20, 20)]];
    [plusButton setBordered:NO];
    [plusButton setImagePosition:CPImageOnly];
    
    [plusMenu addItemWithTitle:@"Add a contact" action:@selector(addContact:) keyEquivalent:@""];
    [plusMenu addItemWithTitle:@"Add a group" action:@selector(addGroup:) keyEquivalent:@""];
    [plusButton setMenu:plusMenu];
    
    var minusButton = [CPButtonBar minusButton];
    [minusButton setTarget:self];
    [minusButton setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"minus.png"] size:CPSizeMake(20, 20)]];
    [minusButton setAction:@selector(didMinusBouttonClicked:)];
    
    [buttonBarLeft setButtons:[plusButton, minusButton]];
    
    
    [viewLoadingModule setBackgroundColor:[CPColor colorWithHexString:@"D3DADF"]];
    
    // copyright;
    [self copyright];
    
}

- (IBAction)didMinusBouttonClicked:(id)sender
{
    var index   = [[_rosterOutlineView selectedRowIndexes] firstIndex];
    var item    = [_rosterOutlineView itemAtRow:index];
    
    if ([item class] == TNStropheContact)
        [self deleteContact:sender];
    else if ([item class] == TNStropheGroup)
        [self deleteGroup:sender];
}

- (void)makeMainMenu
{
    _mainMenu = [[CPMenu alloc] init];
    
    var archipelItem    = [_mainMenu addItemWithTitle:@"Archipel" action:nil keyEquivalent:@""];
    var contactsItem    = [_mainMenu addItemWithTitle:@"Contacts" action:nil keyEquivalent:@""];
    var groupsItem      = [_mainMenu addItemWithTitle:@"Groups" action:nil keyEquivalent:@""];
    var statusItem      = [_mainMenu addItemWithTitle:@"Status" action:nil keyEquivalent:@""];
    var navigationItem  = [_mainMenu addItemWithTitle:@"Navigation" action:nil keyEquivalent:@""];
    var moduleItem      = [_mainMenu addItemWithTitle:@"Modules" action:nil keyEquivalent:@""];
    var helpItem        = [_mainMenu addItemWithTitle:@"Help" action:nil keyEquivalent:@""];
    
    // Archipel
    var archipelMenu = [[CPMenu alloc] init];
    [archipelMenu addItemWithTitle:@"About Archipel" action:nil keyEquivalent:@""];
    [archipelMenu addItem:[CPMenuItem separatorItem]];
    [archipelMenu addItemWithTitle:@"Preferences" action:nil keyEquivalent:@""];
    [archipelMenu addItem:[CPMenuItem separatorItem]];
    [archipelMenu addItemWithTitle:@"Log out" action:@selector(logout:) keyEquivalent:@"q"];
    [archipelMenu addItemWithTitle:@"Quit" action:nil keyEquivalent:@""];
    [_mainMenu setSubmenu:archipelMenu forItem:archipelItem];
    
    // Groups
    var groupsMenu = [[CPMenu alloc] init];
    [groupsMenu addItemWithTitle:@"Add group" action:@selector(addGroup:) keyEquivalent:@"G"];
    [groupsMenu addItemWithTitle:@"Delete group" action:@selector(deleteGroup:) keyEquivalent:@"D"];
    [groupsMenu addItem:[CPMenuItem separatorItem]];
    [groupsMenu addItemWithTitle:@"Rename group" action:@selector(renameGroup:) keyEquivalent:@""];
    [_mainMenu setSubmenu:groupsMenu forItem:groupsItem];
    
    // Contacts
    var contactsMenu = [[CPMenu alloc] init];
    [contactsMenu addItemWithTitle:@"Add contact" action:@selector(addContact:) keyEquivalent:@"n"];
    [contactsMenu addItemWithTitle:@"Delete contact" action:@selector(deleteContact:) keyEquivalent:@"d"];
    [contactsMenu addItem:[CPMenuItem separatorItem]];
    [contactsMenu addItemWithTitle:@"Rename contact" action:@selector(renameContact:) keyEquivalent:@"R"];
    [contactsMenu addItem:[CPMenuItem separatorItem]];
    [contactsMenu addItemWithTitle:@"Reload vCard" action:@selector(reloadContactVCard:) keyEquivalent:@""];
    [_mainMenu setSubmenu:contactsMenu forItem:contactsItem];
    
    // Status
    var statusMenu = [[CPMenu alloc] init];
    [statusMenu addItemWithTitle:@"Set status available" action:nil keyEquivalent:@"1"];
    [statusMenu addItemWithTitle:@"Set status away" action:nil keyEquivalent:@"2"];
    [statusMenu addItemWithTitle:@"Set status busy" action:nil keyEquivalent:@"3"];
    [statusMenu addItem:[CPMenuItem separatorItem]];
    [statusMenu addItemWithTitle:@"Set custom status" action:nil keyEquivalent:@""];
    [_mainMenu setSubmenu:statusMenu forItem:statusItem];
    
    // navigation
    var navigationMenu = [[CPMenu alloc] init];
    [navigationMenu addItemWithTitle:@"Hide main menu" action:@selector(switchMainMenu:) keyEquivalent:@"U"];
    [navigationMenu addItemWithTitle:@"Search entity" action:@selector(focusFilter:) keyEquivalent:@"F"];
    [navigationMenu addItem:[CPMenuItem separatorItem]];
    [navigationMenu addItemWithTitle:@"Select next entity" action:@selector(selectNextEntity:) keyEquivalent:@"]"];
    [navigationMenu addItemWithTitle:@"Select previous entity" action:@selector(selectPreviousEntity:) keyEquivalent:@"["];
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
    var helpMenu = [[CPMenu alloc] init];
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
    
    _tempNumberOfReadyModules = -1;
}

/*! delegate of TNModuleLoader sent when all modules are loaded
*/
- (void)moduleLoaderLoadingComplete:(TNModuleLoader)aLoader
{
    //connection window
    CPLog.trace(@"positionnig the connectionWindow");
    [windowModuleLoading orderOut:nil];
    [connectionWindow center];
    [connectionWindow makeKeyAndOrderFront:nil];
}

/*! delegate of TNModuleLoader sent when a module is loaded
*/
- (void)moduleLoader:(TNModuleLoader)aLoader hasLoadBundle:(CPBundle)aBundle
{
    CPLog.info("Loading complete for bundle " + aBundle);
}


- (IBAction)logout:(id)sender
{
    var defaults = [TNUserDefaults standardUserDefaults];
    
    [defaults removeObjectForKey:@"loginPassword"];
    [defaults setBool:NO forKey:@"loginRememberCredentials"];
    
    CPLog.info(@"starting to disconnect");
    [_mainRoster disconnect];
    
    [CPMenu setMenuBarVisible:NO];
}

- (IBAction)addContact:(id)sender
{
    [addContactWindow setRoster:_mainRoster];
    [addContactWindow makeKeyAndOrderFront:nil];
}

- (IBAction)deleteContact:(id)sender
{
    var index   = [[_rosterOutlineView selectedRowIndexes] firstIndex];
    var item    = [_rosterOutlineView itemAtRow:index];
    
    if ([item class] != TNStropheContact)
    {
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"User supression" message:@"You must choose a contact" icon:TNGrowlIconError];
        return;
    }
    
    var alert   = [[TNAlertRemoveContact alloc] initWithJID:[item JID] roster:_mainRoster];
    if (alert)
    {
        [alert runModal];
    }
}

- (IBAction)addGroup:(id)sender
{
    [addGroupWindow setRoster:_mainRoster];
    [addGroupWindow makeKeyAndOrderFront:nil];
}

- (IBAction)deleteGroup:(id)sender
{
    var growl = [TNGrowlCenter defaultCenter];
    
    var index   = [[_rosterOutlineView selectedRowIndexes] firstIndex];
    var item    = [_rosterOutlineView itemAtRow:index];
    
    if ([item class] == TNStropheGroup)
    {
        if ([[item contacts] count] == 0)
        {
            [_mainRoster removeGroup:item];
            [_rosterOutlineView reloadData];
            [growl pushNotificationWithTitle:@"Group supression" message:@"The group has been removed"];
        }
        else
        {
            [growl pushNotificationWithTitle:@"Group supression" message:@"The group must be empty" icon:TNGrowlIconError];
        }
    }
    else
    {
       [growl pushNotificationWithTitle:@"Group supression" message:@"You must choose a group" icon:TNGrowlIconError]; 
    }
}

- (IBAction)selectNextEntity:(id)sender
{
    var selectedIndex   = [[_rosterOutlineView selectedRowIndexes] firstIndex];
    var nextIndex       = (selectedIndex + 1) > [_rosterOutlineView numberOfRows] - 1 ? 0 : (selectedIndex + 1);
    
    [_rosterOutlineView selectRowIndexes:[CPIndexSet indexSetWithIndex:nextIndex] byExtendingSelection:NO];
}

- (IBAction)selectPreviousEntity:(id)sender
{
    var selectedIndex   = [[_rosterOutlineView selectedRowIndexes] firstIndex];
    var nextIndex       = (selectedIndex - 1) < 0 ? [_rosterOutlineView numberOfRows] -1 : (selectedIndex - 1);
    
    [_rosterOutlineView selectRowIndexes:[CPIndexSet indexSetWithIndex:nextIndex] byExtendingSelection:NO];
    
}

- (IBAction)renameContact:(id)sender
{
    [[propertiesView entryName] mouseDown:nil];
}

- (IBAction)focusFilter:(id)sender
{
    [filterField mouseDown:nil];
}

- (IBAction)expandGroup:(id)sender
{
    var index       = [_rosterOutlineView selectedRowIndexes];
    
    if ([index firstIndex] == -1)
        return;
    
    var item        = [_rosterOutlineView itemAtRow:[index firstIndex]];
    
    [_rosterOutlineView expandItem:item];
}

- (IBAction)collapseGroup:(id)sender
{
    var index = [_rosterOutlineView selectedRowIndexes];
    
    if ([index firstIndex] == -1)
        return;
    
    var item = [_rosterOutlineView itemAtRow:[index firstIndex]];
    
    [_rosterOutlineView collapseItem:item];
}

- (IBAction)expandAllGroups:(id)sender
{
    [_rosterOutlineView expandAll];
}

- (IBAction)collapseAllGroups:(id)sender
{
    [_rosterOutlineView collapseAll];
}

- (IBAction)reloadContactVCard:(id)sender
{
    //
}

- (IBAction)openWebsite:(id)sender
{
    window.open("http://archipelproject.org");
}

- (IBAction)openDonationPage:(id)sender
{
    window.open("http://antoinemercadal.fr/archipelblog/donate/");
}

- (IBAction)openBugTracker:(id)sender
{
    window.open("http://bitbucket.org/primalmotion/archipel/issues/new");
}

- (IBAction)renameGroup:(id)sender
{
    [[propertiesView entryName] mouseDown:nil];
}

- (IBAction)switchMainMenu:(id)sender
{
    if ([CPMenu menuBarVisible])
        [CPMenu setMenuBarVisible:NO];
    else
        [CPMenu setMenuBarVisible:YES];
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
    Trigger on add JID item click
    To have more information about the toolbar, see TNToolbar

    @param sender the sender of the action (the CPToolbarItem)
*/
- (IBAction)toolbarItemAddContactClick:(id)sender
{
    [self addContact:sender];
}

/*! Delegate of toolbar imutables toolbar items.
    Trigger on delete JID item click
    To have more information about the toolbar, see TNToolbar

    @param sender the sender of the action (the CPToolbarItem)
*/
- (IBAction)toolbarItemDeleteContactClick:(id)sender
{
    [self deleteContact:sender]
}

/*! Delegate of toolbar imutables toolbar items.
    Trigger on add group item click
    To have more information about the toolbar, see TNToolbar
*/
- (IBAction)toolbarItemAddGroupClick:(id)sender
{
    [self addGroup:sender];
}

/*! Delegate of toolbar imutables toolbar items.
    Trigger on delete group item click
    NOT IMPLEMENTED
    To have more information about the toolbar, see TNToolbar
*/
- (IBAction)toolbarItemDeleteGroupClick:(id)sender
{
    [self deleteGroup:sender];
}

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
        
        _helpWindow     = [[CPWindow alloc] initWithContentRect:CGRectMake(0,0,950,600) styleMask:CPTitledWindowMask|CPClosableWindowMask|CPMiniaturizableWindowMask|CPResizableWindowMask|CPBorderlessBridgeWindowMask];
        var scrollView  = [[CPScrollView alloc] initWithFrame:[[_helpWindow contentView] bounds]];
        
        [_helpWindow setPlatformWindow:_platformHelpWindow];
        [_platformHelpWindow makeKeyAndOrderFront:nil];
        
        [_helpWindow setDelegate:self];
        [helpView setFrame:[[scrollView contentView] bounds]];
        [scrollView setAutohidesScrollers:YES];
        [scrollView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
        [scrollView setDocumentView:helpView];

        [[_helpWindow contentView] addSubview:scrollView];
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
    var xmppStatus;
    var statusLabel = [sender title];
    
    switch (statusLabel)
    {
        case TNArchipelStatusAvailableLabel:
            xmppStatus = TNStropheContactStatusOnline
            break;
        case TNArchipelStatusAwayLabel:
            xmppStatus = TNStropheContactStatusAway
            break;
        case TNArchipelStatusBusyLabel:
            xmppStatus = TNStropheContactStatusBusy
            break;
    }
    
    var presence    = [TNStropheStanza presenceWithAttributes:{}];
    [presence addChildName:@"status"];
    [presence addTextNode:statusLabel];
    [presence up]
    [presence addChildName:@"show"];
    [presence addTextNode:xmppStatus];
    CPLog.info("Changing presence to " + statusLabel + ":" + xmppStatus);
    
    var growl = [TNGrowlCenter defaultCenter];
    [growl pushNotificationWithTitle:@"Status" message:@"Your status is now " + statusLabel];
    
    [[_mainRoster connection] send:presence];
}

/*! Delegate for CPWindow.
    Tipically set _helpWindow to nil on closes.
*/
- (void)windowWillClose:(CPWindow)aWindow
{
    if (aWindow == _helpWindow)
    {
        _helpWindow = nil;
    }
}

/*! Notification responder of TNStropheConnection
    will be performed on login
    @param aNotification the received notification. This notification will contains as object the TNStropheConnection
*/
- (void)loginStrophe:(CPNotification)aNotification
{
    [connectionWindow orderOut:nil];
    [theWindow makeKeyAndOrderFront:nil];

    _mainRoster = [[TNDatasourceRoster alloc] initWithConnection:[aNotification object]];
    [_mainRoster setDelegate:self];
    [_mainRoster setFilterField:filterField];
    [propertiesView setRoster:_mainRoster];
    
    
    [_mainRoster getRoster];
    
    [CPMenu setMenuBarVisible:YES];
    
    [_moduleLoader setRosterForToolbarItems:_mainRoster andConnection:[aNotification object]];
    
    var user = [[_mainRoster connection] JID];
    
    [[_mainRoster connection] rawInputRegisterSelector:@selector(stropheConnectionRawIn:) ofObject:self];
    [[_mainRoster connection] rawOutputRegisterSelector:@selector(stropheConnectionRawOut:) ofObject:self];
    
    var growl = [TNGrowlCenter defaultCenter];
    [growl pushNotificationWithTitle:@"Welcome" message:@"Welcome back " + user];
}

- (void)stropheConnectionRawIn:(TNStropheStanza)aStanza
{
    [ledIn setImage:_imageLedInData];
    
    if (_ledInTimer)
        [_ledInTimer invalidate];
    
    _ledInTimer = [CPTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(timeOutDataLed:) userInfo:ledIn repeats:NO];
}

- (void)stropheConnectionRawOut:(TNStropheStanza)aStanza
{
    [ledOut setImage:_imageLedOutData];
    
    if (_ledOutTimer)
        [_ledOutTimer invalidate];
    _ledOutTimer = [CPTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(timeOutDataLed:) userInfo:ledOut repeats:NO];
}

- (void)timeOutDataLed:(CPTimer)aTimer
{
    [[aTimer userInfo] setImage:_imageLedNoData];
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

/*! Notification responder for CPApplicationWillTerminateNotification
*/
- (void)onApplicationTerminate:(CPNotification)aNotification
{
    [_mainRoster disconnect];
}


/*! Delegate method of main TNStropheRoster.
    will be performed when a subscription request is sent
    @param requestStanza TNStropheStanza cotainining the subscription request
*/
- (void)didReceiveSubscriptionRequest:(id)requestStanza
{
    var presenceAlert = [[TNAlertPresenceSubscription alloc] initWithStanza:requestStanza roster:_mainRoster];
    
    [presenceAlert runModal];
}


/*! Display the helpView in the rightView
*/
- (void)showHelpView
{
    if (![helpView mainFrameURL])
    {
        var bundle  = [CPBundle mainBundle];
        var url     = [bundle objectForInfoDictionaryKey:@"TNHelpWindowURL"];
        var version = [bundle objectForInfoDictionaryKey:@"TNArchipelVersion"];
        
        if (!url || (url == @"local"))
            url = @"help/index.html";
        
        [helpView setMainFrameURL:[bundle pathForResource:url] + "?version=" + version];
    }
    
    
    [helpView setFrame:[rightView bounds]];
    [rightView addSubview:helpView];
    
    var animView    = [CPDictionary dictionaryWithObjectsAndKeys:helpView, CPViewAnimationTargetKey, CPViewAnimationFadeInEffect, CPViewAnimationEffectKey];
    var anim        = [[CPViewAnimation alloc] initWithViewAnimations:[animView]];
    
    [anim setDuration:0.3];
    // [anim startAnimation];
}

/*! Hide the helpView from the rightView
*/
- (void)hideHelpView
{
    [helpView removeFromSuperview];
}

/*! Delegate of TNOutlineView
    will be performed when selection changes. Tab Modules displaying
    if managed by this message
    @param aNotification the received notification
*/
- (void)outlineViewSelectionDidChange:(CPNotification)notification
{
    var index       = [[_rosterOutlineView selectedRowIndexes] firstIndex];
    var item        = [_rosterOutlineView itemAtRow:index];
    var loadDelay   = parseFloat([[CPBundle mainBundle] objectForInfoDictionaryKey:@"TNArchipelModuleLoadingDelay"]);
    
    if (_moduleLoadingDelay)
        [_moduleLoadingDelay invalidate];
    
    [viewLoadingModule setFrame:[rightView bounds]];
    [rightView addSubview:viewLoadingModule];
    
    // [_mainRoster setCurrentItem:item];
    [propertiesView setEntity:item];
    [propertiesView reload];
    
    _moduleLoadingDelay = [CPTimer scheduledTimerWithTimeInterval:loadDelay target:self selector:@selector(performModuleChange:) userInfo:item repeats:NO];
}

- (void)performModuleChange:(CPTimer)aTimer
{
    if ([_rosterOutlineView numberOfSelectedRows] == 0)
    {
        [self showHelpView];
        [_mainRoster setCurrentItem:nil];
        [propertiesView hide];
        return;
    }
    
    var item        = [aTimer userInfo];
    var defaults    = [TNUserDefaults standardUserDefaults];
    
    // if (item == [_moduleLoader entity])
    //     return;
    
    [_mainRoster setCurrentItem:item];
    
    [self hideHelpView];
    
    if ([item class] == TNStropheGroup)
    {
        CPLog.info(@"setting the entity as " + item + " of type group");
        [_moduleLoader setEntity:item ofType:@"group" andRoster:_mainRoster];
        return;
    }
    else if ([item class] == TNStropheContact)
    {
        var vCard       = [item vCard];
        var entityType  = [_moduleLoader analyseVCard:vCard];

        CPLog.info(@"setting the entity as " + item + " of type " + entityType);
        [_moduleLoader setEntity:item ofType:entityType andRoster:_mainRoster];
        
    }
}


/*! Delegate of mainSplitView
*/
- (void)splitViewDidResizeSubviews:(CPNotification)aNotification
{
    var defaults    = [TNUserDefaults standardUserDefaults];
    var splitView   = [aNotification object];
    var newWidth    = [splitView rectOfDividerAtIndex:0].origin.x;
    
    CPLog.info(@"setting the mainSplitViewPosition value in defaults");
    [defaults setInteger:newWidth forKey:@"mainSplitViewPosition"];
}

- (void)allModuleReady:(CPNotification)aNotification
{
    if ([viewLoadingModule superview])
        [viewLoadingModule removeFromSuperview];
}


- (void)copyright
{
    var bundle = [CPBundle bundleForClass:[self class]];
    
    var copy = document.createElement("div");
    copy.style.position = "absolute";
    copy.style.fontSize = "10px";
    copy.style.color = "#5a5a5a";
    copy.style.width = "300px";
    copy.style.bottom = "8px";
    copy.style.left = "50%";
    copy.style.textAlign = "center";
    copy.style.marginLeft = "-150px";
    copy.style.textShadow = "0px 1px 0px white";
    copy.innerHTML =  [bundle objectForInfoDictionaryKey:@"TNArchipelVersion"] + @" - " + [bundle objectForInfoDictionaryKey:@"TNArchipelCopyright"];
    document.body.appendChild(copy);
    
}
@end
