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

/*! @global
    @group TNModule
    the namespace of Archipel Push Notification stanzas.
*/
TNArchipelPushNotificationNamespace = @"archipel:push";


/*! @ingroup archipelcore
    This is the root class of every module.
    All modules must inherit from TNModule.

    If the child class must perform custom operations on module events (see below),
    it *MUST* call the super method or the module can make all archipel unstable.

    Modules events are the following :
     - <b>willLoad</b>: This message is sent when module will be called by changing selection in roster.
        This assert than the module has its roster and entity properties sets.
     - <b>willUnload</b>: This message is sent when user change roster selection. It can be reloaded instant later,
        with another roster and entity.
     - <b>willShow</b>: This message is sent when user will display the GUI of the module.
     - <b>willHide</b>: This message is sent when user displays other module.

    A module can perform background task only if it is loaded. Loaded doesn't mean displayed on the screen. For example
    a statistique module can start collecting data on willLoad message in background. When message willShow is sent,
    module can perform operation to display the collected data in background and update this display. When willHide
    message is sent, module can stop to update the UI, but will continue to collect data. On willUnload message, the
    module *MUST* stop anything.

    The root class willUnload will remove all TNStropheConnection handler, and remove the module from any subscription
    to CPNotification and all Archipel Push Notifications.

    You can use SampleTabModule and SampleToolbarModule to get example of module implémentation.

*/
@implementation TNModule : CPViewController
{
    TNStropheRoster         _roster                 @accessors(property=roster);
    TNStropheGroup          _group                  @accessors(property=group);
    id                      _entity                 @accessors(property=entity);
    TNStropheConnection     _connection             @accessors(property=connection);
    int                     _index                  @accessors(property=index);
    CPString                _name                   @accessors(property=name);
    CPString                _label                  @accessors(property=label);
    CPArray                 _supportedEntityTypes   @accessors(property=supportedEntityTypes);
    CPBundle                _bundle                 @accessors(property=bundle);
    CPMenuItem              _menuItem               @accessors(property=menuItem);
    CPMenu                  _menu                   @accessors(property=menu);
    BOOL                    _useAnimations          @accessors(getter=isUseAnimations, setter=setUseAnimations:);
    int                     _animationDuration      @accessors(property=animationDuration);
    BOOL                    _toolbarItemOnly        @accessors(getter=isToolbarItemOnly, setter=setToolbarItemOnly:);
    BOOL                    _isActive               @accessors(property=isActive, readonly);
    BOOL                    _isVisible              @accessors(property=isVisible, readonly);
    CPArray                 _registredSelectors;
    
}

- (id)init
{
    if (self = [super init])
    {
        _isActive       = NO;
        _isVisible      = NO;
    }
    
    return self;
}
/*! this method set the roster, the TNStropheConnection and the contact that module will be allow to access.
    YOU MUST NOT CALL THIS METHOD BY YOURSELF. TNModuleLoader will do the job for you.

    @param anEntity : TNStropheContact concerned by the module
    @param aConnection : TNStropheConnection general connection
    @param aRoster : TNStropheRoster general roster
*/
- (void)initializeWithEntity:(id)anEntity connection:(TNStropheConnection)aConnection andRoster:(TNStropheRoster)aRoster
{
    _entity     = anEntity;
    _roster     = aRoster;
    _connection = aConnection;
}

/*! This method allow the module to register itself to Archipel Push notification (archipel:push namespace)
    @param aSelector: Selector to perform on recieve of archipel:push with given type
    @param aPushType: CPString of the push type that will trigger the selector.
*/
- (void)registerSelector:(SEL)aSelector forPushNotificationType:(CPString)aPushType
{
    if ([_entity class] == TNStropheContact)
    {
        CPLog.info([self class] + " is registring for push notification of type : " + aPushType);
        var params = [[CPDictionary alloc] init];

        [params setValue:@"message" forKey:@"name"];
        [params setValue:@"headline" forKey:@"type"];
        
        //<message to="oto@server/resource" xmlns="archipel:push:disk" type="headline" id="55" change="created" />
        if (aPushType)
          [params setValue:aPushType forKey:@"namespace"];

        [_registredSelectors addObject:[_connection registerSelector:aSelector ofObject:self withDict:params]];
    }
}

/*! This message is sent when module is loaded. It will
    reinitialize the _registredSelectors dictionnary
*/
- (void)willLoad
{
    _useAnimations      = [[CPBundle mainBundle] objectForInfoDictionaryKey:@"TNArchipelUseAnimations"]; // if I put this in init, it won't work.
    _animationDuration  = [[CPBundle mainBundle] objectForInfoDictionaryKey:@"TNArchipelAnimationsDuration"]; // if I put this in init, it won't work.
    _registredSelectors = [CPArray array];
    _isActive           = YES;
    
    [_menuItem setEnabled:YES];
}

/*! This message is sent when module is unloaded. It will remove all push registration,
    all TNStropheConnection registration and all CPNotification subscription
*/
- (void)willUnload
{
    // unregister all selectors
    for(var i = 0; i < [_registredSelectors count]; i++)
    {
        var selector = [_registredSelectors objectAtIndex:i];

        [_connection deleteRegistredSelector:selector];
    }
    
    [_menuItem setEnabled:NO];
    
    // remove all notification observers
    var center  = [CPNotificationCenter defaultCenter];
    [center removeObserver:self];
    
    _isActive = NO;
}

/*! This message is sent when module will be displayed
*/
- (void)willShow
{
    if (_useAnimations == 1)
    {
        var animView    = [CPDictionary dictionaryWithObjectsAndKeys:[self view], CPViewAnimationTargetKey, CPViewAnimationFadeInEffect, CPViewAnimationEffectKey];
        var anim        = [[CPViewAnimation alloc] initWithViewAnimations:[animView]];

        [anim setDuration:_animationDuration];
        [anim startAnimation];
    }
    _isVisible = YES;
}

/*! this message is sent when user click on another module.
*/
- (void)willHide
{
    _isVisible = NO;
}

- (void)menuReady
{
    // executed when menu is ready
}

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

/*! This message allow to display an error when stanza type is error
*/

- (void)handleIqErrorFromStanza:(TNStropheStanza)aStanza
{
    var growl   = [TNGrowlCenter defaultCenter];
    var msg     = [self class] + ": " + [[aStanza firstChildWithName:@"error"] text];
    
    [growl pushNotificationWithTitle:@"Error" message:msg icon:TNGrowlIconError];
    CPLog.error(msg);
}

- (IBAction)toolbarItemClicked:(id)sender
{
    
}

@end