/*
 * CPString-UUIDRFC4122.j
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

@import <Foundation/CPString.j>


/*! @ingroup categories
    Categories that allows CPString to generate UUID rfc4122 compliant
*/
@implementation CPString (CPStringWithUUIDSeparated)

+ (CPString)UUID
{
    var g = @"";

    for (var i = 0; i < 32; i++)
    {
        if ((i == 8) || (i == 12) || (i == 16) || (i == 20))
            g += '-';
        g += FLOOR(RAND() * 0xF).toString(0xF);
    }

    return g;
}

@end