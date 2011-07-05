/*
 * TNXMPPSharedGroupsController.j
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
@import <AppKit/CPPopUpButton.j>
@import <AppKit/CPScrollView.j>
@import <AppKit/CPSearchField.j>
@import <AppKit/CPSplitView.j>
@import <AppKit/CPTableView.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPView.j>
@import <AppKit/CPWindow.j>

@import <TNKit/TNAlert.j>
@import <TNKit/TNTableViewDataSource.j>



var TNArchipelTypeXMPPServerGroups              = @"archipel:xmppserver:groups",
    TNArchipelTypeXMPPServerGroupsCreate        = @"create",
    TNArchipelTypeXMPPServerGroupsDelete        = @"delete",
    TNArchipelTypeXMPPServerGroupsAddUsers      = @"addusers",
    TNArchipelTypeXMPPServerGroupsDeleteUsers   = @"deleteusers",
    TNArchipelTypeXMPPServerGroupsList          = @"list";


/*! @ingroup toolbarxmppserver
    Shared groups controller implementation
*/
@implementation TNXMPPSharedGroupsController : CPObject
{
    @outlet CPButton            buttonCreate;
    @outlet CPButtonBar         buttonBarGroups;
    @outlet CPButtonBar         buttonBarUsersInGroups;
    @outlet CPSearchField       filterFieldGroups;
    @outlet CPSearchField       filterFieldUsers;
    @outlet CPSearchField       filterFieldUsersInGroup;
    @outlet CPSplitView         splitViewVertical;
    @outlet CPTableView         tableGroups;
    @outlet CPTableView         tableUsers;
    @outlet CPTableView         tableUsersInGroup;
    @outlet CPTextField         fieldNewGroupDescription;
    @outlet CPTextField         fieldNewGroupName;
    @outlet CPView              mainView                    @accessors(getter=mainView);
    @outlet CPView              viewTableGroupsContainer;
    @outlet CPView              viewTableUsersInGroupContainer;
    @outlet CPWindow            windowAddUserInGroup;
    @outlet CPWindow            windowNewGroup;

    id                          _delegate           @accessors(property=delegate);
    TNStropheContact            _entity             @accessors(setter=setEntity:);
    TNXMPPUsersController       _usersController    @accessors(setter=setUsersController:);

    CPButton                    _addGroupButton;
    CPButton                    _addUserInGroupButton;
    CPButton                    _deleteGroupButton;
    CPButton                    _deleteUserFromGroupButton;
    id                          _currentSelectedGroup;
    int                         _oldSelectedIndexesForGroupTable;
    TNTableViewDataSource       _datasourceGroups;
    TNTableViewDataSource       _datasourceUsers;
    TNTableViewDataSource       _datasourceUsersInGroup;
}

#pragma mark -
#pragma mark Initialization

