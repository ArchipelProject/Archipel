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
    @outlet CPView          mainView                    @accessors(getter=mainView);
    @outlet CPWindow        windowNewGroup;
    @outlet CPTextField     fieldNewGroupName;
    @outlet CPTextField     fieldNewGroupDescription;
    @outlet CPView          viewTableGroupsContainer;
    @outlet CPView          viewTableUsersInGroupContainer;
    @outlet CPScrollView    scrollViewUsers;
    @outlet CPScrollView    scrollViewGroups;
    @outlet CPScrollView    scrollViewUsersInGroup;
    @outlet CPButtonBar     buttonBarGroups;
    @outlet CPButtonBar     buttonBarUsersInGroups;
    @outlet CPSearchField   filterFieldUsers;
    @outlet CPSearchField   filterFieldGroups;
    @outlet CPSearchField   filterFieldUsersInGroup;
    @outlet CPPopUpButton   buttonGroups;
    @outlet CPWindow        windowAddUserInGroup;
    @outlet CPSplitView     splitViewVertical;

    TNStropheContact        _entity             @accessors(setter=setEntity:);
    id                      _delegate           @accessors(property=delegate);
    TNXMPPUsersController   _usersController    @accessors(setter=setUsersController:);

    CPTableView             _tableUsers;
    CPTableView             _tableGroups;
    CPTableView             _tableUsersInGroup;
    TNTableViewDataSource   _datasourceUsers;
    TNTableViewDataSource   _datasourceGroups;
    TNTableViewDataSource   _datasourceUsersInGroup;
    CPButton                _addGroupButton;
    CPButton                _deleteGroupButton;
    CPButton                _addUserInGroupButton;
    CPButton                _deleteUserFromGroupButton;
    id                      _currentSelectedGroup;
    int                     _oldSelectedIndexesForGroupTable;
}

#pragma mark -
#pragma mark Initialization

