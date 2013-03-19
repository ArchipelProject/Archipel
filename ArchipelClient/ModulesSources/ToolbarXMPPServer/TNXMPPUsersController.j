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

@import <GrowlCappuccino/GrowlCappuccino.j>
@import <TNKit/TNAlert.j>
@import <TNKit/TNTableViewLazyDataSource.j>

@import "TNXMPPServerUserFetcher.j"

@class TNTableViewLazyDataSource
@class TNPermissionsCenter
@global CPLocalizedString
@global CPLocalizedStringFromTableInBundle
@global TNPermissionsAdminListUpdatedNotification

var TNArchipelTypeXMPPServerUsers                   = @"archipel:xmppserver:users",
    TNArchipelTypeXMPPServerUsersRegister           = @"register",
    TNArchipelTypeXMPPServerUsersUnregister         = @"unregister",
    TNArchipelXMPPUserAdminImage,
    TNArchipelXMPPUserNormalImage;

/*! @ingroup toolbarxmppserver
    XMPP user controller implementation
*/
@implementation TNXMPPUsersController : CPObject
{
    @outlet CPButton            buttonCreate;
    @outlet CPButtonBar         buttonBarControl;
    @outlet CPImageView         imageFecthingUsers;
    @outlet CPPopover           popoverNewUser;
    @outlet CPSearchField       filterField;
    @outlet CPTableView         tableUsers;
    @outlet CPTextField         fieldNewUserPassword;
    @outlet CPTextField         fieldNewUserPasswordConfirm;
    @outlet CPTextField         fieldNewUserUsername;
    @outlet CPTextField         labelFecthingUsers;
    @outlet CPView              mainView                        @accessors(getter=mainView);
    @outlet CPView              viewTableContainer;

    id                          _delegate                       @accessors(property=delegate);

    TNStropheContact            _entity;
    TNTableViewLazyDataSource   _datasourceUsers;
    CPButton                    _addButton;
    CPButton                    _deleteButton;
    CPButton                    _grantAdminButton;
    CPButton                    _revokeAdminButton;
    TNXMPPServerUserFetcher     _usersFetcher;
}

#pragma mark -
#pragma mark Initialization

