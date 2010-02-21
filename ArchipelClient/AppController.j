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

@import "StropheCappuccino/TNStrophe.j"

@import "TNAlertPresenceSubscription.j"
@import "TNAlertRemoveContact.j"
@import "TNDatasourceRoster.j"
@import "TNOutlineViewRoster.j"
@import "TNToolbar.j"
@import "TNViewHypervisorController.j"
@import "TNViewVirtualMachineController.j"
@import "TNViewLog.j"
@import "TNViewProperties.j"
@import "TNWindowAddContact.j"
@import "TNWindowAddGroup.j"
@import "TNWindowConnection.j"

@implementation AppController : CPObject
{
	@outlet CPView				leftView            @accessors;	
	@outlet CPView              filterView          @accessors;
	@outlet CPTextField         filterField         @accessors;
	@outlet CPView		        rightView           @accessors;
    @outlet CPSplitView         leftSplitView       @accessors;
    @outlet CPWindow            theWindow           @accessors;
	
	@outlet TNViewProperties    propertiesView      @accessors;
	@outlet TNWindowAddContact  addContactWindow    @accessors;
	@outlet TNWindowAddGroup    addGroupWindow      @accessors;
    @outlet TNWindowConnection  connectionWindow    @accessors;
    
	TNDatasourceRoster          _mainRoster;
	TNOutlineViewRoster		    _rosterOutlineView;
	TNToolbar		            _hypervisorToolbar;
    TNViewHypervisorControl     _currentRightViewContent;
    CPScrollView                _rightScrollView;
    CPScrollView                _outlineScrollView;
    
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
    
    // init scroll view of the outline view
	_outlineScrollView = [[CPScrollView alloc] initWithFrame:[[self leftView] bounds]];
	[_outlineScrollView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
	[_outlineScrollView setAutohidesScrollers:YES];
	[[_outlineScrollView contentView] setBackgroundColor:[CPColor colorWithHexString:@"D8DFE8"]];
	[_outlineScrollView setDocumentView:_rosterOutlineView];
    
    // left view
    [[self leftView] setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [[self leftView] addSubview:_outlineScrollView];
    
    // right scrollview
    _rightScrollView = [[CPScrollView alloc] initWithFrame:[[self rightView] bounds]];
	[_rightScrollView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
	[_rightScrollView setAutohidesScrollers:YES];
    
    // right view
    [[self rightView] setBackgroundColor:[CPColor colorWithHexString:@"EEEEEE"]];
    [[self rightView] setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [[self rightView] addSubview:_rightScrollView];
    
    
    //connection window
    [[self connectionWindow] center];
    [[self connectionWindow] orderFront:nil];
    
    // properties view
    [[self leftSplitView] setIsPaneSplitter:YES];
    [[self leftSplitView] setBackgroundColor:[CPColor colorWithHexString:@"D8DFE8"]];
    [[[self leftSplitView] subviews][1] removeFromSuperview];
    [[self leftSplitView] addSubview:[self propertiesView]];
    [[self leftSplitView] setPosition:[[self leftSplitView] bounds].size.height ofDividerAtIndex:0];
    
    // filter view. it is unused for now.
    [[self filterView] setBackgroundColor:[CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:@"Resources/gradientGray.png"]]];
    
    // notifications
    var center = [CPNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(loginStrophe:) name:TNStropheConnectionSuccessNotification object:[self connectionWindow]];
    [center addObserver:self selector:@selector(logoutStrophe:) name:TNStropheDisconnectionNotification object:nil];
}


// utilities
- (void)loadHypervisorControlPanelForItem:(TNStropheContact)item 
{
    var controller = [[CPViewController alloc] initWithCibName: @"HypervisorControlView" bundle:[CPBundle mainBundle]];
    
    _currentRightViewContent = [controller view];
    
    [_rightScrollView setBackgroundColor:[CPColor whiteColor]];
    var frame = [_rightScrollView frame];
    //if (frame.size.height < [_currentRightViewContent frame].size.height)
    frame.size.height = [_currentRightViewContent frame].size.height;
    
    [_currentRightViewContent setFrame:frame];
    [_currentRightViewContent setAutoresizingMask: CPViewWidthSizable];
    [_currentRightViewContent setContact:item andRoster:_mainRoster];
    [_currentRightViewContent initialize];
    
    [_rightScrollView setDocumentView:_currentRightViewContent];
}

- (void)loadVirtualMachineControlPanelForItem:(TNStropheContact)item
{
    var controller = [[CPViewController alloc] initWithCibName: @"VirtualMachineControlView" bundle:[CPBundle mainBundle]];
   
    _currentRightViewContent = [controller view]; 
    
    [_rightScrollView setBackgroundColor:[CPColor whiteColor]];
    
    var frame = [_rightScrollView frame];
    //if (frame.size.height < [_currentRightViewContent frame].size.height)
    frame.size.height = [_currentRightViewContent frame].size.height;
        
    [_currentRightViewContent setFrame:frame];
    [_currentRightViewContent setAutoresizingMask: CPViewWidthSizable];
    [_currentRightViewContent setContact:item andRoster:_mainRoster];
    
    [_rightScrollView setDocumentView:_currentRightViewContent]
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

- (IBAction)toolbarItemViewLogClick:(id)sender
{
    if (![[TNViewLog sharedLogger] superview])
    {
        var bounds = [[theWindow contentView] bounds];
        [[TNViewLog sharedLogger] setFrame:bounds];
        [[theWindow contentView] addSubview:[TNViewLog sharedLogger]];
    }       
    else
        [[TNViewLog sharedLogger] removeFromSuperview];
}

- (IBAction)toolbarItemClearLogClick:(id)sender
{
    [[TNViewLog sharedLogger] clearLog];
}


// strophe 
- (void)loginStrophe:(CPNotification)aNotification 
{
    [[self connectionWindow] orderOut:nil];
    [[self theWindow] orderFront:nil];
    [self setConnected:YES];
    
    _mainRoster = [[TNDatasourceRoster alloc] initWithConnection:[aNotification userInfo]];
    [_mainRoster setDelegate:self];
    [_mainRoster setFilterField:[self filterField]];
    [[self propertiesView] setRoster:_mainRoster];
    [_mainRoster getRoster];
}

- (void)logoutStrophe:(CPNotification)aNotification 
{
    [[self theWindow] orderOut:nil];
    [[self connectionWindow] orderFront:nil];
    [self setConnected:NO];
}

- (void)onMessage:(id)message 
{
    var theMessage = [[TNStropheMessage alloc] initWithStropheMessage:message];
}


// roster delegates
- (void)didReceiveSubscriptionRequest:(id)requestStanza 
{
    var alert = [[TNAlertPresenceSubscription alloc] initWithStanza:requestStanza roster:_mainRoster];
    
    [alert runModal];
}




// outline view delegate
- (void)outlineViewSelectionDidChange:(CPNotification)notification 
{
   var index    = [_rosterOutlineView selectedRowIndexes];
   var item     = [_rosterOutlineView itemAtRow:[index firstIndex]];
   
   if ([item type] == "group")
   {
       //[rightView setDocumentView:nil];
       [self loadVirtualMachineControlPanelForItem:item];
       return
   }

   var vCard    = [item vCard];
 

   // TODO firstChild is stupid. change me.
   if (vCard && ($(vCard.firstChild).text() == "hypervisor"))
   {
       [self loadHypervisorControlPanelForItem:item];
   }
   else //if (vCard && ($(vCard.firstChild).text() == "virtualmachine"))
   {
       [_rightScrollView setDocumentView:nil];
   }
   
   [[self propertiesView] setEntry:item];
   [[self propertiesView] reload];
}
@end
