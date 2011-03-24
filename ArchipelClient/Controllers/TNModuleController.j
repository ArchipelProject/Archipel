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
@import <iTunesTabView/iTunesTabView.j>

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


/*! @global
    @group TNArchipelNotifications
    this notification is sent when all modules are loaded
*/
TNArchipelModulesLoadingCompleteNotification    = @"TNArchipelModulesLoadingCompleteNotification"

/*! @global
    @group TNArchipelNotifications
    this notification is sent when a module is ready
*/
TNArchipelModulesReadyNotification              = @"TNArchipelModulesReadyNotification";

/*! @global
    @group TNArchipelNotifications
    this notification is sent when all modules are ready
*/
TNArchipelModulesAllReadyNotification           = @"TNArchipelModulesAllReadyNotification";


/*! @ingroup archipelcore

    simple TNiTunesTabViewItem subclass to add the TNModule Object inside
*/
@implementation TNModuleTabViewItem : TNiTunesTabViewItem
{
    TNModule _module @accessors(property=module);
}
@end



/*! @ingroup archipelcore

    this is the Archipel Module loader.
    It supports 3 delegates :

     - moduleLoader:hasLoadBundle: is sent when a module is loaded
     - moduleLoader:willLoadBundle: is sent when a module will be loaded
     - moduleLoaderLoadingComplete: is sent when all modules has been loaded
*/
@implementation TNModuleController: CPObject
{
    @outlet  CPView                 viewPermissionDenied;

    BOOL                            _allModulesReady                @accessors(getter=isAllModulesReady);
    BOOL                            _moduleLoadingStarted           @accessors(getter=isModuleLoadingStarted);
    CPArray                         _loadedTabModules               @accessors(getter=loadedTabModules);
    CPDictionary                    _loadedToolbarModules           @accessors(getter=loadedToolbarModules);
    CPMenu                          _modulesMenu                    @accessors(property=modulesMenu);
    CPString                        _modulesPath                    @accessors(property=modulesPath);
    CPString                        _moduleType                     @accessors(property=moduleType);
    CPTextField                     _infoTextField                  @accessors(property=infoTextField);
    CPView                          _mainModuleView                 @accessors(property=mainModuleView);
    id                              _delegate                       @accessors(property=delegate);
    id                              _entity                         @accessors(property=entity);
    int                             _numberOfActiveModules          @accessors(getter=numberOfActiveModules);
    int                             _numberOfReadyModules           @accessors(getter=numberOfReadyModules);
    TNiTunesTabView                 _mainTabView                    @accessors(property=mainTabView);
    TNToolbar                       _mainToolbar                    @accessors(property=mainToolbar);

    CPArray                         _bundles;
    CPDictionary                    _modulesMenuItems;
    CPString                        _previousXMPPShow;
    CPToolbarItem                   _currentToolbarItem;
    CPView                          _currentToolbarModule;
    id                              _modulesPList;
    int                             _numberOfModulesLoaded;
    int                             _numberOfModulesToLoad;
}

#pragma mark -
#pragma mark Initialization

/*! initialize the module loader
    @return an initialized instance of TNModuleLoader
*/
- (void)init
{
    if (self = [super init])
    {
        _loadedTabModulesScrollViews            = [CPDictionary dictionary];
        _loadedToolbarModulesScrollViews        = [CPDictionary dictionary];
        _modulesMenuItems                       = [CPDictionary dictionary];
        _loadedToolbarModules                   = [CPDictionary dictionary];
        _bundles                                = [CPArray array];
        _loadedTabModules                       = [CPArray array];
        _numberOfModulesToLoad                  = 0;
        _numberOfModulesLoaded                  = 0;
        _numberOfActiveModules                  = 0;
        _numberOfReadyModules                   = 0;
        _allModulesReady                        = NO;
        _deactivateModuleTabItemPositionStorage = NO;
        _moduleLoadingStarted                   = NO;
    }

    return self;
}

