/*
 * TNSampleToolbarModule.j
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

@import <AppKit/CPImage.j>
@import <AppKit/CPMenuItem.j>
@import <AppKit/CPPopUpButton.j>
@import <AppKit/CPCheckBox.j>
@import <AppKit/CPTabView.j>
@import <AppKit/CPView.j>

@import "../../Model/TNModule.j"
@import "TNXMPPSharedGroupsController.j"
@import "TNXMPPUsersController.j"

@global CPLocalizedString
@global CPLocalizedStringFromTableInBundle
@global TNArchipelEntityTypeCentralAgent

var TNArchipelPushNotificationXMPPServerUsers = @"archipel:push:xmppserver:users";

/*! @ingroup toolbarxmppserver
    main module controller
*/
@implementation TNXMPPServerController : TNModule
{
    @outlet CPCheckBox                      checkBoxPreferencesUseSRG;
    @outlet CPTabView                       tabViewMain;
    @outlet CPView                          viewBottom;
    @outlet TNXMPPSharedGroupsController    sharedGroupsController;
    @outlet TNXMPPUsersController           usersController;

    BOOL                                    _pushRegistred;
    CPImage                                 _defaultAvatar;
    CPTabViewItem                           _itemViewGroups;
    CPTabViewItem                           _itemViewUsers;
}

#pragma mark -
#pragma mark Initialization

/*! called at cib awakening
*/
- (void)awakeFromCib
{
    var bundle = [CPBundle bundleForClass:[self class]],
        defaults = [CPUserDefaults standardUserDefaults];

    // register defaults defaults
    [defaults registerDefaults:@{@"TNArchipelUseEjabberdSharedRosterGroups":[bundle objectForInfoDictionaryKey:@"TNArchipelUseEjabberdSharedRosterGroups"]}];

    _defaultAvatar  = CPImageInBundle(@"user-unknown.png", nil, [CPBundle mainBundle]);

    _itemViewUsers   = [[CPTabViewItem alloc] initWithIdentifier:@"itemUsers"],
    _itemViewGroups  = [[CPTabViewItem alloc] initWithIdentifier:@"itemGroups"];

    [_itemViewUsers setLabel:CPBundleLocalizedString(@"XMPP Users", @"XMPP Users")];
    [_itemViewUsers setView:[usersController mainView]];

    [_itemViewGroups setLabel:CPBundleLocalizedString(@"Shared Groups", @"Shared Groups")];
    [_itemViewGroups setView:[sharedGroupsController mainView]];

    [self manageToolbarItems];
    [usersController setDelegate:self];
    [usersController setContextualMenu:_contextualMenu]
    [usersController populateViewWithControls];

    [sharedGroupsController setDelegate:self];
    [sharedGroupsController setContextualMenu:_contextualMenu];
    [sharedGroupsController setUsersController:usersController];
    [sharedGroupsController populateViewWithControls];

    _pushRegistred = NO;

    var imageBg = CPImageInBundle(@"bg-controls.png", nil, [CPBundle bundleForClass:[self class]]);
    [viewBottom setBackgroundColor:[CPColor colorWithPatternImage:imageBg]];

}

#pragma mark -
#pragma mark TNModule overrides

- (BOOL)willLoad
{
    // // Retrieve items from pubsub
    // _nodeCentralAgent = [TNPubSubNode pubSubNodeWithNodeName:@"/archipel/centralagentkeepalive" connection:[[TNStropheIMClient defaultClient] connection] pubSubServer:nil];
    // [_nodeCentralAgent setDelegate:self];
    // [_nodeCentralAgent recoverSubscriptions];

    if (![super willLoad])
        return NO;

    return YES;
}

/*! this message is called when module becomes visible
*/
- (BOOL)willShow
{

    if (![super willShow])
        return NO;

    if (!_pushRegistred)
    {
        [[CPNotificationCenter defaultCenter] removeObserver:self name:TNArchipelPushNotificationXMPPServerUsers object:nil];
        [self registerSelector:@selector(_didReceiveUsersPush:) ofObject:usersController forPushNotificationType:TNArchipelPushNotificationXMPPServerUsers];
        _pushRegistred = YES;
    }

    [usersController setEntity:_entity];
    if (([[CPUserDefaults standardUserDefaults] integerForKey:@"TNArchipelUseEjabberdSharedRosterGroups"]))
        [sharedGroupsController setEntity:_entity];

    [self flushUI];
    [self manageToolbarItems];
    [self permissionsChanged];

    return YES;
}

/*! this message is called when module becomes unvisible
*/
- (void)willHide
{
    if ([[CPUserDefaults standardUserDefaults] integerForKey:@"TNArchipelUseEjabberdSharedRosterGroups"])
        [sharedGroupsController willHide]

    [usersController willHide];
    [self flushUI];
    [super willHide];
}

/*! called when permissions changes
*/
- (void)permissionsChanged
{
    [super permissionsChanged];
    [usersController permissionsChanged];
    if ([[CPUserDefaults standardUserDefaults] integerForKey:@"TNArchipelUseEjabberdSharedRosterGroups"])
        [sharedGroupsController permissionsChanged];
}

/*! called when the UI needs to be updated according to the permissions
*/
- (void)setUIAccordingToPermissions
{
    [usersController setUIAccordingToPermissions];
    if ([[CPUserDefaults standardUserDefaults] integerForKey:@"TNArchipelUseEjabberdSharedRosterGroups"])
        [sharedGroupsController setUIAccordingToPermissions];
}

/*! called when user saves preferences
*/
- (void)savePreferences
{
    var defaults = [CPUserDefaults standardUserDefaults];

    [defaults setBool:([checkBoxPreferencesUseSRG state] == CPOnState) forKey:@"TNArchipelUseEjabberdSharedRosterGroups"];
    [self manageToolbarItems];
}

/*! called when user gets preferences
*/
- (void)loadPreferences
{
    var defaults = [CPUserDefaults standardUserDefaults];

    [checkBoxPreferencesUseSRG setState:[defaults boolForKey:@"TNArchipelUseEjabberdSharedRosterGroups"] ? CPOnState : CPOffState];

}

/*! this message is used to flush the UI
*/
- (void)flushUI
{
    [usersController flushUI];
    if ([[CPUserDefaults standardUserDefaults] integerForKey:@"TNArchipelUseEjabberdSharedRosterGroups"])
        [sharedGroupsController flushUI];
}

#pragma mark -
#pragma mark Utilities

- (void)manageToolbarItems
{
    [tabViewMain setDelegate:nil];

    if (![[tabViewMain tabViewItems] containsObject:_itemViewUsers])
        [tabViewMain addTabViewItem:_itemViewUsers];

    if ([[CPUserDefaults standardUserDefaults] integerForKey:@"TNArchipelUseEjabberdSharedRosterGroups"])
    {
        if (![[tabViewMain tabViewItems] containsObject:_itemViewGroups])
            [tabViewMain addTabViewItem:_itemViewGroups];
    }
    else
    {
        [tabViewMain removeTabViewItem:_itemViewGroups];
        [tabViewMain selectFirstTabViewItem:nil];
    }

    if ([tabViewMain selectedTabViewItem] == nil)
        [tabViewMain selectFirstTabViewItem:nil];

    [tabViewMain setDelegate:self];
}

#pragma mark -
#pragma mark Delegate

@end


// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNXMPPServerController], comment);
}
