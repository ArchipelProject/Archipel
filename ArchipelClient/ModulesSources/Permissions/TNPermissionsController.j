/*
 * TNSampleTabModule.j
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

@import <AppKit/CPButton.j>
@import <AppKit/CPButtonBar.j>
@import <AppKit/CPImage.j>
@import <AppKit/CPSearchField.j>
@import <AppKit/CPSplitView.j>
@import <AppKit/CPTableView.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPView.j>

@import <TNKit/TNTableViewDataSource.j>

@import "TNRolesController.j"
@import "TNXMPPUserDatasource.j"



var TNArchipelTypePermissions                   = @"archipel:permissions",
    TNArchipelTypePermissionsList               = @"list",
    TNArchipelTypePermissionsGet                = @"get",
    TNArchipelTypePermissionsSet                = @"set",
    TNArchipelTypePermissionsGetOwn             = @"getown",
    TNArchipelTypePermissionsSetOwn             = @"setown",
    TNArchipelPushNotificationPermissions       = @"archipel:push:permissions",
    TNArchipelPushNotificationXMPPServerUsers   = @"archipel:push:xmppserver:users",
    TNArchipelTypeXMPPServerUsers               = @"archipel:xmppserver:users",
    TNArchipelTypeXMPPServerUsersList           = @"list";

/*! @defgroup  permissionsmodule Module Permissions
    @desc This module allow to manages entity permissions
*/

/*! @ingroup permissionsmodule
    Permission module implementation
*/
@implementation TNPermissionsController : TNModule
{
    @outlet CPButtonBar             buttonBarControl;
    @outlet CPScrollView            scrollViewUsers;
    @outlet CPSearchField           filterField;
    @outlet CPSplitView             splitView;
    @outlet CPTableView             tablePermissions;
    @outlet CPTextField             labelNoUserSelected;
    @outlet CPView                  viewTableContainer;
    @outlet CPView                  viewUsersLeft;
    @outlet TNRolesController       rolesController;

    TNTableViewDataSource           _datasourcePermissions  @accessors(getter=datasourcePermissions);

    CPArray                         _currentUserPermissions;
    CPButton                        _applyRoleButton;
    CPButton                        _saveAsTemplateButton;
    CPButton                        _saveButton;
    CPImage                         _defaultAvatar;
    CPOutlineView                   _outlineViewUsers;
    TNXMPPUserDatasource            _datasourceUsers;
}


#pragma mark -
#pragma mark Initialization