/*! called at cib awakening
*/
- (void)awakeFromCib
{
    [windowNewGroup setDefaultButton:buttonCreate];

    [viewTableGroupsContainer setBorderedWithHexColor:@"#C0C7D2"];
    [viewTableUsersInGroupContainer setBorderedWithHexColor:@"#C0C7D2"];
    [splitViewVertical setBorderedWithHexColor:@"#C0C7D2"];
    [splitViewVertical setIsPaneSplitter:YES];

    /* table Users */
    _datasourceUsers  = [[TNTableViewDataSource alloc] init];
    [_datasourceUsers setTable:tableUsers];
    [_datasourceUsers setSearchableKeyPaths:[@"name", @"jid"]];
    [tableUsers setDataSource:_datasourceUsers];
    [filterFieldUsers setTarget:_datasourceUsers];
    [filterFieldUsers setAction:@selector(filterObjects:)];

    /* table Groups */
    _datasourceGroups   = [[TNTableViewDataSource alloc] init];
    [_datasourceGroups setTable:tableGroups];
    [_datasourceGroups setSearchableKeyPaths:[@"name", @"description"]];
    [tableGroups setDataSource:_datasourceGroups];
    [tableGroups setDelegate:self];
    [filterFieldGroups setTarget:_datasourceGroups];
    [filterFieldGroups setAction:@selector(filterObjects:)];

    _addGroupButton = [CPButtonBar plusButton];
    [_addGroupButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/group-add.png"] size:CPSizeMake(16, 16)]];
    [_addGroupButton setTarget:self];
    [_addGroupButton setAction:@selector(openNewGroupWindow:)];
    [_addGroupButton setToolTip:CPBundleLocalizedString(@"Create a new shared group", @"Create a new shared group")];

    _deleteGroupButton = [CPButtonBar plusButton];
    [_deleteGroupButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/group-remove.png"] size:CPSizeMake(16, 16)]];
    [_deleteGroupButton setTarget:self];
    [_deleteGroupButton setAction:@selector(deleteGroup:)];
    [_deleteGroupButton setToolTip:CPBundleLocalizedString(@"Delete selected shared group", @"Delete selected shared group")];
    [buttonBarGroups setButtons:[_addGroupButton, _deleteGroupButton]];

    /* table users in group */
    _datasourceUsersInGroup  = [[TNTableViewDataSource alloc] init];
    [_datasourceUsersInGroup setTable:tableUsersInGroup];
    [_datasourceUsersInGroup setSearchableKeyPaths:[@"jid"]];
    [tableUsersInGroup setDataSource:_datasourceUsersInGroup];
    [filterFieldUsersInGroup setTarget:_datasourceUsersInGroup];
    [filterFieldUsersInGroup setAction:@selector(filterObjects:)];

    _addUserInGroupButton = [CPButtonBar plusButton];
    [_addUserInGroupButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/user-add.png"] size:CPSizeMake(16, 16)]];
    [_addUserInGroupButton setTarget:self];
    [_addUserInGroupButton setAction:@selector(openAddUserInGroupWindow:)];
    [_addUserInGroupButton setToolTip:CPBundleLocalizedString(@"Add users into selected shared group", @"Add users into selected shared group")];

    _deleteUserFromGroupButton = [CPButtonBar plusButton];
    [_deleteUserFromGroupButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/user-remove.png"] size:CPSizeMake(16, 16)]];
    [_deleteUserFromGroupButton setTarget:self];
    [_deleteUserFromGroupButton setAction:@selector(removeUsersFromGroup:)];
    [_deleteUserFromGroupButton setToolTip:CPBundleLocalizedString(@"Remove users from selected shared group", @"Remove users from selected shared group")];
    [buttonBarUsersInGroups setButtons:[_addUserInGroupButton, _deleteUserFromGroupButton]];
}


#pragma mark -
#pragma mark Utilities

/*! called when permissions has changed
*/
- (void)permissionsChanged
{
    [_delegate setControl:_addGroupButton enabledAccordingToPermissions:[@"xmppserver_groups_list", @"xmppserver_groups_create"]];
    [_delegate setControl:_deleteGroupButton enabledAccordingToPermissions:[@"xmppserver_groups_list", @"xmppserver_groups_delete"]];
    [_delegate setControl:_addUserInGroupButton enabledAccordingToPermissions:[@"xmppserver_users_list", @"xmppserver_groups_list", @"xmppserver_groups_addusers"]];
    [_delegate setControl:_deleteUserFromGroupButton enabledAccordingToPermissions:[@"xmppserver_groups_list", @"xmppserver_groups_deleteusers"]];

    if (![_delegate currentEntityHasPermissions:[@"xmppserver_users_list", @"xmppserver_groups_list", @"xmppserver_groups_addusers"]])
        [windowAddUserInGroup close];

    if (![_delegate currentEntityHasPermissions:[@"xmppserver_groups_list", @"xmppserver_groups_create"]])
        [windowNewGroup close];

    [self reload];
}


/*! reload the controller
*/
- (void)reload
{
    [self getSharedGroupsInfo];
}


#pragma mark -
#pragma mark Actions

/*! open the new group window
    @param aSender the sender of the action
*/
- (IBAction)openNewGroupWindow:(id)aSender
{
    [fieldNewGroupName setStringValue:@""];
    [fieldNewGroupDescription setStringValue:@""];

    [windowNewGroup center];
    [windowNewGroup makeKeyAndOrderFront:aSender];
}

/*! open the add user in group window
    @param aSender the sender of the action
*/
- (IBAction)openAddUserInGroupWindow:(id)aSender
{
    [_datasourceUsers setContent:[[_usersController users] copy]];

    [windowAddUserInGroup center];
    [windowAddUserInGroup makeKeyAndOrderFront:aSender];

    [tableUsers reloadData];
    [tableUsers deselectAll];

    // fuck yea.
    var frame = [windowAddUserInGroup frame];
    frame.size.height++;
    [windowAddUserInGroup setFrame:frame];
    frame.size.height--;
    [windowAddUserInGroup setFrame:frame];
}

/*! create a new group
    @param aSender the sender of the action
*/
- (IBAction)createGroup:(id)aSender
{
    if ([[fieldNewGroupName stringValue] length] < 3)
    {
        [TNAlert showAlertWithMessage:CPBundleLocalizedString(@"Wrong name", @"Wrong name")
                          informative:CPBundleLocalizedString(@"You must enter a name containing at least 4 characters", @"You must enter a name containing at least 4 characters")];
        return;
    }

    [windowNewGroup close];
    [self createGroup:[fieldNewGroupName stringValue] description:[fieldNewGroupDescription stringValue]];
}

/*! create a new group
    @param aSender the sender of the action
*/
- (IBAction)deleteGroup:(id)aSender
{
    if (!_currentSelectedGroup)
    {
        [TNAlert showAlertWithMessage:CPBundleLocalizedString(@"Wrong group", @"Wrong group")
                          informative:CPBundleLocalizedString(@"You must select a group", @"You must select a group")];
        return;
    }

    [self deleteGroupWithID:[_currentSelectedGroup objectForKey:@"id"]];
}

/*! add selected users into selected group
    @param aSender the sender of the action
*/
- (IBAction)addUsersInGroup:(id)aSender
{
    var indexes = [tableUsers selectedRowIndexes],
        rows    = [_datasourceUsers objectsAtIndexes:indexes];

    [self addUsers:rows inGroup:[_currentSelectedGroup objectForKey:@"id"]];

    [windowAddUserInGroup close];
}

/*! remove selected users from selected group
    @param aSender the sender of the action
*/
- (IBAction)removeUsersFromGroup:(id)aSender
{
    if ([tableUsersInGroup numberOfSelectedRows] < 1)
    {
        [TNAlert showAlertWithMessage:CPBundleLocalizedString(@"Wrong users", @"Wrong users")
                          informative:CPBundleLocalizedString(@"You must select at least one user", @"You must select at least one user")];
        return;
    }

    var indexes = [tableUsersInGroup selectedRowIndexes],
        rows    = [_datasourceUsersInGroup objectsAtIndexes:indexes];

    [self removeUsers:rows fromGroup:[_currentSelectedGroup objectForKey:@"id"]];
}


#pragma mark -
#pragma mark XMPP Management

/*! Ask server for all shared groups
*/
- (void)getSharedGroupsInfo
{
    if (![[TNPermissionsCenter defaultCenter] hasPermission:@"xmppserver_groups_list" forEntity:_entity])
    {
        [_datasourceGroups removeAllObjects];
        [_datasourceUsersInGroup removeAllObjects];
        [tableGroups reloadData];
        [tableUsersInGroup reloadData];
        return;
    }

    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeXMPPServerGroups}];
    [stanza addChildWithName:@"archipel" andAttributes:{"action": TNArchipelTypeXMPPServerGroupsList}];

    [_entity sendStanza:stanza andRegisterSelector:@selector(_didGetSharedGroupsInfo:) ofObject:self];
}

/*! compute the answer of groups info
    @param aStanza TNStropheStanza containing the answer
*/
- (void)_didGetSharedGroupsInfo:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        var groups = [aStanza childrenWithName:@"group"];

        _oldSelectedIndexesForGroupTable = [tableGroups selectedRowIndexes];

        [_datasourceGroups removeAllObjects];
        [_datasourceUsersInGroup removeAllObjects];

        for (var i = 0; i < [groups count]; i++)
        {
            var group       = [groups objectAtIndex:i],
                gid         = [group valueForAttribute:@"id"],
                name        = [group valueForAttribute:@"displayed_name"],
                desc        = [group valueForAttribute:@"description"],
                users       = [group childrenWithName:@"user"],
                newItem     = [CPDictionary dictionaryWithObjects:[gid, name, desc, users] forKeys:[@"id", @"name", @"description", @"users"]];
            [_datasourceGroups addObject:newItem];
        }

        [tableGroups reloadData];
        [tableUsersInGroup reloadData];

        [tableGroups selectRowIndexes:_oldSelectedIndexesForGroupTable byExtendingSelection:NO];
        [self tableViewSelectionDidChange:[CPNotification notificationWithName:@"" object:tableGroups]];
    }
    else
        [_delegate handleIqErrorFromStanza:aStanza];
}

