/*
 * TNModule.j
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

@import "TNACP.j"

/*! @global
    @group TNModule
    the namespace of Archipel Push Notification stanzas.
*/
TNArchipelPushNotificationNamespace     = @"archipel:push";
TNArchipelPushNotificationPermissions   = @"archipel:push:permissions";

TNArchipelTypePermissions               = @"archipel:permissions";
TNArchipelTypePermissionsGet            = @"get";

TNArchipelErrorPermission               = 0;
TNArchipelErrorGeneral                  = 1;



/*! @ingroup archipelcore
    This is the root class of every module.
    All modules must inherit from TNModule.

    If the child class must perform custom operations on module events (see below),
    it *MUST* call the super method or the module can make all archipel unstable.

    Modules events are the following :
     - <b>willLoad</b>: This message is sent when module will be called by changing selection in roster. This assert than the module has its roster and entity properties sets.
     - <b>willUnload</b>: This message is sent when user change roster selection. It can be reloaded instant later, with another roster and entity.
     - <b>willShow</b>: This message is sent when user will display the GUI of the module.
     - <b>willHide</b>: This message is sent when user displays other module.
     - <b>menuReady</b>: This message is sent when the the Main Menu is ready. So if module wants to have a menu, it can implement it from its own _menu property
     - <b>savePreferences</b> this message is sent when user have change the preferences. If module has some, it must save them in the current default.
     - <b>loadPreferences</b> this message is sent when user call the preferences window. All modules prefs *MUST* be refreshed

    A module can perform background task only if it is loaded. Loaded doesn't mean displayed on the screen. For example
    a statistic module can start collecting data on willLoad message in background. When message willShow is sent,
    module can perform operation to display the collected data in background and update this display. When willHide
    message is sent, module can stop to update the UI, but will continue to collect data. On willUnload message, the
    module *MUST* stop anything. willUnload will also remove all registration for this module. So if you have set some delegates
    (mostly CPTableView delegates) you *MUST* register them again on next willLoad. This avoid to use ressource for useless module.

    The root class willUnload will remove all TNStropheConnection handler, and remove the module from any subscription
    to CPNotification and all Archipel Push Notifications.

    You can use SampleTabModule and SampleToolbarModule to get example of module implémentation.

*/
@implementation TNModule : CPViewController
{
    @outlet CPView          viewPreferences         @accessors;

    BOOL                    _isActive               @accessors(property=isActive, readonly);
    BOOL                    _isVisible              @accessors(property=isVisible, readonly);
    BOOL                    _toolbarItemOnly        @accessors(getter=isToolbarItemOnly, setter=setToolbarItemOnly:);
    CPArray                 _supportedEntityTypes   @accessors(property=supportedEntityTypes);
    CPBundle                _bundle                 @accessors(property=bundle);
    CPMenu                  _menu                   @accessors(property=menu);
    CPMenuItem              _menuItem               @accessors(property=menuItem);
    CPString                _label                  @accessors(property=label);
    CPString                _name                   @accessors(property=name);
    id                      _entity                 @accessors(property=entity);
    int                     _animationDuration      @accessors(property=animationDuration);
    int                     _index                  @accessors(property=index);
    TNStropheConnection     _connection             @accessors(property=connection);
    TNStropheGroup          _group                  @accessors(property=group);
    TNStropheRoster         _roster                 @accessors(property=roster);
    CPToolbarItem           _toolbarItem            @accessors(property=toolbarItem);
    CPToolbar               _toolbar                @accessors(property=toolbar);
    CPArray                 _mandatoryPermissions   @accessors(property=mandatoryPermissions);

    CPView                  _viewPermissionsDenied  @accessors(property=viewPermissionDenied);
    CPArray                 _registredSelectors;
    CPArray                 _pubsubRegistrar;
    CPDictionary            _cachedGranted;
}


#pragma mark -
#pragma mark Initialization

- (id)init
{
    if (self = [super init])
    {
        _isActive               = NO;
        _isVisible              = NO;
        _pubsubRegistrar        = [CPArray array];
        _cachedGranted          = [CPDictionary dictionary];
    }
    return self;
}

/*! this method set the roster, the TNStropheConnection and the contact that module will be allow to access.
    YOU MUST NOT CALL THIS METHOD BY YOURSELF. TNModuleLoader will do the job for you.

    @param anEntity : TNStropheContact concerned by the module
    @param aConnection : TNStropheConnection general connection
    @param aRoster : TNStropheRoster general roster
*/
- (void)initializeWithEntity:(id)anEntity andRoster:(TNStropheRoster)aRoster
{
    _entity     = anEntity;
    _roster     = aRoster;
    _connection = [_roster connection];
}