/*! called at cib awakening
*/
- (void)awakeFromCib
{
    _currentUserPermissions = [CPArray array];
    _defaultAvatar          = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"user-unknown.png"]];

    [splitView setBorderedWithHexColor:@"#C0C7D2"];

    [viewTableContainer setHidden:YES];

    // table users
    _datasourcePermissions  = [[TNTableViewDataSource alloc] init];
    [_datasourcePermissions setTable:tablePermissions];
    [_datasourcePermissions setSearchableKeyPaths:[@"name", @"description"]];
    [tablePermissions setDataSource:_datasourcePermissions];

    _saveButton = [CPButtonBar plusButton];
    [_saveButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/save.png"] size:CPSizeMake(16, 16)]];
    [_saveButton setTarget:self];
    [_saveButton setAction:@selector(changePermissionsState:)];
    [_saveButton setToolTip:CPBundleLocalizedString(@"Save the current set of permissions", @"Save the current set of permissions")];

    _saveAsTemplateButton = [CPButtonBar plusButton];
    [_saveAsTemplateButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/role_add.png"] size:CPSizeMake(16, 16)]];
    [_saveAsTemplateButton setTarget:rolesController];
    [_saveAsTemplateButton setAction:@selector(openNewTemplateWindow:)];
    [_saveAsTemplateButton setToolTip:CPBundleLocalizedString(@"Save the current set of permissions as a role", @"Save the current set of permissions as a role")];

    _applyRoleButton = [CPButtonBar plusButton];
    [_applyRoleButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/roles.png"] size:CPSizeMake(16, 16)]];
    [_applyRoleButton setTarget:self];
    [_applyRoleButton setAction:@selector(openRolesWindow:)];
    [_applyRoleButton setToolTip:CPBundleLocalizedString(@"Select a role as permissions template", @"Select a role as permissions template")];

    [buttonBarControl setButtons:[_saveButton, _saveAsTemplateButton, _applyRoleButton]];

    [filterField setTarget:_datasourcePermissions];
    [filterField setAction:@selector(filterObjects:)];

    [rolesController setDelegate:self];

    // outline view
    [labelNoUserSelected setTextShadowOffset:CGSizeMake(0.0, 1.0)];
    [labelNoUserSelected setValue:[CPColor whiteColor] forThemeAttribute:@"text-shadow-color"];
    [viewUsersLeft setBackgroundColor:[CPColor colorWithHexString:@"F4F4F4"]];
    [scrollViewUsers setAutohidesScrollers:YES];

    _outlineViewUsers = [[CPOutlineView alloc] initWithFrame:[scrollViewUsers bounds]];
    _datasourceUsers = [[TNXMPPUserDatasource alloc] init];

    [_outlineViewUsers setDelegate:self];
    [_outlineViewUsers setCornerView:nil];
    [_outlineViewUsers setAllowsColumnResizing:YES];
    [_outlineViewUsers setUsesAlternatingRowBackgroundColors:YES];
    [_outlineViewUsers setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [_outlineViewUsers setDataSource:_datasourceUsers];
    [_outlineViewUsers setBackgroundColor:[CPColor blueColor]];
    [scrollViewUsers setDocumentView:_outlineViewUsers];

    var columnName  = [[CPTableColumn alloc] initWithIdentifier:@"description"];

    [[columnName headerView] setStringValue:CPBundleLocalizedString(@"Users", @"Users")];

    [_outlineViewUsers setOutlineTableColumn:columnName];
    [_outlineViewUsers addTableColumn:columnName];
}


#pragma mark -
#pragma mark TNModule overrides

/*! called when module is loaded
*/
- (BOOL)willLoad
{
    [super willLoad];
    [rolesController fetchPubSubNodeIfNeeded];
    [_datasourceUsers removeAllObjects];
    [_outlineViewUsers setDelegate:nil];
    [_outlineViewUsers setDelegate:self];
    [tablePermissions setDelegate:nil];
    [tablePermissions setDelegate:self];

    var center = [CPNotificationCenter defaultCenter];
    [center postNotificationName:TNArchipelModulesReadyNotification object:self];

    [self registerSelector:@selector(_didReceivePermissionsPush:) forPushNotificationType:TNArchipelPushNotificationPermissions];
    [self registerSelector:@selector(_didReceiveUsersPush:) forPushNotificationType:TNArchipelPushNotificationXMPPServerUsers];

    for (var i = 0; i < [[[[TNStropheIMClient defaultClient] roster] contacts] count]; i++)
    {
        var contact = [[[[TNStropheIMClient defaultClient] roster] contacts] objectAtIndex:i];

        if ([[[TNStropheIMClient defaultClient] roster] analyseVCard:[contact vCard]] == TNArchipelEntityTypeUser)
            [_datasourceUsers addRosterUser:[TNStropheJID stropheJIDWithString:[[contact JID] bare]]];
    }

    [self getXMPPUsers];
}

/*! called when module is hidden
*/
- (void)willHide
{
    [rolesController closeWindow:nil];
    [rolesController closeNewTemplateWindow:nil];
    [super willHide];
}

/*! called when module is unloaded
*/
- (void)willUnload
{
    [_datasourcePermissions removeAllObjects];
    [tablePermissions reloadData];
    [_datasourceUsers removeAllObjects];
    [_outlineViewUsers reloadData];
    [viewTableContainer setHidden:YES];
    [labelNoUserSelected setHidden:NO];
    [_outlineViewUsers deselectAll];
    [super willUnload];
}

/*! called when permissions changes
*/
- (void)permissionsChanged
{
    if (![self currentEntityHasPermission:@"permission_get"])
        [self changeCurrentUser:nil];

    var hasSetOwn   = [self currentEntityHasPermission:@"permission_setown"],
        hasSet      = [self currentEntityHasPermission:@"permission_set"];

    if (hasSet || hasSetOwn)
    {
        if (hasSetOwn)
            [self setControl:_saveButton enabledAccordingToPermission:@"permission_setown"];
        if (hasSet)
            [self setControl:_saveButton enabledAccordingToPermission:@"permission_set"];
    }
    else
        [self setControl:_saveButton enabledAccordingToPermission:@"permission_FAKE!"];
}


#pragma mark -
#pragma mark Notification handlers

/*! called when an Archipel push is received
    @param somePushInfo CPDictionary containing the push information
*/
- (BOOL)_didReceivePermissionsPush:(CPDictionary)somePushInfo
{
    var sender  = [somePushInfo objectForKey:@"owner"],
        type    = [somePushInfo objectForKey:@"type"],
        change  = [somePushInfo objectForKey:@"change"],
        date    = [somePushInfo objectForKey:@"date"];

    [self changeCurrentUser:nil];

    return YES;
}

/*! called when an Archipel push is received
    @param somePushInfo CPDictionary containing the push information
*/
- (BOOL)_didReceiveUsersPush:(CPDictionary)somePushInfo
{
    var sender  = [somePushInfo objectForKey:@"owner"],
        type    = [somePushInfo objectForKey:@"type"],
        change  = [somePushInfo objectForKey:@"change"],
        date    = [somePushInfo objectForKey:@"date"],
        stanza  = [somePushInfo objectForKey:@"rawStanza"];

    var users = [stanza childrenWithName:@"user"];
    [_datasourceUsers removeAllObjects];
    for (var i = 0; i < [users count]; i++)
    {
        var user    = [users objectAtIndex:i],
            jid     = [TNStropheJID stropheJIDWithString:[user valueForAttribute:@"jid"]],
            type    = [user valueForAttribute:@"type"];

        if (type == @"human" && ![jid bareEquals:[[TNStropheIMClient defaultClient] JID]])
            [_datasourceUsers addXMPPUser:jid];
    }
    [_outlineViewUsers expandAll];
    [_outlineViewUsers reloadData];

    return YES;
}


#pragma mark -
#pragma mark Utilities

/*! will select all permissions given (and deselect others)
    @param somePermissions CPArray containing a list raw Archipel permissions (TNXMLNodes)
*/
- (void)applyPermissions:(CPArray)somePermissions
{
    for (var j = 0; j < [_datasourcePermissions count]; j++)
    {
        var perm = [_datasourcePermissions objectAtIndex:j];
        [perm setValue:CPOffState forKey:@"state"];
    }

    [self addPermissions:somePermissions];
}

/*! will add all permissions given (keeping existing)
    @param somePermissions CPArray containing a list raw Archipel permissions (TNXMLNodes)
*/
- (void)addPermissions:(CPArray)somePermissions
{
    for (var i = 0; i < [somePermissions count]; i++)
    {
        var permTemplate = [somePermissions objectAtIndex:i];

        for (var j = 0; j < [_datasourcePermissions count]; j++)
        {
            var perm = [_datasourcePermissions objectAtIndex:j];
            if ([perm valueForKey:@"name"] == [permTemplate valueForAttribute:@"permission_name"])
            {
                [perm setValue:CPOnState forKey:@"state"];
                break;
            }
        }
    }

    [tablePermissions reloadData];
}

/*! will remove all permissions given
    @param somePermissions CPArray containing a list raw Archipel permissions (TNXMLNodes)
*/
- (void)retractPermissions:(CPArray)somePermissions
{
    for (var i = 0; i < [somePermissions count]; i++)
    {
        var permTemplate = [somePermissions objectAtIndex:i];

        for (var j = 0; j < [_datasourcePermissions count]; j++)
        {
            var perm = [_datasourcePermissions objectAtIndex:j];
            if ([perm valueForKey:@"name"] == [permTemplate valueForAttribute:@"permission_name"])
            {
                [perm setValue:CPOffState forKey:@"state"];
                break;
            }
        }
    }
    [tablePermissions reloadData];
}


#pragma mark -
#pragma mark Actions

/*! will set permissions
    @param aSender the sender of the action
*/
- (IBAction)changePermissionsState:(id)aSender
{
    [self changePermissionsState];
}

/*! will take care of the current user change
    @param aSender the sender of the action
*/
- (IBAction)changeCurrentUser:(id)aSender
{
    if ([_outlineViewUsers numberOfSelectedRows] > 0)
    {
        var selectedIndexes = [_outlineViewUsers selectedRowIndexes],
            object          = [_outlineViewUsers itemAtRow:[selectedIndexes firstIndex]];

        if ([object isKindOfClass:TNStropheJID])
        {
            [viewTableContainer setHidden:NO];
            [labelNoUserSelected setHidden:YES];
            [self getUserPermissions:[object bare]];
        }
        else if (object == TNXMPPUserDatasourceMe)
        {
            [viewTableContainer setHidden:NO];
            [labelNoUserSelected setHidden:YES];
            [self getUserPermissions:[[[TNStropheIMClient defaultClient] JID] bare]];
        }
        else
        {
            [_datasourcePermissions removeAllObjects];
            [tablePermissions reloadData];
            [viewTableContainer setHidden:YES];
            [labelNoUserSelected setHidden:NO];
        }
    }
    else
    {
        [_datasourcePermissions removeAllObjects];
        [tablePermissions reloadData];
        [viewTableContainer setHidden:YES];
        [labelNoUserSelected setHidden:NO];
    }
}

/*! will open the new role window
    @param aSender the sender of the action
*/
- (IBAction)openRolesWindow:(id)aSender
{
    [rolesController openWindow:aSender];
}


#pragma mark -
#pragma mark XMPP Controls

/*! ask for existing permissions
*/
- (void)getPermissions
{
    if (![self currentEntityHasPermission:@"permission_list"])
        return;

    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypePermissions}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypePermissionsList}];

    [self setModuleStatus:TNArchipelModuleStatusWaiting];
    [_entity sendStanza:stanza andRegisterSelector:@selector(_didReceivePermissions:) ofObject:self];

}

