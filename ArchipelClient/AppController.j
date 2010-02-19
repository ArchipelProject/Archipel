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

@import "TNAlertPresenceSubscription.j"
@import "TNAlertRemoveContact.j"
@import "TNDatasourceRoster.j"
@import "TNOutlineViewRoster.j"
@import "StropheCappuccino/TNStropheRoster.j"
@import "TNToolbar.j"
@import "TNViewHypervisorControl.j"
@import "TNViewHypervisorControl.j"
@import "TNViewLog.j"
@import "TNViewProperties.j"
@import "TNWindowAddContact.j"
@import "TNWindowAddGroup.j"
@import "TNWindowConnection.j"

logger = nil;

@implementation AppController : CPObject
{
	@outlet CPView				leftView;	
	@outlet CPView              filterView;
	@outlet CPTextField         filterField;
	@outlet CPScrollView		rightView;
    @outlet CPSplitView         leftSplitView;
    @outlet CPWindow            theWindow;
	@outlet TNViewLog           logView;        
	@outlet TNViewProperties    propertiesView;
	@outlet TNWindowAddContact  addContactWindow;
	@outlet TNWindowAddGroup    addGroupWindow;
    @outlet TNWindowConnection  connectionWindow;
		
	TNDatasourceRoster          mainRoster;
	TNOutlineViewRoster		    rosterOutlineView;
	TNToolbar		            hypervisorToolbar;
    TNViewHypervisorControl     currentRightViewContent;
    
    BOOL    connected   @accessors(getter=isConnected, setter=setConnected:);
}

 // initialization
- (void)applicationDidFinishLaunching:(CPNotification)aNotification 
{
     [self setConnected:NO];
}

- (void)awakeFromCib
{
    //hide main window
    [theWindow orderOut:nil];
    
    // toolbar
    hypervisorToolbar = [[TNToolbar alloc] initWithTarget:self];
    [theWindow setToolbar:hypervisorToolbar];
    
    //outlineview
    rosterOutlineView = [[TNOutlineViewRoster alloc] initWithFrame:CGRectMake(5,5,0,0)];    
    [rosterOutlineView setDelegate:self];
    
    // logger view
    [logView setBackgroundColor:[CPColor colorWithHexString:@"EEEEEE"]];
    logger = logView;
    
    // init scroll view of the outline view
	var scrollView = [[CPScrollView alloc] initWithFrame:[leftView bounds]];
	[scrollView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
	[scrollView setAutohidesScrollers:YES];
	[[scrollView contentView] setBackgroundColor:[CPColor colorWithHexString:@"D8DFE8"]];
	[scrollView addSubview:rosterOutlineView];
	[scrollView setDocumentView:rosterOutlineView];
    [[self leftView] addSubview:scrollView];
    
    // right view
    [[self rightView] setBackgroundColor:[CPColor colorWithHexString:@"EEEEEE"]];
    [[self rightView] setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [[self leftView] setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    
    //connection window
    [[self connectionWindow] center];
    [[self connectionWindow] orderFront:nil];
    
   
    // properties view
    [[self leftSplitView] setIsPaneSplitter:YES];
    [[self leftSplitView] setBackgroundColor:[CPColor colorWithHexString:@"D8DFE8"]];
    [[[self leftSplitView] subviews][1] removeFromSuperview];
    [[self leftSplitView] addSubview:[self propertiesView]];
    [[self propertiesView] setParentSplitView:[self leftSplitView]];
    

    // filter view. it is unused for now.
    [[self filterView] setBackgroundColor:[CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:@"Resources/gradientGray.png"]]];
    

    // notifications
    var center = [CPNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(loginStrophe:) name:TNStropheConnectionSuccessNotification object:[self connectionWindow]];
    [center addObserver:self selector:@selector(logoutStrophe:) name:TNStropheDisconnectionNotification object:nil];
}


// utilities
- (void)loadHypervisorControlPanelForItem:(TNHypervisor)item 
{
    var controller = [[CPViewController alloc] initWithCibName: @"HypervisorControlView" bundle:[CPBundle mainBundle]];
    currentRightViewContent = [controller view];
    
    [currentRightViewContent setFrame:[[rightView contentView] frame]];
    [currentRightViewContent setAutoresizingMask: CPViewWidthSizable];
    [currentRightViewContent setHypervisor:item andRoster:mainRoster];
    
    [currentRightViewContent setBackgroundColor:[CPColor colorWithHexString:@"EEEEEE"]];
    [rightView setDocumentView:currentRightViewContent]
}


// Toolbar actions
- (IBAction)toolbarItemLogoutClick:(id)sender 
{
    [mainRoster disconnect];
}

- (IBAction)toolbarItemAddContactClick:(id)sender 
{
    [[self addContactWindow] setRoster:mainRoster];
    [[self addContactWindow] orderFront:nil];
}

- (IBAction)toolbarItemDeleteContactClick:(id)sender 
{
    var index   = [[rosterOutlineView selectedRowIndexes] firstIndex];
    var theJid  = [rosterOutlineView itemAtRow:index];
    var alert   = [[TNAlertRemoveContact alloc] initWithJid:[theJid jid] roster:mainRoster];
    
    if (alert)
        [alert runModal];
}

- (IBAction)toolbarItemAddGroupClick:(id)sender 
{
    [[self addGroupWindow] setRoster:mainRoster];
    [[self addGroupWindow] orderFront:nil];
}


// strophe 
- (void)loginStrophe:(CPNotification)aNotification 
{
    [[self logView] log:"strophe connected notif received"];
    [[self connectionWindow] orderOut:nil];
    [[self theWindow] orderFront:nil];
    [self setConnected:YES];
    
    mainRoster = [[TNDatasourceRoster alloc] initWithConnection:[aNotification userInfo]];
    [mainRoster setDelegate:self];
    [mainRoster setFilterField:[self filterField]];
    [[self propertiesView] setRoster:mainRoster];
    // ask roster
    [mainRoster getRoster];
}

- (void)logoutStrophe:(CPNotification)aNotification 
{
    [[self logView] log:"strophe disconnection notif received"];
    [[self theWindow] orderOut:nil];
    [[self connectionWindow] orderFront:nil];
    [self setConnected:NO];
}

- (void)onMessage:(id)message 
{
    var theMessage = [[TNStropheMessage alloc] initWithStropheMessage:message];
    
    [[self logView] log:@"Message from: " + [theMessage from] + " : " + [theMessage message]];
}


// roster delegates
- (void)didReceiveSubscriptionRequest:(id)requestStanza 
{
    var alert = [[TNAlertPresenceSubscription alloc] initWithStanza:requestStanza roster:mainRoster];
    
    [alert runModal];
}


// outline view delegate
- (void)outlineViewSelectionDidChange:(CPNotification)notification 
{
   var index    = [rosterOutlineView selectedRowIndexes];
   var item     = [rosterOutlineView itemAtRow:[index firstIndex]];
   
   [self loadHypervisorControlPanelForItem:item];
   [[self propertiesView] setEntry:item];
   [[self propertiesView] reload];
}





@end
