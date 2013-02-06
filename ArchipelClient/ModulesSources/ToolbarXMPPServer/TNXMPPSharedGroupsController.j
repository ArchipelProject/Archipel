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
@import <TNKit/TNTableViewLazyDataSource.j>

@import "TNXMPPServerUserFetcher.j"

@class TNPermissionsCenter
@global CPLocalizedString
@global CPLocalizedStringFromTableInBundle


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
    @outlet CPButton            buttonAdd;
    @outlet CPButton            buttonCreate;
    @outlet CPButtonBar         buttonBarGroups;
    @outlet CPButtonBar         buttonBarUsersInGroups;
    @outlet CPPopover           popoverAddUserInGroup;
    @outlet CPPopover           popoverNewGroup;
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

    id                          _delegate                   @accessors(property=delegate);
    TNXMPPUsersController       _usersController            @accessors(setter=setUsersController:);

    TNStropheContact            _entity;
    CPButton                    _addGroupButton;
    CPButton                    _addUserInGroupButton;
    CPButton                    _deleteGroupButton;
    CPButton                    _deleteUserFromGroupButton;
    id                          _currentSelectedGroup;
    int                         _oldSelectedIndexesForGroupTable;
    TNTableViewDataSource       _datasourceGroups;
    TNTableViewDataSource       _datasourceUsers;
    TNTableViewDataSource       _datasourceUsersInGroup;
    TNXMPPServerUserFetcher     _usersFetcher;
}

#pragma mark -
#pragma mark Initialization