/*! compute the answer containing the permissions
    @param aStanza TNStropheStanza containing the answer
*/
- (void)_didReceivePermissions:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        [_datasourcePermissions removeAllObjects];

        var permissions = [aStanza childrenWithName:@"permission"];

        for (var i = 0; i < [permissions count]; i++)
        {
            var permission      = [permissions objectAtIndex:i],
                name            = [permission valueForAttribute:@"name"],
                description     = [permission valueForAttribute:@"description"],
                state           = [_currentUserPermissions containsObject:name] ? CPOnState : CPOffState;
            var newPermission = [CPDictionary dictionaryWithObjectsAndKeys:name, @"name", description, @"description", state, "state"];
            [_datasourcePermissions addObject:newPermission];
        }

        [tablePermissions reloadData];
        [self setModuleStatus:TNArchipelModuleStatusReady];
    }
    else
    {
        [self setModuleStatus:TNArchipelModuleStatusError];
        [self handleIqErrorFromStanza:aStanza];
    }
}

/*! ask for permissions of given user
    @param aUser the user you want the permissions
*/
- (void)getUserPermissions:(CPString)aUser
{
    if (![self currentEntityHasPermission:@"permission_get"] && ![self currentEntityHasPermission:@"permission_getown"])
        return;

    var stanza = [TNStropheStanza iqWithType:@"get"],
        currentAction = TNArchipelTypePermissionsGetOwn;

    if ([self currentEntityHasPermission:@"permission_get"])
        currentAction = TNArchipelTypePermissionsGet

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypePermissions}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": currentAction,
        "permission_type": "user",
        "permission_target": aUser}];

    [self setModuleStatus:TNArchipelModuleStatusWaiting];
    [_entity sendStanza:stanza andRegisterSelector:@selector(_didReceiveUserPermissions:) ofObject:self];
}

