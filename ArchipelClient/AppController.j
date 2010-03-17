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
@import <LPKit/LPKit.j>
@import <StropheCappuccino/StropheCappuccino.j>

@import "TNAlertPresenceSubscription.j"
@import "TNAlertRemoveContact.j"
@import "TNDatasourceRoster.j"
@import "TNOutlineViewRoster.j"
@import "TNToolbar.j"
@import "TNTabViewModuleLoader.j"
@import "TNViewLog.j"
@import "TNViewProperties.j"
@import "TNWindowAddContact.j"
@import "TNWindowAddGroup.j"
@import "TNWindowConnection.j"
@import "TNModule.j"
@import "TNAlert.j"
@import "TNViewLineable.j"

TNArchipelEntityTypeHypervisor      = @"hypervisor";
TNArchipelEntityTypeVirtualMachine  = @"virtualmachine";
TNArchipelEntityTypeUser            = @"user";

@implementation AppController : CPObject
{
    @outlet CPView              leftView                @accessors;	
    @outlet CPView              filterView              @accessors;
    @outlet CPSearchField       filterField             @accessors;
    @outlet CPView              rightView               @accessors;
    @outlet CPSplitView         leftSplitView           @accessors;
    @outlet CPWindow            theWindow               @accessors;
    @outlet CPSplitView         mainHorizontalSplitView @accessors;
    
    @outlet TNViewProperties    propertiesView      @accessors;
    @outlet TNWindowAddContact  addContactWindow    @accessors;
    @outlet TNWindowAddGroup    addGroupWindow      @accessors;
    @outlet TNWindowConnection  connectionWindow    @accessors;
    
    TNTabViewModuleLoader       _moduleView;
    TNDatasourceRoster          _mainRoster;
    TNOutlineViewRoster         _rosterOutlineView;
    TNToolbar                   _hypervisorToolbar;
    TNViewHypervisorControl     _currentRightViewContent;
    CPScrollView                _outlineScrollView;
}


// initialization
- (void)awakeFromCib
{
    [mainHorizontalSplitView setIsPaneSplitter:YES];
    
    //hide main window
    [theWindow orderOut:nil];
    
    // toolbar
    _hypervisorToolbar = [[TNToolbar alloc] initWithTarget:self];
    [theWindow setToolbar:_hypervisorToolbar];
    
    //outlineview
    _rosterOutlineView = [[TNOutlineViewRoster alloc] initWithFrame:CGRectMake(0,0,0,0)];    
    [_rosterOutlineView setDelegate:self];
    [_rosterOutlineView registerForDraggedTypes:[TNDragTypeContact]];
    // init scroll view of the outline view
	_outlineScrollView = [[CPScrollView alloc] initWithFrame:[[self leftView] bounds]];
	[_outlineScrollView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
	[_outlineScrollView setAutohidesScrollers:YES];
	[[_outlineScrollView contentView] setBackgroundColor:[CPColor colorWithHexString:@"D8DFE8"]];
	[_outlineScrollView setDocumentView:_rosterOutlineView];
    
    // left view
    [[self leftView] setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [[self leftView] addSubview:_outlineScrollView];
    
    // right view
    [[self rightView] setBackgroundColor:[CPColor colorWithHexString:@"EEEEEE"]];
    [[self rightView] setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    
    
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
    var bundle = [CPBundle bundleForClass:self];
    [[self filterView] setBackgroundColor:[CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"gradientGray.png"]]]];
    
    
    //module view :
    _moduleView = [[TNTabViewModuleLoader alloc] initWithFrame:[[self rightView] bounds]];
    [_moduleView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [_moduleView setBackgroundColor:[CPColor whiteColor]];
    [_moduleView load];
    
    // notifications
    var center = [CPNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(loginStrophe:) name:TNStropheConnectionSuccessNotification object:[self connectionWindow]];
    [center addObserver:self selector:@selector(logoutStrophe:) name:TNStropheDisconnectionNotification object:nil];    
}


// utilities
- (void)loadControlPanelForItem:(TNStropheContact)anItem  withType:(CPString)aType
{
    [_moduleView setEntity:anItem ofType:aType andRoster:_mainRoster];
    
    if ([_moduleView superview] != [self rightView])
        [[self rightView] addSubview:_moduleView];
        
    // var line = [[TNViewLineable alloc] initWithFrame:[[self rightView] bounds]];
    // [[self rightView] addSubview:line];
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
    var bundle = [CPBundle bundleForClass:self]
    
    if (![[TNViewLog sharedLogger] superview])
    {
        [sender setLabel:@"Go back"];
        [sender setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"logo_archipel.png"] size:CPSizeMake(32,32)]];
        var bounds = [[self rightView]  bounds];
        [[TNViewLog sharedLogger] setFrame:bounds];
        [[self rightView] addSubview:[TNViewLog sharedLogger]];
    }       
    else
    {
        [sender setLabel:@"View log"];
        [sender setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"log.png"] size:CPSizeMake(32,32)]];
        [[TNViewLog sharedLogger] removeFromSuperview];
    }
        
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
}


// roster delegates
- (void)didReceiveSubscriptionRequest:(id)requestStanza 
{
    var alert = [[TNAlertPresenceSubscription alloc] initWithStanza:requestStanza roster:_mainRoster];
    
    [alert runModal];
    //[_mainRoster answerAuthorizationRequest:requestStanza answer:YES];
}


// outline view delegate
- (void)outlineViewSelectionDidChange:(CPNotification)notification 
{
    var index    = [_rosterOutlineView selectedRowIndexes];
    var item     = [_rosterOutlineView itemAtRow:[index firstIndex]];
    
    if ([item type] == "group")
    {
       // TODO : manage group
        return
    }
   
    var vCard = [item vCard];
    var entityType = [_moduleView analyseVCard:vCard];
    
    [self loadControlPanelForItem:item withType:entityType];
    
    [[self propertiesView] setContact:item];
    [[self propertiesView] reload];
}
@end
