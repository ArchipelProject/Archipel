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


var TNArchipelTypeXMPPServerGroups               = @"archipel:xmppserver:groups",
    TNArchipelTypeXMPPServerGroupsCreate         = @"create",
    TNArchipelTypeXMPPServerGroupsDelete         = @"delete",
    TNArchipelTypeXMPPServerGroupsAddUsers       = @"addusers",
    TNArchipelTypeXMPPServerGroupsDeleteUsers    = @"deleteusers",
    TNArchipelTypeXMPPServerGroupsList           = @"list";

var TNModuleControlForAddSharedGroup             = @"AddSharedGroup",
    TNModuleControlForRemoveSharedGroup          = @"RemoveSharedGroup",
    TNModuleControlForAddUsersInSharedGroup      = @"AddUsersInSharedGroup",
    TNModuleControlForRemoveUsersFromSharedGroup = @"RemoveUsersFromSharedGroup";

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
    CPMenuItem                  _contextualMenu             @accessors(property=contextualMenu);


    TNStropheContact            _entity;
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
    [_datasourceUsers setSearchableKeyPaths:[@"name", @"JID"]];
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

    /* table users in group */
    _datasourceUsersInGroup  = [[TNTableViewDataSource alloc] init];
    [_datasourceUsersInGroup setTable:tableUsersInGroup];
    [_datasourceUsersInGroup setSearchableKeyPaths:[@"name", @"JID"]];
    [tableUsersInGroup setDataSource:_datasourceUsersInGroup];
    [tableUsersInGroup setDelegate:self];

    [filterFieldGroups setTarget:_datasourceGroups];
    [filterFieldGroups setAction:@selector(filterObjects:)];

    [filterFieldUsersInGroup setTarget:_datasourceUsersInGroup];
    [filterFieldUsersInGroup setAction:@selector(filterObjects:)];

    [filterFieldUsers setSendsSearchStringImmediately:YES];
    [filterFieldUsers setTarget:_datasourceUsers];
    [filterFieldUsers setAction:@selector(filterObjects:)];

    var filterBg = CPImageInBundle(@"Backgrounds/background-filter.png", nil, [CPBundle mainBundle]);
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