/*! compute the answer containing the user' permissions
    @param aStanza TNStropheStanza containing the answer
*/
- (void)_didReceiveUserPermissions:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        var permissions = [aStanza childrenWithName:@"permission"];

        [_currentUserPermissions removeAllObjects];
        for (var i = 0; i < [permissions count]; i++)
        {
            var permission      = [permissions objectAtIndex:i],
                name            = [permission valueForAttribute:@"name"];

            [_currentUserPermissions addObject:name]
        }

        [self getPermissions];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}

/*! change the permissions
*/
- (void)changePermissionsState
{
    var stanza = [TNStropheStanza iqWithType:@"set"],
        currentAction = TNArchipelTypePermissionsSetOwn,
        selectedIndexes = [_outlineViewUsers selectedRowIndexes],
        permissionTarget = [_outlineViewUsers itemAtRow:[selectedIndexes firstIndex]];

    if ([self currentEntityHasPermission:@"permission_set"])
        currentAction = TNArchipelTypePermissionsSet

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypePermissions}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        @"action": currentAction}];


    for (var i = 0; i < [_datasourcePermissions count]; i++)
    {
        var perm = [_datasourcePermissions objectAtIndex:i];
        [stanza addChildWithName:@"permission" andAttributes:{
            @"permission_target": permissionTarget,
            @"permission_type": @"user",
            @"permission_name": [perm objectForKey:@"name"],
            @"permission_value": ([perm valueForKey:@"state"] === CPOnState),
        }];
        [stanza up];
    }

    [_entity sendStanza:stanza andRegisterSelector:@selector(_didChangePermissionsState:) ofObject:self];
}

