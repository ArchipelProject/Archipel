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
@import <TNKit/TNTableViewLazyDataSource.j>

@import "TNPermissionUserFetcher.j"
@import "TNRolesController.j"

var TNArchipelTypePermissions                   = @"archipel:permissions",
    TNArchipelTypePermissionsList               = @"list",
    TNArchipelTypePermissionsGet                = @"get",
    TNArchipelTypePermissionsSet                = @"set",
    TNArchipelTypePermissionsGetOwn             = @"getown",
    TNArchipelTypePermissionsSetOwn             = @"setown",
    TNArchipelPushNotificationPermissions       = @"archipel:push:permissions",
    TNArchipelPushNotificationXMPPServerUsers   = @"archipel:push:xmppserver:users";


/*! @defgroup  permissionsmodule Module Permissions
    @desc This module allow to manages entity permissions
*/

/*! @ingroup permissionsmodule
    Permission module implementation
*/
@implementation TNPermissionsController : TNModule
{
    @outlet CPButtonBar             buttonBarControl;
    @outlet CPSearchField           filterField;
    @outlet CPSearchField           filterUsers;
    @outlet CPSearchField           filterRosterUsers;
    @outlet CPSplitView             splitView;
    @outlet CPTableView             tablePermissions;
    @outlet CPTableView             tableRosterUsers;
    @outlet CPTableView             tableUsers;
    @outlet CPTextField             labelNoUserSelected;
    @outlet CPView                  viewTableContainer;
    @outlet TNRolesController       rolesController;

    TNTableViewDataSource           _datasourcePermissions  @accessors(getter=datasourcePermissions);

    CPArray                         _currentUserPermissions;
    CPButton                        _applyRoleButton;
    CPButton                        _saveAsTemplateButton;
    CPButton                        _saveButton;
    CPImage                         _defaultAvatar;
    CPOutlineView                   _outlineViewUsers;
    TNPermissionUserFetcher         _userFetcher;
    TNTableViewDataSource           _datasourceRosterUsers;
    TNTableViewLazyDataSource       _datasourceUsers;
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

    // Label no users selected
    [labelNoUserSelected setTextShadowOffset:CGSizeMake(0.0, 1.0)];
    [labelNoUserSelected setValue:[CPColor whiteColor] forThemeAttribute:@"text-shadow-color"];

    // Table users in roster
    _datasourceRosterUsers= [[TNTableViewDataSource alloc] init];
    [_datasourceRosterUsers setTable:tableRosterUsers];
    [_datasourceRosterUsers setSearchableKeyPaths:[@"JID"]];
    [tableRosterUsers setDataSource:_datasourceRosterUsers];

    // Table users from server
    _datasourceUsers = [[TNTableViewLazyDataSource alloc] init];
    [_datasourceUsers setTable:tableUsers];
    [tableUsers setDataSource:_datasourceUsers];

    // user fetcher
    _userFetcher = [[TNPermissionUserFetcher alloc] init];
    [_userFetcher setDisplaysOnlyHumans:YES];
    [_userFetcher setDataSource:_datasourceUsers];
    [_userFetcher setDelegate:self];

    [filterUsers setTarget:_datasourceUsers];
    [filterUsers setAction:@selector(filterObjects:)];
    [filterRosterUsers setTarget:_datasourceRosterUsers];
    [filterRosterUsers setAction:@selector(filterObjects:)];

    var filterBg = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"Backgrounds/background-filter.png"]];
    [[filterUsers superview] setBackgroundColor:[CPColor colorWithPatternImage:filterBg]];
    [[filterRosterUsers superview] setBackgroundColor:[CPColor colorWithPatternImage:filterBg]];
    [[filterField superview] setBackgroundColor:[CPColor colorWithPatternImage:filterBg]];
}


#pragma mark -
#pragma mark TNModule overrides

/*! called when module is loaded
*/
- (BOOL)willLoad
{
    if (![super willLoad])
        return;

    [rolesController fetchPubSubNodeIfNeeded];

    [_userFetcher setEntity:_entity];

    [tableRosterUsers setDelegate:nil];
    [tableRosterUsers setDelegate:self];
    [tableUsers setDelegate:nil];
    [tableUsers setDelegate:self];
    [tablePermissions setDelegate:nil];
    [tablePermissions setDelegate:self];

    var center = [CPNotificationCenter defaultCenter];
    [center postNotificationName:TNArchipelModulesReadyNotification object:self];

    [self registerSelector:@selector(_didReceivePermissionsPush:) forPushNotificationType:TNArchipelPushNotificationPermissions];
    [self registerSelector:@selector(_didReceiveUsersPush:) forPushNotificationType:TNArchipelPushNotificationXMPPServerUsers];

    [self reloadRosterUsersTable];
    [self reloadUsersTable];
    return YES;
}

