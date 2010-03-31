/*  
 * TNModuleLoader.j
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

/*! @global
    @group TNArchipelModuleType
    type for tab module
*/
TNArchipelModuleTypeTab     = @"tab";

/*! @global
    @group TNArchipelModuleType
    type for toolbar module
*/
TNArchipelModuleTypeToolbar = @"toolbar";

/*! @ingroup archipelcore
    this is the module loader of Archipel
*/
@implementation TNModuleLoader: CPObject
{
    TNToolbar               mainToolbar                     @accessors;
    CPTabView               mainTabView                     @accessors;

    TNStropheRoster         roster                          @accessors;
    id                      entity                          @accessors;
    CPString                moduleType                      @accessors;
    CPString                modulesPath                     @accessors;
    CPView                  mainRightView                   @accessors;

    id                      _modulesPList;
    CPDictionary            _loadedTabModulesScrollViews;
    CPDictionary            _loadedToolbarModulesScrollViews;
    CPString                _previousStatus;
    CPView                  _currentToolbarView;
    CPToolbarItem           _currentToolbarItem;
}

/*! initialize the module loader
    @return an initialized instance of TNModuleLoader
*/
- (void)init
{
    if (self = [super init])
    {
        _loadedTabModulesScrollViews     = [CPDictionary dictionary];
        _loadedToolbarModulesScrollViews = [CPDictionary dictionary];
    }

    return self;
}

/*! set the XMPP information that will be gave to Tabs Modules.
    @param anEntity id can contains a TNStropheContact or a TNStropheGroup
    @param aType a type of entity. Can be virtualmachine, hypervisor, user or group
    @param aRoster TNStropheRoster the roster where the TNStropheContact besides
*/
- (void)setEntity:(id)anEntity ofType:(CPString)aType andRoster:(TNStropheRoster)aRoster
{
    [self rememberLastSelectedTabIndex];
    
    var center = [CPNotificationCenter defaultCenter];

    [self _removeAllTabsFromModulesTabView];

    [self setEntity:anEntity];
    [self setRoster:aRoster];
    [self setModuleType:aType];

    [center removeObserver:self];
    [center addObserver:self selector:@selector(_didPresenceUpdated:) name:TNStropheContactPresenceUpdatedNotification object:[self entity]];

    _previousStatus = [[self entity] status];
    if (([[self entity] class] == TNStropheContact) && ([[self entity] status] != TNStropheContactStatusOffline))
        [self _populateModulesTabView];
}

/*! store in HTML5 local storage last selected tab index for entity
*/
- (void)rememberLastSelectedTabIndex
{
    if ([self entity])
    {
        var currentItem             = [[self mainTabView] selectedTabViewItem];
        var currentSelectedIndex    = [[self mainTabView] indexOfTabViewItem:currentItem];
        var defaults                = [TNUserDefaults standardUserDefaults];
        var memid                   = @"selectedTabIndexFor" + [[self entity] jid];

        [defaults setInteger:currentSelectedIndex forKey:memid];
    }
}

/*! Reselect the last remembered tab index for entity
*/
- (void)recoverFromLastSelectedIndex
{
    if ([self entity])
    {
        var defaults            = [TNUserDefaults standardUserDefaults];
        var memid               = @"selectedTabIndexFor" + [[self entity] jid];
        var oldSelectedIndex    = [defaults integerForKey:memid];

        if (oldSelectedIndex)
            [[self mainTabView] selectTabViewItemAtIndex:oldSelectedIndex];
    }
}

/*! Set the roster and the connection for the Toolbar Modules.
    @param aRoster TNStropheRoster a connected roster
    @param aConnection the connection used by the roster
*/
- (void)setRosterForToolbarItems:(TNStropheRoster)aRoster andConnection:(TNStropheConnection)aConnection
{
    var allValues = [_loadedToolbarModulesScrollViews allValues];

    for(var i = 0; i < [allValues count]; i++)
    {
        var toolbarModule = [[allValues objectAtIndex:i] documentView];
        [toolbarModule initializeWithEntity:nil connection:aConnection andRoster:aRoster];
    }

}

/*! analyse the content of vCard will return the TNArchipelEntityType
    @param aVCard TNXMLNode containing the vCard
    @return value of TNArchipelEntityType
*/
- (CPString)analyseVCard:(TNXMLNode)aVCard
{
    if (aVCard)
    {
        var itemType = [[aVCard firstChildWithName:@"TYPE"] text];

        if ((itemType == TNArchipelEntityTypeVirtualMachine) || (itemType == TNArchipelEntityTypeHypervisor)
            || (itemType == TNArchipelEntityTypeGroup))
            return itemType;
        else
            return TNArchipelEntityTypeUser;
    }

    return TNArchipelEntityTypeUser;
}

/*! will start to load all the bundles describe in modules.plist
*/
- (void)load
{
    var request     = [CPURLRequest requestWithURL:[CPURL URLWithString:@"Modules/modules.plist"]];
    var connection  = [CPURLConnection connectionWithRequest:request delegate:self];

    [connection cancel]; // recommended by Cappuccino, but generates an Aborted Request error in Firefox.
    [connection start];
}


