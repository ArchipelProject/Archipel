/*
 * TNRESTConnexion.j
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

@import "TNRESTLoginController.j"

@import <Foundation/CPURLConnection.j>

TNRESTConnectionResponseCodeZero = 0;
TNRESTConnectionResponseCodeSuccess = 200;
TNRESTConnectionResponseCodeCreated = 201;
TNRESTConnectionResponseCodeEmpty = 204;
TNRESTConnectionResponseCodeNotFound = 404;
TNRESTConnectionResponseCodeConflict = 409;
TNRESTConnectionResponseCodeInternalServerError = 500;
TNRESTConnectionResponseCodeServiceUnavailable = 503;
TNRESTConnectionResponseCodeUnauthorized = 401;
TNRESTConnectionResponseCodePermissionDenied = 403;
TNRESTConnectionResponseCodeMultipleChoices = 300;

/*! Enhanced version of CPURLConnection
*/
@implementation TNRESTConnection : CPObject
{
    CPData          _responseData           @accessors(getter=responseData);
    CPURLRequest    _request                @accessors(property=request);
    id              _target                 @accessors(property=target);
    id              _userInfo               @accessors(property=userInfo);
    id              _internalUserInfo       @accessors(property=internalUserInfo);
    int             _responseCode           @accessors(getter=responseCode);
    SEL             _selector               @accessors(property=selector);
    CPString        _errorMessage           @accessors(property=errorMessage);
    BOOL            _usesAuthentication     @accessors(property=usesAuthentication);

    BOOL            _isCanceled;
    HTTPRequest     _HTTPRequest;
}


#pragma mark -
#pragma mark Class Methods

/*! Initialize a new TNRESTConnection
    @param aRequest the CPURLRequest to send
    @param anObject a random object that is the target of the result events
    @param aSuccessSelector the selector to send to anObject in case of success
    @param anErrorSelector the selector to send to anObject in case of error
    @return TNRESTConnection fully ready TNRESTConnection
*/
+ (TNRESTConnection)connectionWithRequest:(CPURLRequest)aRequest
                                  target:(CPObject)anObject
                                selector:(SEL)aSelector
{
    var connection = [[TNRESTConnection alloc] initWithRequest:aRequest];
    [connection setTarget:anObject];
    [connection setSelector:aSelector];

    return connection;
}


#pragma mark -
#pragma mark Initialization

/*! Initialize a TNRESTConnection with a CPURLRequest
    @param aRequest the request to user
*/
- (void)initWithRequest:aRequest
{
    if (self = [super init])
    {
        _request = aRequest;
        _isCanceled = NO;
        _usesAuthentication = YES;
        _HTTPRequest = new CFHTTPRequest();
    }

    return self;
}

/*! Start the connection
*/
- (void)start
{
    _isCanceled = NO;

    try
    {
        _HTTPRequest.open([_request HTTPMethod], [[_request URL] absoluteString], YES);

        _HTTPRequest.onreadystatechange = function() { [self _readyStateDidChange]; }

        var fields = [_request allHTTPHeaderFields],
            key = nil,
            keys = [fields keyEnumerator];

        while (key = [keys nextObject])
            _HTTPRequest.setRequestHeader(key, [fields objectForKey:key]);

        if (_usesAuthentication)
        {
            _HTTPRequest.setRequestHeader("X-Nuage-Organization", [[TNRESTLoginController defaultController] company]);
            _HTTPRequest.setRequestHeader("Authorization", [[TNRESTLoginController defaultController] RESTAuthString]);
        }


        _HTTPRequest.send([_request HTTPBody]);
    }
    catch (anException)
    {
        _errorMessage = anException;
        if (_target && _selector)
            [_target performSelector:_selector withObject:self];
    }
}

/*! Abort the connection
*/
- (void)cancel
{
    _isCanceled = YES;

    try { _HTTPRequest.abort(); } catch (anException) {}
}

- (void)reset
{
    _HTTPRequest = new CFHTTPRequest();
    _responseData = nil;
    _responseCode = nil;
    _errorMessage = nil;
}

/*! @ignore
*/
- (void)_readyStateDidChange
{
    if (_HTTPRequest.readyState() === CFHTTPRequest.CompleteState)
    {
        _responseCode = _HTTPRequest.status();
        _responseData = [CPData dataWithRawString:_HTTPRequest.responseText()];

        if (_target && _selector)
            [_target performSelector:_selector withObject:self];

        [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
    }
}

@end
