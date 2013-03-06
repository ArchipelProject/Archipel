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

@import <Foundation/Foundation.j>

@global btoa


var DefaultNURESTLoginController;

@implementation NURESTLoginController : CPObject
{
    CPString _APIKey    @accessors(property=APIKey);
    CPString _company   @accessors(property=company);
    CPString _password  @accessors(property=password);
    CPString _URL       @accessors(property=URL);
    CPString _user      @accessors(property=user);
}

+ (NULoginController)defaultController
{
    if (!DefaultNURESTLoginController)
        DefaultNURESTLoginController = [[NURESTLoginController alloc] init];
    return DefaultNURESTLoginController;
}

- (CPString)RESTAuthString
{
    // Generate the auth string. If APIToken is set, it'll be used. Otherwise, the clear
    // text password will be sent. Users of NURESTLoginController are responsible to
    // clean the password property.
    var authString = [CPString stringWithFormat:@"%s:%s", _user, _APIKey || _password];

    return @"XREST " + btoa(authString);
}

- (BOOL)validateCurrentPassword:(CPString)aPassword
{
    // @TODO: Make this work with the new token based authentication;

    return NO; //Sha1.hash(aPassword) == _password;
}

@end
