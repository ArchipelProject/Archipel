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
@import <AppKit/CPImageView.j>

@import <GrowlCappuccino/TNGrowlCenter.j>
@import <StropheCappuccino/TNPubSub.j>
@import <StropheCappuccino/TNStropheContact.j>
@import <StropheCappuccino/TNStropheIMClient.j>
@import <StropheCappuccino/TNStropheJID.j>
@import <StropheCappuccino/TNStropheStanza.j>

@import "../Resources/admin-accounts.js"

@class CPLocalizedString
@global TNArchipelEntityTypeUser
@global CPWindowAbove

TNPermissionsValidationModeBare             = 0;
TNPermissionsValidationModeNode             = 1;

TNPermissionsAdminListUpdatedNotification   = @"TNPermissionsAdminListUpdatedNotification";

var TNArchipelPushNotificationPermissions   = @"archipel:push:permissions",
    TNArchipelTypePermissions               = @"archipel:permissions",
    TNArchipelTypePermissionsGetOwn         = @"getown";

var __defaultPermissionCenter;

/*! @ingroup archipelcore

    The representation of the Archipel's permission controller
*/

@implementation TNPermissionsCenter : CPObject
{
    CPDictionary            _adminAccounts              @accessors(getter=adminAccounts);
    CPDictionary            _cachedPermissions          @accessors(getter=permissions);
    int                     _adminAccountValidationMode @accessors(getter=validationMode);

    CPArray                 _delegates;
    CPDictionary            _disableBadgesRegistry;
    CPImageView             _imageViewControlDisabledPrototype;
    TNPubSubNode            _pubsubAdminAccounts;
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
        _imageViewControlDisabledPrototype  = [[CPImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 16.0, 16.0)];
        _adminAccountValidationMode         = [[CPBundle mainBundle] objectForInfoDictionaryKey:@"ArchipelCheckNodeAdminAccount"];

        [self resetAdminAccounts];

        [_imageViewControlDisabledPrototype setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"denied.png"] size:CGSizeMake(16.0, 16.0)]];
    }

    return self;
}


#pragma mark -
#pragma mark Controls

