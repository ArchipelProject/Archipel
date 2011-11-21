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

@import <AppKit/CPMenu.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPToolbarItem.j>
@import <AppKit/CPView.j>

@import <StropheCappuccino/StropheCappuccino.j>
@import <TNKit/TNTabView.j>
@import <TNKit/TNToolbar.j>

/*! @global
    @group TNArchipelModuleType
    type for tab module
*/
TNArchipelModuleTypeTab     = @"tab";
TNArchipelModuleTypeToolbar = @"toolbar";

TNArchipelModulesLoadingCompleteNotification    = @"TNArchipelModulesLoadingCompleteNotification";
TNArchipelModulesReadyNotification              = @"TNArchipelModulesReadyNotification";
TNArchipelModulesAllReadyNotification           = @"TNArchipelModulesAllReadyNotification";
TNArchipelModulesVisibilityRequestNotification  = @"TNArchipelModulesVisibilityRequestNotification";


/*! @ingroup archipelcore
    simple TNTabViewItem subclass to add the TNModule Object inside
*/
@implementation TNModuleTabViewItem : CPTabViewItem
{
    TNModule    _module    @accessors(property=module);
    int         _index     @accessors(property=index);
}
@end


/*! @ingroup archipelcore

    this is the Archipel Module loader.
    It supports 3 delegate methods:

     - moduleLoader:hasLoadBundle: is sent when a module is loaded
     - moduleLoader:willLoadBundle: is sent when a module will be loaded
     - moduleLoaderLoadingComplete: is sent when all modules has been loaded
*/
@implementation TNModuleController: CPObject
{
    @outlet CPView                  viewPermissionDenied;

    BOOL                            _allModulesReady                @accessors(getter=isAllModulesReady);
    BOOL                            _moduleLoadingStarted           @accessors(getter=isModuleLoadingStarted);
    CPColor                         _toolbarModuleBackgroundColor   @accessors(property=toolbarModuleBackgroundColor);
    CPMenu                          _modulesMenu                    @accessors(property=modulesMenu);
    CPMenu                          _rosterContactsMenu             @accessors(property=rosterContactsMenu);
    CPMenu                          _rosterGroupsMenu               @accessors(property=rosterGroupsMenu);
    CPString                        _modulesPath                    @accessors(property=modulesPath);
    CPString                        _moduleType                     @accessors(property=moduleType);
    CPTextField                     _infoTextField                  @accessors(property=infoTextField);
    CPView                          _mainModuleView                 @accessors(property=mainModuleView);
    id                              _delegate                       @accessors(property=delegate);
    id                              _entity                         @accessors(property=entity);
    int                             _numberOfActiveModules          @accessors(getter=numberOfActiveModules);
    int                             _numberOfReadyModules           @accessors(getter=numberOfReadyModules);
    TNTabView                       _mainTabView                    @accessors(property=mainTabView);
    TNToolbar                       _mainToolbar                    @accessors(property=mainToolbar);

    CPDictionary                    _modulesMenuItems;
    CPDictionary                    _openedTabsRegistry;
    CPDictionary                    _tabModules;
    CPDictionary                    _toolbarModules;
    CPString                        _previousXMPPShow;
    id                              _modulesPList;
    int                             _numberOfModulesLoaded;
    int                             _numberOfModulesToLoad;
    TNModule                        _currentToolbarModule;
}


#pragma mark -
#pragma mark Initialization

/*! called at cib awakening
*/
- (void)awakeFromCib
{
    [viewPermissionDenied setBackgroundColor:[CPColor whiteColor]];
}

