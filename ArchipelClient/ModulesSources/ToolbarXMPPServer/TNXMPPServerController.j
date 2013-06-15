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
@import <AppKit/CPPopUpButton.j>
@import <AppKit/CPTabView.j>
@import <AppKit/CPView.j>

@import "../../Model/TNModule.j"
@import "TNXMPPSharedGroupsController.j"
@import "TNXMPPUsersController.j"

@global CPLocalizedString
@global CPLocalizedStringFromTableInBundle
@global TNArchipelEntityTypeHypervisor

var TNArchipelPushNotificationXMPPServerUsers   = @"archipel:push:xmppserver:users";

/*! @defgroup  toolbarxmppserver Module XMPP Server
    @desc module to manage XMPP servers
*/


/*! @ingroup toolbarxmppserver
    main module controller
*/
@implementation TNXMPPServerController : TNModule
{
    @outlet CPCheckBox                      checkBoxPreferencesUseSRG;
    @outlet CPPopUpButton                   buttonHypervisors;
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

    [buttonHypervisors setTarget:self];
    [buttonHypervisors setAction:@selector(changeCurrentHypervisor:)];

    var imageBg = CPImageInBundle(@"bg-controls.png", nil, [CPBundle bundleForClass:[self class]]);
    [viewBottom setBackgroundColor:[CPColor colorWithPatternImage:imageBg]];
}

#pragma mark -
#pragma mark TNModule overrides


/*! this message is called when module becomes visible
*/
- (BOOL)willShow
{
    if (![super willShow])
        return NO;

    [self populateHypervisors];

    if (!_pushRegistred)
    {
        [self registerSelector:@selector(_didReceiveUsersPush:) ofObject:usersController forPushNotificationType:TNArchipelPushNotificationXMPPServerUsers];
        _pushRegistred = YES;
    }

    // simulate tab view item change
    [self tabView:tabViewMain didSelectTabViewItem:[tabViewMain selectedTabViewItem]];

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

    [[CPNotificationCenter defaultCenter] removeObserver:self];

    [super willHide];
}

/*! called when permissions changes
*/
- (void)permissionsChanged
{
    [super permissionsChanged];
    if ([[CPUserDefaults standardUserDefaults] integerForKey:@"TNArchipelUseEjabberdSharedRosterGroups"])
        [sharedGroupsController permissionsChanged];
    [usersController permissionsChanged];
}

/*! called when the UI needs to be updated according to the permissions
*/
- (void)setUIAccordingToPermissions
{
    if ([[CPUserDefaults standardUserDefaults] integerForKey:@"TNArchipelUseEjabberdSharedRosterGroups"])
        [sharedGroupsController setUIAccordingToPermissions];
    [usersController setUIAccordingToPermissions];
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
    if ([[CPUserDefaults standardUserDefaults] integerForKey:@"TNArchipelUseEjabberdSharedRosterGroups"])
        [sharedGroupsController flushUI];
    [usersController flushUI];

}

#pragma mark -
#pragma mark Notification handlers

/*! called when on of hypervisor changes its presence
    @param aNotification the notification
*/
- (void)_didHypervisorPresenceUpdate:(CPNotification)aNotification
{
    [self populateHypervisors];
    [usersController reload];
    if ([[CPUserDefaults standardUserDefaults] integerForKey:@"TNArchipelUseEjabberdSharedRosterGroups"])
        [sharedGroupsController reload];
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

    [tabViewMain setDelegate:self];
}

/*! populate the hypervisor pop up button according to roster
*/
- (void)populateHypervisors
{
    [buttonHypervisors removeAllItems];

    var servers = [CPArray array],
        items = [CPArray array];

    for (var i = 0; i < [[[[TNStropheIMClient defaultClient] roster] contacts] count]; i++)
    {
        var contact = [[[[TNStropheIMClient defaultClient] roster] contacts] objectAtIndex:i],
            item = [[CPMenuItem alloc] init];

        if (([[[TNStropheIMClient defaultClient] roster] analyseVCard:[contact vCard]] === TNArchipelEntityTypeHypervisor)
            && ([contact XMPPShow] != TNStropheContactStatusOffline)
            && ![servers containsObject:[[contact JID] domain]])
        {

            [servers addObject:[[contact JID] domain]];

            [item setTitle:[[contact JID] domain]]; // sic..
            [item setRepresentedObject:contact];
            [items addObject:item];

            [[CPNotificationCenter defaultCenter] removeObserver:self name:TNStropheContactPresenceUpdatedNotification object:contact];
            [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_didHypervisorPresenceUpdate:) name:TNStropheContactPresenceUpdatedNotification object:contact];
        }
    }

    var sortDescriptor  = [CPSortDescriptor sortDescriptorWithKey:@"title.uppercaseString" ascending:YES],
        sortedItems     = [items sortedArrayUsingDescriptors:[CPArray arrayWithObject:sortDescriptor]];

    for (var i = 0; i < [sortedItems count]; i++)
        [buttonHypervisors addItem:[sortedItems objectAtIndex:i]];

    [buttonHypervisors selectItemAtIndex:0];
    _entity = [[buttonHypervisors selectedItem] representedObject];
}


#pragma mark -
#pragma mark Actions

/*! update sub controllers according to the selected hypervisor
    @param aSender the sender of the action
*/
- (IBAction)changeCurrentHypervisor:(id)aSender
{
    _entity = [[buttonHypervisors selectedItem] representedObject];

    [usersController setEntity:[[buttonHypervisors selectedItem] representedObject]];

    if ([[CPUserDefaults standardUserDefaults] integerForKey:@"TNArchipelUseEjabberdSharedRosterGroups"])
        [sharedGroupsController setEntity:[[buttonHypervisors selectedItem] representedObject]];

    [self permissionsChanged];
}


#pragma mark -
#pragma mark Delegate

- (void)tabView:(CPTabView)aTabView didSelectTabViewItem:(CPTabViewItem)anItem
{
    switch ([anItem identifier])
    {
        case @"itemUsers":
            [usersController setEntity:[[buttonHypervisors selectedItem] representedObject]];
            [usersController reload];
            break;

        case @"itemGroups":
            [sharedGroupsController setEntity:[[buttonHypervisors selectedItem] representedObject]];
            [sharedGroupsController reload];
            break;
    }
}

@end


// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNXMPPServerController], comment);
}