/*! compute the answer containing the result of changing the permissions
    @param aStanza TNStropheStanza containing the answer
*/
- (void)_didChangePermissionsState:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[_entity nickname]
                                                         message:CPBundleLocalizedString(@"Permission for selected user has been saved.", @"Permission for selected user has been saved.")];
    else
        [self handleIqErrorFromStanza:aStanza];
}

/*! ask for permissions of given user
*/
- (void)getXMPPUsers
{
    var hypervisors = [CPArray array],
        servers = [CPArray array],
        roster = [[TNStropheIMClient defaultClient] roster];

    for (var i = 0; i < [[roster contacts] count]; i++)
    {
        var contact = [[roster contacts] objectAtIndex:i];

        if (([roster analyseVCard:[contact vCard]] === TNArchipelEntityTypeHypervisor)
            && ([contact XMPPShow] != TNStropheContactStatusOffline)
            && ![hypervisors containsObject:contact]
            && ![servers containsObject:[[contact JID] domain]])
        {
            if (![[TNPermissionsCenter defaultCenter] hasPermission:@"xmppserver_users_list" forEntity:contact])
                continue;
            [servers addObject:[[contact JID] domain]];
            [hypervisors addObject:contact];
        }
    }

    for (var i = 0; i < [hypervisors count]; i++)
    {
        var stanza = [TNStropheStanza iqWithType:@"get"];

        [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeXMPPServerUsers}];
        [stanza addChildWithName:@"archipel" andAttributes:{
            "action": TNArchipelTypeXMPPServerUsersList}];

        [[hypervisors objectAtIndex:i] sendStanza:stanza andRegisterSelector:@selector(_didGetXMPPUsers:) ofObject:self];
    }
}

/*! compute the answer containing the user' permissions
    @param aStanza TNStropheStanza containing the answer
*/
- (void)_didGetXMPPUsers:(TNStropheStanza)aStanza
{
    if ([aStanza type] != @"result")
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}


#pragma mark -
#pragma mark Delegate

- (void)tableView:(CPTableView)aTableView willDisplayView:(CPView)aView forTableColumn:(CPTableColumn)aColumn row:(int)aRow
{
    if ([aView isKindOfClass:CPCheckBox])
        [aView setState:[[_datasourcePermissions objectAtIndex:aRow] objectForKey:@"state"]];
}

- (void)outlineViewSelectionDidChange:(CPNotification)aNotification
{
    [self changeCurrentUser:nil];
}

- (void)outlineView:(CPOutlineView)anOutlineView shouldSelectItem:(id)anItem
{
    return ([anItem isKindOfClass:TNStropheJID] || anItem == TNXMPPUserDatasourceMe);
}

- (void)outlineView:(CPOutlineView)anOutlineView dataViewForTableColumn:(CPTableColumn)aColumn item:(id)anItem
{
    var viewProto = [[CPTextField alloc] init];

    if (![anItem isKindOfClass:TNStropheJID])
    {
        [viewProto setTextColor:[CPColor colorWithHexString:@"7F7F7F"]];
        [viewProto setValue:[CPColor whiteColor] forThemeAttribute:@"text-color" inState:CPThemeStateSelectedDataView];
        [viewProto setFont:[CPFont boldSystemFontOfSize:12.0]];
        return viewProto;
    }
    return viewProto;
}
@end


// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNPermissionsController], comment);
}