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
// @import "TNQuickEditView.j";
@import "TNGrowl.j";

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
    @outlet CPSearchField       filterField                 @accessors;
    @outlet CPView              rightView                   @accessors;
    @outlet CPWebView           helpView                    @accessors;
    @outlet CPSplitView         leftSplitView               @accessors;
    @outlet CPWindow            theWindow                   @accessors;
    @outlet CPWindow            windowModuleLoading         @accessors;
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
    BOOL                        _shouldShowHelpView;
    CPWindow                    _helpWindow;
}

/*! This method initialize the content of the GUI when the CIB file
    as finished to load.
*/
- (void)awakeFromCib
{
    CPLogRegister(CPLogConsole);
    var bundle      = [CPBundle bundleForClass:self];
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
    
    //hide main window
    [theWindow orderOut:nil];
    
    // toolbar
    CPLog.trace("initializing mianToolbar");
    _mainToolbar = [[TNToolbar alloc] initWithTarget:self];
    [theWindow setToolbar:_mainToolbar];

    //outlineview
    CPLog.trace(@"initializing _rosterOutlineView");
    _rosterOutlineView = [[TNOutlineViewRoster alloc] initWithFrame:[leftView bounds]];
    [_rosterOutlineView setDelegate:self];
    [_rosterOutlineView registerForDraggedTypes:[TNDragTypeContact]];

    // init scroll view of the outline view
    CPLog.trace(@"initializing _outlineScrollView");
    _outlineScrollView = [[CPScrollView alloc] initWithFrame:[leftView bounds]];
    [_outlineScrollView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [_outlineScrollView setAutohidesScrollers:YES];
    [[_outlineScrollView contentView] setBackgroundColor:[CPColor colorWithHexString:@"D8DFE8"]]; //D8DFE8
    [_outlineScrollView setDocumentView:_rosterOutlineView];

    CPLog.trace(@"adding _outlineScrollView as subview of leftView");
    [leftView addSubview:_outlineScrollView];

    // right view
    CPLog.trace(@"initializing rightView");
    [rightView setBackgroundColor:[CPColor colorWithHexString:@"EEEEEE"]];
    [rightView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];

    // properties view
    CPLog.trace(@"initializing the leftSplitView");
    [leftSplitView setIsPaneSplitter:YES];
    [leftSplitView setBackgroundColor:[CPColor colorWithHexString:@"D8DFE8"]];
    [[leftSplitView subviews][1] removeFromSuperview];
    [leftSplitView addSubview:propertiesView];
    [leftSplitView setPosition:[leftSplitView bounds].size.height ofDividerAtIndex:0];

    // filter view.
    CPLog.trace(@"initializing the filterView");
    [filterView setBackgroundColor:[CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"gradientGray.png"]]]];

    //tab module view
    CPLog.trace(@"initializing the _moduleTabView");
    _moduleTabView = [[CPTabView alloc] initWithFrame:[rightView bounds]];
    [_moduleTabView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [_moduleTabView setBackgroundColor:[CPColor whiteColor]];
    [rightView addSubview:_moduleTabView];

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
    [windowModuleLoading center]
    [windowModuleLoading orderFront:nil];
    CPLog.trace(@"initializing _moduleLoader");
    _moduleLoader = [[TNModuleLoader alloc] init]
    
    [_moduleLoader setDelegate:self];
    
    [_moduleTabView setDelegate:_moduleLoader];
    [_moduleLoader setMainToolbar:_mainToolbar];
    [_moduleLoader setMainTabView:_moduleTabView];
    [_moduleLoader setModulesPath:@"Modules/"]
    [_moduleLoader setMainRightView:rightView];

    CPLog.trace(@"loading all modules");
    [_moduleLoader load];


    _shouldShowHelpView = YES;
    [self showHelpView];
    
    // notifications
    var center = [CPNotificationCenter defaultCenter];

    CPLog.trace(@"registering for notification TNStropheConnectionSuccessNotification");
    [center addObserver:self selector:@selector(loginStrophe:) name:TNStropheConnectionStatusConnected object:nil];
    
    CPLog.trace(@"registering for notification TNStropheDisconnectionNotification");
    [center addObserver:self selector:@selector(logoutStrophe:) name:TNStropheConnectionStatusDisconnecting object:nil];
    
    CPLog.trace(@"registering for notification CPApplicationWillTerminateNotification");
    [center addObserver:self selector:@selector(onApplicationTerminate:) name:CPApplicationWillTerminateNotification object:nil];
    
    CPLog.info(@"AppController initialized");
    
    var bg = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"growl-bg.png"]]];
    var defaultIcon = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"growl-info.png"]];
    var growl = [TNGrowlCenter defaultCenter];
    [growl setView:rightView];
    [growl setDefaultIcon:defaultIcon];
    [growl setBackgroundColor:bg]
}

