/*
 * TNPermissionsController.j
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

TNArchipelPushNotificationPermissions   = @"archipel:push:permissions";

TNArchipelTypePermissions               = @"archipel:permissions";
TNArchipelTypePermissionsGetOwn         = @"getown";


/*! @ingroup archipelcore

    The representation of the Archipel's permission controller
*/

@implementation TNPermissionsController : CPObject
{
    CPDictionary            _cachedPermissions      @accessors(getter=permissions);
    TNStropheRoster         _roster                 @accessors(property=roster);

    CPArray                 _delegates;
}

#pragma mark -
#pragma mark Initialization

/*! initializes the TNPermissionsController
*/
- (id)init
{
    if (self = [super init])
    {
        _cachedPermissions  = [CPDictionary dictionary];
        _delegates          = [CPArray array];
    }

    return self;
}

/*! Add a delegate that will be notified when permission cache will be updated
    @param anObject the object you want to add as delegate
*/
- (void)addDelegate:(id)anObject
{
    [_delegates addObject:anObject];
}

/*! remove a delegate
    @param anObject the object you want to remove from delegates
*/
- (void)removeDelegate:(id)anObject
{
    [_delegates removeObject:anObject];
}

/*! start to listen permissions event
*/
- (void)startWatching
{
    [TNPubSubNode registerSelector:@selector(_onPermissionsPubSubEvents:) ofObject:self forPubSubEventWithConnection:[_roster connection]];

    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_entityReady:) name:TNStropheContactVCardReceivedNotification object:nil];
}

#pragma mark -
#pragma mark Notification handlers

/*! message sent when an entity updated it's vCard, which mean it is fully ready
    @param aNotification the notification
*/
- (void)_entityReady:(CPNotification)aNotification
{
    var contact = [aNotification object],
        entityType = [_roster analyseVCard:[contact vCard]];

    if ((entityType == TNArchipelEntityTypeHypervisor) || (entityType == TNArchipelEntityTypeVirtualMachine))
        [self getPermissionForEntity:contact];
}


/*! @ignore
    this message is sent when module receive a permission push in order to refresh
    display and permission cache
    @param somePushInfo the push informations as a CPDictionary
*/
- (BOOL)_onPermissionsPubSubEvents:(TNStropheStanza)aStanza
{
    var sender  = [[aStanza firstChildWithName:@"items"] valueForAttribute:@"node"].split("/")[2],
        type    = [[aStanza firstChildWithName:@"push"] valueForAttribute:@"xmlns"],
        user    = [TNStropheJID stropheJIDWithString:[[aStanza firstChildWithName:@"push"] valueForAttribute:@"change"]];

    if (type != TNArchipelPushNotificationPermissions)
        return YES;

    if (![[[_roster connection] JID] bareEquals:user])
        return YES;

    if ([_cachedPermissions containsKey:sender])
    {
        var anEntity = [_roster contactWithBareJID:[TNStropheJID stropheJIDWithString:sender]];

        [_cachedPermissions removeObjectForKey:sender];
        CPLog.info("cache for entity " + anEntity + " has been invalidated");
    }

    [self getPermissionForEntity:anEntity];

    return YES;
}


#pragma mark -
#pragma mark XMPP management

/*! @ignore
    Check if given entity meet the minimal mandatory permission to display the module
    Thoses mandatory permissions are stored into _mandatoryPermissions
    @param anEntity selector that will be executed if user is conform to mandatory permissions
    @param grantedSelector selector that will be executed if user is not conform to mandatory permissions
    @param anEntity the entity to which we should check the permission
*/
- (void)getPermissionForEntity:(TNStropheContact)anEntity
{
    if (!anEntity)
        return;

    if ([anEntity class] == TNStropheGroup)
    {
        [anObject performSelector:aSelector];
        return;
    }

    CPLog.info("Ask permission to entity for entity " + anEntity);

    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypePermissions}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypePermissionsGetOwn,
        "permission_type": "user",
        "permission_target": [[[_roster connection] JID] bare]}];

    [anEntity sendStanza:stanza andRegisterSelector:@selector(_didReceivePermissions:ofEntity:) ofObject:self userInfo:anEntity];
}

/*! @ignore
    compute the answer containing the users' permissions
    @param aStanza TNStropheStanza containing the answer
    @param someUserInfo CPDictionary containing the two selectors and the current entity
*/
- (void)_didReceivePermissions:(TNStropheStanza)aStanza ofEntity:(TNStropheContact)anEntity
{
    if ([aStanza type] == @"result")
    {
        var permissions         = [aStanza childrenWithName:@"permission"],
            defaultAdminAccount = [[CPBundle mainBundle] objectForInfoDictionaryKey:@"ArchipelDefaultAdminAccount"];

        [_cachedPermissions setObject:[CPArray array] forKey:[[anEntity JID] bare]];

        for (var i = 0; i < [permissions count]; i++)
        {
            var permission      = [permissions objectAtIndex:i],
                name            = [permission valueForAttribute:@"name"];

            [[_cachedPermissions objectForKey:[[anEntity JID] bare]] addObject:name];
        }

        CPLog.info("Permissions for entity " + anEntity + " sucessfully cached");

        for (var i = 0 ; i < [_delegates count]; i++)
        {
            var delegate = [_delegates objectAtIndex:i];
            if ([delegate respondsToSelector:@selector(permissionCenter:updatePermissionForEntity:)])
                [delegate permissionCenter:self updatePermissionForEntity:anEntity];
        }
    }
    else
    {
        CPLog.error("error in _didReceivePermissions " + aStanza);
    }
}



@end
