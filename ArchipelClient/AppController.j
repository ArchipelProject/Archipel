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


/*! @ingroup archipelcore
    This is the main application controller. It is loaded from MainMenu.cib.
    Anyone that is interessted in the way of Archipel is working should begin
    to read this class. This is the main application entry point.
*/
@implementation AppController : CPObject
{
    @outlet CPView              leftView                    @accessors;
    @outlet CPView              filterView                  @accessors;
    @outlet CPSearchField       filterField                 @accessors;
    @outlet CPView              rightView                   @accessors;
    @outlet CPSplitView         leftSplitView               @accessors;
    @outlet CPWindow            theWindow                   @accessors;
    @outlet CPSplitView         mainHorizontalSplitView     @accessors;
    @outlet TNViewProperties    propertiesView              @accessors;
    @outlet TNWindowAddContact  addContactWindow            @accessors;
    @outlet TNWindowAddGroup    addGroupWindow              @accessors;
    @outlet TNWindowConnection  connectionWindow            @accessors;

    TNModuleLoader              _moduleLoader;
    CPTabView                   _moduleTabView;

    TNDatasourceRoster          _mainRoster;
    TNOutlineViewRoster         _rosterOutlineView;
    TNToolbar                   _mainToolbar;
    TNViewHypervisorControl     _currentRightViewContent;
    CPScrollView                _outlineScrollView;
}

/*! This method initialize the content of the GUI when the CIB file
    as finished to load.
*/
- (void)awakeFromCib
{
    CPLogRegister(CPLogConsole);
    
    var defaults = [TNUserDefaults standardUserDefaults];
    
    [mainHorizontalSplitView setIsPaneSplitter:YES];
    
    
    var posx;
    if (posx = [defaults integerForKey:@"mainSplitViewPosition"])
    {
        CPLog.trace("recovering with of main vertical CPSplitView from last state");
        [mainHorizontalSplitView setPosition:posx ofDividerAtIndex:0];

        var bounds = [[self leftView] bounds];
        bounds.size.width = posx;
        [[self leftView] setFrame:bounds];
        [[self leftView] setBackgroundColor:[CPColor redColor]]
    }
    [mainHorizontalSplitView setDelegate:self];    
    
    //hide main window
    [theWindow orderOut:nil];

    
    // toolbar
    CPLog.trace("initializing mianToolbar");
    _mainToolbar = [[TNToolbar alloc] initWithTarget:self];
    [theWindow setToolbar:_mainToolbar];

    //outlineview
    CPLog.trace(@"initializing _rosterOutlineView");
    _rosterOutlineView = [[TNOutlineViewRoster alloc] initWithFrame:[[self leftView] bounds]];
    [_rosterOutlineView setDelegate:self];
    [_rosterOutlineView registerForDraggedTypes:[TNDragTypeContact]];

    // init scroll view of the outline view
    CPLog.trace(@"initializing _outlineScrollView");
    _outlineScrollView = [[CPScrollView alloc] initWithFrame:[[self leftView] bounds]];
    [_outlineScrollView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [_outlineScrollView setAutohidesScrollers:YES];
    [[_outlineScrollView contentView] setBackgroundColor:[CPColor colorWithHexString:@"D8DFE8"]]; //D8DFE8
    [_outlineScrollView setDocumentView:_rosterOutlineView];

    CPLog.trace(@"adding _outlineScrollView as subview of leftView");
    [[self leftView] addSubview:_outlineScrollView];

    // right view
    CPLog.trace(@"initializing rightView");
    [[self rightView] setBackgroundColor:[CPColor colorWithHexString:@"EEEEEE"]];
    [[self rightView] setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];

    //connection window
    CPLog.trace(@"positionnig the connectionWindow");
    [[self connectionWindow] center];
    [[self connectionWindow] orderFront:nil];

    // properties view
    CPLog.trace(@"initializing the leftSplitView");
    [[self leftSplitView] setIsPaneSplitter:YES];
    [[self leftSplitView] setBackgroundColor:[CPColor colorWithHexString:@"D8DFE8"]];
    [[[self leftSplitView] subviews][1] removeFromSuperview];
    [[self leftSplitView] addSubview:[self propertiesView]];
    [[self leftSplitView] setPosition:[[self leftSplitView] bounds].size.height ofDividerAtIndex:0];

    // filter view.
    CPLog.trace(@"initializing the filterView");
    var bundle = [CPBundle bundleForClass:self];
    [[self filterView] setBackgroundColor:[CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"gradientGray.png"]]]];

    //tab module view
    CPLog.trace(@"initializing the _moduleTabView");
    _moduleTabView = [[CPTabView alloc] initWithFrame:[[self rightView] bounds]];
    [_moduleTabView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [_moduleTabView setBackgroundColor:[CPColor whiteColor]];
    [[self rightView] addSubview:_moduleTabView];

    // message in _moduleTabView
    var message = [CPTextField labelWithTitle:@"Entity is currently offline. You can't interract with it."];
    var bounds  = [_moduleTabView bounds];

    [message setFrame:CGRectMake(bounds.size.width / 2 - 300, 153, 600, 200)];
    [message setAutoresizingMask: CPViewMaxXMargin | CPViewMinXMargin];
    [message setAlignment:CPCenterTextAlignment]
    [message setFont:[CPFont boldSystemFontOfSize:18]];
    [message setTextColor:[CPColor grayColor]];
    [_moduleTabView addSubview:message];

    // module Loader
    CPLog.trace(@"initializing _moduleLoader");
    _moduleLoader = [[TNModuleLoader alloc] init]
    
    [_moduleTabView setDelegate:_moduleLoader];
    [_moduleLoader setMainToolbar:_mainToolbar];
    [_moduleLoader setMainTabView:_moduleTabView];
    [_moduleLoader setModulesPath:@"Modules/"]
    [_moduleLoader setMainRightView:[self rightView]];

    CPLog.trace(@"loading all modules");
    [_moduleLoader load];

    // notifications
    var center = [CPNotificationCenter defaultCenter];

    CPLog.trace(@"registering for notification TNStropheConnectionSuccessNotification");
    [center addObserver:self selector:@selector(loginStrophe:) name:TNStropheConnectionSuccessNotification object:[self connectionWindow]];
    
    CPLog.trace(@"registering for notification TNStropheDisconnectionNotification");
    [center addObserver:self selector:@selector(logoutStrophe:) name:TNStropheDisconnectionNotification object:nil];
    
    CPLog.info(@"AppController initialized");
}