/*! set the XMPP information that will be gave to Tabs Modules.
    @param anEntity id can contains a TNStropheContact or a TNStropheGroup
    @param aType a type of entity. Can be virtualmachine, hypervisor, user or group
    @param aRoster TNStropheRoster the roster where the TNStropheContact besides
*/
- (BOOL)setEntity:(id)anEntity ofType:(CPString)aType
{
    if (anEntity === _entity)
        return NO;

    var center = [CPNotificationCenter defaultCenter];

    [self _removeAllTabsFromModulesTabView];

    _numberOfActiveModules  = 0;
    _numberOfReadyModules   = 0;
    _allModulesReady        = NO;
    _entity                 = anEntity;
    _moduleType             = aType;

    [center removeObserver:self];

    if (!_entity)
        return;

    [center addObserver:self selector:@selector(_didPresenceUpdate:) name:TNStropheContactPresenceUpdatedNotification object:_entity];
    [center addObserver:self selector:@selector(_didReceiveVcard:) name:TNStropheContactVCardReceivedNotification object:_entity];
    [center addObserver:self selector:@selector(_didAllModulesReady:) name:TNArchipelModulesReadyNotification object:nil];

    if ([_entity class] == TNStropheContact)
    {
        _previousXMPPShow = [_entity XMPPShow];

        if ((_previousXMPPShow != TNStropheContactStatusOffline) && (_previousXMPPShow != TNStropheContactStatusDND))
        {
            [self _populateModulesTabView];
        }
        else
        {
            if (_previousXMPPShow == TNStropheContactStatusOffline)
                [_infoTextField setStringValue:@"Entity is offline"];
            else if (_previousXMPPShow == TNStropheContactStatusDND)
            {
                [self rememberSelectedIndexOfItem:[_mainTabView selectedTabViewItem]];
                [_infoTextField setStringValue:@"Entity do not want to be disturbed"];
            }

            [center postNotificationName:TNArchipelModulesReadyNotification object:self];
        }
    }
    else
    {
        [self _populateModulesTabView];
    }

    return YES;
}


- (void)setCurrentEntityForToolbarModules:(TNStropheContact)anEntity
{
    for (var i = 0; i < [[_loadedToolbarModules allValues] count]; i++)
    {
        var module = [[_loadedToolbarModules allValues] objectAtIndex:i];
        [module setEntity:anEntity];
    }
}


#pragma mark -
#pragma mark Storage

/*! set wich item tab to remember
    @param anItem: the TNiTunesTabView item to remember
*/
- (void)rememberSelectedIndexOfItem:(id)anItem
{
    if (_deactivateModuleTabItemPositionStorage)
        return;

    if (!anItem || !_entity)
        return;

    if ([_mainTabView numberOfTabViewItems] <= 0)
        return;

    var defaults                = [CPUserDefaults standardUserDefaults],
        currentSelectedIndex    = [_mainTabView indexOfTabViewItem:anItem],
        identifier              = ([_entity class] == TNStropheContact) ? [_entity JID] : [_entity name],
        memid                   = @"selectedTabIndexFor" + identifier;

    if (currentSelectedIndex == [defaults integerForKey:memid])
        return;

    CPLog.debug("remembered last selected tabindex " + currentSelectedIndex + " for entity " + _entity);
    [defaults setInteger:currentSelectedIndex forKey:memid];
}

/*! Reselect the last remembered tab index for entity
*/
- (void)recoverFromLastSelectedIndex
{
    var defaults            = [CPUserDefaults standardUserDefaults],
        identifier          = ([_entity class] === TNStropheContact) ? [_entity JID] : [_entity name],
        memid               = @"selectedTabIndexFor" + identifier,
        oldSelectedIndex    = [defaults integerForKey:memid],
        numberOfTabItems    = [_mainTabView numberOfTabViewItems];

    if (!(_entity && (numberOfTabItems > 0) && ((numberOfTabItems - 1) >= oldSelectedIndex) && (oldSelectedIndex != -1)))
        return;

    CPLog.debug("recovering last selected tab index " + oldSelectedIndex);
    [_mainTabView selectTabViewItemAtIndex:oldSelectedIndex];
}


#pragma mark -
#pragma mark Modules loading

/*! will start to load all the bundles describe in modules.plist
*/
- (void)load
{
    var request     = [CPURLRequest requestWithURL:[CPURL URLWithString:@"Modules/modules.plist"]],
        connection  = [CPURLConnection connectionWithRequest:request delegate:self];

    _moduleLoadingStarted = YES;
    [connection cancel];
    [connection start];
}

