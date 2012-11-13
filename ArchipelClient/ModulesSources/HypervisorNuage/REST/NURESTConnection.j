/*
*   Filename:         NURESTConnection.j
*   Created:          Tue Oct  9 11:49:32 PDT 2012
*   Author:           Antoine Mercadal <antoine.mercadal@alcatel-lucent.com>
*   Description:      CNA Dashboard
*   Project:          Cloud Network Automation - Nuage - Data Center Service Delivery - IPD
*
* Copyright (c) 2011-2012 Alcatel, Alcatel-Lucent, Inc. All Rights Reserved.
*
* This source code contains confidential information which is proprietary to Alcatel.
* No part of its contents may be used, copied, disclosed or conveyed to any party
* in any manner whatsoever without prior written permission from Alcatel.
*
* Alcatel-Lucent is a trademark of Alcatel-Lucent, Inc.
*
*/

@import <Foundation/CPURLConnection.j>

NURESTConnectionResponseCodeZero = 0;
NURESTConnectionResponseCodeSuccess = 200;
NURESTConnectionResponseCodeCreated = 201;
NURESTConnectionResponseCodeEmpty = 204;
NURESTConnectionResponseCodeNotFound = 404;
NURESTConnectionResponseCodeConflict = 409;
NURESTConnectionResponseCodeInternalServerError = 500;
NURESTConnectionResponseCodeServiceUnavailable = 503;
NURESTConnectionResponseCodeUnauthorized = 401;
NURESTConnectionResponseCodePreconditionFailed = 412;
NURESTConnectionResponseCodePermissionDenied = 403;
NURESTConnectionResponseCodeMultipleChoices = 300;
NURESTConnectionTimeout = 42;

NURESTConnectionFailureNotification = @"NURESTConnectionFailureNotification";


/*! Enhanced version of CPURLConnection
*/
@implementation NURESTConnection : CPObject
{
    BOOL            _usesAuthentication     @accessors(property=usesAuthentication);
    BOOL            _hasTimeouted           @accessors(getter=hasTimeouted);
    CPData          _responseData           @accessors(getter=responseData);
    CPString        _errorMessage           @accessors(property=errorMessage);
    CPURLRequest    _request                @accessors(property=request);
    HTTPRequest     _HTTPRequest            @accessors(getter=nativeRequest);
    id              _internalUserInfo       @accessors(property=internalUserInfo);
    id              _target                 @accessors(property=target);
    id              _userInfo               @accessors(property=userInfo);
    int             _responseCode           @accessors(getter=responseCode);
    SEL             _selector               @accessors(property=selector);
    int             _XHRTimeout             @accessors(property=timeout);

    BOOL            _isCanceled;
}


#pragma mark -
#pragma mark Class Methods

/*! Initialize a new NURESTConnection
    @param aRequest the CPURLRequest to send
    @param anObject a random object that is the target of the result events
    @param aSuccessSelector the selector to send to anObject in case of success
    @param anErrorSelector the selector to send to anObject in case of error
    @return NURESTConnection fully ready NURESTConnection
*/
+ (NURESTConnection)connectionWithRequest:(CPURLRequest)aRequest
                                  target:(CPObject)anObject
                                selector:(SEL)aSelector
{
    var connection = [[NURESTConnection alloc] initWithRequest:aRequest];
    [connection setTarget:anObject];
    [connection setSelector:aSelector];

    return connection;
}


#pragma mark -
#pragma mark Initialization

/*! Initialize a NURESTConnection with a CPURLRequest
    @param aRequest the request to user
*/
- (void)initWithRequest:aRequest
{
    if (self = [super init])
    {
        _request = aRequest;
        _isCanceled = NO;
        _hasTimeouted = NO;
        _usesAuthentication = YES;
        _XHRTimeout = 5000;
        _HTTPRequest = new CFHTTPRequest();
    }

    return self;
}

/*! Start the connection
*/
- (void)start
{
    _isCanceled = NO;
    _hasTimeouted = NO;

    try
    {
        _HTTPRequest.open([_request HTTPMethod], [[_request URL] absoluteString], YES);

        _HTTPRequest._nativeRequest.timeout = _XHRTimeout;
        _HTTPRequest.onreadystatechange = function() { [self _readyStateDidChange]; }
        _HTTPRequest._nativeRequest.ontimeout = function() { [self _XHRDidTimeout]; }

        var fields = [_request allHTTPHeaderFields],
            key = nil,
            keys = [fields keyEnumerator];

        while (key = [keys nextObject])
            _HTTPRequest.setRequestHeader(key, [fields objectForKey:key]);

        if (_usesAuthentication)
        {
            _HTTPRequest.setRequestHeader("X-Nuage-Organization", [[NURESTLoginController defaultController] company]);
            _HTTPRequest.setRequestHeader("Authorization", [[NURESTLoginController defaultController] RESTAuthString]);
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

- (void)_XHRDidTimeout
{
    _hasTimeouted = YES;

    if (_target && _selector)
        [_target performSelector:_selector withObject:self];

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
}

@end
