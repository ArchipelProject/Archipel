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

@implementation TNDownload : CPObject
{
    CPString    _identifier  @accessors(property=identifier);
    CPString    _name        @accessors(property=name);
    float       _percentage  @accessors(property=percentage);
    float       _totalSize   @accessors(property=totalSize);
}

+ (TNDownload)downloadWithIdentifier:(CPString)anIdentifier name:(CPString)aName totalSize:(float)aSize percentage:(float)aPercentage
{
    var dl = [[TNDownload alloc] init];
    [dl setIdentifier:anIdentifier];
    [dl setTotalSize:aSize];
    [dl setName:aName];
    [dl setPercentage:aPercentage];
    
    return dl;
}

- (CPString)percentage
{
    return @"" + _percentage + @"%";
}

@end