/*! will load all CPBundle
*/
- (void)_loadNextBundle
{
    var module  = [[_modulesPList objectForKey:@"Modules"] objectAtIndex:_numberOfModulesLoaded],
        path    = _modulesPath + [module objectForKey:@"folder"],
        bundle  = [CPBundle bundleWithPath:path];

    CPLog.debug("Loading " + [CPBundle bundleWithPath:path]);

    if ([_delegate respondsToSelector:@selector(moduleLoader:willLoadBundle:)])
        [_delegate moduleLoader:self willLoadBundle:bundle];

    [bundle loadWithDelegate:self];
}

/*! will display the modules that have to be displayed according to the entity type.
    triggered by -setEntity:ofType:andRoster:
*/
- (void)_populateModulesTabView
{
    var modulesToLoad   = [CPArray array],
        sortDescriptor  = [CPSortDescriptor sortDescriptorWithKey:@"index" ascending:YES],
        sortedValue     = [_loadedTabModules sortedArrayUsingDescriptors:[CPArray arrayWithObject:sortDescriptor]];

    _numberOfActiveModules = 0;

    // we know disable the storage remembering during the tab item populating
    _deactivateModuleTabItemPositionStorage = YES;

    for (var i = 0; i < [sortedValue count]; i++)
    {
        var module      = [sortedValue objectAtIndex:i],
            moduleTypes = [module supportedEntityTypes];

        if ([moduleTypes containsObject:_moduleType])
        {
            [self _addItemToModulesTabView:module];
            _numberOfActiveModules++;
        }
    }
    // and we reactivate it
    _deactivateModuleTabItemPositionStorage = NO;

    [self recoverFromLastSelectedIndex];
}

/*! will remove all loaded modules and send message willUnload to all TNModules
*/
- (void)_removeAllTabsFromModulesTabView
{
    if ([_mainTabView numberOfTabViewItems] <= 0)
        return;

    var arrayCpy = [CPArray arrayWithArray:[_mainTabView tabViewItems]];

    for (var i = 0; i < [arrayCpy count]; i++)
    {
        var tabViewItem = [arrayCpy objectAtIndex:i],
            module      = [tabViewItem module];

        [module willUnload];
        [module setEntity:nil];

        [[module view] scrollPoint:CPMakePoint(0.0, 0.0)];

        [[tabViewItem view] setDocumentView:nil];
        [[tabViewItem view] removeFromSuperview];
        [_mainTabView removeTabViewItem:tabViewItem];
    }

    delete arrayCpy;
}

