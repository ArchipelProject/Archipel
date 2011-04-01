/*
 * CPUserDefault+customDomain.j
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


/*! @ingroup categories
 Groups name are uppercase
*/
@implementation CPUserDefaults (TNKit)

- (CPString)setInteger:(int)aValue forKey:(CPString)aKey inDomain:(CPString)aDomain
{
    if ([aValue respondsToSelector:@selector(intValue)])
        aValue = [aValue intValue];
    [self setObject:parseInt(aValue) forKey:aKey inDomain:aDomain];
}

- (CPString)integerForKey:(int)aKey inDomain:(CPString)aDomain
{
    var value = [self objectForKey:aKey inDomain:aDomain];
    if (value === nil)
        return 0;

    if ([value respondsToSelector:@selector(intValue)])
        value = [value intValue];

    return parseInt(value);
}

- (void)setBool:(BOOL)aValue forKey:(CPString)aKey inDomain:(CPString)aDomain
{
    if ([aValue respondsToSelector:@selector(boolValue)])
        [self setObject:[aValue boolValue] forKey:aKey inDomain:aDomain];
}

- (BOOL)boolForKey:(CPString)aKey inDomain:(CPString)aDomain
{
    var value = [self objectForKey:aKey inDomain:aDomain];
    if ([value respondsToSelector:@selector(boolValue)])
        return [value boolValue];

    return NO;
}


@end