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
@import "StropheCappuccino/TNStrophe.j"
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
	@outlet CPView				leftView            @accessors;	
	@outlet CPView              filterView          @accessors;
	@outlet CPTextField         filterField         @accessors;
	@outlet CPScrollView		rightView           @accessors;
    @outlet CPSplitView         leftSplitView       @accessors;
    @outlet CPWindow            theWindow           @accessors;
	@outlet TNViewLog           logView             @accessors;        
	@outlet TNViewProperties    propertiesView      @accessors;
	@outlet TNWindowAddContact  addContactWindow    @accessors;
	@outlet TNWindowAddGroup    addGroupWindow      @accessors;
    @outlet TNWindowConnection  connectionWindow    @accessors;
		
	TNDatasourceRoster          _mainRoster;
	TNOutlineViewRoster		    _rosterOutlineView;
	TNToolbar		            _hypervisorToolbar;
    TNViewHypervisorControl     _currentRightViewContent;
    
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
    _hypervisorToolbar = [[TNToolbar alloc] initWithTarget:self];
    [theWindow setToolbar:_hypervisorToolbar];
    
    //outlineview
    _rosterOutlineView = [[TNOutlineViewRoster alloc] initWithFrame:CGRectMake(5,5,0,0)];    
    [_rosterOutlineView setDelegate:self];
    
    // logger view
    [logView setBackgroundColor:[CPColor colorWithHexString:@"EEEEEE"]];
    logger = logView;
    
    // init scroll view of the outline view
	var scrollView = [[CPScrollView alloc] initWithFrame:[leftView bounds]];
	[scrollView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
	[scrollView setAutohidesScrollers:YES];
	[[scrollView contentView] setBackgroundColor:[CPColor colorWithHexString:@"D8DFE8"]];
	[scrollView addSubview:_rosterOutlineView];
	[scrollView setDocumentView:_rosterOutlineView];
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
    _currentRightViewContent = [controller view];
    
    [_currentRightViewContent setFrame:[[rightView contentView] frame]];
    [_currentRightViewContent setAutoresizingMask: CPViewWidthSizable];
    [_currentRightViewContent setHypervisor:item andRoster:_mainRoster];
    
    //[_currentRightViewContent setBackgroundColor:[CPColor colorWithHexString:@"EEEEEE"]];
    [rightView setDocumentView:_currentRightViewContent]
}


// Toolbar actions
- (IBAction)toolbarItemLogoutClick:(id)sender 
{
    [_mainRoster disconnect];
}

- (IBAction)toolbarItemAddContactClick:(id)sender 
{
    [[self addContactWindow] setRoster:_mainRoster];
    [[self addContactWindow] orderFront:nil];
}

- (IBAction)toolbarItemDeleteContactClick:(id)sender 
{
    var index   = [[_rosterOutlineView selectedRowIndexes] firstIndex];
    var theJid  = [_rosterOutlineView itemAtRow:index];
    var alert   = [[TNAlertRemoveContact alloc] initWithJid:[theJid jid] roster:_mainRoster];
    
    if (alert)
        [alert runModal];
}

- (IBAction)toolbarItemAddGroupClick:(id)sender 
{
    [[self addGroupWindow] setRoster:_mainRoster];
    [[self addGroupWindow] orderFront:nil];
}


// strophe 
- (void)loginStrophe:(CPNotification)aNotification 
{
    [[self logView] log:"strophe connected notif received"];
    [[self connectionWindow] orderOut:nil];
    [[self theWindow] orderFront:nil];
    [self setConnected:YES];
    
    _mainRoster = [[TNDatasourceRoster alloc] initWithConnection:[aNotification userInfo]];
    [_mainRoster setDelegate:self];
    [_mainRoster setFilterField:[self filterField]];
    [[self propertiesView] setRoster:_mainRoster];
    // ask roster
    [_mainRoster getRoster];
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
    var alert = [[TNAlertPresenceSubscription alloc] initWithStanza:requestStanza roster:_mainRoster];
    
    [alert runModal];
}




// outline view delegate
// this have to move into the TNOutlineViewRoster
- (void)outlineViewSelectionDidChange:(CPNotification)notification 
{
   var index    = [_rosterOutlineView selectedRowIndexes];
   var item     = [_rosterOutlineView itemAtRow:[index firstIndex]];
   
   if ([item type] == "group")
   {
       [rightView setDocumentView:nil];
       return
   }

   var vCard    = [item vCard];
 
   
   if (vCard && ($(vCard.firstChild).text() == "hypervisor"))
   {
       [self loadHypervisorControlPanelForItem:item];
   }
   else
   {
       [rightView setDocumentView:nil];
   }
   
   [[self propertiesView] setEntry:item];
   [[self propertiesView] reload];
}





@end