/*! called at cib awakening
*/
- (void)awakeFromCib
{
    /* table Users */
    [splitViewVertical setBorderedWithHexColor:@"#C0C7D2"];
    [splitViewVertical setIsPaneSplitter:YES];

    [scrollViewUsers setBorderedWithHexColor:@"#C0C7D2"];

    _datasourceUsers  = [[TNTableViewDataSource alloc] init];
    _tableUsers       = [[CPTableView alloc] initWithFrame:[scrollViewUsers bounds]];

    [scrollViewUsers setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [scrollViewUsers setAutohidesScrollers:YES];
    [scrollViewUsers setDocumentView:_tableUsers];

    [_tableUsers setUsesAlternatingRowBackgroundColors:YES];
    [_tableUsers setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [_tableUsers setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [_tableUsers setAllowsColumnReordering:YES];
    [_tableUsers setAllowsColumnResizing:YES];
    [_tableUsers setAllowsEmptySelection:YES];
    [_tableUsers setAllowsMultipleSelection:YES];

    var colName     = [[CPTableColumn alloc] initWithIdentifier:@"name"],
        colJID      = [[CPTableColumn alloc] initWithIdentifier:@"jid"],
        colIcon     = [[CPTableColumn alloc] initWithIdentifier:@"icon"],
        iconView    = [[CPImageView alloc] initWithFrame:CGRectMake(0,0,16,16)];

    [colName setWidth:275];
    [[colName headerView] setStringValue:@"Name"];
    [colName setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];

    [colJID setWidth:200];
    [[colJID headerView] setStringValue:@"JID"];
    [colJID setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"jid" ascending:YES]];

    [iconView setImageScaling:CPScaleNone];
    [colIcon setWidth:16];
    [colIcon setDataView:iconView];
    [[colIcon headerView] setStringValue:@""];

    [_tableUsers addTableColumn:colIcon];
    [_tableUsers addTableColumn:colName];
    [_tableUsers addTableColumn:colJID];

    [_datasourceUsers setTable:_tableUsers];
    [_datasourceUsers setSearchableKeyPaths:[@"name", @"jid"]];
    [_tableUsers setDataSource:_datasourceUsers];

    [filterFieldUsers setTarget:_datasourceUsers];
    [filterFieldUsers setAction:@selector(filterObjects:)];


    /* table Groups */

    [viewTableGroupsContainer setBorderedWithHexColor:@"#C0C7D2"];

    _datasourceGroups   = [[TNTableViewDataSource alloc] init];
    _tableGroups        = [[CPTableView alloc] initWithFrame:[scrollViewGroups bounds]];

    [scrollViewGroups setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [scrollViewGroups setAutohidesScrollers:YES];
    [scrollViewGroups setDocumentView:_tableGroups];

    [_tableGroups setUsesAlternatingRowBackgroundColors:YES];
    [_tableGroups setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [_tableGroups setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [_tableGroups setAllowsColumnReordering:YES];
    [_tableGroups setAllowsColumnResizing:YES];
    [_tableGroups setAllowsEmptySelection:YES];
    [_tableGroups setAllowsMultipleSelection:NO];

    var colName = [[CPTableColumn alloc] initWithIdentifier:@"name"],
        colDescription  = [[CPTableColumn alloc] initWithIdentifier:@"description"];

    [colName setWidth:175];
    [[colName headerView] setStringValue:@"Name"];
    [colName setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];

    [colDescription setWidth:450];
    [[colDescription headerView] setStringValue:@"Description"];
    [colDescription setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"description" ascending:YES]];

    [_tableGroups addTableColumn:colName];
    [_tableGroups addTableColumn:colDescription];

    [_datasourceGroups setTable:_tableGroups];
    [_datasourceGroups setSearchableKeyPaths:[@"name", @"description"]];
    [_tableGroups setDataSource:_datasourceGroups];
    [_tableGroups setDelegate:self];

    _addGroupButton = [CPButtonBar plusButton];
    [_addGroupButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/group-add.png"] size:CPSizeMake(16, 16)]];
    [_addGroupButton setTarget:self];
    [_addGroupButton setAction:@selector(openNewGroupWindow:)];
    [_addGroupButton setToolTip:@"Create a new shared group"];

    _deleteGroupButton = [CPButtonBar plusButton];
    [_deleteGroupButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/group-remove.png"] size:CPSizeMake(16, 16)]];
    [_deleteGroupButton setTarget:self];
    [_deleteGroupButton setAction:@selector(deleteGroup:)];
    [_deleteGroupButton setToolTip:@"Delete selected shared group"];

    [buttonBarGroups setButtons:[_addGroupButton, _deleteGroupButton]];

    [filterFieldGroups setTarget:_datasourceGroups];
    [filterFieldGroups setAction:@selector(filterObjects:)];


    /* table users in group */

    [viewTableUsersInGroupContainer setBorderedWithHexColor:@"#C0C7D2"];

    _datasourceUsersInGroup  = [[TNTableViewDataSource alloc] init];
    _tableUsersInGroup       = [[CPTableView alloc] initWithFrame:[scrollViewUsersInGroup bounds]];

    [scrollViewUsersInGroup setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [scrollViewUsersInGroup setAutohidesScrollers:YES];
    [scrollViewUsersInGroup setDocumentView:_tableUsersInGroup];

    [_tableUsersInGroup setUsesAlternatingRowBackgroundColors:YES];
    [_tableUsersInGroup setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [_tableUsersInGroup setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [_tableUsersInGroup setAllowsColumnReordering:YES];
    [_tableUsersInGroup setAllowsColumnResizing:YES];
    [_tableUsersInGroup setAllowsEmptySelection:YES];
    [_tableUsersInGroup setAllowsMultipleSelection:YES];

    var colUserName = [[CPTableColumn alloc] initWithIdentifier:@"jid"];

    [colUserName setWidth:175];
    [[colUserName headerView] setStringValue:@"jid"];
    [colUserName setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"jid" ascending:YES]];

    [_tableUsersInGroup addTableColumn:colUserName];

    [_datasourceUsersInGroup setTable:_tableUsersInGroup];
    [_datasourceUsersInGroup setSearchableKeyPaths:[@"jid"]];
    [_tableUsersInGroup setDataSource:_datasourceUsersInGroup];

    _addUserInGroupButton = [CPButtonBar plusButton];
    [_addUserInGroupButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/user-add.png"] size:CPSizeMake(16, 16)]];
    [_addUserInGroupButton setTarget:self];
    [_addUserInGroupButton setAction:@selector(openAddUserInGroupWindow:)];
    [_addUserInGroupButton setToolTip:@"Add users into selected shared group"];

    _deleteUserFromGroupButton = [CPButtonBar plusButton];
    [_deleteUserFromGroupButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/user-remove.png"] size:CPSizeMake(16, 16)]];
    [_deleteUserFromGroupButton setTarget:self];
    [_deleteUserFromGroupButton setAction:@selector(removeUsersFromGroup:)];
    [_deleteUserFromGroupButton setToolTip:@"Remove users from selected shared group"];

    [buttonBarUsersInGroups setButtons:[_addUserInGroupButton, _deleteUserFromGroupButton]];

    [filterFieldUsersInGroup setTarget:_datasourceUsersInGroup];
    [filterFieldUsersInGroup setAction:@selector(filterObjects:)];
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

    [_tableUsers reloadData];
    [_tableUsers deselectAll];

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
        [TNAlert showAlertWithMessage:@"Wrong name" informative:@"You must enter a name containing at least 4 characters"];
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
        [TNAlert showAlertWithMessage:@"Wrong group" informative:@"You must select a group"];
        return;
    }

    [self deleteGroupWithID:[_currentSelectedGroup objectForKey:@"id"]];
}

/*! add selected users into selected group
    @param aSender the sender of the action
*/
- (IBAction)addUsersInGroup:(id)aSender
{
    var indexes = [_tableUsers selectedRowIndexes],
        rows    = [_datasourceUsers objectsAtIndexes:indexes];

    [self addUsers:rows inGroup:[_currentSelectedGroup objectForKey:@"id"]];

    [windowAddUserInGroup close];
}

/*! remove selected users from selected group
    @param aSender the sender of the action
*/
- (IBAction)removeUsersFromGroup:(id)aSender
{
    if ([_tableUsersInGroup numberOfSelectedRows] < 1)
    {
        [TNAlert showAlertWithMessage:@"Wrong users" informative:@"You must select at least one user"];
        return;
    }

    var indexes = [_tableUsersInGroup selectedRowIndexes],
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
        [_tableGroups reloadData];
        [_tableUsersInGroup reloadData];
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

        _oldSelectedIndexesForGroupTable = [_tableGroups selectedRowIndexes];

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

        [_tableGroups reloadData];
        [_tableUsersInGroup reloadData];

        [_tableGroups selectRowIndexes:_oldSelectedIndexesForGroupTable byExtendingSelection:NO];
        [self tableViewSelectionDidChange:[CPNotification notificationWithName:@"" object:_tableGroups]];
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

    if (table === _tableGroups)
    {
        if ([_tableGroups numberOfSelectedRows] != 1)
        {
            _currentSelectedGroup = nil;
            [_datasourceUsersInGroup removeAllObjects];
            [_tableUsersInGroup reloadData];

            return;
        }

        var index   = [[_tableGroups selectedRowIndexes] firstIndex],
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
        [_tableUsersInGroup reloadData];
    }
}

@end