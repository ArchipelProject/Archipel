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

@import <AppKit/CPButton.j>
@import <AppKit/CPButtonBar.j>
@import <AppKit/CPImage.j>
@import <AppKit/CPScrollView.j>
@import <AppKit/CPSearchField.j>
@import <AppKit/CPTableView.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPView.j>
@import <AppKit/CPWindow.j>

@import <TNKit/TNAlert.j>
@import <TNKit/TNAttachedWindow.j>
@import <TNKit/TNTableViewDataSource.j>



var TNArchipelTypeXMPPServerUsers                   = @"archipel:xmppserver:users",
    TNArchipelTypeXMPPServerUsersRegister           = @"register",
    TNArchipelTypeXMPPServerUsersUnregister         = @"unregister",
    TNArchipelTypeXMPPServerUsersList               = @"list";

/*! @ingroup toolbarxmppserver
    XMPP user controller implementation
*/
@implementation TNXMPPUsersController : CPObject
{
    @outlet CPButton            buttonCreate;
    @outlet CPButtonBar         buttonBarControl;
    @outlet TNUIKitScrollView   scrollViewUsers;
    @outlet CPSearchField       filterField;
    @outlet CPTextField         fieldNewUserPassword;
    @outlet CPTextField         fieldNewUserPasswordConfirm;
    @outlet CPTextField         fieldNewUserUsername;
    @outlet CPView              mainView                        @accessors(getter=mainView);
    @outlet CPView              viewTableContainer;
    @outlet CPView              viewNewUser;
    @outlet CPTableView         tableUsers;

    CPArray                     _users                          @accessors(getter=users);
    id                          _delegate                       @accessors(property=delegate);
    TNStropheContact            _entity                         @accessors(setter=setEntity:);
    TNTableViewDataSource       _datasourceUsers                @accessors(getter=datasource);

    CPButton                    _addButton;
    CPButton                    _deleteButton;
    CPImage                     _iconEntityTypeHuman;
    CPImage                     _iconEntityTypeHypervisor;
    CPImage                     _iconEntityTypeVM;
    TNAttachedWindow            _windowNewUser;
}

#pragma mark -
#pragma mark Initialization

