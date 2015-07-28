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
@global TNArchipelEntityTypeHypervisor
@global TNArchipelEntityTypeCentralAgent

var TNArchipelPushNotificationXMPPServerUsers   = @"archipel:push:xmppserver:users";

var TNArchipelTypeXMPPServer                        = @"archipel:xmppserver",
    TNArchipelTypeXMPPServerManagementCapabilities  = @"managementcapabilities";

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
    CPDictionary                            _currentDomains;
    CPDictionary                            _entityCapabilities
    CPDictionary                            _savedDomains;
    BOOL                                    _forceRosterRefresh;
    BOOL                                    _keepSearching;
    CPImage                                 _defaultAvatar;
    CPTabViewItem                           _itemViewGroups;
    CPTabViewItem                           _itemViewUsers;

    TNPubSubNode                            _nodeCentralAgent;
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

    _currentDomains     = [[CPDictionary alloc] init];
    _savedDomains       = [[CPDictionary alloc] init];
    _entityCapabilities = [[CPDictionary alloc] init];

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

    // Try to fetch some savedDomains if we don't have one use currentDomains
    _savedDomains = [[CPUserDefaults standardUserDefaults] objectForKey:@"TNArchipelXMPPServerSaved"];

    // Retrieve items from pubsub
    _nodeCentralAgent = [TNPubSubNode pubSubNodeWithNodeName:@"/archipel/centralagentkeepalive" connection:[[TNStropheIMClient defaultClient] connection] pubSubServer:nil];
    [_nodeCentralAgent setDelegate:self];
    [_nodeCentralAgent retrieveItems];

    _forceRosterRefresh = YES;
    _keepSearching = YES;

    [self checkHypervisors];

    if (!_pushRegistred)
    {
        [[CPNotificationCenter defaultCenter] removeObserver:self name:TNArchipelPushNotificationXMPPServerUsers object:nil];
        [self registerSelector:@selector(_didReceiveUsersPush:) ofObject:usersController forPushNotificationType:TNArchipelPushNotificationXMPPServerUsers];
        _pushRegistred = YES;
    }

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

    // Save the currentDomains for later

    [[CPUserDefaults standardUserDefaults] setObject:[_currentDomains copy] forKey:@"TNArchipelXMPPServerSaved"];

    [super willHide];
}

/*! called when permissions changes
*/
- (void)permissionsChanged
{
    [super permissionsChanged];
    [usersController permissionsChanged];
    if ([[CPUserDefaults standardUserDefaults] integerForKey:@"TNArchipelUseEjabberdSharedRosterGroups"] && [_entityCapabilities valueForKey:@"canManageSharedRostergroups"])
        [sharedGroupsController permissionsChanged];
}

/*! called when the UI needs to be updated according to the permissions
*/
- (void)setUIAccordingToPermissions
{
    [usersController setUIAccordingToPermissions];
    if ([[CPUserDefaults standardUserDefaults] integerForKey:@"TNArchipelUseEjabberdSharedRosterGroups"] && [_entityCapabilities valueForKey:@"canManageSharedRostergroups"])
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
    if ([[CPUserDefaults standardUserDefaults] integerForKey:@"TNArchipelUseEjabberdSharedRosterGroups"] && [_entityCapabilities valueForKey:@"canManageSharedRostergroups"])
        [sharedGroupsController flushUI];
}

#pragma mark -
#pragma mark Notification handlers

