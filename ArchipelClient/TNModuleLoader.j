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


@implementation TNModuleTabViewItem : CPTabViewItem
{
    TNModule _module @accessors(property=module);
}
@end


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


/*! this notification is sent when all modules are loaded
*/
TNArchipelModulesLoadingCompleteNotification = @"TNArchipelModulesLoadingCompleteNotification"

TNArchipelModulesReadyNotification          = @"TNArchipelModulesReadyNotification";
TNArchipelModulesAllReadyNotification       = @"TNArchipelModulesAllReadyNotification"; 

/*! @ingroup archipelcore
    
    this is the Archipel Module loader.
    It supports 3 delegates :
    
     - moduleLoader:hasLoadBundle: is sent when a module is loaded
     - moduleLoader:willLoadBundle: is sent when a module will be loaded
     - moduleLoaderLoadingComplete: is sent when all modules has been loaded
*/
@implementation TNModuleLoader: CPObject
{
    TNToolbar               mainToolbar                     @accessors;
    CPTabView               mainTabView                     @accessors;
    id                      delegate                        @accessors;
    
    TNStropheRoster         roster                          @accessors;
    id                      entity                          @accessors;
    CPString                moduleType                      @accessors;
    CPString                modulesPath                     @accessors;
    CPView                  mainRightView                   @accessors;
    CPMenu                  modulesMenu                     @accessors;

    CPTextField             infoTextField                   @accessors;
    int                     _numberOfActiveModules          @accessors(getter=numberOfActiveModules);
    int                     _numberOfReadyModules           @accessors(getter=numberOfReadyModules);
    BOOL                    _allModulesReady                @accessors(getter=isAllModulesReady);
    id                      _modulesPList;
    CPArray                 _bundles;
    CPArray                 _loadedTabModules;
    CPDictionary            _loadedToolbarModules;
    // CPDictionary            _loadedTabModulesScrollViews;
    // CPDictionary            _loadedToolbarModulesScrollViews;
    CPString                _previousStatus;
    CPView                  _currentToolbarModule;
    CPToolbarItem           _currentToolbarItem;
    int                     _numberOfModulesToLoad;
    int                     _numberOfModulesLoaded;
}

/*! initialize the module loader
    @return an initialized instance of TNModuleLoader
*/
- (void)init
{
    if (self = [super init])
    {
        var center = [CPNotificationCenter defaultCenter];
        
        _loadedTabModulesScrollViews     = [CPDictionary dictionary];
        _loadedToolbarModulesScrollViews = [CPDictionary dictionary];
        _numberOfModulesToLoad  = 0;
        _numberOfModulesLoaded  = 0;
        _numberOfActiveModules  = 0;
        _numberOfReadyModules   = 0;
        _allModulesReady        = NO;
        _bundles                = [CPArray array];
        _loadedTabModules       = [CPArray array];
        _loadedToolbarModules   = [CPDictionary dictionary];
    }

    return self;
}



/*! set the XMPP information that will be gave to Tabs Modules.
    @param anEntity id can contains a TNStropheContact or a TNStropheGroup
    @param aType a type of entity. Can be virtualmachine, hypervisor, user or group
    @param aRoster TNStropheRoster the roster where the TNStropheContact besides
*/
- (BOOL)setEntity:(id)anEntity ofType:(CPString)aType andRoster:(TNStropheRoster)aRoster
{
    if (anEntity == entity)
        return NO;
        
    var center = [CPNotificationCenter defaultCenter];
    
    [center removeObserver:self name:TNStropheContactPresenceUpdatedNotification object:entity];
    
    _numberOfActiveModules = 0;
    // [self rememberLastSelectedTabIndex];
    
    
    
    [self _removeAllTabsFromModulesTabView];
    _numberOfReadyModules = 0;
    _allModulesReady = NO;
    
    [self setEntity:anEntity];
    [self setRoster:aRoster];
    [self setModuleType:aType];

    [center removeObserver:self];
    [center addObserver:self selector:@selector(_didPresenceUpdate:) name:TNStropheContactPresenceUpdatedNotification object:entity];
    [center addObserver:self selector:@selector(_didReceiveVcard:) name:TNStropheContactVCardReceivedNotification object:entity];
    [center addObserver:self selector:@selector(_didAllModulesReady:) name:TNArchipelModulesReadyNotification object:nil];
    
    if ([[self entity] class] == TNStropheContact)
    {
        _previousStatus = [[self entity] status];
        
        if ((_previousStatus != TNStropheContactStatusOffline) && (_previousStatus != TNStropheContactStatusDND))
            [self _populateModulesTabView];
        else
        {
            var label;
            if (_previousStatus == TNStropheContactStatusOffline)
                label = @"Entity is offline";
            else if (_previousStatus == TNStropheContactStatusDND)
                label = @"Entity do not want to be disturbed";
            
            [infoTextField setStringValue:label];
            var center = [CPNotificationCenter defaultCenter];
            [center postNotificationName:TNArchipelModulesAllReadyNotification object:self];
            
        }
    }
    else
    {
        [self _populateModulesTabView];
    }
    
    return YES;
}