#pragma mark -
#pragma mark Events management

/*! PRIVATE: this message is called when a matching pubsub event is received

    @param aStanza the TNStropheStanza that contains the event

    @return YES in order to continue to listen for events
*/
- (void)_onPubSubEvents:(TNStropheStanza)aStanza
{
    CPLog.trace("Raw (not filtered) pubsub event received from " + [aStanza from]);

    var nodeOwner   = [[aStanza firstChildWithName:@"items"] valueForAttribute:@"node"].split("/")[2],
        pushType    = [[aStanza firstChildWithName:@"push"] valueForAttribute:@"xmlns"],
        pushDate    = [[aStanza firstChildWithName:@"push"] valueForAttribute:@"date"],
        pushChange  = [[aStanza firstChildWithName:@"push"] valueForAttribute:@"change"],
        infoDict    = [CPDictionary dictionaryWithObjectsAndKeys:   nodeOwner,  @"owner",
                                                                    pushType,   @"type",
                                                                    pushDate,   @"date",
                                                                    pushChange, @"change"];

    for (var i = 0; i < [_pubsubRegistrar count]; i++)
    {
        var item = [_pubsubRegistrar objectAtIndex:i];

        if (pushType == [item objectForKey:@"type"])
        {
            [self performSelector:[item objectForKey:@"selector"] withObject:infoDict]
        }
    }

    return YES;
}

/*! This method allow the module to register itself to Archipel Push notification (archipel:push namespace)

    A valid Archipel Push is following the form:
    <message from="pubsub.xmppserver" type="headline" to="controller@xmppserver" >
        <event xmlns="http://jabber.org/protocol/pubsub#event">
            <items node="/archipel/09c206aa-8829-11df-aa46-0016d4e6adab@xmppserver/events" >
                <item id="DEADBEEF" >
                    <push xmlns="archipel:push:disk" date="1984-08-18 09:42:00.00000" change="created" />
                </item>
            </items>
        </event>
    </message>

    @param aSelector: Selector to perform on recieve of archipel:push with given type
    @param aPushType: CPString of the push type that will trigger the selector.
*/
- (void)registerSelector:(SEL)aSelector forPushNotificationType:(CPString)aPushType
{
    if ([_entity class] == TNStropheContact)
    {
        var registrarItem = [CPDictionary dictionary];

        CPLog.info([self class] + @" is registring for push notification of type : " + aPushType);
        [registrarItem setValue:aSelector forKey:@"selector"];
        [registrarItem setValue:aPushType forKey:@"type"];

        [_pubsubRegistrar addObject:registrarItem];
    }
}

/*! this message is sent when module receive a permission push in order to refresh
    display and permission cache
    @param somePushInfo the push informations as a CPDictionary
*/
- (void)_didReceivePermissionsPush:(id)somePushInfo
{
    var sender  = [somePushInfo objectForKey:@"owner"],
        type    = [somePushInfo objectForKey:@"type"],
        change  = [somePushInfo objectForKey:@"change"],
        date    = [somePushInfo objectForKey:@"date"];

    // check if we already have cached some information about the entity
    // if not, permissions will be recovered at next display so we don't care
    if ([_cachedGranted containsKey:sender])
    {
        var anEntity = [_roster contactWithBareJID:[TNStropheJID stropheJIDWithString:sender]];

        // invalide the cache for current entity
        [_cachedGranted removeObjectForKey:sender];

        // if the sender if the _entity then we'll need to perform graphicall chages
        // otherwise we just update the cache.
        if (anEntity == _entity)
            [self checkMandatoryPermissionsAndPerformOnGrant:@selector(hidePermissionDeniedView) onDenial:@selector(displayPermissionDeniedView) forEntity:anEntity];
        else
            [self checkMandatoryPermissionsAndPerformOnGrant:nil onDenial:nil forEntity:anEntity];
    }

    return YES;
}


#pragma mark -
#pragma mark Mandatory permissions validation