/// PRIVATES

/*! will load all CPBundle
*/
- (void)_loadAllBundles
{
    for(var i = 0; i < [[_modulesPList objectForKey:@"Modules"] count]; i++)
    {
        var module              = [[_modulesPList objectForKey:@"Modules"] objectAtIndex:i];
        var path                = [self modulesPath] + [module objectForKey:@"folder"];
        var bundle              = [CPBundle bundleWithPath:path];

        [bundle loadWithDelegate:self];
    }
}

/*! will display the modules that have to be displayed according to the entity type.
    triggered by -setEntity:ofType:andRoster:
*/
- (void)_populateModulesTabView
{
    var allValues = [_loadedTabModulesScrollViews allValues];

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
            [self _addItemToModulesTabViewWithLabel:moduleLabel moduleView:[sortedValue objectAtIndex:i] atIndex:moduleIndex];
        }
    }
    
    [self recoverFromLastSelectedIndex];
}

/*! will remove all loaded modules and send message willUnload to all TNModules
*/
- (void)_removeAllTabsFromModulesTabView
{
    var arrayCpy        = [[mainTabView tabViewItems] copy];
    var selectedItem    = [mainTabView selectedTabViewItem];
    var theModule       = [[selectedItem view] documentView]

    //@each(var aTabViewItem in [self tabViewItems])
    for(var i = 0; i < [arrayCpy count]; i++)
    {
        var aTabViewItem    = [arrayCpy objectAtIndex:i];
        var theModule       = [[aTabViewItem view] documentView];

        [theModule willUnload];
        [theModule setEntity:nil];
        [theModule setRoster:nil];

        [[aTabViewItem view] removeFromSuperview];
        [mainTabView removeTabViewItem:aTabViewItem];
    }
}

/*! insert a TNModules embeded in a scroll view to the mainToolbarView CPView
    @param aLabel CPString containing the displayed label
    @param aModuleScrollView CPScrollView containing the TNModule
    @param anIndex CPNumber representing the insertion index
*/
- (void)_addItemToModulesTabViewWithLabel:(CPString)aLabel moduleView:(CPScrollView)aModuleScrollView atIndex:(CPNumber)anIndex
{
    var newViewItem     = [[CPTabViewItem alloc] initWithIdentifier:aLabel];
    var theEntity       = [self entity];
    var theConnection   = [[self entity] connection];
    var theRoster       = [self roster];
    var theModule       = [aModuleScrollView documentView];

    [theModule initializeWithEntity:theEntity connection:theConnection andRoster:theRoster];
    [theModule willLoad];

    [newViewItem setLabel:aLabel];
    [newViewItem setView:aModuleScrollView];

    [mainTabView addTabViewItem:newViewItem];
}

/*! triggered on TNStropheContactPresenceUpdatedNotification receiption. This will sent _removeAllTabsFromModulesTabView
    to self if presence if Offline. If presence was Offline and bacame online, it will ask for the vCard to
    know what TNModules to load.
*/
- (void)_didPresenceUpdated:(CPNotification)aNotification
{
    if ([[aNotification object] status] == TNStropheContactStatusOffline)
    {
        _previousStatus = TNStropheContactStatusOffline;
        [self rememberLastSelectedTabIndex];
        [self _removeAllTabsFromModulesTabView];

    }
    else if (([[aNotification object] status] == TNStropheContactStatusOnline) && (_previousStatus) && (_previousStatus == TNStropheContactStatusOffline))
    {
        var center = [CPNotificationCenter defaultCenter];

        _previousStatus = nil;
        [center addObserver:self selector:@selector(_didReceiveVcard:) name:TNStropheContactVCardReceivedNotification object:[self entity]];
    }

}

/*! triggered on vCard reception
    @param aNotification CPNotification that trigger the selector
*/
- (void)_didReceiveVcard:(CPNotification)aNotification
{
    var center  = [CPNotificationCenter defaultCenter];
    var vCard   = [[aNotification object] vCard];

    [center removeObserver:self name:TNStropheContactVCardReceivedNotification object:[self entity]];
    [self setModuleType:[self analyseVCard:vCard]];

    [self _populateModulesTabView];
}


/// DELEGATES

/*! CPTabView delegate. Will sent willHide to current tab module and willShow to the one that will be be display
    @param aTabView the CPTabView that sent the message (mainTabView)
    @param anItem the new selected item
*/
- (void)tabView:(CPTabView)aTabView willSelectTabViewItem:(CPTabViewItem)anItem
{
    var currentTabItem          = [aTabView selectedTabViewItem];
    var oldModule               = [[currentTabItem view] documentView];
    var newModule               = [[anItem view] documentView];
    
    [oldModule willHide];
    [newModule willShow];
}