/*! populateViewWithControls - Add controls (buttonbarbuttons and contextual menu item) to the current controller.
*/
- (void)populateViewWithControls
{
    [_delegate addControlsWithIdentifier:TNModuleControlForAddSharedGroup
                          title:CPBundleLocalizedString(@"Create a new shared group", @"Create a new shared group")
                         target:self
                         action:@selector(openNewGroupWindow:)
                          image:CPImageInBundle(@"IconsButtons/group-add.png",nil, [CPBundle mainBundle])];

    [_delegate addControlsWithIdentifier:TNModuleControlForRemoveSharedGroup
                          title:CPBundleLocalizedString(@"Delete selected shared group", @"Delete selected shared group")
                         target:self
                         action:@selector(deleteGroup:)
                          image:CPImageInBundle(@"IconsButtons/group-remove.png",nil, [CPBundle mainBundle])];

    [_delegate addControlsWithIdentifier:TNModuleControlForAddUsersInSharedGroup
                          title:CPBundleLocalizedString(@"Add user(s) to shared group", @"Add user(s) to shared group")
                         target:self
                         action:@selector(openAddUserInGroupWindow:)
                          image:CPImageInBundle(@"IconsButtons/user-add.png",nil, [CPBundle mainBundle])];

    [_delegate addControlsWithIdentifier:TNModuleControlForRemoveUsersFromSharedGroup
                          title:CPBundleLocalizedString(@"Remove selected user(s) from shared group", @"Remove selected user(s) from shared group")
                         target:self
                         action:@selector(removeUsersFromGroup:)
                          image:CPImageInBundle(@"IconsButtons/user-remove.png",nil, [CPBundle mainBundle])];

    [buttonBarGroups setButtons:[
        [_delegate buttonWithIdentifier:TNModuleControlForAddSharedGroup],
        [_delegate buttonWithIdentifier:TNModuleControlForRemoveSharedGroup]]];

    [buttonBarUsersInGroups setButtons:[
        [_delegate buttonWithIdentifier:TNModuleControlForAddUsersInSharedGroup],
        [_delegate buttonWithIdentifier:TNModuleControlForRemoveUsersFromSharedGroup]]];
}

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

    [_delegate setControl:[_delegate buttonWithIdentifier:TNModuleControlForAddSharedGroup] enabledAccordingToPermissions:[@"xmppserver_groups_list", @"xmppserver_groups_create"]];
    [_delegate setControl:[_delegate buttonWithIdentifier:TNModuleControlForRemoveSharedGroup] enabledAccordingToPermissions:[@"xmppserver_groups_list", @"xmppserver_groups_delete"] specialCondition:condition1];

    [_delegate setControl:[_delegate buttonWithIdentifier:TNModuleControlForAddUsersInSharedGroup] enabledAccordingToPermissions:[@"xmppserver_users_list", @"xmppserver_groups_list", @"xmppserver_groups_addusers"] specialCondition:condition1];
    [_delegate setControl:[_delegate buttonWithIdentifier:TNModuleControlForRemoveUsersFromSharedGroup] enabledAccordingToPermissions:[@"xmppserver_groups_list", @"xmppserver_groups_deleteusers"] specialCondition:condition2];

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

    if ([aSender isKindOfClass:CPMenuItem])
    {
        var rect = [tableGroups rectOfRow:[tableGroups selectedRow]];
        rect.origin.y += rect.size.height / 2;
        rect.origin.x += rect.size.width / 2;
        [popoverNewGroup showRelativeToRect:CGRectMake(rect.origin.x, rect.origin.y, 10, 10) ofView:tableGroups preferredEdge:nil];
    }
    else
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

    if ([aSender isKindOfClass:CPMenuItem])
    {
        var rect = [tableUsersInGroup rectOfRow:[tableUsersInGroup selectedRow]];
        rect.origin.y += rect.size.height / 2;
        rect.origin.x += rect.size.width / 2;
        [popoverAddUserInGroup showRelativeToRect:CGRectMake(rect.origin.x, rect.origin.y, 10, 10) ofView:tableUsersInGroup preferredEdge:nil];
    }
    else
        [popoverAddUserInGroup showRelativeToRect:nil ofView:aSender preferredEdge:nil];

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
                newItem     = @{@"id":gid, @"name":name, @"description":desc, @"users":users};
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
        [stanza addChildWithName:@"user" andAttributes:{"jid": [[someJIDs objectAtIndex:i] objectForKey:@"JID"]}];
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
        [stanza addChildWithName:@"user" andAttributes:{"jid": [[someJIDs objectAtIndex:i] objectForKey:@"JID"]}];
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
                    newItem = @{@"JID":[user valueForAttribute:@"jid"]};
                [_datasourceUsersInGroup addObject:newItem];
            }
            [tableUsersInGroup reloadData];
        }
    }

    [self setUIAccordingToPermissions];
}

/*! Delegate of CPTableView - This will be called when context menu is triggered with right click
*/
- (CPMenu)tableView:(CPTableView)aTableView menuForTableColumn:(CPTableColumn)aColumn row:(int)aRow
{

    var itemRow = [aTableView rowAtPoint:aRow];
    if ([aTableView selectedRow] != aRow)
        [aTableView selectRowIndexes:[CPIndexSet indexSetWithIndex:aRow] byExtendingSelection:NO];

    [_contextualMenu removeAllItems];

    switch (aTableView)
    {
        case tableUsersInGroup:
            if ([aTableView numberOfSelectedRows] == 0)
            {
                [_contextualMenu addItem:[_delegate menuItemWithIdentifier:TNModuleControlForAddUsersInSharedGroup]];
            }
            else
            {
                [_contextualMenu addItem:[_delegate menuItemWithIdentifier:TNModuleControlForRemoveUsersFromSharedGroup]];
            }
            break;

        case tableGroups:
            if ([aTableView numberOfSelectedRows] == 0)
            {
                [_contextualMenu addItem:[_delegate menuItemWithIdentifier:TNModuleControlForAddSharedGroup]];
            }
            else
            {
                [_contextualMenu addItem:[_delegate menuItemWithIdentifier:TNModuleControlForRemoveSharedGroup]];
            }
            break;
    }

    return _contextualMenu;
}

/* Delegate of CPTableView - this will be triggered on delete key events
*/
- (void)tableViewDeleteKeyPressed:(CPTableView)aTableView
{
  if ([aTableView numberOfSelectedRows] == 0)
      return;

  switch (aTableView)
  {
    case tableUsersInGroup:
        [self removeUsersFromGroup];
        break;

    case tableGroups:
        [self RemoveSharedGroup];
        break;
  }
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
