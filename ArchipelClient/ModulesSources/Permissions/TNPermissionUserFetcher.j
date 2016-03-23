/*
 * TNPermissionUserFetcher.j
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

@import <StropheCappuccino/TNStropheStanza.j>
@import <StropheCappuccino/TNStropheContact.j>
@import <TNKit/TNTableViewLazyDataSource.j>

@class TNPermissionsCenter

var TNArchipelTypeXMPPServerUsers                   = @"archipel:xmppserver:users",
    TNArchipelTypeXMPPServerUsersList               = @"list",
    TNArchipelTypeXMPPServerUsersFilter             = @"filter",
    TNArchipelTypeXMPPServerUsersNumber             = @"number";

/*! @ingroup permissionsmodule
    Shared user fetcher using the lazy loading
*/
@implementation TNPermissionUserFetcher: CPObject
{
    BOOL                        _displaysOnlyHumans @accessors(getter=isDisplayingOnlyHumans, setter=setDisplaysOnlyHumans:);
    id                          _delegate           @accessors(property=delegate);
    TNStropheContact            _entity             @accessors(property=entity);
    TNTableViewLazyDataSource   _dataSource         @accessors(getter=dataSource);

    int                         _maxLoadedPage;
}


#pragma mark -
#pragma mark Initialization

/*! Instaciate the class
*/
- (id)init
{
    if (self = [super init])
    {
        _maxLoadedPage = 0;
        _displaysOnlyHumans = YES;
    }

    return self;
}


#pragma mark -
#pragma mark Getters / Setters

/*! Set the target datasource, and set self ad datasource delegate
    @pathForResource aDataSource the TNTableViewLazyDataSource to use
*/
- (void)setDataSource:(TNTableViewLazyDataSource)aDataSource
{
    _dataSource = aDataSource;
    [_dataSource setDelegate:self];
}


#pragma mark -
#pragma mark Utilities

/*! Reset informations
*/
- (void)reset
{
    _maxLoadedPage = 0;
    [_dataSource setTotalCount:-1];
    [_dataSource setCurrentlyLoading:NO];
    if ([_delegate respondsToSelector:@selector(userFetcher:isLoading:)])
        [_delegate userFetcher:self isLoading:NO];
}


#pragma mark -
#pragma mark XMPP Controls

/*! Ask the agent for the total number of accounts
*/
- (void)getNumberOfXMPPUsers
{
    [self getNumberOfXMPPUsers:nil];
}

/*! Ask the agent for the total number of accounts
    @param aCallback eventual callback to call when user number has been fetched
*/
- (void)getNumberOfXMPPUsers:(SEL)aCallback
{
    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeXMPPServerUsers}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeXMPPServerUsersNumber,
        "humans_only": _displaysOnlyHumans ? "true" : "false"}];

    [_entity sendStanza:stanza andRegisterSelector:@selector(_didGetNumberOfXMPPUsers:callback:) ofObject:self userInfo:aCallback];
}

/*! @ignore
*/
- (BOOL)_didGetNumberOfXMPPUsers:(TNStropheStanza)aStanza callback:(SEL)aCallback
{
    if ([aStanza type] == @"result")
    {
        var total = [[aStanza firstChildWithName:@"users"] valueForAttribute:@"total"];
        [_dataSource setTotalCount:total];
        if (aCallback)
            [self performSelector:aCallback];
    }
    else
    {
        [_delegate handleIqErrorFromStanza:aStanza];
    }
}

/*! compute the answer containing the total number of users
    @param aStanza TNStropheStanza containing the answer
*/
- (void)getXMPPUsers
{
    if (![[TNPermissionsCenter defaultCenter] hasPermission:@"xmppserver_users_list" forEntity:_entity])
    {
        [_delegate userFetcherClean];
        return;
    }

    if ([_dataSource totalCount] == -1)
    {
        [self getNumberOfXMPPUsers:@selector(getXMPPUsers)];
        return;
    }

    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeXMPPServerUsers}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeXMPPServerUsersList,
        "page": _maxLoadedPage,
        "humans_only": _displaysOnlyHumans ? "true" : "false"}];

    [_dataSource setCurrentlyLoading:YES];
    if ([_delegate respondsToSelector:@selector(userFetcher:isLoading:)])
        [_delegate userFetcher:self isLoading:YES];

    [_entity sendStanza:stanza andRegisterSelector:@selector(_didGetXMPPUsers:) ofObject:self];
}

/*! Ask for entities that macthes the given filter
    @param aFilter the filter to match
*/
- (void)getXMPPFilteredUsers:(CPString)aFilter
{
    if (![[TNPermissionsCenter defaultCenter] hasPermission:@"xmppserver_users_list" forEntity:_entity])
    {
        [_delegate userFetcherClean];
        return;
    }

    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeXMPPServerUsers}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeXMPPServerUsersFilter,
        "filter": aFilter}];

    [_dataSource setCurrentlyLoading:YES];
    if ([_delegate respondsToSelector:@selector(userFetcher:isLoading:)])
        [_delegate userFetcher:self isLoading:YES];

    [_entity sendStanza:stanza andRegisterSelector:@selector(_didGetXMPPUsers:) ofObject:self];
}

/*! compute the answer containing the users list
    @param aStanza TNStropheStanza containing the answer
*/
- (void)_didGetXMPPUsers:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        var users = [aStanza childrenWithName:@"user"];

        for (var i = 0; i < [users count]; i++)
        {
            var user = [users objectAtIndex:i],
                jid;

            try {jid = [TNStropheJID stropheJIDWithString:[user valueForAttribute:@"jid"]]} catch(e){continue};

            [_dataSource addObject:jid];
        }

        [[_dataSource table] reloadData];
    }
    else
    {
        [_delegate handleIqErrorFromStanza:aStanza];
    }

    [_dataSource setCurrentlyLoading:NO];
    if ([_delegate respondsToSelector:@selector(userFetcher:isLoading:)])
        [_delegate userFetcher:self isLoading:NO];

}


#pragma mark -
#pragma mark Delegate

/*! TNTableViewLazyDataSource delegate
*/
- (void)tableViewDataSourceNeedsLoading:(TNTableViewLazyDataSource)aDataSource
{
    _maxLoadedPage++;
    [self getXMPPUsers];
}

/*! TNTableViewLazyDataSource delegate
*/
- (void)tableViewDataSource:(TNTableViewLazyDataSource)aDataSource applyFilter:(CPString)aFilter
{
    [_delegate userFetcherClean];
    if ([aFilter length] >= 3)
        [self getXMPPFilteredUsers:aFilter];
}

/*! TNTableViewLazyDataSource delegate
*/
- (void)tableViewDataSource:(TNTableViewLazyDataSource)aDataSource removeFilter:(CPString)aFilter
{
    [_delegate userFetcherClean];
    [self getXMPPUsers];
}

@end