/*! delegate of TNModuleLoader sent when all modules are loaded
*/
- (void)moduleLoaderLoadingComplete:(TNModuleLoader)aLoader
{
    //connection window
    CPLog.trace(@"positionnig the connectionWindow");
    [windowModuleLoading orderOut:nil];
    [connectionWindow center];
    [connectionWindow orderFront:nil];
}

/*! delegate of TNModuleLoader sent when a module is loaded
*/
- (void)moduleLoader:(TNModuleLoader)aLoader hasLoadBundle:(CPBundle)aBundle
{
    CPLog.info("Loading complete for bundle " + aBundle);
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
    [addContactWindow setRoster:_mainRoster];
    [addContactWindow orderFront:nil];
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
    {
        [alert runModal];
    }
}

/*! Delegate of toolbar imutables toolbar items.
    Trigger on add group item click
    To have more information about the toolbar, see TNToolbar
*/
- (IBAction)toolbarItemAddGroupClick:(id)sender
{
    [addGroupWindow setRoster:_mainRoster];
    [addGroupWindow orderFront:nil];
}

/*! Delegate of toolbar imutables toolbar items.
    Trigger on delete group item click
    NOT IMPLEMENTED
    To have more information about the toolbar, see TNToolbar
*/
- (IBAction)toolbarItemDeleteGroupClick:(id)sender
{
    var growl = [TNGrowlCenter defaultCenter];
    [growl pushNotificationWithTitle:@"Not implemented" message:@"This function is not implemented" icon:nil];
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
        _helpWindow     = [[CPWindow alloc] initWithContentRect:CGRectMake(0,0,950,600) styleMask:CPTitledWindowMask|CPClosableWindowMask|CPMiniaturizableWindowMask|CPResizableWindowMask];
        var scrollView  = [[CPScrollView alloc] initWithFrame:[[_helpWindow contentView] bounds]];
        
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
    [growl pushNotificationWithTitle:@"Status" message:@"Your status is now " + statusLabel icon:nil];
    
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
    [theWindow orderFront:nil];

    _mainRoster = [[TNDatasourceRoster alloc] initWithConnection:[aNotification object]];
    [_mainRoster setDelegate:self];
    [_mainRoster setFilterField:filterField];
    [propertiesView setRoster:_mainRoster];
    [_mainRoster getRoster];

    [_moduleLoader setRosterForToolbarItems:_mainRoster andConnection:[aNotification object]];
    
    var user = [[_mainRoster connection] jid];
    
    var growl = [TNGrowlCenter defaultCenter];
    [growl pushNotificationWithTitle:@"Welcome" message:@"Welcome back " + user icon:nil];
}

/*! Notification responder of TNStropheConnection
    will be performed on logout

    @param aNotification the received notification. This notification will contains as object the TNStropheConnection
*/
- (void)logoutStrophe:(CPNotification)aNotification
{
    [theWindow orderOut:nil];
    [connectionWindow orderFront:nil];
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
    try
    {
        var index       = [_rosterOutlineView selectedRowIndexes];
        
        if ([index firstIndex] == -1)
        {
            [self showHelpView];
            return;
        }
        
        [self hideHelpView];
        
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
        [propertiesView setContact:item];
        [propertiesView reload];
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