/*! Reset the content of admin accounts according to the Info.plist and the live array
*/
- (void)resetAdminAccounts
{
    _adminAccounts = [CPDictionary dictionary];

    var defaultStaticAccounts = [[CPBundle mainBundle] objectForInfoDictionaryKey:@"ArchipelDefaultAdminAccounts"];

    for (var i = 0; i < [defaultStaticAccounts count]; i++)
    {
        var item = [defaultStaticAccounts objectAtIndex:i];
        [_adminAccounts setObject:item forKey:"STATIC_" + item];
    }

    for (var i = 0; i < [ARCHIPEL_ADMIN_ACCOUNTS_ARRAY count]; i++)
    {
        var item = [ARCHIPEL_ADMIN_ACCOUNTS_ARRAY objectAtIndex:i];
        [_adminAccounts setObject:item forKey:"STATIC_" + item];
    }
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

/*! start to listen permissions pubsub
*/
- (void)watchPubSubs
{
    [TNPubSubNode registerSelector:@selector(_onPermissionsPubSubEvents:) ofObject:self forPubSubEventWithConnection:[[TNStropheIMClient defaultClient] connection]];

    _pubsubAdminAccounts = [TNPubSubNode pubSubNodeWithNodeName:@"/archipel/adminaccounts" connection:[[TNStropheIMClient defaultClient] connection] pubSubServer:nil];
    [_pubsubAdminAccounts setDelegate:self];
    [_pubsubAdminAccounts retrieveItems];
    [_pubsubAdminAccounts recoverSubscriptions];
    [_pubsubAdminAccounts retrieveAffiliations];
}

/*! Cache permissions for a user
    @param anEntity TNStropheContact the contact to watch
    @return YES if already cached
*/
- (BOOL)cachePermissionsForEntityIfNeeded:(TNStropheContact)aContact
{
    if (![_cachedPermissions containsKey:aContact])
    {
        [self getPermissionForEntity:aContact];
        return NO;
    }
    return YES;
}

/*! start to listen change for user
    @param anEntity TNStropheContact the contact to unwatch
*/
- (void)uncachePermissionsForEntity:(TNStropheContact)aContact
{
    if ([_cachedPermissions containsKey:aContact])
        [_cachedPermissions removeObjectForKey:aContact];
}

/*! Check if permissions are cached for the current user
    @param anEntity TNStropheContact the contact to check
*/
- (void)arePermissionsCachedForEntity:(TNStropheContact)aContact
{
    if (![aContact isKindOfClass:TNStropheContact])
        return YES;

    if ([[[TNStropheIMClient defaultClient] roster] analyseVCard:[aContact vCard]] == TNArchipelEntityTypeUser)
        return YES;

    return [_cachedPermissions containsKey:aContact];
}

/*! check if user has given permissions against entity
    @param somePermissions array of permissions
    @param anEntity TNStropheContact representing the entity
*/
- (BOOL)hasPermissions:(CPArray)somePermissions forEntity:(TNStropheContact)anEntity
{
    for (var i = 0; i < [somePermissions count]; i++)
    {
        if (![anEntity isKindOfClass:TNStropheContact])
            return NO;

        if (((_adminAccountValidationMode === TNPermissionsValidationModeNode)
                && ([[_adminAccounts allValues] containsObject:[[[TNStropheIMClient defaultClient] JID] node]]))
            || ((_adminAccountValidationMode === TNPermissionsValidationModeBare)
                && ([[_adminAccounts allValues] containsObject:[[[TNStropheIMClient defaultClient] JID] bare]])))
            return YES;

        if ([[_cachedPermissions objectForKey:anEntity] containsObject:@"all"])
            return YES;

        if (![[_cachedPermissions objectForKey:anEntity] containsObject:[somePermissions objectAtIndex:i]])
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

/*! check if we already have a permission cache for the given entity
    @param anEntity TNStropheContact representing the entity
*/
- (BOOL)containsCachedPermissionsForEntity:(TNStropheContact)anEntity
{
    return [_cachedPermissions containsKey:anEntity];
}

/*! Check if given JID should be considered as an admin
    @param aJID the JID to check
*/
- (BOOL)isJIDInAdminList:(TNStropheJID)aJID
{
    var JIDTranslation = (_adminAccountValidationMode === TNPermissionsValidationModeBare) ? [aJID bare] : [aJID node];
    return ([[_adminAccounts allKeysForObject:JIDTranslation] count] > 0);
}

/*! Check if current connection's JID should be considered as an admin
*/
- (BOOL)isCurrentUserInAdminList
{
    return [self isJIDInAdminList:[[TNStropheIMClient defaultClient] JID]];
}


#pragma mark -
#pragma mark Notification handlers

/*! @ignore
    this message is sent when module receive a permission push in order to refresh
    display and permission cache
    @param somePushInfo the push informations as a CPDictionary
*/
- (BOOL)_onPermissionsPubSubEvents:(TNStropheStanza)aStanza
{
    var type = [[aStanza firstChildWithName:@"push"] valueForAttribute:@"xmlns"];

    if (type != TNArchipelPushNotificationPermissions)
        return YES;

    var sender  = [[aStanza firstChildWithName:@"items"] valueForAttribute:@"node"].split("/")[2],
        user    = [TNStropheJID stropheJIDWithString:[[aStanza firstChildWithName:@"push"] valueForAttribute:@"change"]];

    if (![[[TNStropheIMClient defaultClient] JID] bareEquals:user] && user != "admins")
        return YES;

    var anEntity = [[[TNStropheIMClient defaultClient] roster] contactWithBareJID:[TNStropheJID stropheJIDWithString:sender]];

    if ([_cachedPermissions containsKey:anEntity])
    {
        [_cachedPermissions removeObjectForKey:anEntity];
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

    [badge setFrameOrigin:CGPointMake(CGRectGetWidth([aControl frame]) - 16.0, CGRectGetHeight([aControl frame]) - 16.0)];

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

    [badge setFrameOrigin:CGPointMake(CGRectGetWidth([segment frame]) - 16.0 + [segment frame].origin.x, CGRectGetHeight([segment frame]) - 16.0)];

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
    if (!anEntity || (![anEntity isKindOfClass:TNStropheContact]) || [anEntity XMPPShow] == TNStropheContactStatusOffline)
        return;

    CPLog.info("Ask permission to entity for entity " + anEntity);

    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypePermissions}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypePermissionsGetOwn,
        "permission_type": "user",
        "permission_target": [[[TNStropheIMClient defaultClient] JID] bare]}];

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

        [_cachedPermissions setObject:[CPArray array] forKey:anEntity];

        for (var i = 0; i < [permissions count]; i++)
        {
            var permission      = [permissions objectAtIndex:i],
                name            = [permission valueForAttribute:@"name"];

            [[_cachedPermissions objectForKey:anEntity] addObject:name];
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

- (void)addAdminAccount:(TNStropheJID)aJID
{
    if ([self isJIDInAdminList:aJID])
        return;

    var newAccount = [TNXMLNode nodeWithName:@"admin"];
    [newAccount setValue:[aJID node] forAttribute:@"node"];
    [newAccount setValue:[aJID domain] forAttribute:@"domain"];

    [_pubsubAdminAccounts publishItem:newAccount];
    [_pubsubAdminAccounts changeAffiliation:TNPubSubNodeAffiliationOwner forJID:aJID];
}

- (void)removeAdminAccount:(TNStropheJID)aJID
{
    var JIDTranslation = (_adminAccountValidationMode === TNPermissionsValidationModeBare) ? [aJID bare] : [aJID node],
        keys = [_adminAccounts allKeysForObject:JIDTranslation];

    [_pubsubAdminAccounts retractItemsWithIDs:keys]
    [_pubsubAdminAccounts changeAffiliation:TNPubSubNodeAffiliationNone forJID:aJID];
}

#pragma mark -
#pragma mark Delegates

/*! TNPubSubNode delegate
*/
- (void)pubSubNode:(TNPubSubNode)aPubSubNode retrievedItems:(BOOL)didRetrieveItems
{
    if (aPubSubNode !== _pubsubAdminAccounts)
        return;

    [self resetAdminAccounts];

    var contents = [_pubsubAdminAccounts content];
    for (var i = 0; i < [contents count]; i++)
    {
        var item = [contents objectAtIndex:i],
            itemId = [item valueForAttribute:@"id"],
            adminAccount = [[item firstChildWithName:@"admin"] valueForAttribute:@"node"];

        if (_adminAccountValidationMode === TNPermissionsValidationModeBare)
            adminAccount = [CPString stringWithFormat:@"%s@%s", [[item firstChildWithName:@"admin"] valueForAttribute:@"node"],
                                                                [[item firstChildWithName:@"admin"] valueForAttribute:@"domain"]];

        [_adminAccounts setObject:adminAccount forKey:itemId];
    }
}

/*! TNPubSubNode delegate
*/
- (void)pubSubNode:(TNPubSubNode)aPubSubNode retrievedSubscriptions:(BOOL)areSubscriptionsRetrieved
{
    if (aPubSubNode !== _pubsubAdminAccounts)
        return;

    if (areSubscriptionsRetrieved)
    {
        CPLog.info("sucessfully subscriptions retreived for node " + [aPubSubNode name]);
        if ([aPubSubNode numberOfSubscriptions] == 0)
            [aPubSubNode subscribe];
    }
    else
        CPLog.info("cannot retrieve subscriptions for node " + [aPubSubNode name]);
}

/*! TNPubSubNode delegate
*/
- (void)pubSubNode:(TNPubSubNode)aPubSubNode receivedEvent:(TNStropheStanza)aStanza
{
    if (aPubSubNode !== _pubsubAdminAccounts)
        return;

    if (![aStanza containsChildrenWithName:@"headers"])
        return;

    [_pubsubAdminAccounts retrieveItems];
    [[CPNotificationCenter defaultCenter] postNotificationName:TNPermissionsAdminListUpdatedNotification object:self];
}

- (void)pubSubNode:(TNPubSubNode)aPubSubNode publishedItem:(TNStropheStanza)aStanza
{
    if (aPubSubNode !== _pubsubAdminAccounts)
        return;

    if ([aStanza type] == @"result")
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:CPLocalizedString(@"Admin rights", @"Admin rights")
                                                         message:CPLocalizedString(@"User admin rights successfully granted", @"User admin rights successfully granted")];

    }
    else
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:CPLocalizedString(@"Admin rights", @"Admin rights")
                                                         message:CPLocalizedString(@"Unable to grant admin rights to users. See log", @"Unable to grant admin rights to users. See log")
                                                            icon:TNGrowlIconError];
        CPLog.error("Unable to grant admin rights to users");
        CPLog.error(aStanza);
    }
}