/*! called when module is hidden
*/
- (void)willHide
{
    [_userFetcher reset];
    [rolesController closeWindow:nil];
    [rolesController closeNewTemplateWindow:nil];
    [super willHide];
}

/*! called when permissions changes
*/
- (void)permissionsChanged
{
    [super permissionsChanged];
    [self reloadRosterUsersTable];
    [self reloadUsersTable];
}

/*! called when the UI needs to be updated according to the permissions
*/
- (void)setUIAccordingToPermissions
{
    // ATTENTION
    // if (![self currentEntityHasPermission:@"permission_get"])
    //     [self changeCurrentUser:nil];

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

/*! this message is used to flush the UI
*/
- (void)flushUI
{
    [_userFetcher reset];

    [_datasourceUsers removeAllObjects];
    [_datasourceRosterUsers removeAllObjects];
    [_datasourcePermissions removeAllObjects];

    [tableUsers reloadData];
    [tableRosterUsers reloadData];
    [tablePermissions reloadData];
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

    // ATTENTION
    // [self changeCurrentUser:nil];

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

    [self reloadUsersTable];
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

/*! Reloads the server users table
*/
- (void)reloadUsersTable
{
    [_userFetcher reset];
    [_datasourceUsers removeAllObjects];
    [tableUsers reloadData];
    [_userFetcher getXMPPUsers];
}

/*! Reloads the roster users table
*/
- (void)reloadRosterUsersTable
{
    [_datasourceRosterUsers removeAllObjects];
    for (var i = 0; i < [[[[TNStropheIMClient defaultClient] roster] contacts] count]; i++)
    {
        var contact = [[[[TNStropheIMClient defaultClient] roster] contacts] objectAtIndex:i];

        if ([[[TNStropheIMClient defaultClient] roster] analyseVCard:[contact vCard]] == TNArchipelEntityTypeUser)
            [_datasourceRosterUsers addObject:contact];
    }

    [tableRosterUsers reloadData];
}

/*! will take care of the current user change
    @param currentTable the source tableview
*/
- (void)changeCurrentUser:(id)currentTable
{
    if ([currentTable numberOfSelectedRows] > 0)
    {
        var object = [[currentTable dataSource] objectAtIndex:[currentTable selectedRow]];

        [viewTableContainer setHidden:NO];
        [labelNoUserSelected setHidden:YES];
        if ([object isKindOfClass:TNStropheContact])
            [self getUserPermissions:[[object JID] bare]];
        else
            [self getUserPermissions:[object bare]];
    }
    else
    {
        [_datasourcePermissions removeAllObjects];
        [tablePermissions reloadData];
        [viewTableContainer setHidden:YES];
        [labelNoUserSelected setHidden:NO];
    }
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
    var currentTable = ([tableUsers numberOfSelectedRows] > 0) ? tableUsers : tableRosterUsers,
        stanza = [TNStropheStanza iqWithType:@"set"],
        currentAction = TNArchipelTypePermissionsSetOwn,
        permissionTarget = [[currentTable dataSource] objectAtIndex:[currentTable selectedRow]];

    if ([permissionTarget isKindOfClass:TNStropheContact])
        permissionTarget = [[permissionTarget JID] bare];
    else
        permissionTarget = [permissionTarget bare];

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


#pragma mark -
#pragma mark Delegate

- (void)tableView:(CPTableView)aTableView willDisplayView:(CPView)aView forTableColumn:(CPTableColumn)aColumn row:(int)aRow
{
    if (aTableView !== tablePermissions)
        return;

    try
    {
        if ([aView isKindOfClass:CPCheckBox])
            [aView setState:[[_datasourcePermissions objectAtIndex:aRow] objectForKey:@"state"]]; // I guess there is bug in Capp here
    }
    catch (e)
    {
        CPLog.error("weird error here " + e);
    }
}

- (void)tableViewSelectionDidChange:(CPNotification)aNotification
{
    if ([aNotification object] === tablePermissions)
        return;

    switch ([aNotification object])
    {
        case tableUsers:
            // avoid stack spam
            if ([tableRosterUsers numberOfSelectedRows] > 0)
                [tableRosterUsers deselectAll];
            else
                [self changeCurrentUser:tableUsers];
            break;

        case tableRosterUsers:
            // avoid stack spam
            if ([tableUsers numberOfSelectedRows] > 0)
                [tableUsers deselectAll];
            else
                [self changeCurrentUser:tableRosterUsers];
            break;
    }
}

/*! delegate of TNPermissionUserFetcher
*/
- (void)userFetcherClean
{

    [_datasourceUsers removeAllObjects];
    [tableUsers reloadData];
}

@end


// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNPermissionsController], comment);
}