/*! called when on of hypervisor changes its presence
    @param aNotification the notification
*/
- (void)_didHypervisorPresenceUpdate:(CPNotification)aNotification
{
    [self checkHypervisors];
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

    if ([[CPUserDefaults standardUserDefaults] integerForKey:@"TNArchipelUseEjabberdSharedRosterGroups"] && [_entityCapabilities valueForKey:@"canManageSharedRostergroups"])
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

/*! check the hypervisors for management purpose
*/
- (void)checkHypervisors
{
    var checkForDomain = nil,
        enumerator = [_savedDomains keyEnumerator],
        key;

    if ([_savedDomains count] > 0)
        [_currentDomains removeAllObjects];

    if (([_savedDomains count] == 0) && _forceRosterRefresh)
    {
        _forceRosterRefresh = NO;

        for (var i = 0; i < [[[[TNStropheIMClient defaultClient] roster] contacts] count]; i++)
        {
            var contact = [[[[TNStropheIMClient defaultClient] roster] contacts] objectAtIndex:i];

            if (!_keepSearching)
                break

            if (![contact vCard])
            {
                [[CPNotificationCenter defaultCenter] removeObserver:self name:TNStropheContactVCardReceivedNotification object:nil];
                [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_didReceiveVcard:) name:TNStropheContactVCardReceivedNotification object:contact];
                [contact getVCard];
                continue;
            }

            if ((([[[TNStropheIMClient defaultClient] roster] analyseVCard:[contact vCard]] === TNArchipelEntityTypeHypervisor)
                || ([[[TNStropheIMClient defaultClient] roster] analyseVCard:[contact vCard]] === TNArchipelEntityTypeCentralAgent))
                && ([contact XMPPShow] != TNStropheContactStatusOffline))
            {
                [self fetchManagementCapabilitiesFor:contact];
            }
        }
    }
    else
    {
        while ((key = [enumerator nextObject]) != nil)
        {
            checkForDomain  = [ _savedDomains valueForKey:key];
            [_savedDomains removeObjectForKey:key];

            for (var i = 0; i < [[[[TNStropheIMClient defaultClient] roster] contacts] count]; i++)
            {
                var contact = [[[[TNStropheIMClient defaultClient] roster] contacts] objectAtIndex:i];

                if (!_keepSearching)
                    break

                if (![contact vCard])
                {
                    [[CPNotificationCenter defaultCenter] removeObserver:self name:TNStropheContactVCardReceivedNotification object:nil];
                    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_didReceiveVcard:) name:TNStropheContactVCardReceivedNotification object:contact];
                    [contact getVCard];
                    continue;
                }

                if ((([[[TNStropheIMClient defaultClient] roster] analyseVCard:[contact vCard]] === TNArchipelEntityTypeHypervisor)
                    || ([[[TNStropheIMClient defaultClient] roster] analyseVCard:[contact vCard]] === TNArchipelEntityTypeCentralAgent))
                    && ([contact XMPPShow] != TNStropheContactStatusOffline)
                    && ([[contact JID] compare:[[checkForDomain objectForKey:@"contact"] JID]] == 0))
                    [self fetchManagementCapabilitiesFor:contact];
            }
        }
    }
}

/*! populate the hypervisor pop up button according to dictionnary
*/

- (void)populateHypervisors
{
    var items = [CPArray array],
        enumerator = [_currentDomains keyEnumerator],
        key;

    while (key = [enumerator nextObject])
    {
        var item = [[CPMenuItem alloc] init],
            contact = [[_currentDomains objectForKey:key] objectForKey:@"contact"];

        [item setTitle:key];
        [item setRepresentedObject:[_currentDomains objectForKey:key]];
        [items addObject:item];
        [[CPNotificationCenter defaultCenter] removeObserver:self name:TNStropheContactPresenceUpdatedNotification object:contact];
        [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_didHypervisorPresenceUpdate:) name:TNStropheContactPresenceUpdatedNotification object:contact];
    }

    var sortDescriptor  = [CPSortDescriptor sortDescriptorWithKey:@"title.uppercaseString" ascending:YES],
        sortedItems     = [items sortedArrayUsingDescriptors:[CPArray arrayWithObject:sortDescriptor]];

    [buttonHypervisors removeAllItems];

    for (var i = 0; i < [sortedItems count]; i++)
        [buttonHypervisors addItem:[sortedItems objectAtIndex:i]];

    [buttonHypervisors selectItemAtIndex:0];
    [self changeCurrentHypervisor:buttonHypervisors];
}


#pragma mark -
#pragma mark Actions

