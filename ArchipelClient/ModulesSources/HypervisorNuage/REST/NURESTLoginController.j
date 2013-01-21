/*
*   Filename:         NURESTLoginController.j
*   Created:          Tue Oct  9 11:49:41 PDT 2012
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
@import "../Resources/SHA1.js"

var DefaultNURESTLoginController;

@implementation NURESTLoginController : CPObject
{
    CPString _user      @accessors(property=user);
    CPString _password  @accessors(property=password);
    CPString _company   @accessors(property=company);
    CPString _URL       @accessors(property=URL);
}

+ (NULoginController)defaultController
{
    if (!DefaultNURESTLoginController)
        DefaultNURESTLoginController = [[NURESTLoginController alloc] init];
    return DefaultNURESTLoginController;
}

- (CPString)RESTAuthString
{
    var token = @"XREST " + btoa([CPString stringWithFormat:@"%s:%s", _user, _password]);
    return token;
}

- (void)setPassword:(CPString)aPassword
{
    _password = Sha1.hash(aPassword);
    aPassword = nil;
}

@end