/*! Check if given entity meet the minimal mandatory permission to display the module
    Thoses mandatory permissions are stored into _mandatoryPermissions
    @param grantedSelector selector that will be executed if user is conform to mandatory permissions
    @param grantedSelector selector that will be executed if user is not conform to mandatory permissions
    @param anEntity the entity to which we should check the permission
*/
- (void)checkMandatoryPermissionsAndPerformOnGrant:(SEL)grantedSelector onDenial:(SEL)denialSelector forEntity:(TNStropheContact)anEntity
{
    if (!_cachedGranted)
        _cachedGranted = [CPDictionary dictionary];

    if (!_mandatoryPermissions || [_mandatoryPermissions count] == 0)
    {
        if (grantedSelector)
            [self performSelector:grantedSelector];

        return;
    }

    if ([_cachedGranted containsKey:[[anEntity JID] bare]])
    {
        if ([_cachedGranted valueForKey:[[anEntity JID] bare]] && grantedSelector)
            [self performSelector:grantedSelector];
        else if (denialSelector)
            [self performSelector:denialSelector];

        return;
    }

    var stanza = [TNStropheStanza iqWithType:@"get"],
        selectors = [CPDictionary dictionaryWithObjectsAndKeys: grantedSelector, @"grantedSelector",
                                                                denialSelector, @"denialSelector",
                                                                anEntity, @"entity"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypePermissions}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypePermissionsGet,
        "permission_type": "user",
        "permission_target": [[_connection JID] bare]}];

    [anEntity sendStanza:stanza andRegisterSelector:@selector(_didReceiveMandatoryPermissions:selectors:) ofObject:self userInfo:selectors];
}

/*! compute the answer containing the users' permissions
    @param aStanza TNStropheStanza containing the answer
    @param someUserInfo CPDictionary containing the two selectors and the current entity
*/
- (void)_didReceiveMandatoryPermissions:(TNStropheStanza)aStanza selectors:(CPDictionary)someUserInfo
{
    if ([aStanza type] == @"result")
    {
        var permissions = [aStanza childrenWithName:@"permission"],
            currentPermissions = [CPArray array],
            anEntity = [someUserInfo objectForKey:@"entity"];

        [_cachedGranted setValue:YES forKey:[[anEntity JID] bare]];

        for (var i = 0; i < [permissions count]; i++)
        {
            var permission      = [permissions objectAtIndex:i],
                name            = [permission valueForAttribute:@"name"];
            [currentPermissions addObject:name];
        }

        if ((![currentPermissions containsObject:@"all"])
            && [[_connection JID] bare] != [[CPBundle mainBundle] objectForInfoDictionaryKey:@"ArchipelDefaultAdminAccount"]) // <-- TODO!
        {
            for (var i = 0; i < [_mandatoryPermissions count]; i++)
            {
                if (![currentPermissions containsObject:[_mandatoryPermissions objectAtIndex:i]])
                {
                    [_cachedGranted setValue:NO forKey:[[anEntity JID] bare]];
                    break;
                }
            }
        }

        if ([_cachedGranted valueForKey:[[anEntity JID] bare]] && [someUserInfo objectForKey:@"grantedSelector"])
        {
            [self performSelector:[someUserInfo objectForKey:@"grantedSelector"]];
        }
        else if ([someUserInfo objectForKey:@"denialSelector"] )
        {
            [self performSelector:[someUserInfo objectForKey:@"denialSelector"]];
        }
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza]
    }
}

/*! Display the permission denial view
*/
- (void)displayPermissionDeniedView
{
    if ([_viewPermissionsDenied superview])
        return;

    [_viewPermissionsDenied setFrame:[[self view] frame]];

    [[self view] addSubview:_viewPermissionsDenied];

}

/*! Hide the permission denial view
*/
- (void)hidePermissionDeniedView
{
    if ([_viewPermissionsDenied superview])
        [_viewPermissionsDenied removeFromSuperview];
}

#pragma mark -
#pragma mark TNModule events implementation

/*! @ignore
    This is called my module controller in order to check if user is granted to display module
    it will check from cache if any cahed value, or will ask entity with ACP permissions 'get'
*/
- (void)_beforeWillLoad
{
    [self checkMandatoryPermissionsAndPerformOnGrant:@selector(willLoad) onDenial:@selector(permissionDenied) forEntity:_entity];
}

/*! This message is sent when module is loaded. It will
    reinitialize the _registredSelectors dictionary
*/
- (void)willLoad
{
    [self hidePermissionDeniedView];

    _animationDuration  = [[CPBundle mainBundle] objectForInfoDictionaryKey:@"TNArchipelAnimationsDuration"]; // if I put this in init, it won't work.
    _registredSelectors = [CPArray array];
    _pubsubRegistrar    = [CPArray array];
    _isActive           = YES;

    [_menuItem setEnabled:YES];

    [_registredSelectors addObject:[TNPubSubNode registerSelector:@selector(_onPubSubEvents:) ofObject:self forPubSubEventWithConnection:_connection]];

    [self registerSelector:@selector(_didReceivePermissionsPush:) forPushNotificationType:TNArchipelPushNotificationPermissions];
}