/*! store in TNUserDefaults last selected tab index for entity
*/
- (void)rememberLastSelectedTabIndex
{
    if ([self entity] && ([[self mainTabView] numberOfTabViewItems] > 0))
    {
        var currentItem = [[self mainTabView] selectedTabViewItem];
        
        [self rememberSelectedIndexOfItem:currentItem];
    }
}

/*! set wich item tab to remember
    @param anItem: the CPTabView item to remember
*/
- (void)rememberSelectedIndexOfItem:(id)anItem
{
    CPLog.debug(@"rememberSelectedIndexOfItem: with item " + anItem);
    if (anItem && [self entity] && ([mainTabView numberOfTabViewItems] > 0))
    {
        var identifier;
        var memid;
        var defaults                = [TNUserDefaults standardUserDefaults];
        var currentSelectedIndex    = [mainTabView indexOfTabViewItem:anItem];
        
        if ([[self entity] class] == TNStropheContact)
            identifier = [[self entity] JID];
        else
            identifier = [[self entity] name];

        memid = @"selectedTabIndexFor" + identifier;
        
        [defaults setInteger:currentSelectedIndex forKey:memid];
    }
}

/*! Reselect the last remembered tab index for entity
*/
- (void)recoverFromLastSelectedIndex
{
    var identifier;
    if ([[self entity] class] == TNStropheContact)
        identifier = [[self entity] JID];
    else
        identifier = [[self entity] name];
    
    var defaults            = [TNUserDefaults standardUserDefaults];
    var memid               = @"selectedTabIndexFor" + identifier;
    var oldSelectedIndex    = [defaults integerForKey:memid];
    var numberOfTabItems    = [[self mainTabView] numberOfTabViewItems];
    
    if ([self entity] && (numberOfTabItems > 0) && ((numberOfTabItems - 1) >= oldSelectedIndex) && (oldSelectedIndex != -1))
    {
        CPLog.debug("recovering last selected tab index " + oldSelectedIndex);
        [[self mainTabView] selectTabViewItemAtIndex:oldSelectedIndex];
    }
}