/*! TNPubSubNode delegate
*/
- (void)pubSubNode:(TNPubSubNode)aPubSubNode retractedItem:(TNStropheStanza)aStanza
{
    if (aPubSubNode !== _pubsubAdminAccounts)
        return;

    if ([aStanza type] == @"result")
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:CPLocalizedString(@"Admin rights", @"Admin rights")
                                                         message:CPLocalizedString(@"User admin rights successfuly revoked", @"User admin rights successfuly revoked")];

    }
    else
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:CPLocalizedString(@"Admin rights", @"Admin rights")
                                                         message:CPLocalizedString(@"Unable to revoke admin rights to users. See log", @"Unable to revoke admin rights to users. See log")
                                                            icon:TNGrowlIconError];
        CPLog.error("Unable to grant admin rights to users");
        CPLog.error(aStanza);
    }
}

/*! TNPubSubNode delegate
*/
- (void)pubSubNode:(TNPubSubNode)aPubSubNode retrievedAffiliations:(TNStropheStanza)aStanza
{
    if (aPubSubNode !== _pubsubAdminAccounts)
        return;
    if ([aStanza type] == @"result")
        CPLog.info(@"affiliations successfully retrieved: " + [aPubSubNode affiliations]);
    else
        CPLog.error(@"Cannot retrieve affiliations: " + aStanza);
}

/*! TNPubSubNode delegate
*/
- (void)pubSubNode:(TNPubSubNode)aPubSubNode changedAffiliations:(TNStropheStanza)aStanza
{
    if (aPubSubNode !== _pubsubAdminAccounts)
        return;
    if ([aStanza type] == @"result")
        CPLog.info(@"successfully change affiliations: " + [aPubSubNode affiliations]);
    else
        CPLog.error(@"Cannot change affiliations: " + aStanza);
}

@end
