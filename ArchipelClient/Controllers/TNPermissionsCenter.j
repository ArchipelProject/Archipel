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

var __defaultPermissionCenter;

/*! @ingroup archipelcore

    The representation of the Archipel's permission controller
*/

@implementation TNPermissionsCenter : CPObject
{
    CPDictionary            _cachedPermissions      @accessors(getter=permissions);
    TNStropheRoster         _roster                 @accessors(property=roster);

    CPArray                 _delegates;
    CPDictionary            _disableBadgesRegistry;
    CPImageView             _imageViewControlDisabledPrototype;
}

+ (TNPermissionsCenter)defaultCenter
{
    if (!__defaultPermissionCenter)
        __defaultPermissionCenter = [[TNPermissionsCenter alloc] init];

    return __defaultPermissionCenter;
}

#pragma mark -
#pragma mark Initialization

/*! initializes the TNPermissionsController
*/
- (id)init
{
    if (self = [super init])
    {
        _cachedPermissions                  = [CPDictionary dictionary];
        _delegates                          = [CPArray array];
        _disableBadgesRegistry              = [CPDictionary dictionary];
        _imageViewControlDisabledPrototype  = [[CPImageView alloc] initWithFrame:CPRectMake(0.0, 0.0, 16.0, 16.0)];

        [_imageViewControlDisabledPrototype setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"denied.png"] size:CPSizeMake(16.0, 16.0)]];
    }

    return self;
}


#pragma mark -
#pragma mark Controls

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

/*! check if user has given permissions against entity
    @param somePermissions array of permissions
    @param anEntity TNStropheContact representing the entity
*/
- (BOOL)hasPermissions:(CPArray)somePermissions forEntity:(TNStropheContact)anEntity
{
    for (var i = 0; i < [somePermissions count]; i++)
    {
        if ([anEntity class] !== TNStropheContact)
            return NO;

        if ([[[_roster connection] JID] bare] === [[CPBundle mainBundle] objectForInfoDictionaryKey:@"ArchipelDefaultAdminAccount"])
            return YES;

        if ([[_cachedPermissions objectForKey:[[anEntity JID] bare]] containsObject:@"all"])
            return YES;

        if (![[_cachedPermissions objectForKey:[[anEntity JID] bare]] containsObject:[somePermissions objectAtIndex:i]])
            return NO;
    }

    return YES;
}

/*! check if user has given permission against entity
    @param somePermissions name of the permission
    @param anEntity TNStropheContact representing the entity
*/
- (BOOL)hasPermission:(CPString)aPermission forEntity:(TNStropheContact)anEntity
{
    return [self hasPermissions:[aPermission] forEntity:anEntity];
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
    {
        var server = [[contact JID] domain];

        [self getPermissionForEntity:contact];
    }

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
#pragma mark Disabled badges

/*! generate a valid unique identifier for given control
    @param aControl the original control
    @return CPString containing the generated key
*/
- (CPString)generateBadgeKeyForControl:(CPControl)aControl
{
    var key = @"" + aControl + @"";
    return key.replace(" ", "_");
}

/*! Add a deactivated badge with given key to given control
    @param aKey the key of the control (you may use generateBadgeKeyForControl:)
    @param aControl the original control
*/
- (void)addBadgeWithKey:(CPString)aKey toControl:(CPControl)aControl
{

    if ([_disableBadgesRegistry containsKey:aKey])
        return;

    var data = [CPKeyedArchiver archivedDataWithRootObject:_imageViewControlDisabledPrototype],
        badge = [CPKeyedUnarchiver unarchiveObjectWithData:data];

    [badge setFrameOrigin:CPPointMake(CPRectGetWidth([aControl frame]) - 16.0, CPRectGetHeight([aControl frame]) - 16.0)];

    [aControl addSubview:badge positioned:CPWindowAbove relativeTo:nil];

    [_disableBadgesRegistry setObject:badge forKey:aKey];
}

/*! Add a deactivated badge with given key to given segment of given segmented control
    @param aKey the key of the control (you may use generateBadgeKeyForControl:)
    @param aSegmentedControl the original control
    @param aSegment the identifier of the segment
*/
- (void)addBadgeWithKey:(CPString)aKey toSegmentedControl:(CPControl)aSegmentedControl segment:(int)aSegment
{
    if ([_disableBadgesRegistry containsKey:aKey])
        return;

    var data = [CPKeyedArchiver archivedDataWithRootObject:_imageViewControlDisabledPrototype],
        badge = [CPKeyedUnarchiver unarchiveObjectWithData:data],
        segment = [aSegmentedControl segment:aSegment];

    [badge setFrameOrigin:CPPointMake(CPRectGetWidth([segment frame]) - 16.0 + [segment frame].origin.x, CPRectGetHeight([segment frame]) - 16.0)];

    [aSegmentedControl addSubview:badge positioned:CPWindowAbove relativeTo:nil];

    [_disableBadgesRegistry setObject:badge forKey:aKey];
}


/*! remove the badge with given key
    @param aKey the key of the badge (you may use generateBadgeKeyForControl:)
*/
- (void)removeBadgeWithKey:(CPString)aKey
{
    if ([_disableBadgesRegistry containsKey:aKey])
    {
        [[_disableBadgesRegistry objectForKey:aKey] removeFromSuperview];
        [_disableBadgesRegistry removeObjectForKey:aKey];
    }
}


#pragma mark -
#pragma mark Disabling controls

/*! enable given control if current entity has given permission
    otherwise, disable it and put a badge
    @param aControl the original control
    @param aSegment the identifier of the segment (if not nil, the control will be considered as a CPSegmentedControl)
    @param somePermissions array of permissions
    @param aSpecialCondition suplemetary condition that must be YES to enable the control (but will remove the badge if permission is granted)
*/
- (void)setControl:(CPControl)aControl segment:(int)aSegment enabledAccordingToPermissions:(CPArray)somePermissions forEntity:(TNStropheContact)anEntity specialCondition:(BOOL)aSpecialCondition
{
    var permissionCenter = [TNPermissionsCenter defaultCenter];

    if ([self hasPermissions:somePermissions forEntity:anEntity])
    {
        if (aSegment !== nil)
            [permissionCenter removeBadgeWithKey:[self generateBadgeKeyForControl:[aControl segment:aSegment]]];
        else
            [permissionCenter removeBadgeWithKey:[self generateBadgeKeyForControl:aControl]];

        if (aSpecialCondition)
        {
            if (aSegment !== nil)
                [aControl setEnabled:YES forSegment:aSegment];
            else
                [aControl setEnabled:YES];
        }
        else
        {
            if (aSegment !== nil)
                [aControl setEnabled:NO forSegment:aSegment];
            else
                [aControl setEnabled:NO];
        }
    }
    else
    {
        if (aSegment !== nil)
        {
            [aControl setEnabled:NO forSegment:aSegment];
            [permissionCenter addBadgeWithKey:[self generateBadgeKeyForControl:[aControl segment:aSegment]] toSegmentedControl:aControl segment:aSegment];
        }
        else
        {
            [aControl setEnabled:NO]
            [permissionCenter addBadgeWithKey:[self generateBadgeKeyForControl:aControl] toControl:aControl];
        }
    }
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
    if (!anEntity || ([anEntity class] != TNStropheContact))
        return;

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
