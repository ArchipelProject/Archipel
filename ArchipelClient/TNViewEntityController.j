/*  
 * TNViewEntityController.j
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

@import "StropheCappuccino/TNStrophe.j";
@import "TNSplitView.j";

@implementation TNViewEntityController: CPTabView 
{
    TNStropheRoster         roster              @accessors;
    TNStropheContact        contact             @accessors;
    CPString                moduleType          @accessors;
    CPString                modulesPath         @accessors;
    CPDictionary            loadedModulesScrollViews   @accessors;
    
    id  _modulesPList;
    
}

- (void)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        [self setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
        [self setLoadedModulesScrollViews:[[CPDictionary alloc] init]];
        
        [self setModulesPath:@"Modules/"];
    }
    
    return self;
}

- (void)setContact:(TNStropheContact)aContact ofType:(CPString)aType andRoster:(TNStropheRoster)aRoster
{
    [self removeAllTabs];
        
    [self setContact:aContact];
    [self setRoster:aRoster];
    [self setModuleType:aType];
    
    [self populateTabs];
}

- (void)load
{    
    var request     = [CPURLRequest requestWithURL:[CPURL URLWithString:@"Modules/modules.plist"]];
    var connection  = [CPURLConnection connectionWithRequest:request delegate:self];
    
    [connection cancel]; // recommended by Cappuccino, but generates an Aborted Request error in Firefox.
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
        var currentModuleTypes  = [module objectForKey:@"type"];
        var moduleIndex         = [module objectForKey:@"index"];
        var moduleLabel         = [module objectForKey:@"label"];
        var path                = [self modulesPath] + [module objectForKey:@"folder"];
        var moduleName          = [module objectForKey:@"BundleName"];
        var bundle              = [TNBundle bundleWithPath:path];
            
        [bundle setUserInfo:[CPDictionary dictionaryWithObjectsAndKeys:moduleIndex, @"index", 
                currentModuleTypes, @"type", moduleLabel, @"label", moduleName, @"name"]];
        [bundle loadWithDelegate:self];
    }
}

- (void)bundleDidFinishLoading:(TNBundle)aBundle
{   
    var bundleName          = [aBundle objectForInfoDictionaryKey:@"CPBundleName"];
    var theViewController   = [[CPViewController alloc] initWithCibName:bundleName bundle:aBundle];
    var moduleTabIndex      = [[aBundle userInfo] objectForKey:@"index"];
    var moduleTabType       = [[aBundle userInfo] objectForKey:@"type"];
    var moduleName          = [[aBundle userInfo] objectForKey:@"name"];
    var moduleLabel         = [[aBundle userInfo] objectForKey:@"label"];
    var scrollView          = [[CPScrollView alloc] initWithFrame:[self bounds]];
	
	[scrollView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
	[scrollView setAutohidesScrollers:YES];
	[scrollView setBackgroundColor:[CPColor whiteColor]];
	
	var frame = [scrollView bounds];
	frame.size.height = [[theViewController view] frame].size.height;
	
	[[theViewController view] setFrame:frame];
	[[theViewController view] setAutoresizingMask: CPViewWidthSizable];
	[scrollView setDocumentView:[theViewController view]];

	[[theViewController view] setModuleBundle:aBundle];
	[[theViewController view] setModuleTypes:moduleTabType];
	[[theViewController view] setModuleTabIndex:moduleTabIndex];
	[[theViewController view] setModuleName:moduleName];
	[[theViewController view] setModuleLabel:moduleLabel];
	
    [[self loadedModulesScrollViews] setObject:scrollView forKey:moduleName];
}


- (void)populateTabs
{   
    [self removeAllTabs];
    
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

    [newViewItem setLabel:aLabel];
    [newViewItem setView:aModuleScrollView];
    
    [[aModuleScrollView documentView] willBeDisplayed];
    
    [self addTabViewItem:newViewItem];

    [[aModuleScrollView documentView] initializeWithContact:[self contact] andRoster:[self roster]];
}

- (void)removeAllTabs
{   
    var selectedItem = [self selectedTabViewItem];

    [[[selectedItem view] documentView] willBeUnDisplayed];
    [[selectedItem view] removeFromSuperview];
    
    [self removeTabViewItem:selectedItem];
    
    //@each(var aTabViewItem in [self tabViewItems])
    for(var i = 0; i < [[self tabViewItems] count]; i++)
    {
        var aTabViewItem = [[self tabViewItems] objectAtIndex:i];
        
        [[[aTabViewItem view] documentView] willBeUnDisplayed];
        [[aTabViewItem view] removeFromSuperview];
        [self removeTabViewItem:aTabViewItem];
    }
}
@end



// Category to add a userInfo Dict in CPBundle
@implementation TNBundle : CPBundle
{   
    CPDictionary userInfo @accessors;
}
@end