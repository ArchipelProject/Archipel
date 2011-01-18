/*
 * TNStropheClient+singleton.j
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

@import <StropheCappuccino/TNStropheIMClient.j>

var DefaultTNStropheIMClient = nil;


/*! @ingroup categories
 Make TNStropheIMClient singular
*/
@implementation TNStropheIMClient (defaultClient)

+ (TNStropheIMClient)defaultClient
{
    if (!DefaultTNStropheIMClient)
        [CPException raise:CPInternalInconsistencyException raison:@"DefaultTNStropheIMClient is not set. use setDefaultClient: before"];
    return DefaultTNStropheIMClient;
}

- (void)setDefaultClient
{
    DefaultTNStropheIMClient = self;
}

@end