/*! delegate of CPURLConnection triggered when modules.plist is loaded.
    @param connection CPURLConnection that sent the message
    @param data CPString containing the result of the url
*/
- (void)connection:(CPURLConnection)connection didReceiveData:(CPString)data
{
    var cpdata = [CPData dataWithRawString:data];

    _modulesPList = [cpdata plistObject];

    [self _loadAllBundles];
}

/*! delegate of CPBundle. Will initialize all the modules in plist
    @param aBundle CPBundle that sent the message
*/
- (void)bundleDidFinishLoading:(CPBundle)aBundle
{
    CPLogConsole("Bundle loaded : " + aBundle)
    var moduleName          = [aBundle objectForInfoDictionaryKey:@"CPBundleName"];
    var moduleCibName       = [aBundle objectForInfoDictionaryKey:@"CibName"];
    var moduleLabel         = [aBundle objectForInfoDictionaryKey:@"PluginDisplayName"];
    var moduleInsertionType = [aBundle objectForInfoDictionaryKey:@"InsertionType"];
    var moduleIdentifier    = [aBundle objectForInfoDictionaryKey:@"CPBundleIdentifier"];

    var theViewController   = [[CPViewController alloc] initWithCibName:moduleCibName bundle:aBundle];
    var scrollView          = [[CPScrollView alloc] initWithFrame:[[self mainRightView] bounds]];

    [scrollView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [scrollView setAutohidesScrollers:YES];
    [scrollView setBackgroundColor:[CPColor whiteColor]];

    var frame = [scrollView bounds];

    [[theViewController view] setAutoresizingMask: CPViewWidthSizable];
    [[theViewController view] setModuleName:moduleName];
    [[theViewController view] setModuleLabel:moduleLabel];
    [[theViewController view] setModuleBundle:aBundle];

    [scrollView setDocumentView:[theViewController view]];

    if (moduleInsertionType == TNArchipelModuleTypeTab)
    {
        var moduleTabIndex      = [aBundle objectForInfoDictionaryKey:@"TabIndex"];
        var supportedTypes      = [aBundle objectForInfoDictionaryKey:@"SupportedEntityTypes"];

        [[theViewController view] setModuleTypes:supportedTypes];
        [[theViewController view] setModuleTabIndex:moduleTabIndex];

        [_loadedTabModulesScrollViews setObject:scrollView forKey:moduleName];
        frame.size.height = [[theViewController view] frame].size.height;
    }
    else if (moduleInsertionType == TNArchipelModuleTypeToolbar)
    {
        var moduleToolbarIndex = [aBundle objectForInfoDictionaryKey:@"ToolbarIndex"];

        [[self mainToolbar] addItemWithIdentifier:moduleName label:moduleLabel icon:[aBundle pathForResource:@"icon.png"] target:self action:@selector(didToolbarModuleClicked:)];
        [[self mainToolbar] setPosition:moduleToolbarIndex forToolbarItemIdentifier:moduleName];

        [[theViewController view] willLoad];

        [[self mainToolbar] _reloadToolbarItems];

        [_loadedToolbarModulesScrollViews setObject:scrollView forKey:moduleName];
    }

    [[theViewController view] setFrame:frame];
}

/*! Action that respond on Toolbar TNModules to display the view of the module.
    @param sender the CPToolbarItem that sent the message
*/
- (IBAction)didToolbarModuleClicked:(id)sender
{
    var oldView;

    if (_currentToolbarView)
    {
        var moduleBundle    = [[_currentToolbarView documentView] moduleBundle];
        var iconPath        = [moduleBundle pathForResource:[moduleBundle objectForInfoDictionaryKey:@"ToolbarIcon"]];

        //[_currentToolbarItem setLabel:[moduleBundle objectForInfoDictionaryKey:@"PluginDisplayName"]];
        [_currentToolbarItem setImage:[[CPImage alloc] initWithContentsOfFile:iconPath size:CPSizeMake(32,32)]];

        [[_currentToolbarView documentView] willHide];
        [_currentToolbarView removeFromSuperview];

        oldView = _currentToolbarView;

        _currentToolbarView = nil;
        _currentToolbarItem = nil;
    }

    var view            = [_loadedToolbarModulesScrollViews objectForKey:[sender itemIdentifier]];

    if (oldView != view)
    {
        var bounds          = [[self mainRightView] bounds];
        var moduleBundle    = [[view documentView] moduleBundle];
        var iconPath        = [moduleBundle pathForResource:[moduleBundle objectForInfoDictionaryKey:@"AlternativeToolbarIcon"]];

        //[sender setLabel:[moduleBundle objectForInfoDictionaryKey:@"AlternativePluginDisplayName"]];
        [sender setImage:[[CPImage alloc] initWithContentsOfFile:iconPath size:CPSizeMake(32,32)]];

        [view setFrame:bounds];

        [[view documentView] willShow];

        [[self mainRightView] addSubview:view];

        _currentToolbarView = view;
        _currentToolbarItem = sender;
    }
}
@end
