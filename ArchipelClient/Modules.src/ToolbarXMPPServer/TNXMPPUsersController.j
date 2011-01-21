/*
 * TNXMPPUsersController.j
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


var TNArchipelTypeXMPPServerUsers               = @"archipel:xmppserver:users",
    TNArchipelTypeXMPPServerUsersRegister       = @"register",
    TNArchipelTypeXMPPServerUsersUnregister     = @"unregister",
    TNArchipelTypeXMPPServerUsersList           = @"list";

/*! @ingroup toolbarxmppserver
    XMPP user controller implementation
*/
@implementation TNXMPPUsersController : CPObject
{
    @outlet CPButtonBar     buttonBarControl;
    @outlet CPScrollView    scrollViewUsers;
    @outlet CPSearchField   filterField;
    @outlet CPTextField     fieldNewUserPassword;
    @outlet CPTextField     fieldNewUserPasswordConfirm;
    @outlet CPTextField     fieldNewUserUsername;
    @outlet CPView          mainView        @accessors(getter=mainView);
    @outlet CPView          viewTableContainer;
    @outlet CPWindow        windowNewUser;

    TNStropheContact        _entity             @accessors(setter=setEntity:);
    TNTableViewDataSource   _datasourceUsers    @accessors(getter=datasource);
    id                      _delegate           @accessors(property=delegate);

    CPTableView             _tableUsers;
    CPButton                _addButton;
    CPButton                _deleteButton;
}

#pragma mark -
#pragma mark Initialization

- (void)awakeFromCib
{
    [viewTableContainer setBorderedWithHexColor:@"#C0C7D2"];

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


    var colName = [[CPTableColumn alloc] initWithIdentifier:@"name"],
        colJID  = [[CPTableColumn alloc] initWithIdentifier:@"jid"];

    [colName setWidth:325];
    [[colName headerView] setStringValue:@"Name"];
    [colName setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];

    [colJID setWidth:450];
    [[colJID headerView] setStringValue:@"JID"];
    [colJID setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"jid" ascending:YES]];

    [_tableUsers addTableColumn:colName];
    [_tableUsers addTableColumn:colJID];

    [_datasourceUsers setTable:_tableUsers];
    [_datasourceUsers setSearchableKeyPaths:[@"name", @"jid"]];
    [_tableUsers setDataSource:_datasourceUsers];

    _addButton = [CPButtonBar plusButton];
    [_addButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/user-add.png"] size:CPSizeMake(16, 16)]];
    [_addButton setTarget:self];
    [_addButton setAction:@selector(openRegisterUserWindow:)];

    _deleteButton = [CPButtonBar plusButton];
    [_deleteButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/user-remove.png"] size:CPSizeMake(16, 16)]];
    [_deleteButton setTarget:self];
    [_deleteButton setAction:@selector(unregisterUser:)];

    [buttonBarControl setButtons:[_addButton, _deleteButton]];

    [filterField setTarget:_datasourceUsers];
    [filterField setAction:@selector(filterObjects:)];

    [fieldNewUserPassword setSecure:YES];
    [fieldNewUserPasswordConfirm setSecure:YES];
}


#pragma mark -
#pragma mark Utilities

/*! called when permissions has changed
*/
- (void)permissionsChanged
{
    [_delegate setControl:_addButton enabledAccordingToPermissions:[@"xmppserver_users_list", @"xmppserver_users_register"]];
    [_delegate setControl:_deleteButton enabledAccordingToPermissions:[@"xmppserver_users_list", @"xmppserver_users_unregister"]];

    if (![_delegate currentEntityHasPermissions:[@"xmppserver_users_list", @"xmppserver_users_register"]])
        [windowNewUser close];

    [self reload];
}

/*! reload the display of the module
*/
- (void)reload
{
    [self getXMPPUsers];
}


#pragma mark -
#pragma mark Actions

/*! open the new user window
    @param aSender the sender of the action
*/
- (IBAction)openRegisterUserWindow:(id)aSender
{
    [fieldNewUserUsername setStringValue:@""];
    [fieldNewUserPassword setStringValue:@""];
    [fieldNewUserPasswordConfirm setStringValue:@""];

    [windowNewUser center];
    [windowNewUser makeKeyAndOrderFront:aSender];
}

/*! create a new user
    @param aSender the sender of the action
*/
- (IBAction)registerUser:(id)aSender
{
    if ([fieldNewUserPassword stringValue] != [fieldNewUserPasswordConfirm stringValue])
    {
        [TNAlert showAlertWithMessage:@"Password doesn't match" informative:@"You have to enter identical passwords"];
        return;
    }

    if ([[fieldNewUserPassword stringValue] length] < 8)
    {
        [TNAlert showAlertWithMessage:@"Bad password" informative:@"The password is too short. it must be at least 8 characters"];
        return;
    }

    [windowNewUser close];
    [self registerUserWithName:[fieldNewUserUsername stringValue] password:[fieldNewUserPassword stringValue]];
}

/*! create a new user
    @param aSender the sender of the action
*/
- (IBAction)unregisterUser:(id)aSender
{
    if ([_tableUsers numberOfSelectedRows] < 1)
    {
        [TNAlert showAlertWithMessage:@"You must select one user" informative:@""];
        return;
    }

    var indexes     = [_tableUsers selectedRowIndexes],
        users       = [_datasourceUsers objectsAtIndexes:indexes],
        usernames   = [CPArray array];

    for (var i = 0; i < [users count]; i ++)
    {
        var user = [users objectAtIndex:i];
        [usernames addObject:[[user objectForKey:@"jid"] node]];
    }

    var thealert = [TNAlert alertWithMessage:@"Unregister"
                                informative:@"Are you sure you want to unregister selected user(s) ?"
                                 target:self
                                 actions:[["Confirm", @selector(unregisterUserWithNames:)], ["Cancel", nil]]];

    [thealert setUserInfo:usernames];
    [thealert runModal];
}


#pragma mark -
#pragma mark XMPP Management

/*! ask for permissions of given user
*/
- (void)getXMPPUsers
{
    if (![[TNPermissionsCenter defaultCenter] hasPermission:@"xmppserver_users_list" forEntity:_entity])
    {
        [_datasourceUsers removeAllObjects];
        [_tableUsers reloadData];
        return;
    }

    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeXMPPServerUsers}];
    [stanza addChildWithName:@"archipel" andAttributes:{"action": TNArchipelTypeXMPPServerUsersList}];

    [_entity sendStanza:stanza andRegisterSelector:@selector(_didGetXMPPUsers:) ofObject:self];
}