- (void)awakeFromCib
{
    _windowNewUser = [[TNAttachedWindow alloc] initWithContentRect:CPRectMake(0.0, 0.0, [viewNewUser frameSize].width, [viewNewUser frameSize].height) styleMask:CPClosableWindowMask | TNAttachedWhiteWindowMask];
    [_windowNewUser setContentView:viewNewUser];
    [_windowNewUser setDefaultButton:buttonCreate];

    [viewTableContainer setBorderedWithHexColor:@"#C0C7D2"];

    var bundle = [CPBundle bundleForClass:[self class]];

    _users                      = [CPArray array];
    _iconEntityTypeHuman        = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"type-human.png"] size:CPSizeMake(16, 16)];
    _iconEntityTypeVM           = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"type-vm.png"] size:CPSizeMake(16, 16)];
    _iconEntityTypeHypervisor   = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"type-hypervisor.png"] size:CPSizeMake(16, 16)];

    // table users
    _datasourceUsers = [[TNTableViewDataSource alloc] init];
    [_datasourceUsers setTable:tableUsers];
    [_datasourceUsers setSearchableKeyPaths:[@"name", @"jid"]];
    [tableUsers setDataSource:_datasourceUsers];

    _addButton = [CPButtonBar plusButton];
    [_addButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/user-add.png"] size:CPSizeMake(16, 16)]];
    [_addButton setTarget:self];
    [_addButton setAction:@selector(openRegisterUserWindow:)];
    [_addButton setToolTip:CPBundleLocalizedString(@"Create a new user account", @"Create a new user account")];

    _deleteButton = [CPButtonBar plusButton];
    [_deleteButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/user-remove.png"] size:CPSizeMake(16, 16)]];
    [_deleteButton setTarget:self];
    [_deleteButton setAction:@selector(unregisterUser:)];
    [_deleteButton setToolTip:CPBundleLocalizedString(@"Delete selected user accounts", @"Delete selected user accounts")];

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
        [_windowNewUser close];

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

    [_windowNewUser positionRelativeToView:aSender];
}

/*! close the new user window
    @param aSender the sender of the action
*/
- (IBAction)closeRegisterUserWindow:(id)aSender
{
    [_windowNewUser close];
}

/*! create a new user
    @param aSender the sender of the action
*/
- (IBAction)registerUser:(id)aSender
{
    if ([fieldNewUserPassword stringValue] != [fieldNewUserPasswordConfirm stringValue])
    {
        [TNAlert showAlertWithMessage:CPBundleLocalizedString(@"Password doesn't match", @"Password doesn't match")
                          informative:CPBundleLocalizedString(@"You have to enter identical passwords", @"You have to enter identical passwords")];
        return;
    }

    if ([[fieldNewUserPassword stringValue] length] < 8)
    {
        [TNAlert showAlertWithMessage:CPBundleLocalizedString(@"Bad password", @"Bad password")
                          informative:CPBundleLocalizedString(@"The password is too short. it must be at least 8 characters", @"The password is too short. it must be at least 8 characters")];
        return;
    }

    [_windowNewUser close];
    [self registerUserWithName:[fieldNewUserUsername stringValue] password:[fieldNewUserPassword stringValue]];
}

/*! create a new user
    @param aSender the sender of the action
*/
- (IBAction)unregisterUser:(id)aSender
{
    if ([tableUsers numberOfSelectedRows] < 1)
    {
        [TNAlert showAlertWithMessage:CPBundleLocalizedString(@"You must select one user", @"You must select one user")
                          informative:@""];
        return;
    }

    var indexes     = [tableUsers selectedRowIndexes],
        users       = [_datasourceUsers objectsAtIndexes:indexes],
        usernames   = [CPArray array];

    for (var i = 0; i < [users count]; i ++)
    {
        var user = [users objectAtIndex:i];
        [usernames addObject:[[user objectForKey:@"jid"] node]];
    }

    var thealert = [TNAlert alertWithMessage:CPBundleLocalizedString(@"Unregister", @"Unregister")
                                informative:CPBundleLocalizedString(@"Are you sure you want to unregister selected user(s) ?", @"Are you sure you want to unregister selected user(s) ?")
                                 target:self
                                 actions:[[CPBundleLocalizedString("Confirm", "Confirm"), @selector(unregisterUserWithNames:)], [CPBundleLocalizedString("Cancel", "Cancel"), nil]]];

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
        [tableUsers reloadData];
        return;
    }

    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeXMPPServerUsers}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeXMPPServerUsersList}];

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
        [_users removeAllObjects];

        for (var i = 0; i < [users count]; i++)
        {
            var user    = [users objectAtIndex:i],
                jid     = [TNStropheJID stropheJIDWithString:[user valueForAttribute:@"jid"]],
                type    = [user valueForAttribute:@"type"],
                name    = [jid node],
                contact = [[[TNStropheIMClient defaultClient] roster] contactWithJID:jid],
                newItem;

            if (contact)
                name = [contact nickname];

            var icon;
            switch (type)
            {
                case "human":
                    icon = _iconEntityTypeHuman
                    break;
                case "virtualmachine":
                    icon = _iconEntityTypeVM
                    break;
                case "hypervisor":
                    icon = _iconEntityTypeHypervisor
                    break;
            }

            newItem = [CPDictionary dictionaryWithObjects:[name, jid, type, icon] forKeys:[@"name", @"jid", @"type", @"icon"]]
            [_users addObject:newItem];

            if (type == "human")
                [_datasourceUsers addObject:newItem];
        }

        [tableUsers reloadData];
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

// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNXMPPUsersController], comment);
}
