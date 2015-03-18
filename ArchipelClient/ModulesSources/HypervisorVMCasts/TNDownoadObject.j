/*
 * TNDownoadObject.j
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

@global CPLocalizedString
@global CPLocalizedStringFromTableInBundle


/*! @ingroup hypervisorvmcasts
    This object represent a download
*/
@implementation TNDownload : CPObject
{
    CPString    _identifier  @accessors(property=identifier);
    CPString    _name        @accessors(property=name);
    float       _percentage  @accessors(property=percentage);
    float       _totalSize   @accessors(property=totalSize);
}

/*! initialize a TNDownload object with given values
    @param anIdentifier the download identifier
    @param aName the download name
    @param aSize the download total size
    @param aPercentage the download percentage
    @return initialized TNDownload
*/
+ (TNDownload)downloadWithIdentifier:(CPString)anIdentifier name:(CPString)aName totalSize:(float)aSize percentage:(float)aPercentage
{
    var dl = [[TNDownload alloc] init];
    [dl setIdentifier:anIdentifier];
    [dl setTotalSize:aSize];
    [dl setName:aName];
    [dl setPercentage:aPercentage];

    return dl;
}


#pragma mark -
#pragma mark Accessors

/*! format the size
    @return formated size
*/
- (float)totalSize
{
    return [CPString formatByteSize:_totalSize];
}

@end

// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNDownload], comment);
}
