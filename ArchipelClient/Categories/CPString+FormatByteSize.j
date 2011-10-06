/*
 * CPString+FormatByteSize.j
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


@implementation CPString (formatByteSize)

/*! format a size string from a given integer size in bytes
    @param  aSize integer containing the size in bytes.
    @return CPString containing "XX Unit" where Unit can be Kb, Mb or Gb
*/
+ (CPString)formatByteSize:(float)aSize
{
    var usedKind = CPLocalizedString(@"TB", @"TB"),
        originSize = parseFloat(aSize);

    aSize = parseFloat(aSize);
    aSize = Math.round((aSize / 1099511627776) * 100)  / 100;
    if (aSize < 0.5)
    {
        aSize = Math.round((originSize / 1073741824) * 100)  / 100;
        usedKind = CPLocalizedString(@"GB", @"GB");
        if (aSize < 0.5)
        {
            aSize = Math.round((originSize / 1048576) * 100)  / 100;
            usedKind = CPLocalizedString(@"MB", @"MB");
            if (aSize < 0.5)
            {
                aSize = Math.round((originSize / 1024) * 100)  / 100;
                usedKind = CPLocalizedString(@"KB", @"KB");
                if (aSize < 0.5)
                {
                    aSize = originSize;
                    usedKind = CPLocalizedString(@"B", @"B");
                }
            }
        }
    }
    return @"" + aSize + @" " + usedKind;
}

@end