/*! update sub controllers according to the selected hypervisor
    @param aSender the sender of the action
*/
- (IBAction)changeCurrentHypervisor:(id)aSender
{
    _entity = [[[buttonHypervisors selectedItem] representedObject] objectForKey:@"contact"];

    var canManageUsers = [[[buttonHypervisors selectedItem] representedObject] objectForKey:@"canManageUsers"] || NO,
        canManageSharedRostergroups = [[[buttonHypervisors selectedItem] representedObject] objectForKey:@"canManageSharedRostergroups"] || NO;

    _entityCapabilities = @{@"canManageUsers": canManageUsers, @"canManageSharedRostergroups": canManageSharedRostergroups}

    [buttonHypervisors setToolTip:CPBundleLocalizedString([[_entity JID] domain] + @" managed by " + [[_entity JID] bare], [[_entity JID] domain] + @" managed by " + [[_entity JID] bare])];

    [usersController setEntity:[[buttonHypervisors selectedItem] representedObject]];

    if (([[CPUserDefaults standardUserDefaults] integerForKey:@"TNArchipelUseEjabberdSharedRosterGroups"]) && [_entityCapabilities valueForKey:@"canManageSharedRostergroups"])
        [sharedGroupsController setEntity:[[buttonHypervisors selectedItem] representedObject]];

    [self flushUI];
    [self manageToolbarItems];
    [self permissionsChanged];
    [self tabView:tabViewMain didSelectTabViewItem:[tabViewMain selectedTabViewItem]];

}

#pragma mark -
#pragma mark XMPP Management


/*! get the group management capabilities
*/
- (void)fetchManagementCapabilitiesFor:(id)aContact
{
    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{@"xmlns": TNArchipelTypeXMPPServer}];
    [stanza addChildWithName:@"archipel" andAttributes:{@"action": TNArchipelTypeXMPPServerManagementCapabilities}];
    [aContact sendStanza:stanza andRegisterSelector:@selector(_didfetchManagementCapabilities:forContact:) ofObject:self userInfo:aContact];
}

/*! compute the answer
    @param aStanza TNStropheStanza containing the answer
*/
- (void)_didfetchManagementCapabilities:(TNStropheStanza)aStanza forContact:(id)aContact
{
    if ([aStanza type] == @"result")
    {

        var usersManagement  = (([[aStanza firstChildWithName:@"users"] valueForAttribute:@"xmpp"]    == @"True") ? true : false) || (([[aStanza firstChildWithName:@"users"] valueForAttribute:@"xmlrpc"]  == @"True") ? true : false),
            groupsManagement = (([[aStanza firstChildWithName:@"groups"] valueForAttribute:@"xmpp"]   == @"True") ? true : false) || (([[aStanza firstChildWithName:@"groups"] valueForAttribute:@"xmlrpc"] == @"True") ? true : false);

        if (usersManagement && groupsManagement)
        {
            [_currentDomains setValue:@{@"contact":aContact, @"canManageUsers":usersManagement, @"canManageSharedRostergroups":groupsManagement}  forKey:[[aContact JID] domain]];
            _keepSearching = NO;

        }
        else if ((usersManagement && ! groupsManagement) && ! ([_currentDomains containsKey:[[aContact JID] domain]]))
        {
            [_currentDomains setValue:@{@"contact":aContact, @"canManageUsers":usersManagement, @"canManageSharedRostergroups":groupsManagement}  forKey:[[aContact JID] domain]];
        }

        [self populateHypervisors];

    }
}

- (void)_didReceiveVcard:(CPNotification)aNotification
{
    var contact = [aNotification object];

    if ((([[[TNStropheIMClient defaultClient] roster] analyseVCard:[contact vCard]] === TNArchipelEntityTypeHypervisor)
        || ([[[TNStropheIMClient defaultClient] roster] analyseVCard:[contact vCard]] === TNArchipelEntityTypeCentralAgent))
        && ([contact XMPPShow] != TNStropheContactStatusOffline))
    {
        [self fetchManagementCapabilitiesFor:contact];
    }
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

/*! delegate of TNPubSubNode
*/
- (void)pubSubNode:(TNPubSubNode)aNode retrievedItems:(BOOL)hasRetrievedItems
{
    var last_pubsub_item = [[_nodeCentralAgent content] firstObject];
    if (last_pubsub_item)
    {
        var jid = [[last_pubsub_item firstChildWithName:@"event"] valueForAttribute:@"jid"],
            JID = [TNStropheJID stropheJIDWithString:jid],
            roster = [[TNStropheIMClient defaultClient] roster],
            contact = [roster contactWithJID:JID];

        CPLog.info("Central Agent jid found, we will use it: " + JID);
        if (!contact)
        {
            [roster addContact:JID withName:[JID node] inGroup:nil];
            contact = [roster contactWithJID:JID];
        }

        [self fetchManagementCapabilitiesFor:contact];
    }
}

@end


// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNXMPPServerController], comment);
}
