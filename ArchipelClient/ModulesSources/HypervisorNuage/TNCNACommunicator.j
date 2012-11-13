/*
 * TNCNACommunicator.j
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

@import "REST/NURESTConnection.j"
@import "REST/NURESTPushCenter.j"

var defaultTNCNACommunicator;


@implementation TNCNACommunicator : CPObject
{
    CPURL       _baseURL                @accessors(property=baseURL);
    CPString    _username               @accessors(property=username);
    CPString    _company                @accessors(property=company);
    CPString    _token                  @accessors(property=token);

    CPString    _currentOrganizationID  @accessors(property=currentOrganizationID);
    CPString    _currentUserID          @accessors(property=currentUserID);

    BOOL        _authenticated          @accessors(property=authenticated);
}

+ (TNCNACommunicator)defaultCNACommunicator
{
    if (!defaultTNCNACommunicator)
        defaultTNCNACommunicator = [[TNCNACommunicator alloc] init];

    return defaultTNCNACommunicator;
}

#pragma mark -
#pragma mark Initialization

- (void)initWithBaseURL:(CPURL)anURL
{
    if (self = [super init])
    {
        _baseURL = anURL;
    }

    return self;
}


#pragma mark -
#pragma mark Communication

- (void)_prepareLogin
{
    var defaults = [CPUserDefaults standardUserDefaults],
        username = [defaults objectForKey:@"TNArchipelNuageUserName"],
        company =  [defaults objectForKey:@"TNArchipelNuageCompany"],
        password = [defaults objectForKey:@"TNArchipelNuagePassword"];

    if (_username == username && _company == company && _token == password)
        return;

    _username = username;
    _company = company;
    _token = password;

    [[NURESTLoginController defaultController] setUser:username];
    [[NURESTLoginController defaultController] setPassword:password];
    [[NURESTLoginController defaultController] setCompany:company];
}

- (void)fetchMe
{
    [self setAuthenticated:NO];

    [self _prepareLogin];

    var request = [CPURLRequest requestWithURL:[CPURL URLWithString:@"me" relativeToURL:_baseURL]],
        connection = [NURESTConnection connectionWithRequest:request target:self selector:@selector(_didFetchMe:)];

    [connection start];
}

- (void)_didFetchMe:(NURESTConnection)aConnection
{
    if ([aConnection responseCode] !== 200)
    {
        [self setAuthenticated:NO];
        return;
    }

    var JSON = [[aConnection responseData] JSONObject];
    _currentOrganizationID = JSON[0].enterpriseID;
    _currentUserID = JSON[0].ID;
    CPLog.info("Nuage: Fetched REST user Nuage enterprise ID: " + _currentOrganizationID);
    CPLog.info("Nuage: Fetched REST user ID: " + _currentUserID);

    [self setAuthenticated:YES];
}

- (void)fetchOrganizationsAndSetCompletionForComboBox:(CPComboBox)aComboBox
{
    if (!_authenticated)
        return;

    var request = [CPURLRequest requestWithURL:[CPURL URLWithString:@"enterprises" relativeToURL:_baseURL]],
        connection = [NURESTConnection connectionWithRequest:request target:self selector:@selector(_didFetchObjects:)];

    [connection setUserInfo:aComboBox];
    [connection setInternalUserInfo:@"name"];
    [connection start];
}

- (void)fetchGroupsAndSetCompletionForComboBox:(CPComboBox)aComboBox
{
    if (!_authenticated)
        return;

    var request = [CPURLRequest requestWithURL:[CPURL URLWithString:@"enterprises/" + _currentOrganizationID + @"/groups" relativeToURL:_baseURL]],
        connection = [NURESTConnection connectionWithRequest:request target:self selector:@selector(_didFetchObjects:)];

    [connection setUserInfo:aComboBox];
    [connection setInternalUserInfo:@"name"];
    [connection start];
}

- (void)fetchUsersAndSetCompletionForComboBox:(CPComboBox)aComboBox
{
    if (!_authenticated)
        return;

    var request = [CPURLRequest requestWithURL:[CPURL URLWithString:@"enterprises/" + _currentOrganizationID + @"/users" relativeToURL:_baseURL]],
        connection = [NURESTConnection connectionWithRequest:request target:self selector:@selector(_didFetchObjects:)];

    [connection setUserInfo:aComboBox];
    [connection setInternalUserInfo:@"userName"];
    [connection start];
}

- (void)fetchApplicationsAndSetCompletionForComboBox:(CPComboBox)aComboBox
{
    if (!_authenticated)
        return;

    var request = [CPURLRequest requestWithURL:[CPURL URLWithString:@"users/" + _currentUserID + @"/apps" relativeToURL:_baseURL]],
        connection = [NURESTConnection connectionWithRequest:request target:self selector:@selector(_didFetchObjects:)];

    [connection setUserInfo:aComboBox];
    [connection setInternalUserInfo:@"name"];
    [connection start];
}

- (void)_didFetchObjects:(NURESTConnection)aConnection
{
    CPLog.info("CNA REST RESPONSE", [aConnection responseCode], ":", [[aConnection responseData] rawString]);

    if ([aConnection responseCode] !== 200 && [aConnection responseCode] !== 204)
    {
        var title = "An error occured while sending REST to " + _baseURL,
            informative = [aConnection errorMessage];

        [TNAlert showAlertWithMessage:title informative:informative style:CPCriticalAlertStyle];
        return;
    }

    var JSONObj = [[aConnection responseData] JSONObject],
        completions = [CPArray array],
        RESTToken = [aConnection internalUserInfo],
        comboBox = [aConnection userInfo];

    if (!JSONObj)
    {
        CPLog.warn("JSON object is empty.");
        return;
    }


    for (var i = 0; i < JSONObj.length; i++)
        [completions addObject:[JSONObj[i][RESTToken]]];

    [comboBox setContentValues:completions];
    [comboBox _popUpButtonWasClicked];
    [comboBox popUpList];
}

- (void)fetchDomainsAndCallSelector:(SEL)aSelector ofObject:(id)anObject
{
    if (!_authenticated)
        return;

    var request = [CPURLRequest requestWithURL:[CPURL URLWithString:@"enterprises/" + _currentOrganizationID + "/domains" relativeToURL:_baseURL]],
        connection = [NURESTConnection connectionWithRequest:request target:anObject selector:aSelector];

    [connection start];
}

- (void)fetchZonesInDomainWithID:(CPString)aDomainID andCallSelector:(SEL)aSelector ofObject:(id)anObject
{
    if (!_authenticated)
        return;

    var request = [CPURLRequest requestWithURL:[CPURL URLWithString:@"domains/" + aDomainID + "/zones" relativeToURL:_baseURL]],
        connection = [NURESTConnection connectionWithRequest:request target:anObject selector:aSelector];

    [connection start];
}


@end