- (void)awakeFromCib
{
    [viewTableContainer setBorderedWithHexColor:@"#C0C7D2"];
    [imageFecthingUsers setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"spinner.gif"] size:CGSizeMake(16, 16)]];

    // table users
    _datasourceUsers = [[TNTableViewLazyDataSource alloc] init];
    [_datasourceUsers setTable:tableUsers];
    [_datasourceUsers setSearchableKeyPaths:[@"name", @"JID"]];
    [tableUsers setDataSource:_datasourceUsers];

    // user fetcher
    _usersFetcher = [[TNXMPPServerUserFetcher alloc] init];
    [_usersFetcher setDataSource:_datasourceUsers];
    [_usersFetcher setDelegate:self];
    [_usersFetcher setDisplaysOnlyHumans:YES];

    _addButton = [CPButtonBar plusButton];
    [_addButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/user-add.png"] size:CGSizeMake(16, 16)]];
    [_addButton setTarget:self];
    [_addButton setAction:@selector(openRegisterUserWindow:)];
    [_addButton setToolTip:CPBundleLocalizedString(@"Register a new user", @"Register a new user")];

    _deleteButton = [CPButtonBar plusButton];
    [_deleteButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/user-remove.png"] size:CGSizeMake(16, 16)]];
    [_deleteButton setTarget:self];
    [_deleteButton setAction:@selector(unregisterUser:)];
    [_deleteButton setToolTip:CPBundleLocalizedString(@"Unregister selected users", @"Unregister selected users")];

    _grantAdminButton = [CPButtonBar plusButton];
    [_grantAdminButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/star.png"] size:CGSizeMake(16, 16)]];
    [_grantAdminButton setTarget:self];
    [_grantAdminButton setAction:@selector(grantAdmin:)];
    [_grantAdminButton setToolTip:CPBundleLocalizedString(@"Make selected users as admins", @"Make selected users as admins")];

    _revokeAdminButton = [CPButtonBar minusButton];
    [_revokeAdminButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/unstar.png"] size:CGSizeMake(16, 16)]];
    [_revokeAdminButton setTarget:self];
    [_revokeAdminButton setAction:@selector(revokeAdmin:)];
    [_revokeAdminButton setToolTip:CPBundleLocalizedString(@"Remove admin rights to selected users", @"Remove admin rights to selected users")];

    [buttonBarControl setButtons:[_addButton, _deleteButton, _grantAdminButton, _revokeAdminButton]];

    [filterField setTarget:_datasourceUsers];
    [filterField setAction:@selector(filterObjects:)];

    [fieldNewUserPassword setSecure:YES];
    [fieldNewUserPasswordConfirm setSecure:YES];

    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_didAdminAccountsListUpdate:) name:TNPermissionsAdminListUpdatedNotification object:nil];
}

/*! Called when the list of Admin accounts has been updated.
    It will refresh the user list
*/
- (void)_didAdminAccountsListUpdate:(CPNotification)aNotification
{
    if ([[TNStropheIMClient defaultClient] JID])
    {
        [self flushUI];
        [_usersFetcher getXMPPUsers];
    }
}


#pragma mark -
#pragma mark Notification handlers

- (void)_didReceiveUsersPush:(CPDictionary)somePushInfo
{
    var sender  = [somePushInfo objectForKey:@"owner"],
        type    = [somePushInfo objectForKey:@"type"],
        change  = [somePushInfo objectForKey:@"change"],
        date    = [somePushInfo objectForKey:@"date"],
        stanza  = [somePushInfo objectForKey:@"rawStanza"];

    switch (change)
    {
        case @"registered":
            [self flushUI];
            [_usersFetcher getXMPPUsers];
            break;

        case @"unregistered":
            [self flushUI];
            [_usersFetcher getXMPPUsers];
            break
    }

    return YES;
}


#pragma mark -
#pragma mark Setters / Getters

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
    [self closeRegisterUserWindow:nil];
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
    // this will check against a non existing permissions
    // As these controls are only for admins, we don't really care about the permission
    [_delegate setControl:_revokeAdminButton enabledAccordingToPermissions:[@"dummy_permission"]];
    [_delegate setControl:_grantAdminButton enabledAccordingToPermissions:[@"dummy_permission"]];

    [_delegate setControl:_addButton enabledAccordingToPermissions:[@"xmppserver_users_list", @"xmppserver_users_register"]];
    [_delegate setControl:_deleteButton enabledAccordingToPermissions:[@"xmppserver_users_list", @"xmppserver_users_unregister"]];

    if (![_delegate currentEntityHasPermissions:[@"xmppserver_users_list", @"xmppserver_users_register"]])
        [popoverNewUser close];
}

/*! reload the display of the module
*/
- (void)reload
{
    [self setUIAccordingToPermissions];
    [labelFecthingUsers setHidden:YES];
    [imageFecthingUsers setHidden:YES];

    if ([_datasourceUsers isCurrentlyLoading])
        return;

    [self flushUI];
    [_usersFetcher getXMPPUsers];
}

/*! this message is used to flush the UI
*/
- (void)flushUI
{
    [_usersFetcher reset];
    [_datasourceUsers removeAllObjects];
    [tableUsers reloadData];
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

    [popoverNewUser close];
    [popoverNewUser showRelativeToRect:nil ofView:aSender preferredEdge:nil];
    [popoverNewUser setDefaultButton:buttonCreate];
    [popoverNewUser makeFirstResponder:fieldNewUserUsername];
}

/*! close the new user window
    @param aSender the sender of the action
*/
- (IBAction)closeRegisterUserWindow:(id)aSender
{
    [popoverNewUser close];
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

    [popoverNewUser close];
    var JID;
    try {
        JID = [TNStropheJID stropheJIDWithString:[fieldNewUserUsername stringValue]];
        if (![JID domain])
            [CPException raise:@"Bad JID" reason:@"JID must follow the form user@node"]
    }
    catch(e)
    {
        [TNAlert showAlertWithMessage:CPBundleLocalizedString(@"Bad JID", @"Bad JID")
                          informative:[fieldNewUserUsername stringValue] + CPLocalizedString(" is not a valid JID.", " is not a valid JID.")
                          style:CPCriticalAlertStyle];
        return;
    }
    [self registerUserWithJID:JID password:[fieldNewUserPassword stringValue]];
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
        [usernames addObject:[user objectForKey:@"JID"]];
    }

    var thealert = [TNAlert alertWithMessage:CPBundleLocalizedString(@"Unregister", @"Unregister")
                                informative:CPBundleLocalizedString(@"Are you sure you want to unregister selected user(s) ?", @"Are you sure you want to unregister selected user(s) ?")
                                 target:self
                                 actions:[[CPBundleLocalizedString("Confirm", "Confirm"), @selector(unregisterUserWithJIDs:)], [CPBundleLocalizedString("Cancel", "Cancel"), nil]]];

    [thealert setUserInfo:usernames];
    [thealert runModal];
}