/*! insert a TNModules embeded in a scroll view to the mainToolbarView CPView
    @param aLabel CPString containing the displayed label
    @param aModuleScrollView CPScrollView containing the TNModule
    @param anIndex CPNumber representing the insertion index
*/
- (void)_addItemToModulesTabView:(TNModule)aModule
{
    var frame           = [_mainModuleView bounds],
        newViewItem     = [[TNModuleTabViewItem alloc] initWithIdentifier:[aModule name]],
        scrollView      = [[CPScrollView alloc] initWithFrame:frame];

    [scrollView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [scrollView setAutohidesScrollers:YES];
    [scrollView setBackgroundColor:[CPColor whiteColor]];

    if ([[aModule bundle] objectForInfoDictionaryKey:@"FullscreenModule"])
    {
        [[aModule view] setFrame:frame];
        [[aModule view] setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    }
    else
    {
        frame.size.height = [[aModule view] bounds].size.height;
        [[aModule view] setFrame:frame];
    }

    [newViewItem setModule:aModule];
    [newViewItem setLabel:[aModule label]];
    [newViewItem setView:scrollView];

    [aModule setEntity:_entity];

    [scrollView setDocumentView:[aModule view]];

    [aModule _beforeWillLoad];

    [_mainTabView addTabViewItem:newViewItem];
}

/*! Insert a Tab item module
    @param aBundle the CPBundle contaning the TNModule
*/
- (void)manageTabItemLoad:(CPBundle)aBundle
{
    var moduleName                  = [aBundle objectForInfoDictionaryKey:@"CPBundleName"],
        moduleCibName               = [aBundle objectForInfoDictionaryKey:@"CibName"],
        moduleLabel                 = [aBundle objectForInfoDictionaryKey:@"PluginDisplayName"],
        moduleIdentifier            = [aBundle objectForInfoDictionaryKey:@"CPBundleIdentifier"],
        moduleTabIndex              = [aBundle objectForInfoDictionaryKey:@"TabIndex"],
        supportedTypes              = [aBundle objectForInfoDictionaryKey:@"SupportedEntityTypes"],
        useMenu                     = [aBundle objectForInfoDictionaryKey:@"UseModuleMenu"],
        mandatoryPermissions        = [aBundle objectForInfoDictionaryKey:@"MandatoryPermissions"],
        moduleItem                  = [[CPMenuItem alloc] init],
        moduleRootMenu              = [[CPMenu alloc] init],
        currentModuleController     = [[[aBundle principalClass] alloc] initWithCibName:moduleCibName bundle:aBundle],
        frame                       = [_mainModuleView bounds];

    [currentModuleController initializeModule];
    [[currentModuleController view] setAutoresizingMask:CPViewWidthSizable];
    [currentModuleController setName:moduleName];
    [currentModuleController setLabel:moduleLabel];
    [currentModuleController setBundle:aBundle];
    [currentModuleController setModuleType:TNArchipelModuleTypeTab];
    [currentModuleController setSupportedEntityTypes:supportedTypes];
    [currentModuleController setIndex:moduleTabIndex];
    [currentModuleController setMandatoryPermissions:mandatoryPermissions];
    [currentModuleController setViewPermissionDenied:viewPermissionDenied];

    if (useMenu)
    {
        [moduleItem setTitle:moduleLabel];
        [_modulesMenu setAutoenablesItems:NO];
        [moduleItem setTarget:currentModuleController];
        [_modulesMenu setSubmenu:moduleRootMenu forItem:moduleItem];
        [currentModuleController setMenuItem:moduleItem];
        [currentModuleController setMenu:moduleRootMenu];
        [currentModuleController menuReady];

        [moduleItem setEnabled:NO];

        if (![_modulesMenuItems containsKey:supportedTypes])
            [_modulesMenuItems setObject:[CPArray array] forKey:supportedTypes];

        [[_modulesMenuItems objectForKey:supportedTypes] addObject:moduleItem];
    }

    [_loadedTabModules addObject:currentModuleController];

}

/*! Insert a toolbar item module
    @param aBundle the CPBundle contaning the TNModule
*/
- (void)manageToolbarItemLoad:(CPBundle)aBundle
{
    var currentModuleController,
        moduleName              = [aBundle objectForInfoDictionaryKey:@"CPBundleName"],
        moduleLabel             = [aBundle objectForInfoDictionaryKey:@"PluginDisplayName"],
        moduleIdentifier        = [aBundle objectForInfoDictionaryKey:@"CPBundleIdentifier"],
        moduleTabIndex          = [aBundle objectForInfoDictionaryKey:@"TabIndex"],
        supportedTypes          = [aBundle objectForInfoDictionaryKey:@"SupportedEntityTypes"],
        moduleToolbarIndex      = [aBundle objectForInfoDictionaryKey:@"ToolbarIndex"],
        toolbarOnly             = [aBundle objectForInfoDictionaryKey:@"ToolbarItemOnly"],
        mandatoryPermissions    = [aBundle objectForInfoDictionaryKey:@"MandatoryPermissions"],
        frame                   = [_mainModuleView bounds],
        moduleToolbarItem       = [[CPToolbarItem alloc] initWithItemIdentifier:moduleName];

    [moduleToolbarItem setLabel:moduleLabel];
    [moduleToolbarItem setImage:[[CPImage alloc] initWithContentsOfFile:[aBundle pathForResource:@"icon.png"] size:CPSizeMake(32, 32)]];
    [moduleToolbarItem setAlternateImage:[[CPImage alloc] initWithContentsOfFile:[aBundle pathForResource:@"icon-alt.png"] size:CPSizeMake(32, 32)]];

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
        [[currentModuleController view] setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

        [moduleToolbarItem setTarget:self];
        [moduleToolbarItem setAction:@selector(didToolbarModuleClicked:)];
    }

    [_mainToolbar addItem:moduleToolbarItem withIdentifier:moduleName];
    [_mainToolbar setPosition:moduleToolbarIndex forToolbarItemIdentifier:moduleName];
    //[_mainToolbar _reloadToolbarItems];

    [currentModuleController initializeModule];
    [currentModuleController setName:moduleName];
    [currentModuleController setToolbarItem:moduleToolbarItem];
    [currentModuleController setToolbar:_mainToolbar];
    [currentModuleController setLabel:moduleLabel];
    [currentModuleController setModuleType:TNArchipelModuleTypeToolbar];
    [currentModuleController setMandatoryPermissions:mandatoryPermissions];
    [currentModuleController setViewPermissionDenied:viewPermissionDenied];

    [_loadedToolbarModules setObject:currentModuleController forKey:moduleName];

    [currentModuleController _beforeWillLoad];
}

/*! Insert all modules' MainMenu items
*/
- (void)insertModulesMenuItems
{
    var modulesNames    = [_modulesMenuItems allKeys].sort(), // it would be better to also use a sort desc but it doesn't work..
        sortDescriptor  = [CPSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];

    for (var k = 0; k < [modulesNames count] ; k++)
    {
        var menuItems       = [_modulesMenuItems objectForKey:[modulesNames objectAtIndex:k]],
            sortedMenuItems = [menuItems sortedArrayUsingDescriptors:[CPArray arrayWithObject:sortDescriptor]];

        for (var i = 0; i < [sortedMenuItems count]; i++)
            [_modulesMenu addItem:[sortedMenuItems objectAtIndex:i]];

        if (k + 1 < [modulesNames count])
            [_modulesMenu addItem:[CPMenuItem separatorItem]];
    }
}


#pragma mark -
#pragma mark Notifications handlers

/*! triggered on TNStropheContactPresenceUpdatedNotification receiption. This will sent _removeAllTabsFromModulesTabView
    to self if presence if Offline. If presence was Offline and bacame online, it will ask for the vCard to
    know what TNModules to load.
*/
- (void)_didPresenceUpdate:(CPNotification)aNotification
{
    if ([[aNotification object] XMPPShow] == TNStropheContactStatusOffline)
    {
        _numberOfActiveModules  = 0;
        _allModulesReady        = NO;

        [self _removeAllTabsFromModulesTabView];
        _previousXMPPShow = TNStropheContactStatusOffline;
        [_infoTextField setStringValue:@"Entity is offline"];
    }
    else if ([[aNotification object] XMPPShow] == TNStropheContactStatusDND)
    {
        _numberOfActiveModules  = 0;
        _allModulesReady        = NO;

        [self _removeAllTabsFromModulesTabView];
        _previousXMPPShow = TNStropheContactStatusDND;
        [_infoTextField setStringValue:@"Entity do not want to be disturbed"];
    }
    else if ((_previousXMPPShow == TNStropheContactStatusOffline) || (_previousXMPPShow == TNStropheContactStatusDND))
    {
        _previousXMPPShow           = nil;
        _numberOfActiveModules      = 0;
        _allModulesReady            = NO;

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

    if ([vCard text] != [[_entity vCard] text])
    {
        _moduleType = [[[TNStropheIMClient defaultClient] roster] analyseVCard:vCard];

        [self _removeAllTabsFromModulesTabView];
        [self _populateModulesTabView];
    }
}

/*! Triggered when all modules are ready
*/
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


#pragma mark -
#pragma mark Delegates

/*! TNiTunesTabView delegate. Wil check if current tab item is OK to be hidden
    @param aTabView the TNiTunesTabView that sent the message (_mainTabView)
    @param anItem the item that should be selected
*/
- (BOOL)tabView:(TNiTunesTabView)aTabView shouldSelectTabViewItem:(TNModuleTabViewItem)anItem
{
    if ([aTabView numberOfTabViewItems] <= 0)
        return YES;

    var currentTabItem = [aTabView selectedTabViewItem];

    if (!currentTabItem)
        return YES;

    var currentModule = [currentTabItem module];

    return [currentModule shouldHideAndSelectItem:anItem ofObject:aTabView];
}


/*! TNiTunesTabView delegate. Will sent willHide to current tab module and willShow to the one that will be be display
    @param aTabView the TNiTunesTabView that sent the message (_mainTabView)
    @param anItem the new selected item
*/
- (void)tabView:(TNiTunesTabView)aTabView willSelectTabViewItem:(TNModuleTabViewItem)anItem
{
    if ([aTabView numberOfTabViewItems] <= 0)
        return

    var currentTabItem = [aTabView selectedTabViewItem];

    if (currentTabItem == anItem)
        return;

    if (currentTabItem)
    {
        var oldModule = [currentTabItem module];

        [oldModule willHide];
        [oldModule setCurrentSelectedIndex:NO];

        [self rememberSelectedIndexOfItem:anItem];
    }

    var newModule = [anItem module];
    [newModule setCurrentSelectedIndex:YES];
    [newModule willShow];
}

/*! delegate of CPURLConnection triggered when modules.plist is loaded.
    @param connection CPURLConnection that sent the message
    @param data CPString containing the result of the url
*/
- (void)connection:(CPURLConnection)connection didReceiveData:(CPString)data
{
    var cpdata = [CPData dataWithRawString:data];

    CPLog.info(@"Module.plist recovered");

    _modulesPList           = [cpdata plistObject];
    _numberOfModulesToLoad  = [[_modulesPList objectForKey:@"Modules"] count];

    [self _removeAllTabsFromModulesTabView];

    [self _loadNextBundle];
}

/*! delegate of CPBundle. Will initialize all the modules in plist
    @param aBundle CPBundle that sent the message
*/
- (void)bundleDidFinishLoading:(CPBundle)aBundle
{
    var moduleInsertionType = [aBundle objectForInfoDictionaryKey:@"InsertionType"];

    [_bundles addObject:aBundle];

    if (moduleInsertionType == TNArchipelModuleTypeTab)
        [self manageTabItemLoad:aBundle];
    else if (moduleInsertionType == TNArchipelModuleTypeToolbar)
        [self manageToolbarItemLoad:aBundle];

    _numberOfModulesLoaded++;
    CPLog.debug("Loaded " + _numberOfModulesLoaded + " module(s) of " + _numberOfModulesToLoad)

    if ([_delegate respondsToSelector:@selector(moduleLoader:loadedBundle:progress:)])
        [_delegate moduleLoader:self loadedBundle:aBundle progress:(_numberOfModulesLoaded / _numberOfModulesToLoad)];


    if (_numberOfModulesLoaded == _numberOfModulesToLoad)
    {
        var center = [CPNotificationCenter defaultCenter];

        [center postNotificationName:TNArchipelModulesLoadingCompleteNotification object:self];

        if ([_delegate respondsToSelector:@selector(moduleLoaderLoadingComplete:)])
        {
            [_delegate moduleLoaderLoadingComplete:self];
            [self insertModulesMenuItems];
        }
    }
    else
    {
        [self _loadNextBundle];
    }
}



#pragma mark -
#pragma mark Actions

/*! Action that respond on Toolbar TNModules to display the view of the module.
    @param sender the CPToolbarItem that sent the message
*/
- (IBAction)didToolbarModuleClicked:(id)sender
{
    var module  = [_loadedToolbarModules objectForKey:[sender itemIdentifier]],
        oldModule;

    if (_currentToolbarModule)
    {
        var moduleBundle    = [_currentToolbarModule bundle],
            iconPath        = [moduleBundle pathForResource:[moduleBundle objectForInfoDictionaryKey:@"ToolbarIcon"]];

        oldModule = _currentToolbarModule;
        [_currentToolbarItem setImage:[[CPImage alloc] initWithContentsOfFile:iconPath size:CPSizeMake(32,32)]];

        [_currentToolbarModule willHide];
        [[_currentToolbarModule view] removeFromSuperview];
        _currentToolbarModule   = nil;
        _currentToolbarItem     = nil;

        [_mainToolbar deselectToolbarItem];
    }

    if (module != oldModule)
    {
        var bounds          = [_mainModuleView bounds],
            moduleBundle    = [module bundle],
            iconPath        = [moduleBundle pathForResource:[moduleBundle objectForInfoDictionaryKey:@"AlternativeToolbarIcon"]];

        [sender setImage:[[CPImage alloc] initWithContentsOfFile:iconPath size:CPSizeMake(32,32)]];

        [[module view] setFrame:bounds];
        [module willShow];

        [_mainModuleView addSubview:[module view]];

        _currentToolbarModule   = module;
        _currentToolbarItem     = sender;

        [_mainToolbar selectToolbarItem:sender];
    }
}

@end
