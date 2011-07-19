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
@import <AppKit/CPPopUpButton.j>
@import <AppKit/CPPopUpButton.j>
@import <AppKit/CPTabView.j>
@import <AppKit/CPView.j>

@import "TNXMPPSharedGroupsController.j"
@import "TNXMPPUsersController.j"

var TNArchipelPushNotificationXMPPServerUsers   = @"archipel:push:xmppserver:users";

/*! @defgroup  toolbarxmppserver Module XMPP Server
    @desc module to manage XMPP servers
*/


/*! @ingroup toolbarxmppserver
    main module controller
*/
@implementation TNXMPPServerController : TNModule
{
    @outlet CPPopUpButton                   buttonHypervisors;
    @outlet CPTabView                       tabViewMain;
    @outlet CPView                          viewBottom;
    @outlet TNXMPPSharedGroupsController    sharedGroupsController;
    @outlet TNXMPPUsersController           usersController;

    BOOL        pushRegistred;
    CPImage     _defaultAvatar;
}

#pragma mark -
#pragma mark Initialization

/*! called at cib awakening
*/
- (void)awakeFromCib
{
    _defaultAvatar  = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"user-unknown.png"]];

    var itemViewUsers   = [[CPTabViewItem alloc] init],
        itemViewGroups  = [[CPTabViewItem alloc] init];

    [itemViewUsers setLabel:CPBundleLocalizedString(@"XMPP Users", @"XMPP Users")];
    [itemViewUsers setView:[usersController mainView]];

    [itemViewGroups setLabel:CPBundleLocalizedString(@"Shared Groups", @"Shared Groups")];
    [itemViewGroups setView:[sharedGroupsController mainView]];

    [tabViewMain addTabViewItem:itemViewUsers];
    [tabViewMain addTabViewItem:itemViewGroups];

    [usersController setDelegate:self];
    [sharedGroupsController setDelegate:self];
    [sharedGroupsController setUsersController:usersController];

    pushRegistred = NO;

    [buttonHypervisors setTarget:self];
    [buttonHypervisors setAction:@selector(changeCurrentHypervisor:)];

    var imageBg = [[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:[self class]] pathForResource:@"bg-controls.png"]];
    [viewBottom setBackgroundColor:[CPColor colorWithPatternImage:imageBg]];

    [buttonHypervisors setToolTip:CPBundleLocalizedString(@"Select the hypervisor to use. It will configure its own XMPP server", @"Select the hypervisor to use. It will configure its own XMPP server")];
}

#pragma mark -
#pragma mark TNModule overrides

/*! this message is called when module is loaded
*/
- (void)willLoad
{
    [super willLoad];
}

/*! this message is called when module is unloaded
*/
- (void)willUnload
{
    [super willUnload];
   // message sent when view will be removed from superview;
}

/*! this message is called when module becomes visible
*/
- (BOOL)willShow
{
    if (![super willShow])
        return NO;

    [self populateHypervisors];

    if (!pushRegistred)
    {
        [self registerSelector:@selector(_didReceivePush:) forPushNotificationType:TNArchipelPushNotificationXMPPServerUsers];
        pushRegistred = YES;
    }

    [usersController setEntity:[[buttonHypervisors selectedItem] objectValue]];
    [usersController reload];

    [sharedGroupsController setEntity:[[buttonHypervisors selectedItem] objectValue]];
    [sharedGroupsController reload];

    return YES;
}

/*! this message is called when module becomes unvisible
*/
- (void)willHide
{
    [sharedGroupsController closeNewGroupWindow:nil];
    [sharedGroupsController closeAddUserInGroupWindow:nil];
    [usersController closeRegisterUserWindow:nil];

    [super willHide];
    // message sent when the tab is changed
}

/*! called when permissions changes
*/
- (void)permissionsChanged
{
    [sharedGroupsController permissionsChanged];
    [usersController permissionsChanged];
}

#pragma mark -
#pragma mark Notification handlers

/*! called when on of hypervisor changes its presence
    @param aNotification the notification
*/
- (void)_didHypervisorPresenceUpdate:(CPNotification)aNotification
{
    [self populateHypervisors];
}

/*! called when an Archipel push is received
    @param somePushInfo CPDictionary containing the push information
*/
- (BOOL)_didReceivePush:(CPDictionary)somePushInfo
{
    var sender  = [somePushInfo objectForKey:@"owner"],
        type    = [somePushInfo objectForKey:@"type"],
        change  = [somePushInfo objectForKey:@"change"],
        date    = [somePushInfo objectForKey:@"date"];

    CPLog.info(@"PUSH NOTIFICATION: from: " + sender + ", type: " + type + ", change: " + change);
    [usersController reload];
    [sharedGroupsController reload];

    return YES;
}


#pragma mark -
#pragma mark Utilities

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
            item = [[TNMenuItem alloc] init];

        if (([[[TNStropheIMClient defaultClient] roster] analyseVCard:[contact vCard]] === TNArchipelEntityTypeHypervisor)
            && ([contact XMPPShow] != TNStropheContactStatusOffline)
            && ![servers containsObject:[[contact JID] domain]])
        {

            [servers addObject:[[contact JID] domain]];

            [item setTitle:[[contact JID] domain]]; // sic..
            [item setObjectValue:contact];
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
    _entity = [[buttonHypervisors selectedItem] objectValue];
    [self permissionsChanged];
}


#pragma mark -
#pragma mark Actions

/*! update sub controllers according to the selected hypervisor
    @param aSender the sender of the action
*/
- (IBAction)changeCurrentHypervisor:(id)aSender
{
    _entity = [[buttonHypervisors selectedItem] objectValue];

    [usersController setEntity:[[buttonHypervisors selectedItem] objectValue]];
    [sharedGroupsController setEntity:[[buttonHypervisors selectedItem] objectValue]];

    [self permissionsChanged];
}


@end


// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNXMPPServerController], comment);
}