/*! Delegate of toolbar imutables toolbar items.
    Trigger on logout item click
    To have more information about the toolbar, see TNToolbar

    @param sender the sender of the action (the CPToolbarItem)
*/
- (IBAction)toolbarItemLogoutClick:(id)sender
{
    var defaults = [TNUserDefaults standardUserDefaults];
    
    [defaults removeObjectForKey:@"loginPassword"];
    [defaults setBool:NO forKey:@"loginRememberCredentials"];
    
    CPLog.info(@"starting to disconnect");
    [_mainRoster disconnect];
}

/*! Delegate of toolbar imutables toolbar items.
    Trigger on add JID item click
    To have more information about the toolbar, see TNToolbar

    @param sender the sender of the action (the CPToolbarItem)
*/
- (IBAction)toolbarItemAddContactClick:(id)sender
{
    [[self addContactWindow] setRoster:_mainRoster];
    [[self addContactWindow] orderFront:nil];
}

/*! Delegate of toolbar imutables toolbar items.
    Trigger on delete JID item click
    To have more information about the toolbar, see TNToolbar

    @param sender the sender of the action (the CPToolbarItem)
*/
- (IBAction)toolbarItemDeleteContactClick:(id)sender
{
    var index   = [[_rosterOutlineView selectedRowIndexes] firstIndex];
    var theJid  = [_rosterOutlineView itemAtRow:index];
    var alert   = [[TNAlertRemoveContact alloc] initWithJid:[theJid jid] roster:_mainRoster];

    if (alert)
        [alert runModal];
}

/*! Delegate of toolbar imutables toolbar items.
    Trigger on add group item click
    To have more information about the toolbar, see TNToolbar
*/
- (IBAction)toolbarItemAddGroupClick:(id)sender
{
    [[self addGroupWindow] setRoster:_mainRoster];
    [[self addGroupWindow] orderFront:nil];
}

- (IBAction)toolbarItemDeleteGroupClick:(id)sender
{
    [CPException raise:@"NotImplemented" reason:@"This message is not implemented"];
}


/*! Notification responder of TNStropheConnection
    will be performed on login

    @param aNotification the received notification. This notification will contains as object the TNStropheConnection
*/
- (void)loginStrophe:(CPNotification)aNotification
{
    [[self connectionWindow] orderOut:nil];
    [[self theWindow] orderFront:nil];

    _mainRoster = [[TNDatasourceRoster alloc] initWithConnection:[aNotification userInfo]];
    [_mainRoster setDelegate:self];
    [_mainRoster setFilterField:[self filterField]];
    [[self propertiesView] setRoster:_mainRoster];
    [_mainRoster getRoster];

    [_moduleLoader setRosterForToolbarItems:_mainRoster andConnection:[aNotification object]];
}

/*! Notification responder of TNStropheConnection
    will be performed on logout

    @param aNotification the received notification. This notification will contains as object the TNStropheConnection
*/
- (void)logoutStrophe:(CPNotification)aNotification
{
    [[self theWindow] orderOut:nil];
    [[self connectionWindow] orderFront:nil];
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


/*! Delegate of TNOutlineView
    will be performed when selection changes. Tab Modules displaying
    if managed by this message

    @param aNotification the received notification
*/
- (void)outlineViewSelectionDidChange:(CPNotification)notification
{
    try
    {
        var index       = [_rosterOutlineView selectedRowIndexes];
        var item        = [_rosterOutlineView itemAtRow:[index firstIndex]];
        var defaults    = [TNUserDefaults standardUserDefaults];

        if ([item type] == "group")
            return; //[CPException raise:@"NotImplemented" reason:@"Group module are not implemented"]

        var vCard       = [item vCard];
        var entityType  = [_moduleLoader analyseVCard:vCard];

        CPLog.info(@"setting the entity as " + item + " of type " + entityType);
        [_moduleLoader setEntity:item ofType:entityType andRoster:_mainRoster];
        
    }
    catch(ex)
    {
        CPLog.error(ex);
    }
    finally
    {
        [[self propertiesView] setContact:item];
        [[self propertiesView] reload];
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

@end