/*! initialize the module loader
    @return an initialized instance of TNModuleLoader
*/
- (void)init
{
    if (self = [super init])
    {
        var defaults = [CPUserDefaults standardUserDefaults];

        _modulesMenuItems                       = [CPDictionary dictionary];
        _toolbarModules                         = [CPDictionary dictionary];
        _tabModules                             = [CPDictionary dictionary];
        _numberOfModulesToLoad                  = 0;
        _numberOfModulesLoaded                  = 0;
        _numberOfActiveModules                  = 0;
        _numberOfReadyModules                   = 0;
        _allModulesReady                        = NO;
        _deactivateModuleTabItemPositionStorage = NO;
        _moduleLoadingStarted                   = NO;
        _openedTabsRegistry                     = [CPDictionary dictionary];

        if  (![defaults objectForKey:@"TNArchipelModuleControllerOpenedTabRegistry"])
            [defaults setObject:_openedTabsRegistry forKey:@"TNArchipelModuleControllerOpenedTabRegistry"];
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
    if (_numberOfModulesToLoad && _numberOfModulesLoaded != _numberOfModulesToLoad)
        return NO;

    if ((anEntity === _entity) && (anEntity != nil))
        return NO;

    var center = [CPNotificationCenter defaultCenter];

    [self _removeAllTabsFromModulesTabView];
    [_infoTextField setStringValue:@""];
    [_infoTextField setHidden:YES];

    _numberOfActiveModules  = 0;
    _numberOfReadyModules   = 0;
    _allModulesReady        = NO;
    _entity                 = anEntity;
    _moduleType             = aType;

    [center removeObserver:self];
    [[CPNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_didReceiveVisibilityRequest:)
                                                 name:TNArchipelModulesVisibilityRequestNotification
                                               object:nil];


    if (_moduleType != TNArchipelEntityTypeGeneral)
    {
        [center addObserver:self selector:@selector(_didPresenceUpdate:) name:TNStropheContactPresenceUpdatedNotification object:_entity];
        [center addObserver:self selector:@selector(_didReceiveVcard:) name:TNStropheContactVCardReceivedNotification object:_entity];
    }
    [center addObserver:self selector:@selector(_didAllModulesReady:) name:TNArchipelModulesReadyNotification object:nil];

    if ([_entity isKindOfClass:TNStropheContact])
    {
        _previousXMPPShow = [_entity XMPPShow];

        if ((_previousXMPPShow != TNStropheContactStatusOffline) && (_previousXMPPShow != TNStropheContactStatusDND))
        {
            [self _populateModulesTabView];
        }
        else
        {
            if (_previousXMPPShow == TNStropheContactStatusOffline)
            {
                [_infoTextField setStringValue:@"Entity is offline"];
                [_infoTextField setHidden:NO];
            }
            else if (_previousXMPPShow == TNStropheContactStatusDND)
            {
                if ([_mainTabView selectedTabViewItem])
                    [self rememberSelectedIndexOfItem:[_mainTabView selectedTabViewItem]];
                [_infoTextField setStringValue:@"Entity does not want to be disturbed"];
                [_infoTextField setHidden:NO];
            }
            else
            {
                [_infoTextField setStringValue:@""];
                [_infoTextField setHidden:YES];
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
    for (var i = 0; i < [[self toolbarModules] count]; i++)
    {
        var module = [[self toolbarModules] objectAtIndex:i];
        [module setEntity:anEntity];
    }
}


#pragma mark -
#pragma mark Getters / Setters

/*! Return an Array of all TNModules loaded
*/
- (CPArray)tabModules
{
    return [_tabModules allValues];
}

/*! Return an Array of all TNModules loaded
*/
- (CPArray)toolbarModules
{
    return [_toolbarModules allValues];
}


#pragma mark -
#pragma mark Storage

/*! set wich item tab to remember
    @param anItem: the TNTabView item to remember
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
        identifier              = ([_entity isKindOfClass:TNStropheContact]) ? [_entity JID] : [_entity name],
        memid                   = @"selectedTabIndexFor" + identifier;

    if (currentSelectedIndex == [[defaults objectForKey:@"TNArchipelModuleControllerOpenedTabRegistry"] objectForKey:memid])
        return;

    CPLog.info("remembered last selected tabindex " + currentSelectedIndex + " for entity " + _entity);
    [[defaults objectForKey:@"TNArchipelModuleControllerOpenedTabRegistry"] setObject:currentSelectedIndex forKey:memid];
}

/*! Reselect the last remembered tab index for entity
*/
- (void)recoverFromLastSelectedIndex
{
    var defaults            = [CPUserDefaults standardUserDefaults],
        identifier          = ([_entity isKindOfClass:TNStropheContact]) ? [_entity JID] : [_entity name],
        memid               = @"selectedTabIndexFor" + identifier,
        oldSelectedIndex    = [[defaults objectForKey:@"TNArchipelModuleControllerOpenedTabRegistry"] objectForKey:memid] || 0,
        numberOfTabItems    = [_mainTabView numberOfTabViewItems];

    if (!(_entity && (numberOfTabItems > 0) && ((numberOfTabItems - 1) >= oldSelectedIndex) && (oldSelectedIndex != -1)))
        return;

    CPLog.info("recovering last selected tab index " + oldSelectedIndex);

    if ([_mainTabView selectedTabViewIndex] != oldSelectedIndex)
        [_mainTabView selectTabViewItemAtIndex:oldSelectedIndex];
}


#pragma mark -
#pragma mark Modules loading

/*! will start to load all the bundles describe in modules.plist
*/
- (void)load
{
    var request = [CPURLRequest requestWithURL:[CPURL URLWithString:@"Modules/modules.plist"]],
        connection = [CPURLConnection connectionWithRequest:request delegate:self];

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

/*! @ignore
    Insert a Tab item module
    @param aBundle the CPBundle contaning the TNModule
*/
- (void)_manageTabItemLoad:(CPBundle)aBundle
{
    var defaults                    = [CPUserDefaults standardUserDefaults],
        moduleName                  = [aBundle objectForInfoDictionaryKey:@"CPBundleName"],
        moduleLabel                 = [aBundle objectForInfoDictionaryKey:@"PluginDisplayName"],
        moduleTabIndex              = [aBundle objectForInfoDictionaryKey:@"TabIndex"],
        supportedTypes              = [aBundle objectForInfoDictionaryKey:@"SupportedEntityTypes"],
        useMenu                     = [aBundle objectForInfoDictionaryKey:@"UseModuleMenu"],
        mandatoryPermissions        = [aBundle objectForInfoDictionaryKey:@"MandatoryPermissions"],
        bundleLocale                = [aBundle objectForInfoDictionaryKey:@"CPBundleLocale"],
        entityDefinition            = [aBundle objectForInfoDictionaryKey:@"EntityTypesRegistry"],
        isFullscreen                = [aBundle objectForInfoDictionaryKey:@"FullscreenModule"],
        moduleIdentifier            = [aBundle objectForInfoDictionaryKey:@"CPBundleIdentifier"],
        moduleItem                  = [[CPMenuItem alloc] init],
        moduleRootMenu              = [[CPMenu alloc] init],
        frame                       = [_mainModuleView bounds],
        scrollView                  = [[CPScrollView alloc] initWithFrame:CPRectMakeZero()],
        moduleTabItem               = [[TNModuleTabViewItem alloc] initWithIdentifier:moduleIdentifier],
        currentModuleController     = [self _loadLocalizedModuleController:bundleLocale forBundle:aBundle];

    if ([moduleLabel isKindOfClass:CPDictionary] && bundleLocale)
    {
        moduleLabel = [moduleLabel objectForKey:[defaults objectForKey:@"CPBundleLocale"]];
        if (!moduleLabel)
            moduleLabel = [[aBundle objectForInfoDictionaryKey:@"PluginDisplayName"] objectForKey:@"en"];
    }

    // Register custom entity types if told so by the module
    if (entityDefinition)
    {
        var entityType = [entityDefinition objectForKey:@"Type"],
            entityDescriptionGroup = [entityDefinition objectForKey:@"Description"];

        if (!entityDescriptionGroup)
            entityDescription = entityType;
        else
        {
            entityDescription = [entityDescriptionGroup objectForKey:[defaults objectForKey:@"CPBundleLocale"]];
            if (!entityDescription)
                entityDescription = [entityDescriptionGroup objectForKey:@"en"];
        }

        // Register the entity types in the global variable
        [TNArchipelEntityTypes setObject:entityDescription forKey:entityType];
    }

    [currentModuleController initializeModule];
    [currentModuleController setBundle:aBundle];
    [currentModuleController setFullscreen:isFullscreen];
    [currentModuleController setHasCIB:YES];
    [currentModuleController setIdentifier:moduleIdentifier];
    [currentModuleController setIndex:moduleTabIndex];
    [currentModuleController setLabel:moduleLabel];
    [currentModuleController setMandatoryPermissions:mandatoryPermissions];
    [currentModuleController setModuleType:TNArchipelModuleTypeTab];
    [currentModuleController setName:moduleName];
    [currentModuleController setSupportedEntityTypes:supportedTypes];
    [currentModuleController setUIItem:moduleTabItem];
    [currentModuleController setUIObject:_mainTabView];
    [currentModuleController setViewPermissionDenied:viewPermissionDenied];

    [[currentModuleController view] setAutoresizingMask:CPViewWidthSizable];

    if (useMenu)
    {
        [moduleItem setTitle:moduleLabel];
        [moduleItem setTarget:currentModuleController];
        [_modulesMenu setAutoenablesItems:NO];
        [_modulesMenu setSubmenu:moduleRootMenu forItem:moduleItem];
        [currentModuleController setRosterGroupsMenu:_rosterGroupsMenu];
        [currentModuleController setRosterContactsMenu:_rosterContactsMenu];
        [currentModuleController setMenuItem:moduleItem];
        [currentModuleController setMenu:moduleRootMenu];
        [currentModuleController menuReady];

        [moduleItem setEnabled:NO];

        if (![_modulesMenuItems containsKey:supportedTypes])
            [_modulesMenuItems setObject:[CPArray array] forKey:supportedTypes];

        [[_modulesMenuItems objectForKey:supportedTypes] addObject:moduleItem];
    }

    // we now create the tabView item that will be inserted in the tab view when needed
    [scrollView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [scrollView setAutohidesScrollers:YES];
    [scrollView setDocumentView:[currentModuleController view]];

    [moduleTabItem setModule:currentModuleController];
    [moduleTabItem setLabel:moduleLabel];
    [moduleTabItem setView:scrollView];
    [moduleTabItem setIndex:moduleTabIndex];

    [_tabModules setObject:currentModuleController forKey:moduleIdentifier];
}

/*! @ignore
    Insert a toolbar item module
    @param aBundle the CPBundle contaning the TNModule
*/
- (void)_manageToolbarItemLoad:(CPBundle)aBundle
{
    var currentModuleController,
        defaults                = [CPUserDefaults standardUserDefaults],
        moduleName              = [aBundle objectForInfoDictionaryKey:@"CPBundleName"],
        moduleLabel             = [aBundle objectForInfoDictionaryKey:@"PluginDisplayName"],
        moduleTabIndex          = [aBundle objectForInfoDictionaryKey:@"TabIndex"],
        moduleToolTip           = [aBundle objectForInfoDictionaryKey:@"ToolTip"],
        supportedTypes          = [aBundle objectForInfoDictionaryKey:@"SupportedEntityTypes"],
        moduleToolbarIndex      = [aBundle objectForInfoDictionaryKey:@"ToolbarIndex"],
        toolbarOnly             = [aBundle objectForInfoDictionaryKey:@"ToolbarItemOnly"],
        mandatoryPermissions    = [aBundle objectForInfoDictionaryKey:@"MandatoryPermissions"],
        bundleLocale            = [aBundle objectForInfoDictionaryKey:@"CPBundleLocale"],
        isFullscreen            = [aBundle objectForInfoDictionaryKey:@"FullscreenModule"],
        moduleIdentifier        = [aBundle objectForInfoDictionaryKey:@"CPBundleIdentifier"],
        frame                   = [_mainModuleView bounds],
        moduleToolbarItem       = [[CPToolbarItem alloc] initWithItemIdentifier:moduleIdentifier];

    if ([moduleLabel isKindOfClass:CPDictionary] && bundleLocale)
        moduleLabel = [moduleLabel objectForKey:[defaults objectForKey:@"CPBundleLocale"]] || [moduleLabel objectForKey:@"en"];

    if ([moduleToolTip isKindOfClass:CPDictionary] && bundleLocale)
        moduleToolTip = [moduleToolTip objectForKey:[defaults objectForKey:@"CPBundleLocale"]];

    [moduleToolbarItem setLabel:moduleLabel];
    [moduleToolbarItem setImage:[[CPImage alloc] initWithContentsOfFile:[aBundle pathForResource:@"icon.png"] size:CPSizeMake(32, 32)]];
    [moduleToolbarItem setAlternateImage:[[CPImage alloc] initWithContentsOfFile:[aBundle pathForResource:@"icon-alt.png"] size:CPSizeMake(32, 32)]];
    [moduleToolbarItem setToolTip:moduleToolTip];

    // if toolbar item only, no cib
    if (toolbarOnly)
    {
        currentModuleController = [[[aBundle principalClass] alloc] init];
        [currentModuleController setHasCIB:NO];

        [moduleToolbarItem setTarget:currentModuleController];
        [moduleToolbarItem setAction:@selector(toolbarItemClicked:)];
    }
    else
    {
        currentModuleController = [self _loadLocalizedModuleController:bundleLocale forBundle:aBundle];

        [currentModuleController setHasCIB:YES];
        [[currentModuleController view] setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        [[currentModuleController view] setBackgroundColor:_toolbarModuleBackgroundColor];

        [moduleToolbarItem setTarget:self];
        [moduleToolbarItem setAction:@selector(didToolbarModuleClicked:)];
    }

    [_mainToolbar addItem:moduleToolbarItem withIdentifier:moduleIdentifier];
    [_mainToolbar setPosition:moduleToolbarIndex forToolbarItemIdentifier:moduleIdentifier];

    [currentModuleController initializeModule];
    [currentModuleController setFullscreen:isFullscreen];
    [currentModuleController setIdentifier:moduleIdentifier];
    [currentModuleController setLabel:moduleLabel];
    [currentModuleController setMandatoryPermissions:mandatoryPermissions];
    [currentModuleController setModuleType:TNArchipelModuleTypeToolbar];
    [currentModuleController setName:moduleName];
    [currentModuleController setUIItem:moduleToolbarItem];
    [currentModuleController setUIObject:_mainToolbar];
    [currentModuleController setViewPermissionDenied:viewPermissionDenied];

    [_toolbarModules setObject:currentModuleController forKey:moduleIdentifier];

    [currentModuleController _beforeWillLoad];
}

/*! Insert all modules' MainMenu items
*/
- (void)_insertModulesMenuItems
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

/*! Get the loacalized version of the bundle
    @param bundleLocale the locale to use
    @param aBundle the bundle to load
    @return localized and initialized bundle principal class
*/
- (id)_loadLocalizedModuleController:(CPString)bundleLocale forBundle:(CPBundle)aBundle
{
    var defaults = [CPUserDefaults standardUserDefaults],
        moduleIdentifier = [aBundle objectForInfoDictionaryKey:@"CPBundleIdentifier"],
        moduleCibName = [aBundle objectForInfoDictionaryKey:@"CibName"],
        localizedCibName = [defaults objectForKey:@"CPBundleLocale"] + @".lproj/" + moduleCibName,
        localizationStringsURL = [aBundle pathForResource:[defaults objectForKey:@"CPBundleLocale"] + ".lproj/Localizable.xstrings"],
        englishStringsURL = [aBundle pathForResource:@"en.lproj/Localizable.xstrings"];

    // we don't use CPURLConnection because what is important is the error code
    // not the content that vary accross servers...
    var req = new XMLHttpRequest();
    req.open("GET", localizationStringsURL, false);
    req.send(null);
    if (req.status == 200)
    {
        CPLog.debug("MODULE LOADER: " + moduleIdentifier + " : Found the translation " + [defaults objectForKey:@"CPBundleLocale"]
            + " strings information as expected at " + localizationStringsURL)
        var plist = [CPPropertyListSerialization propertyListFromData:[CPData dataWithRawString:req.responseText] format:nil];

        [aBundle setDictionary:plist forTable:@"Localizable"];

        return [[[aBundle principalClass] alloc] initWithCibName:localizedCibName bundle:aBundle];
    }
    else
    {
        CPLog.debug("MODULE LOADER: " + moduleIdentifier + " : Unable to  the translation " + [defaults objectForKey:@"CPBundleLocale"]
            + ". Getting english at URL " + englishStringsURL)

        var req = new XMLHttpRequest();
        req.open("GET", englishStringsURL, false);
        req.send(null);

        var plist = [CPPropertyListSerialization propertyListFromData:[CPData dataWithRawString:req.responseText] format:nil],
            localizedCibName = @"en.lproj/" + moduleCibName;

        [aBundle setDictionary:plist forTable:@"Localizable"];

        return [[[aBundle principalClass] alloc] initWithCibName:localizedCibName bundle:aBundle];
    }
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

    [self _loadNextBundle];
}

/*! delegate of CPBundle. Will initialize all the modules in plist
    @param aBundle CPBundle that sent the message
*/
- (void)bundleDidFinishLoading:(CPBundle)aBundle
{
    var moduleInsertionType = [aBundle objectForInfoDictionaryKey:@"InsertionType"];

    if (moduleInsertionType == TNArchipelModuleTypeTab)
        [self _manageTabItemLoad:aBundle];
    else if (moduleInsertionType == TNArchipelModuleTypeToolbar)
        [self _manageToolbarItemLoad:aBundle];

    _numberOfModulesLoaded++;
    CPLog.debug("Loaded " + _numberOfModulesLoaded + " module(s) of " + _numberOfModulesToLoad)

    if (_numberOfModulesLoaded == _numberOfModulesToLoad)
    {
        [[CPNotificationCenter defaultCenter] postNotificationName:TNArchipelModulesLoadingCompleteNotification object:self];

        if ([_delegate respondsToSelector:@selector(moduleLoaderLoadingComplete:)])
            [_delegate moduleLoaderLoadingComplete:self];
        [self _insertModulesMenuItems];
    }
    else
    {
        if ([_delegate respondsToSelector:@selector(moduleLoader:loadedBundle:progress:)])
            [_delegate moduleLoader:self loadedBundle:aBundle progress:(_numberOfModulesLoaded / _numberOfModulesToLoad)];

        [self _loadNextBundle];
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
    if (_numberOfModulesLoaded != _numberOfModulesToLoad)
        return;

    if ([[aNotification object] XMPPShow] == TNStropheContactStatusOffline)
    {
        _numberOfActiveModules  = 0;
        _allModulesReady        = NO;

        [self _removeAllTabsFromModulesTabView];
        _previousXMPPShow = TNStropheContactStatusOffline;
        [_infoTextField setStringValue:@"Entity is offline"];
        [_infoTextField setHidden:NO];
    }
    else if ([[aNotification object] XMPPShow] == TNStropheContactStatusDND)
    {
        _numberOfActiveModules  = 0;
        _allModulesReady        = NO;

        [self _removeAllTabsFromModulesTabView];
        _previousXMPPShow = TNStropheContactStatusDND;
        [_infoTextField setStringValue:@"Entity does not want to be disturbed"];
        [_infoTextField setHidden:NO];
    }
    else if ((_previousXMPPShow == TNStropheContactStatusOffline) || (_previousXMPPShow == TNStropheContactStatusDND))
    {
        _previousXMPPShow           = nil;
        _numberOfActiveModules      = 0;
        _allModulesReady            = NO;

        [_infoTextField setStringValue:@""];
        [_infoTextField setHidden:YES];
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

/*! Triggered when TNArchipelModulesVisibilityRequestNotification is recieved
*/
- (void)_didReceiveVisibilityRequest:(CPNotification)aNotification
{
    var requester = [aNotification object],
        module = [_tabModules objectForKey:[requester identifier]];

    for (var i = 0; i < [[_mainTabView tabViewItems] count]; i++)
        if ([[[_mainTabView tabViewItems] objectAtIndex:i] identifier] == [requester name])
            [_mainTabView selectTabViewItem:[[_mainTabView tabViewItems] objectAtIndex:i]];
}



#pragma mark -
#pragma mark Tabs Modules Management

/*! will display the modules that have to be displayed according to the entity type.
    triggered by -setEntity:ofType:andRoster:
*/
- (void)_populateModulesTabView
{
    var sortDescriptor = [CPSortDescriptor sortDescriptorWithKey:@"index" ascending:YES],
        sortedValue = [[_tabModules allValues] sortedArrayUsingDescriptors:[sortDescriptor]],
        mainModuleViewFrame = [_mainModuleView bounds];

    _numberOfActiveModules = 0;

    // we now disable the storage remembering during the tab item populating
    _deactivateModuleTabItemPositionStorage = YES;

    [_mainTabView setDelegate:nil];

    for (var i = 0; i < [sortedValue count]; i++)
    {
        var module = [sortedValue objectAtIndex:i],
            moduleTypes = [module supportedEntityTypes],
            scrollView = [[module UIItem] view];

        if (![moduleTypes containsObject:_moduleType])
            continue;

        [scrollView setFrame:mainModuleViewFrame];

        if ([module isFullscreen])
        {
            [[module view] setFrame:mainModuleViewFrame];
            [[module view] setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        }
        else
        {
            mainModuleViewFrame.size.height = [[module view] bounds].size.height;
            [[module view] setFrame:mainModuleViewFrame];
        }

        [module setEntity:_entity];

        [_mainTabView addTabViewItem:[module UIItem]];

        // if not permissions are not cached, AppController will do it
        // we just wait. If entity is nil, then there is no permissions to wait for
        if (!_entity || [[TNPermissionsCenter defaultCenter] arePermissionsCachedForEntity:_entity])
            [module _beforeWillLoad];

        _numberOfActiveModules++;
    }

    // and we reactivate it
    _deactivateModuleTabItemPositionStorage = NO;

    [self recoverFromLastSelectedIndex];
    [_mainTabView setDelegate:self];

    var currentModule = [_tabModules objectForKey:[[_mainTabView selectedTabViewItem] identifier]];
    [currentModule setCurrentSelectedIndex:YES];
    if (!_entity || [[TNPermissionsCenter defaultCenter] arePermissionsCachedForEntity:_entity])
        [currentModule willShow];
}

/*! will remove all loaded modules and send message willHide willUnload to all TNModules
*/
- (void)_removeAllTabsFromModulesTabView
{
    if ([_mainTabView numberOfTabViewItems] <= 0)
        return;

    var arrayCpy = [CPArray arrayWithArray:[_mainTabView tabViewItems]];

    [_mainTabView setDelegate:nil];

    for (var i = 0; i < [arrayCpy count]; i++)
    {
        var tabViewItem = [arrayCpy objectAtIndex:i],
            module = [tabViewItem module];

        if ([module isVisible])
            [module willHide];

        [module setCurrentSelectedIndex:NO];
        [module willUnload];
        [module setEntity:nil];

        [[module view] scrollPoint:CPMakePoint(0.0, 0.0)];

        [_mainTabView removeTabViewItem:tabViewItem];
    }

    [_mainTabView setDelegate:self];
}

/*! TNTabView delegate. Wil check if current tab item is OK to be hidden
    @param aTabView the TNTabView that sent the message (_mainTabView)
    @param anItem the item that should be selected
*/
- (BOOL)tabView:(TNTabView)aTabView shouldSelectTabViewItem:(TNModuleTabViewItem)anItem
{
    if ([aTabView numberOfTabViewItems] <= 0)
        return YES;

    var currentTabItem = [aTabView selectedTabViewItem];

    if (!currentTabItem)
        return YES;

    var currentModule = [currentTabItem module];

    return [currentModule shouldHideAndSelectItem:anItem ofObject:aTabView];
}

/*! TNTabView delegate. Will sent willHide to current tab module and willShow to the one that will be be display
    @param aTabView the TNTabView that sent the message (_mainTabView)
    @param anItem the new selected item
*/
- (void)tabView:(TNTabView)aTabView willSelectTabViewItem:(TNModuleTabViewItem)anItem
{
    if ([aTabView numberOfTabViewItems] <= 0)
        return;

    var currentTabItem = [aTabView selectedTabViewItem];

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


#pragma mark -
#pragma mark Toolbar Modules Management

/*! Action that respond on Toolbar TNModules to display the view of the module.
    @param sender the CPToolbarItem that sent the message
*/
- (IBAction)didToolbarModuleClicked:(CPToolbarItem)sender
{
    var newModule = [_toolbarModules objectForKey:[sender itemIdentifier]],
        oldModule;

    if (_currentToolbarModule)
    {
        oldModule = _currentToolbarModule;
        [_currentToolbarModule willHide];
        [[_currentToolbarModule view] removeFromSuperview];
        _currentToolbarModule = nil;
        [_mainToolbar deselectToolbarItem];
    }

    if (newModule != oldModule)
    {
        [[newModule view] setFrame:[_mainModuleView bounds]];
        [newModule setUIItem:sender]; // due to archiving, we lost the origin item
        [newModule willShow];
        [_mainModuleView addSubview:[newModule view]];
        _currentToolbarModule = newModule;
        [_mainToolbar selectToolbarItem:sender];
    }
}

@end
