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


@implementation TNViewEntityController: CPTabView 
{
    CPArray                 tabViews            @accessors;
    TNStropheRoster         roster              @accessors;
    TNStropheContact        contact             @accessors;
    CPString                moduleType          @accessors;
    CPString                modulesPath         @accessors;
    CPArray                 loadedBundles       @accessors;
    
    id  _plistObject;
    
}

- (void)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        console.log("inited");
        [self setTabViews:[[CPArray alloc] init]];
        [self setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
        [self setLoadedBundles:[[CPArray alloc] init]];
        
        [self setModulesPath:@"/Modules/"];
    }
    
    return self;
}

- (void)setContact:(TNStropheContact)aContact ofType:(CPString)aType andRoster:(TNStropheRoster)aRoster
{
    [self setContact:aContact];
    [self setRoster:aRoster];
    [self setModuleType:aType];
    
    [self getAssociatedModules];
}

- (void)getAssociatedModules
{
    var request = [CPURLRequest requestWithURL:[CPURL URLWithString:@"Modules/modules.plist"]];
    var connection = [CPURLConnection connectionWithRequest:request delegate:self];
    
    [connection cancel];
    [connection start];
}

- (void)connection:(CPURLConnection)connection didReceiveData:(CPString)data
{
    var cpdata = [CPData dataWithRawString:data]; 
    _plistObject = [cpdata plistObject];
    
    [self populateTabsFromPlist];
}

- (void)populateTabsFromPlist
{
    @each(var module in [_plistObject objectForKey:@"Modules"])
    {
        var currentModuleType   = [module objectForKey:@"type"];
        
        if ([self moduleType] == currentModuleType)
        {   
            var path    = [self modulesPath] + [module objectForKey:@"folder"];
            var bundle  = [CPBundle bundleWithPath:path]
            
            CPLogConsole(bundle);
            
            if (![[self loadedBundles] containsObject:bundle])
            {
                [[self loadedBundles] addObject:[bundle bundlePath]];
                [bundle loadWithDelegate:self];
                console.log("bundle path " + [bundle bundlePath]);
            }
            else
            {
                console.log("TOTO");
                [self bundleDidFinishLoading:[[self loadedBundles] objectForKey:path]];
            }
            
            
        }
    }
}

- (void)bundleDidFinishLoading:(CPBundle)aBundle
{   
    var theViewController = [[CPViewController alloc] initWithCibName:[aBundle objectForInfoDictionaryKey:@"CPBundleName"] bundle:aBundle];
    
    CPLogConsole([theViewController view]);
    
    var newViewItem = [[CPTabViewItem alloc] initWithIdentifier:[aBundle objectForInfoDictionaryKey:@"PluginDisplayName"]];
    [newViewItem setLabel:[aBundle objectForInfoDictionaryKey:@"PluginDisplayName"]];
    [newViewItem setView:[theViewController view]];
    
    [self addTabViewItem:newViewItem];
    
    [[theViewController view] initializeWithContact:[self contact] andRoster:[self roster]];
}
@end



// thoses categories make CPTabView beatiful.
@implementation CPTabView (myTabView)
{   
}

- (void)_createBezelBorder
{
    var bounds = [self bounds];
     bounds.size.width += 7.0;
     bounds.origin.x -= 7.0;
     
    _labelsView = [[_CPTabLabelsView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(bounds), 0.0)];
    
     [_labelsView setTabView:self];
     [_labelsView setAutoresizingMask:CPViewWidthSizable];
    
     [self addSubview:_labelsView];

}

- (CGRect)contentRect
{
    var contentRect = CGRectMakeCopy([self bounds]);
    
    if (_tabViewType == CPTopTabsBezelBorder)
    {
        var labelsViewHeight = [_CPTabLabelsView height],
            auxiliaryViewHeight = _auxiliaryView ? CGRectGetHeight([_auxiliaryView frame]) : 5.0,
            separatorViewHeight = 0.0;

        contentRect.origin.y += labelsViewHeight + auxiliaryViewHeight + separatorViewHeight;
        contentRect.size.height -= labelsViewHeight + auxiliaryViewHeight + separatorViewHeight * 2.0;
    }

    return contentRect;
}
@end

@implementation _CPTabLabelsView (MyLabelView)
{
    
}
- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {
        _tabLabels = [];
        
        [self setBackgroundColor:[CPColor colorWithHexString:@"3e4a5e"]];

        [self setFrameSize:CGSizeMake(CGRectGetWidth(aFrame), 26.0)];
    }
    
    return self;
}
// - (void)layoutSubviews
// {
//     var index = 0,
//         count = _tabLabels.length,
//         width = 150.0,
//         x = 15;
//     
//     for (; index < count; ++index)
//     {
//         var label = _tabLabels[index],
//             frame = _CGRectMake(x, 8.0, width, 18.0);
//         
//         [label setFrame:frame];
//         
//         x = _CGRectGetMaxX(frame);
//     }
// }
@end








// objj_importFile(path + controllerFile, NO, function()
// {
//     var theViewController = [[CPViewController alloc] initWithCibName:path + cibname bundle:nil];
//     
//     var newViewItem = [[CPTabViewItem alloc] initWithIdentifier:label];
//     [newViewItem setLabel:label];
//     [newViewItem setView:[theViewController view]];
//     
//     [self addTabViewItem:newViewItem];
//      
//     [[theViewController view] initializeWithContact:[self contact] andRoster:[self roster]];
// });