/*! Grant selected users admin rights
    @param aSender the sender of the action
*/
- (IBAction)grantAdmin:(id)aSender
{
    var indexes = [tableUsers selectedRowIndexes],
        users = [_datasourceUsers objectsAtIndexes:indexes];

    for (var i = 0; i < [users count]; i ++)
    {
        var user = [users objectAtIndex:i];
        [[TNPermissionsCenter defaultCenter] addAdminAccount:[user objectForKey:@"JID"]];
    }
}

/*! revoke selected users admin rights
    @param aSender the sender of the action
*/
- (IBAction)revokeAdmin:(id)aSender
{
    var indexes = [tableUsers selectedRowIndexes],
        users = [_datasourceUsers objectsAtIndexes:indexes];

    for (var i = 0; i < [users count]; i ++)
    {
        var user = [users objectAtIndex:i];
        if (![[user objectForKey:@"JID"] bareEquals:[[TNStropheIMClient defaultClient] JID]])
            [[TNPermissionsCenter defaultCenter] removeAdminAccount:[user objectForKey:@"JID"]];
        else
        {
            [TNAlert showAlertWithMessage:CPLocalizedString(@"Admin rights", @"Admin rights")
                              informative:CPLocalizedString(@"You can't revoke yourself your admin rights. No resignation allowed buddy!", @"You can't revoke yourself your admin rights. No resignation allowed buddy!")];
        }
    }
}


#pragma mark -
#pragma mark XMPP Management

/*! create a new user with given username and password
    @param aUserName the username of the new user
    @param aPasswor the password of the new user
*/
- (void)registerUserWithJID:(TNStropheJID)aJID password:(CPString)aPassword
{
    var stanza = [TNStropheStanza iqWithType:@"set"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeXMPPServerUsers}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeXMPPServerUsersRegister}];

    [stanza addChildWithName:@"user" andAttributes:{"jid": [aJID bare], "password": aPassword}];
    [_entity sendStanza:stanza andRegisterSelector:@selector(_didRegisterUser:) ofObject:self];
}

/*! compute the answer of user creation
    @param aStanza TNStropheStanza containing the answer
*/
- (void)_didRegisterUser:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:CPLocalizedString(@"Regisration complete", @"Regisration complete")
                                                         message:CPLocalizedString(@"New user has been sucessfully registred", @"New user has been sucessfully registred")];

    }
    else
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:CPLocalizedString(@"Registration error", @"Registration error")
                                                         message:CPLocalizedString(@"Agent was unable to register the user.", @"Agent was unable to register the user.")
                                                            icon:TNGrowlIconError];
        [_delegate handleIqErrorFromStanza:aStanza];
    }
}

/*! unregister a new user with given username and password
    @param aUserName the username of the user
*/
- (void)unregisterUserWithJIDs:(CPArray)someJIDs
{
    var stanza = [TNStropheStanza iqWithType:@"set"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeXMPPServerUsers}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeXMPPServerUsersUnregister}];

    for (var i = 0; i < [someJIDs count]; i++)
    {
        var JID = [someJIDs objectAtIndex:i];
        [stanza addChildWithName:@"user" andAttributes:{"jid": [JID bare]}];
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
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:CPLocalizedString(@"Unegisration complete", @"Unegisration complete")
                                                         message:CPLocalizedString(@"User has been sucessfully unregistred", @"User has been sucessfully unregistred")];

    }
    else
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:CPLocalizedString(@"Unregistration error", @"Unregistration error")
                                                         message:CPLocalizedString(@"Agent was unable to unregister the user.", @"Agent was unable to unregister the user.")
                                                            icon:TNGrowlIconError];
        [_delegate handleIqErrorFromStanza:aStanza];
    }
}


#pragma mark -
#pragma mark Delegates

/*! delegate of TNXMPPServerUserFetcher
*/
- (void)userFetcherClean
{
    [self flushUI];
}

/*! delegate of TNXMPPServerUserFetcher
*/
- (void)userFetcher:(TNXMPPServerUserFetcher)userFecther isLoading:(BOOL)isLoading
{
    [labelFecthingUsers setHidden:!isLoading];
    [imageFecthingUsers setHidden:!isLoading];
}

@end

// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNXMPPUsersController], comment);
}