/*! compute the answer containing the user' permissions
    @param aStanza TNStropheStanza containing the answer
*/
- (void)_didGetXMPPUsers:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        var users = [aStanza childrenWithName:@"user"];

        [_datasourceUsers removeAllObjects];

        for (var i = 0; i < [users count]; i++)
        {
            var user     = [users objectAtIndex:i],
                jid     = [TNStropheJID stropheJIDWithString:[user valueForAttribute:@"jid"]],
                name    = [jid node],
                contact = [[[TNStropheIMClient defaultClient] roster] contactWithJID:jid],
                newItem;

            if (contact)
                name = [contact nickname];

            newItem = [CPDictionary dictionaryWithObjects:[name, jid] forKeys:[@"name", @"jid"]]
            [_datasourceUsers addObject:newItem];
        }

        [_tableUsers reloadData];
    }
    else
    {
        [_delegate handleIqErrorFromStanza:aStanza];
    }
}

/*! create a new user with given username and password
    @param aUserName the username of the new user
    @param aPasswor the password of the new user
*/
- (void)registerUserWithName:(CPString)aUserName password:(CPString)aPassword
{
    var stanza = [TNStropheStanza iqWithType:@"set"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeXMPPServerUsers}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeXMPPServerUsersRegister}];

    [stanza addChildWithName:@"user" andAttributes:{"username": aUserName, "password": aPassword}];

    [_entity sendStanza:stanza andRegisterSelector:@selector(_didRegisterUser:) ofObject:self];
}

/*! compute the answer of user creation
    @param aStanza TNStropheStanza containing the answer
*/
- (void)_didRegisterUser:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
        [self reload]
    else
        [_delegate handleIqErrorFromStanza:aStanza];
}

/*! unregister a new user with given username and password
    @param aUserName the username of the user
*/
- (void)unregisterUserWithNames:(CPArray)someUserNames
{
    var stanza = [TNStropheStanza iqWithType:@"set"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeXMPPServerUsers}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeXMPPServerUsersUnregister}];

    for (var i = 0; i < [someUserNames count]; i++)
    {
        var username = [someUserNames objectAtIndex:i];
        [stanza addChildWithName:@"user" andAttributes:{"username": username}];
        [stanza up];
    }

    [_entity sendStanza:stanza andRegisterSelector:@selector(_didUnregisterUsers:) ofObject:self];
}

/*! compute the answer of user creation
    @param aStanza TNStropheStanza containing the answer
*/
- (void)_didUnregisterUsers:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
        [self reload]
    else
        [_delegate handleIqErrorFromStanza:aStanza];
}

@end