/*! ask the server to create a shared group
    @param aName the name of the group
    @param aDescription the description of the group
*/
- (void)createGroup:(CPString)aName description:(CPString)aDescription
{
    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeXMPPServerGroups}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeXMPPServerGroupsCreate,
        "id": [CPString UUID],
        "name": aName,
        "description": aDescription}];

    [_entity sendStanza:stanza andRegisterSelector:@selector(_didCreateGroup:) ofObject:self];
}

/*! compute the answer of group creation
    @param aStanza TNStropheStanza containing the answer
*/
- (void)_didCreateGroup:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
        [self reload]
    else
        [_delegate handleIqErrorFromStanza:aStanza];
}

/*! ask the server to delete a group
    @param aGroupId the id of the group
*/
- (void)deleteGroupWithID:(CPString)aGroupId
{
    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeXMPPServerGroups}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeXMPPServerGroupsDelete,
        "id": aGroupId}];

    [_entity sendStanza:stanza andRegisterSelector:@selector(_didRemoveGroup:) ofObject:self];
}

/*! compute the answer of group deleting
    @param aStanza TNStropheStanza containing the answer
*/
- (void)_didRemoveGroup:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
        [self reload]
    else
        [_delegate handleIqErrorFromStanza:aStanza];
}

/*! ask the server to add some users in group
    @param someJIDs CPArray of users' jid (string representation)
    @aGroupUID CPString representing the group ID
*/
- (void)addUsers:(CPArray)someJIDs inGroup:(CPString)aGroupUID
{
    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeXMPPServerGroups}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeXMPPServerGroupsAddUsers,
        "groupid": aGroupUID}];

    for (var i = 0; i < [someJIDs count]; i++)
    {
        [stanza addChildWithName:@"user" andAttributes:{"jid": [[someJIDs objectAtIndex:i] objectForKey:@"jid"]}];
        [stanza up];
    }

    [_entity sendStanza:stanza andRegisterSelector:@selector(_didAddUsersInGroup:) ofObject:self];
}