/*! This message is sent when module is unloaded. It will remove all push registration,
    all TNStropheConnection registration and all CPNotification subscription
*/
- (void)willUnload
{
    // remove all notification observers
    [[CPNotificationCenter defaultCenter] removeObserver:self];

    // unregister all selectors
    for (var i = 0; i < [_registredSelectors count]; i++)
        [_connection deleteRegisteredSelector:[_registredSelectors objectAtIndex:i]];

    // flush any outgoing stanza
    [_connection flush];

    [_pubsubRegistrar removeAllObjects];
    [_menuItem setEnabled:NO];

    _isActive = NO;
}

/*! This message is sent when module will be displayed
*/
- (void)willShow
{
    var defaults = [CPUserDefaults standardUserDefaults];

    if ([defaults boolForKey:@"TNArchipelUseAnimations"])
    {
        var animView    = [CPDictionary dictionaryWithObjectsAndKeys:[self view], CPViewAnimationTargetKey, CPViewAnimationFadeInEffect, CPViewAnimationEffectKey],
            anim        = [[CPViewAnimation alloc] initWithViewAnimations:[animView]];

        [anim setDuration:_animationDuration];
        [anim startAnimation];
    }
    _isVisible = YES;
}

/*! this message is called when mandatory permissions do not match current permissions
*/
- (void)permissionDenied
{
    [self displayPermissionDeniedView];
}

/*! this message is sent when user click on another module.
*/
- (void)willHide
{
    _isVisible = NO;
}

/*! this message is sent when the MainMenu is ready
    i.e. you can insert your module menu items;
*/
- (void)menuReady
{
    // executed when menu is ready
}

/*! this message is sent when the user changes the preferences. Implement this method to store
    datas from your eventual viewPreferences
*/
- (void)savePreferences
{
    // executed when use saves preferences
}

/*! this message is sent when Archipel displays the preferences window.
    implement this in order to refresh your eventual viewPreferences
*/
- (void)loadPreferences
{
    // executed when archipel displays preferences panel
}

/*! this message is sent only in case of a ToolbarItem module when user
    press the module's toolbar icon.
*/
- (IBAction)toolbarItemClicked:(id)sender
{
    // executed when users click toolbar item in case of toolbar module
}


#pragma mark -
#pragma mark Communication utilities

/*! this message simplify the sending and the post-management of TNStropheStanza to the contact
    @param aStanza: TNStropheStanza to send to the contact
    @param aSelector: Selector to perform when contact send answer
*/
- (void)sendStanza:(TNStropheStanza)aStanza andRegisterSelector:(SEL)aSelector
{
    var selectorID = [_entity sendStanza:aStanza andRegisterSelector:aSelector ofObject:self];
    [_registredSelectors addObject:selectorID];
}

/*! this message simplify the sending and the post-management of TNStropheStanza to the contact
    if also allow to define the XMPP uid of the stanza. This is useless in the most of case.
    @param aStanza: TNStropheStanza to send to the contact
    @param aSelector: Selector to perform when contact send answer
    @param anUid: CPString containing the XMPP uid to use.
*/
- (void)sendStanza:(TNStropheStanza)aStanza andRegisterSelector:(SEL)aSelector withSpecificID:(CPString)anUid
{
    var selectorID = [_entity sendStanza:aStanza andRegisterSelector:aSelector ofObject:self withSpecificID:anUid];
    [_registredSelectors addObject:selectorID];
}


#pragma mark -
#pragma mark Error management

/*! This message allow to display an error when stanza type is error
*/
- (void)handleIqErrorFromStanza:(TNStropheStanza)aStanza
{
    var growl   = [TNGrowlCenter defaultCenter],
        code    = [[aStanza firstChildWithName:@"error"] valueForAttribute:@"code"],
        type    = [[aStanza firstChildWithName:@"error"] valueForAttribute:@"type"];
        perm    = [[aStanza firstChildWithName:@"error"] firstChildWithName:@"archipel-error-permission"];

    if (perm)
    {
        CPLog.warn("Permission denied (" + code + "): " + [[aStanza firstChildWithName:@"text"] text]);
        return TNArchipelErrorPermission
    }
    else if ([aStanza firstChildWithName:@"text"])
    {
        var msg     = [[aStanza firstChildWithName:@"text"] text];

        [growl pushNotificationWithTitle:@"Error (" + code + " / " + type + ")" message:msg icon:TNGrowlIconError];
        CPLog.error(msg);
    }
    else
        CPLog.error(@"Error " + code + " / " + type + ". No message. If 503, it should be allright");

    return TNArchipelErrorGeneral;
}

@end