/*! Set the roster and the connection for the Toolbar Modules.
    @param aRoster TNStropheRoster a connected roster
    @param aConnection the connection used by the roster
*/
- (void)setRosterForToolbarItems:(TNStropheRoster)aRoster andConnection:(TNStropheConnection)aConnection
{
    for(var i = 0; i < [[_loadedToolbarModules allValues] count]; i++)
    {
        var module = [[_loadedToolbarModules allValues] objectAtIndex:i];
        [module initializeWithEntity:nil connection:aConnection andRoster:aRoster];
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
    [self unloadAllModules];
    
    var request     = [CPURLRequest requestWithURL:[CPURL URLWithString:@"Modules/modules.plist"]];
    var connection  = [CPURLConnection connectionWithRequest:request delegate:self];
        
    //[connection cancel];
    [connection start];
}

- (void)unloadAllModules
{

}

/// PRIVATES

/*! will load all CPBundle
*/
- (void)_loadAllBundles
{
    CPLog.debug("going to parse the PList");
    
    for(var i = 0; i < [[_modulesPList objectForKey:@"Modules"] count]; i++)
    {
        CPLog.debug("parsing " + [CPBundle bundleWithPath:path]);
        
        var module  = [[_modulesPList objectForKey:@"Modules"] objectAtIndex:i];
        var path    = [self modulesPath] + [module objectForKey:@"folder"];
        var bundle  = [CPBundle bundleWithPath:path];
        
        _numberOfModulesToLoad++;    
            
        if ([delegate respondsToSelector:@selector(moduleLoader:willLoadBundle:)])
            [delegate moduleLoader:self willLoadBundle:bundle];
                       
        [bundle loadWithDelegate:self];
    }
    
    if ((_numberOfModulesToLoad == 0) && ([delegate respondsToSelector:@selector(moduleLoaderLoadingComplete:)]))
        [delegate moduleLoaderLoadingComplete:self];
}

/*! will display the modules that have to be displayed according to the entity type.
    triggered by -setEntity:ofType:andRoster:
*/
- (void)_populateModulesTabView
{
    var sortedValue = [_loadedTabModules sortedArrayUsingFunction:function(a, b, context){
        var indexA = [a index];
        var indexB = [b index];
        if (indexA < indexB)
                return CPOrderedAscending;
            else if (indexA > indexB)
                return CPOrderedDescending;
            else
                return CPOrderedSame;
    }]
    
    var modulesToLoad = [CPArray array];
    
    
    // THE PIGGY WAY. I'LL REDO THAT LATER.
    _numberOfActiveModules = 0; 
    for(var i = 0; i < [sortedValue count]; i++)
    {
        var module      = [sortedValue objectAtIndex:i];
        var moduleTypes = [module supportedEntityTypes];
        var moduleIndex = [module index];
        var moduleLabel = [module label];
        var moduleName  = [module name];
        
        if ([moduleTypes containsObject:[self moduleType]])
            _numberOfActiveModules++;
    }

    //@each(var module in [_modulesPList objectForKey:@"Modules"];
    for(var i = 0; i < [sortedValue count]; i++)
    {
        var module      = [sortedValue objectAtIndex:i];
        var moduleTypes = [module supportedEntityTypes];
        var moduleIndex = [module index];
        var moduleLabel = [module label];
        var moduleName  = [module name];
        
        if ([moduleTypes containsObject:[self moduleType]])
        {
            [self _addItemToModulesTabView:module];
        }
    }    
    
    [self recoverFromLastSelectedIndex];
}

/*! will remove all loaded modules and send message willUnload to all TNModules
*/
- (void)_removeAllTabsFromModulesTabView
{
    if ([mainTabView numberOfTabViewItems] <= 0)
        return;
        
    var arrayCpy        = [[mainTabView tabViewItems] copy];
    // var selectedItem    = [mainTabView selectedTabViewItem];
    // var theModule       = [[selectedItem view] documentView];

    //@each(var aTabViewItem in [self tabViewItems])
    for(var i = 0; i < [arrayCpy count]; i++)
    {
        var aTabViewItem    = [arrayCpy objectAtIndex:i];
        var theModule       = [aTabViewItem module];

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
- (void)_addItemToModulesTabView:(TNModule)aModule
{
    var frame           = [mainRightView bounds];
    var newViewItem     = [[TNModuleTabViewItem alloc] initWithIdentifier:[aModule name]];
    var theEntity       = [self entity];
    var theConnection   = [[self entity] connection];
    var theRoster       = [self roster];
    var scrollView      = [[CPScrollView alloc] initWithFrame:frame];
    
    [scrollView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [scrollView setAutohidesScrollers:YES];
    [scrollView setBackgroundColor:[CPColor whiteColor]];
    
    frame.size.height = [[aModule view] bounds].size.height;
    [[aModule view] setFrame:frame];
        
    [newViewItem setModule:aModule];
    [newViewItem setLabel:[aModule label]];
    [newViewItem setView:scrollView];
    
    [aModule initializeWithEntity:theEntity connection:theConnection andRoster:theRoster];
    [aModule willLoad];
    
    [scrollView setDocumentView:[aModule view]];    
    [mainTabView addTabViewItem:newViewItem];
}

/*! triggered on TNStropheContactPresenceUpdatedNotification receiption. This will sent _removeAllTabsFromModulesTabView
    to self if presence if Offline. If presence was Offline and bacame online, it will ask for the vCard to
    know what TNModules to load.
*/
- (void)_didPresenceUpdate:(CPNotification)aNotification
{
    if ([[aNotification object] status] == TNStropheContactStatusOffline)
    {
        _numberOfActiveModules = 0;
        _allModulesReady = NO;
        [self _removeAllTabsFromModulesTabView];
        _previousStatus = TNStropheContactStatusOffline;
        [infoTextField setStringValue:@"Entity is offline"];
    }
    else if ([[aNotification object] status] == TNStropheContactStatusDND)
    {
        _numberOfActiveModules = 0;
        _allModulesReady = NO;
        [self _removeAllTabsFromModulesTabView];
        _previousStatus = TNStropheContactStatusDND;
        [infoTextField setStringValue:@"Entity do not want to be disturbed"];
    }
    else if ((_previousStatus == TNStropheContactStatusOffline) || (_previousStatus == TNStropheContactStatusDND))
    {
        _previousStatus = nil;
        _numberOfActiveModules = 0;
        _allModulesReady = NO;
        [self _removeAllTabsFromModulesTabView];
        [self _populateModulesTabView];
    }
}

/*! triggered on vCard reception
    @param aNotification CPNotification that trigger the selector
*/
- (void)_didReceiveVcard:(CPNotification)aNotification
{
    var vCard   = [[aNotification object] vCard];
    
    if ([vCard text] != [[entity vCard] text])
    {
        [self setModuleType:[self analyseVCard:vCard]];

        [self _removeAllTabsFromModulesTabView];
        [self _populateModulesTabView];
    }
}

- (void)_didAllModulesReady:(CPNotification)aNotification
{
    _numberOfReadyModules++;
    
    if (_numberOfReadyModules == _numberOfActiveModules)
    {
        var center = [CPNotificationCenter defaultCenter];
        
        CPLog.debug("sending all modules ready notification")
        [center postNotificationName:TNArchipelModulesAllReadyNotification object:self];
        
        _allModulesReady = YES;
    }
}


/// DELEGATES

/*! CPTabView delegate. Will sent willHide to current tab module and willShow to the one that will be be display
    @param aTabView the CPTabView that sent the message (mainTabView)
    @param anItem the new selected item
*/
- (void)tabView:(CPTabView)aTabView willSelectTabViewItem:(TNModuleTabViewItem)anItem
{
    if ([aTabView numberOfTabViewItems] <= 0)
        return

    if ([self isAllModulesReady])
        [self rememberSelectedIndexOfItem:anItem];
    
    var currentTabItem = [aTabView selectedTabViewItem];
    
    if (currentTabItem)
    {
        var oldModule = [currentTabItem module];
        [oldModule willHide];
    }
    
    var newModule = [anItem module];
    [newModule willShow];
}

/*! delegate of CPURLConnection triggered when modules.plist is loaded.
    @param connection CPURLConnection that sent the message
    @param data CPString containing the result of the url
*/
- (void)connection:(CPURLConnection)connection didReceiveData:(CPString)data
{
    var cpdata = [CPData dataWithRawString:data];

    CPLog.info("Module.plist recovered");

    _modulesPList = [cpdata plistObject];
    
    [self _removeAllTabsFromModulesTabView];
    
    [self _loadAllBundles];
}

/*! delegate of CPBundle. Will initialize all the modules in plist
    @param aBundle CPBundle that sent the message
*/
- (void)bundleDidFinishLoading:(CPBundle)aBundle
{
    var moduleInsertionType = [aBundle objectForInfoDictionaryKey:@"InsertionType"];
    
    [_bundles addObject:aBundle];
    _numberOfModulesLoaded++;
    
    if (moduleInsertionType == TNArchipelModuleTypeTab)
        [self manageTabItemLoad:aBundle];
    else if (moduleInsertionType == TNArchipelModuleTypeToolbar)
        [self manageToolbarItemLoad:aBundle];
    
    if ([delegate respondsToSelector:@selector(moduleLoader:hasLoadBundle:)])
        [delegate moduleLoader:self hasLoadBundle:aBundle];
        
    if (_numberOfModulesLoaded >= _numberOfModulesToLoad)
    {
        var center = [CPNotificationCenter defaultCenter];
        
        [center postNotificationName:TNArchipelModulesLoadingCompleteNotification object:self];
        
        if ([delegate respondsToSelector:@selector(moduleLoaderLoadingComplete:)])
            [delegate moduleLoaderLoadingComplete:self];
    }
}


- (void)manageTabItemLoad:(CPBundle)aBundle
{
    var moduleName                  = [aBundle objectForInfoDictionaryKey:@"CPBundleName"];
    var moduleCibName               = [aBundle objectForInfoDictionaryKey:@"CibName"];
    var moduleLabel                 = [aBundle objectForInfoDictionaryKey:@"PluginDisplayName"];
    var moduleIdentifier            = [aBundle objectForInfoDictionaryKey:@"CPBundleIdentifier"];
    var moduleTabIndex              = [aBundle objectForInfoDictionaryKey:@"TabIndex"];
    var supportedTypes              = [aBundle objectForInfoDictionaryKey:@"SupportedEntityTypes"];
    var moduleItem                  = [modulesMenu addItemWithTitle:moduleLabel action:nil keyEquivalent:@""];
    var currentModuleController     = [[[aBundle principalClass] alloc] initWithCibName:moduleCibName bundle:aBundle];
    var moduleRootMenu              = [[CPMenu alloc] init];
    var frame                       = [mainRightView bounds];
    
    
    [[currentModuleController view] setAutoresizingMask:CPViewWidthSizable];
    [currentModuleController setName:moduleName];
    [currentModuleController setLabel:moduleLabel];
    [currentModuleController setBundle:aBundle];

    [moduleItem setEnabled:NO];
    [moduleItem setTarget:currentModuleController];
    [modulesMenu setSubmenu:moduleRootMenu forItem:moduleItem];
    
    [currentModuleController setMenuItem:moduleItem];
    [currentModuleController setMenu:moduleRootMenu];
    [currentModuleController setSupportedEntityTypes:supportedTypes];
    [currentModuleController setIndex:moduleTabIndex];
    [currentModuleController menuReady];
    
    [_loadedTabModules addObject:currentModuleController];
    
}

- (void)manageToolbarItemLoad:(CPBundle)aBundle
{
    var currentModuleController;
    var moduleName              = [aBundle objectForInfoDictionaryKey:@"CPBundleName"];
    var moduleLabel             = [aBundle objectForInfoDictionaryKey:@"PluginDisplayName"];
    var moduleIdentifier        = [aBundle objectForInfoDictionaryKey:@"CPBundleIdentifier"];
    var moduleTabIndex          = [aBundle objectForInfoDictionaryKey:@"TabIndex"];
    var supportedTypes          = [aBundle objectForInfoDictionaryKey:@"SupportedEntityTypes"];
    var moduleToolbarIndex      = [aBundle objectForInfoDictionaryKey:@"ToolbarIndex"];
    var toolbarOnly             = [aBundle objectForInfoDictionaryKey:@"ToolbarItemOnly"];
    var frame                   = [mainRightView bounds];
    var moduleToolbarItem       = [[CPToolbarItem alloc] initWithItemIdentifier:moduleName];
    
    [moduleToolbarItem setLabel:moduleLabel];
    [moduleToolbarItem setImage:[[CPImage alloc] initWithContentsOfFile:[aBundle pathForResource:@"icon.png"] size:CPSizeMake(32,32)]];
    
    // if toolbar item only, no cib
    if (toolbarOnly)
    {
        currentModuleController =  [[[aBundle principalClass] alloc] init];

        [currentModuleController setToolbarItemOnly:YES];
        [moduleToolbarItem setTarget:currentModuleController];
        [moduleToolbarItem setAction:@selector(toolbarItemClicked:)];        
    }
    else
    {
        var moduleCibName       = [aBundle objectForInfoDictionaryKey:@"CibName"];
        currentModuleController = [[[aBundle principalClass] alloc] initWithCibName:moduleCibName bundle:aBundle];
        
        [currentModuleController setToolbarItemOnly:NO];
        
        [moduleToolbarItem setTarget:self];
        [moduleToolbarItem setAction:@selector(didToolbarModuleClicked:)];
    }

    [mainToolbar addItem:moduleToolbarItem withIdentifier:moduleName];
    [mainToolbar setPosition:moduleToolbarIndex forToolbarItemIdentifier:moduleName];
    [mainToolbar _reloadToolbarItems];
    
    [_loadedToolbarModules setObject:currentModuleController forKey:moduleName];
    
    [currentModuleController willLoad];
}


/*! Action that respond on Toolbar TNModules to display the view of the module.
    @param sender the CPToolbarItem that sent the message
*/
- (IBAction)didToolbarModuleClicked:(id)sender
{
    var module  = [_loadedToolbarModules objectForKey:[sender itemIdentifier]];
    var oldModule;

    if (_currentToolbarModule)
    {
        var moduleBundle    = [_currentToolbarModule bundle];
        var iconPath        = [moduleBundle pathForResource:[moduleBundle objectForInfoDictionaryKey:@"ToolbarIcon"]];
        
        oldModule = _currentToolbarModule;
        [_currentToolbarItem setImage:[[CPImage alloc] initWithContentsOfFile:iconPath size:CPSizeMake(32,32)]];
        
        [_currentToolbarModule willHide];
        [[_currentToolbarModule view] removeFromSuperview];
        _currentToolbarModule   = nil;
        _currentToolbarItem     = nil;
    }
        
    if (module != oldModule)
    {
        var bounds          = [mainRightView bounds];
        var moduleBundle    = [module bundle];
        var iconPath        = [moduleBundle pathForResource:[moduleBundle objectForInfoDictionaryKey:@"AlternativeToolbarIcon"]];
        
        [sender setImage:[[CPImage alloc] initWithContentsOfFile:iconPath size:CPSizeMake(32,32)]];
        
        [[module view] setFrame:bounds];
        [module willShow];
        
        [mainRightView addSubview:[module view]];
        
        _currentToolbarModule   = module;
        _currentToolbarItem     = sender;
    }
}
@end