/*! compute the answer of users adding
    @param aStanza TNStropheStanza containing the answer
*/
- (void)_didAddUsersInGroup:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
        [self reload];
    else
        [_delegate handleIqErrorFromStanza:aStanza];
}

/*! ask the server to remove some users from group
    @param someJIDs CPArray of users' jid (string representation)
    @aGroupUID CPString representing the group ID
*/
- (void)removeUsers:(CPArray)someJIDs fromGroup:(CPString)aGroupUID
{
    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeXMPPServerGroups}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeXMPPServerGroupsDeleteUsers,
        "groupid": aGroupUID}];

    for (var i = 0; i < [someJIDs count]; i++)
    {
        [stanza addChildWithName:@"user" andAttributes:{"jid": [[someJIDs objectAtIndex:i] objectForKey:@"jid"]}];
        [stanza up];
    }

    [_entity sendStanza:stanza andRegisterSelector:@selector(_didRemoveUsersFromGroup:) ofObject:self];
}

/*! compute the answer of users removing
    @param aStanza TNStropheStanza containing the answer
*/
- (void)_didRemoveUsersFromGroup:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        [self reload];
    }
    else
        [_delegate handleIqErrorFromStanza:aStanza];
}


#pragma mark -
#pragma mark Delegates

/*! delegate of CPTableView
*/
- (void)tableViewSelectionDidChange:(CPNotification)aNotification
{
    var table = [aNotification object];

    if (table === tableGroups)
    {
        if ([tableGroups numberOfSelectedRows] != 1)
        {
            _currentSelectedGroup = nil;
            [_datasourceUsersInGroup removeAllObjects];
            [tableUsersInGroup reloadData];

            return;
        }

        var index   = [[tableGroups selectedRowIndexes] firstIndex],
            group   = [_datasourceGroups objectAtIndex:index],
            users   = [group objectForKey:@"users"];

        _currentSelectedGroup = group;

        [_datasourceUsersInGroup removeAllObjects];
        for (var i = 0; i < [users count]; i++)
        {
            var user    = [users objectAtIndex:i],
                newItem = [CPDictionary dictionaryWithObjects:[[user valueForAttribute:@"jid"]] forKeys:[@"jid"]];
            [_datasourceUsersInGroup addObject:newItem];
        }
        [tableUsersInGroup reloadData];
    }
}

@end

// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNXMPPSharedGroupsController], comment);
}