/*! called at cib awakening
*/
- (void)awakeFromCib
{
    // [viewTableGroupsContainer setBorderedWithHexColor:@"#C0C7D2"];
    // [viewTableUsersInGroupContainer setBorderedWithHexColor:@"#C0C7D2"];
    [splitViewVertical setBorderedWithHexColor:@"#C0C7D2"];
    [splitViewVertical setIsPaneSplitter:YES];

    /* table Users */
    _datasourceUsers  = [[TNTableViewLazyDataSource alloc] init];
    [_datasourceUsers setTable:tableUsers];
    [_datasourceUsers setSearchableKeyPaths:[@"name", @"jid"]];
    [tableUsers setDataSource:_datasourceUsers];

    // user fetcher
    _usersFetcher = [[TNXMPPServerUserFetcher alloc] init];
    [_usersFetcher setDataSource:_datasourceUsers];
    [_usersFetcher setDelegate:self];
    [_usersFetcher setDisplaysOnlyHumans:NO];

    /* table Groups */
    _datasourceGroups   = [[TNTableViewDataSource alloc] init];
    [_datasourceGroups setTable:tableGroups];
    [_datasourceGroups setSearchableKeyPaths:[@"name", @"description"]];
    [tableGroups setDataSource:_datasourceGroups];
    [tableGroups setDelegate:self];

    _addGroupButton = [CPButtonBar plusButton];
    [_addGroupButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/group-add.png"] size:CGSizeMake(16, 16)]];
    [_addGroupButton setTarget:self];
    [_addGroupButton setAction:@selector(openNewGroupWindow:)];
    [_addGroupButton setToolTip:CPBundleLocalizedString(@"Add a new shared group", @"Add a new shared group")];

    _deleteGroupButton = [CPButtonBar plusButton];
    [_deleteGroupButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/group-remove.png"] size:CGSizeMake(16, 16)]];
    [_deleteGroupButton setTarget:self];
    [_deleteGroupButton setAction:@selector(deleteGroup:)];
    [_deleteGroupButton setToolTip:CPBundleLocalizedString(@"Delete selected shared groups", @"Delete selected shared groups")];

    [buttonBarGroups setButtons:[_addGroupButton, _deleteGroupButton]];

    /* table users in group */
    _datasourceUsersInGroup  = [[TNTableViewDataSource alloc] init];
    [_datasourceUsersInGroup setTable:tableUsersInGroup];
    [_datasourceUsersInGroup setSearchableKeyPaths:[@"jid"]];
    [tableUsersInGroup setDataSource:_datasourceUsersInGroup];
    [tableUsersInGroup setDelegate:self];

    _addUserInGroupButton = [CPButtonBar plusButton];
    [_addUserInGroupButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/user-add.png"] size:CGSizeMake(16, 16)]];
    [_addUserInGroupButton setTarget:self];
    [_addUserInGroupButton setAction:@selector(openAddUserInGroupWindow:)];
    [_addUserInGroupButton setToolTip:CPBundleLocalizedString(@"Add selected users to shared group", @"Add selected users to shared group")];

    _deleteUserFromGroupButton = [CPButtonBar plusButton];
    [_deleteUserFromGroupButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/user-remove.png"] size:CGSizeMake(16, 16)]];
    [_deleteUserFromGroupButton setTarget:self];
    [_deleteUserFromGroupButton setAction:@selector(removeUsersFromGroup:)];
    [_deleteUserFromGroupButton setToolTip:CPBundleLocalizedString(@"Remove selected users from shared group", @"Remove selected users from shared group")];

    [buttonBarUsersInGroups setButtons:[_addUserInGroupButton, _deleteUserFromGroupButton]];

    [filterFieldGroups setTarget:_datasourceGroups];
    [filterFieldGroups setAction:@selector(filterObjects:)];

    [filterFieldUsersInGroup setTarget:_datasourceUsersInGroup];
    [filterFieldUsersInGroup setAction:@selector(filterObjects:)];

    [filterFieldUsers setSendsSearchStringImmediately:YES];
    [filterFieldUsers setTarget:_datasourceUsers];
    [filterFieldUsers setAction:@selector(filterObjects:)];


    var filterBg = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"Backgrounds/background-filter.png"]];
    [[viewTableGroupsContainer superview] setBackgroundColor:[CPColor colorWithPatternImage:filterBg]];
    [[viewTableUsersInGroupContainer superview] setBackgroundColor:[CPColor colorWithPatternImage:filterBg]];
}


#pragma mark -
#pragma mark Getters / Setters

- (void)setEntity:(TNStropheContact)anEntity
{
    _entity = anEntity;
    [_usersFetcher setEntity:_entity];
}


#pragma mark -
#pragma mark Utilities

/*! clean stuff when hidden
*/
- (void)willHide
{
    [self closeNewGroupWindow:nil];
    [self closeAddUserInGroupWindow:nil];

    [_usersFetcher reset];
}

/*! called when permissions has changed
*/
- (void)permissionsChanged
{
    [self reload];
}

/*! set the UI according to the permissions
*/
- (void)setUIAccordingToPermissions
{
    var condition1 = ([tableGroups numberOfSelectedRows] > 0),
        condition2 = condition1 && ([tableUsersInGroup numberOfSelectedRows] > 0);

    [_delegate setControl:_addGroupButton enabledAccordingToPermissions:[@"xmppserver_groups_list", @"xmppserver_groups_create"]];
    [_delegate setControl:_deleteGroupButton enabledAccordingToPermissions:[@"xmppserver_groups_list", @"xmppserver_groups_delete"] specialCondition:condition1];

    [_delegate setControl:_addUserInGroupButton enabledAccordingToPermissions:[@"xmppserver_users_list", @"xmppserver_groups_list", @"xmppserver_groups_addusers"] specialCondition:condition1];
    [_delegate setControl:_deleteUserFromGroupButton enabledAccordingToPermissions:[@"xmppserver_groups_list", @"xmppserver_groups_deleteusers"] specialCondition:condition2];

    if (![_delegate currentEntityHasPermissions:[@"xmppserver_users_list", @"xmppserver_groups_list", @"xmppserver_groups_addusers"]])
        [popoverAddUserInGroup close];

    if (![_delegate currentEntityHasPermissions:[@"xmppserver_groups_list", @"xmppserver_groups_create"]])
        [popoverNewGroup close];
}

/*! reload the controller
*/
- (void)reload
{
    if ([_datasourceUsers isCurrentlyLoading])
        return;

    [self getSharedGroupsInfo];
}

/*! this message is used to flush the UI
*/
- (void)flushUI
{
    [_datasourceGroups removeAllObjects];
    [_datasourceUsers removeAllObjects];
    [_datasourceUsersInGroup removeAllObjects];

    [tableUsers reloadData];
    [tableUsersInGroup reloadData];
    [tableGroups reloadData];
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

    [popoverNewGroup close];
    [popoverNewGroup showRelativeToRect:nil ofView:aSender preferredEdge:nil];
    [popoverNewGroup setDefaultButton:buttonCreate];
    [popoverNewGroup makeFirstResponder:fieldNewGroupName];
}

/*! close the new group window
    @param aSender the sender of the action
*/
- (IBAction)closeNewGroupWindow:(id)aSender
{
    [popoverNewGroup close];
}

/*! open the add user in group window
    @param aSender the sender of the action
*/
- (IBAction)openAddUserInGroupWindow:(id)aSender
{
    [_datasourceUsers removeAllObjects];
    [tableUsers reloadData];

    [_usersFetcher reset];
    [_usersFetcher getXMPPUsers];

    [popoverAddUserInGroup close];
    [popoverAddUserInGroup showRelativeToRect:nil ofView:aSender preferredEdge:nil];
    [popoverAddUserInGroup setDefaultButton:buttonAdd];
}

/*! close the add user in group window
    @param aSender the sender of the action
*/
- (IBAction)closeAddUserInGroupWindow:(id)aSender
{
    [popoverAddUserInGroup close];
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

    [popoverNewGroup close];
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

    [popoverAddUserInGroup close];
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
        }
        else
        {
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

    [self setUIAccordingToPermissions];
}

/*! delegate of TNXMPPServerUserFetcher
*/
- (void)userFetcherClean
{
    [_usersFetcher reset];
    [_datasourceUsers removeAllObjects];
    [tableUsers reloadData];
}

@end

// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNXMPPSharedGroupsController], comment);
}
