/*
 * TNRESTLoginController.j
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


@import <Foundation/CPURLConnection.j>
@import "Resources/SHA1.js"

var DefaultTNRESTLoginController;

@implementation TNRESTLoginController : CPObject
{
    CPString _user      @accessors(property=user);
    CPString _password  @accessors(property=password);
    CPString _company   @accessors(property=company);
    CPString _URL       @accessors(property=URL);
}

+ (NULoginController)defaultController
{
    if (!DefaultTNRESTLoginController)
        DefaultTNRESTLoginController = [[TNRESTLoginController alloc] init];
    return DefaultTNRESTLoginController;
}

- (CPString)authString
{
    var token = @"Basic " + btoa([CPString stringWithFormat:@"%s:%s", _user, _password]);
    return token;
}

- (CPString)RESTAuthString
{
    var sha1pass = Sha1.hash(_password),
        token = @"XREST " + btoa([CPString stringWithFormat:@"%s:%s", _user, sha1pass]);
    return token;
}

@end
