/*  
 * TNTabViewModuleLoader.j
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

@import "TNCategoriesAndGlobalSubclasses.j";

@implementation TNTabViewModuleLoader: CPTabView 
{
    TNStropheRoster         roster                      @accessors;
    id                      entity                      @accessors;
    CPString                moduleType                  @accessors;
    CPString                modulesPath                 @accessors;
    CPDictionary            loadedModulesScrollViews    @accessors;
    TNToolbar               mainToolbar                 @accessors;
    CPView                  mainRightView               @accessors;
        
    id                      _modulesPList;
    CPString                _previousStatus;
    CPView                  _currentToolbarView;
    CPToolbarItem           _currentToolbarItem;
}

- (void)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        [self setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
        [self setLoadedModulesScrollViews:[[CPDictionary alloc] init]];
        
        [self setModulesPath:@"Modules/"]; // TODO: conf
        [self setDelegate:self];
    }
    
    var message = [CPTextField labelWithTitle:@"Entity is currently offline. You can't interract with it."];
    var bounds = [self bounds];
    
    [message setFrame:CGRectMake(bounds.size.width / 2 - 300, 153, 600, 200)];
    [message setAutoresizingMask: CPViewMaxXMargin | CPViewMinXMargin];
    [message setAlignment:CPCenterTextAlignment]
    [message setFont:[CPFont boldSystemFontOfSize:18]];
    [message setTextColor:[CPColor grayColor]];
    [self addSubview:message];
    
    return self;
}

- (void)setEntity:(id)anEntity ofType:(CPString)aType andRoster:(TNStropheRoster)aRoster
{
    var center = [CPNotificationCenter defaultCenter];
    
    [self removeAllTabs]; 
    [self setEntity:anEntity];
    [self setRoster:aRoster];
    [self setModuleType:aType];
    
    [center removeObserver:self];
    [center addObserver:self selector:@selector(_didPresenceUpdated:) name:TNStropheContactPresenceUpdatedNotification object:[self entity]];
    
    _previousStatus = [[self entity] status]; 
    if (([[self entity] class] == TNStropheContact) && ([[self entity] status] != TNStropheContactStatusOffline))
        [self populateTabs];
}

- (void)load
{
    var request     = [CPURLRequest requestWithURL:[CPURL URLWithString:@"Modules/modules.plist"]];
    var connection  = [CPURLConnection connectionWithRequest:request delegate:self];
    
    //[connection cancel]; // recommended by Cappuccino, but generates an Aborted Request error in Firefox.
    [connection start];
}

- (void)connection:(CPURLConnection)connection didReceiveData:(CPString)data
{
    var cpdata = [CPData dataWithRawString:data]; 
    
    _modulesPList = [cpdata plistObject];
    
    [self loadAllBundles];
}

- (void)loadAllBundles
{
    for(var i = 0; i < [[_modulesPList objectForKey:@"Modules"] count]; i++)
    {
        var module              = [[_modulesPList objectForKey:@"Modules"] objectAtIndex:i];
        var path                = [self modulesPath] + [module objectForKey:@"folder"];
        var bundle              = [CPBundle bundleWithPath:path];
        
        [bundle loadWithDelegate:self];
    }
}

- (void)bundleDidFinishLoading:(TNBundle)aBundle
{
    var moduleName          = [aBundle objectForInfoDictionaryKey:@"CPBundleName"];
    var moduleCibName       = [aBundle objectForInfoDictionaryKey:@"CibName"];
    var moduleLabel         = [aBundle objectForInfoDictionaryKey:@"PluginDisplayName"];
    var moduleInsertionType = [aBundle objectForInfoDictionaryKey:@"insertionType"];
    var moduleIdentifier    = [aBundle objectForInfoDictionaryKey:@"CPBundleIdentifier"];

    var theViewController   = [[CPViewController alloc] initWithCibName:moduleCibName bundle:aBundle];
    var scrollView          = [[CPScrollView alloc] initWithFrame:[self bounds]];
    
    [scrollView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [scrollView setAutohidesScrollers:YES];
    [scrollView setBackgroundColor:[CPColor whiteColor]];
    
    var frame = [scrollView bounds];
    frame.size.height = [[theViewController view] frame].size.height;
    
    [[theViewController view] setFrame:frame];
    [[theViewController view] setAutoresizingMask: CPViewWidthSizable];
    [[theViewController view] setModuleName:moduleName];
    [[theViewController view] setModuleLabel:moduleLabel];
    [[theViewController view] setModuleBundle:aBundle];
    
    [scrollView setDocumentView:[theViewController view]];
    
    if (moduleInsertionType == @"tab")
    {
        var moduleTabIndex      = [aBundle objectForInfoDictionaryKey:@"TabIndex"];
        var moduleTabTypes      = [aBundle objectForInfoDictionaryKey:@"SupportedEntityTypes"];
        
        [[theViewController view] setModuleTypes:moduleTabTypes];
        [[theViewController view] setModuleTabIndex:moduleTabIndex];
        
    }
    else if (moduleInsertionType == @"toolbar")
    {
        var moduleToolbarIndex = [aBundle objectForInfoDictionaryKey:@"ToolbarIndex"];
        
        [[self mainToolbar] addItemWithIdentifier:moduleName label:moduleLabel icon:[aBundle pathForResource:@"icon.png"] target:self action:@selector(didToolbarModuleClicked:)];
        [[self mainToolbar] setPosition:moduleToolbarIndex forToolbarItemIdentifier:moduleName];
        
        [[self mainToolbar] _reloadToolbarItems];
    }
    
    [[self loadedModulesScrollViews] setObject:scrollView forKey:moduleName];
}

- (void)populateTabs
{
    var allValues = [[self loadedModulesScrollViews] allValues];
    
    var sortedValue = [allValues sortedArrayUsingFunction:function(a, b, context){
        var indexA = [[a documentView] moduleTabIndex];
        var indexB = [[b documentView] moduleTabIndex];
        if (indexA < indexB)
                return CPOrderedAscending;
            else if (indexA > indexB)
                return CPOrderedDescending;
            else
                return CPOrderedSame;
    }]
    
    //@each(var module in [_modulesPList objectForKey:@"Modules"])
    for(var i = 0; i < [sortedValue count]; i++)
    {
        var module      = [[sortedValue objectAtIndex:i] documentView];
        var moduleTypes = [module moduleTypes];
        var moduleIndex = [module moduleTabIndex];
        var moduleLabel = [module moduleLabel];
        var moduleName  = [module moduleName];
        
        if ([moduleTypes containsObject:[self moduleType]])
        {
            [self addItemWithLabel:moduleLabel moduleView:[sortedValue objectAtIndex:i] atIndex:moduleIndex];
        }
    }
}

- (void)addItemWithLabel:(CPString)aLabel moduleView:(TNModule)aModuleScrollView atIndex:(CPNumber)anIndex
{
    var newViewItem = [[CPTabViewItem alloc] initWithIdentifier:aLabel];
    
    
    [[aModuleScrollView documentView] initializeWithEntity:[self entity] connection:[[self entity] connection] andRoster:[self roster]];
    [[aModuleScrollView documentView] willLoad];
    
    [newViewItem setLabel:aLabel];
    [newViewItem setView:aModuleScrollView];
    
    [self addTabViewItem:newViewItem];
}

- (void)removeAllTabs
{
    var selectedItem = [self selectedTabViewItem];
    
    [[[selectedItem view] documentView] willUnload];
    [[[selectedItem view] documentView] setEntity:nil];
    [[[selectedItem view] documentView] setRoster:nil];
    [[selectedItem view] removeFromSuperview];
    
    [self removeTabViewItem:selectedItem];
    
    var arrayCpy = [[self tabViewItems] copy];
    
    //@each(var aTabViewItem in [self tabViewItems])
    for(var i = 0; i < [arrayCpy count]; i++)
    {
        var aTabViewItem = [arrayCpy objectAtIndex:i];
        
        [[[aTabViewItem view] documentView] willUnload];
        [[aTabViewItem view] removeFromSuperview];
        [[[aTabViewItem view] documentView] setEntity:nil];
        [[[aTabViewItem view] documentView] setRoster:nil];
        [self removeTabViewItem:aTabViewItem];
    }
}

- (void)_didPresenceUpdated:(CPNotification)aNotification
{
    if ([[aNotification object] status] == TNStropheContactStatusOffline)
    {
        _previousStatus = TNStropheContactStatusOffline;
        [self removeAllTabs];
        
    }
    else if (([[aNotification object] status] == TNStropheContactStatusOnline) && (_previousStatus) && (_previousStatus == TNStropheContactStatusOffline))
    {
        var center = [CPNotificationCenter defaultCenter];

        _previousStatus = nil;        
        [center addObserver:self selector:@selector(_didReceiveVcard:) name:TNStropheContactVCardReceivedNotification object:[self entity]];
    }
        
}

- (CPString)analyseVCard:(id)aVCard
{
    if (aVCard)
    {
        var itemType = [[aVCard firstChildWithName:@"TYPE"] text];
        
        if (itemType)
            return itemType;
        else 
            return TNArchipelEntityTypeUser;
    }
    
    return TNArchipelEntityTypeUser;
}

- (void)_didReceiveVcard:(CPNotification)aNotification
{
    var center  = [CPNotificationCenter defaultCenter];
    var vCard   = [[aNotification object] vCard];
    
    [center removeObserver:self name:TNStropheContactVCardReceivedNotification object:[self entity]];
    [self setModuleType:[self analyseVCard:vCard]];
    
    [self populateTabs];
}

// tabview delegate
- (void)tabView:(CPTabView)aTabView willSelectTabViewItem:(CPTabViewItem)anItem
{
    [[[[self selectedTabViewItem] view] documentView] willHide];
    
    [[[anItem view] documentView] willShow];
}

// action for toolbaritems
- (IBAction)didToolbarModuleClicked:(id)sender
{
    if (!_currentToolbarView)
    {
        var view            = [[self loadedModulesScrollViews] objectForKey:[sender itemIdentifier]];
        var bounds          = [[self mainRightView] bounds];
        var moduleBundle    = [[view documentView] moduleBundle];
        var iconPath        = [moduleBundle pathForResource:[moduleBundle objectForInfoDictionaryKey:@"AlternativeToolbarIcon"]];
        
        //[sender setLabel:[moduleBundle objectForInfoDictionaryKey:@"AlternativePluginDisplayName"]];
        [sender setImage:[[CPImage alloc] initWithContentsOfFile:iconPath size:CPSizeMake(32,32)]];
        
        [view setFrame:bounds];
        
        [[self mainRightView] addSubview:view];
        
        _currentToolbarView = view;
        _currentToolbarItem = sender;
    }
    else
    {
        var moduleBundle    = [[_currentToolbarView documentView] moduleBundle];
        var iconPath        = [moduleBundle pathForResource:[moduleBundle objectForInfoDictionaryKey:@"ToolbarIcon"]];
        
        //[_currentToolbarItem setLabel:[moduleBundle objectForInfoDictionaryKey:@"PluginDisplayName"]];
        [_currentToolbarItem setImage:[[CPImage alloc] initWithContentsOfFile:iconPath size:CPSizeMake(32,32)]];
        
        [_currentToolbarView removeFromSuperview];
        
        _currentToolbarView = nil;
        _currentToolbarItem = nil;
    }
    
}
@end
