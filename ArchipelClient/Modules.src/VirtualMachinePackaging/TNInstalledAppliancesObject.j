/*  
 * TNInstalledAppliancesDatasource.j
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

TNArchipelApplianceInstalled            = 1;

@implementation TNInstalledAppliance : CPObject
{
    CPString    name            @accessors;
    CPString    path            @accessors;
    CPString    comment         @accessors;
    CPString    UUID            @accessors;
    BOOL        _used           @accessors(getter=isUsed,setter=setUsed:);
    
    CPImage     _usedIcon;
}

+ (TNInstalledAppliance)InstalledApplianceWithName:(CPString)aName UUID:(CPString)anUUID path:(CPString)aPath comment:(CPString)aComment used:(BOOL)inUse
{
    var appliance = [[TNInstalledAppliance alloc] init];
    [appliance setName:aName];
    [appliance setPath:aPath];
    [appliance setUUID:anUUID];
    [appliance setUsed:inUse];
    [appliance setComment:aComment];
    
    return appliance;
}

- (id)init
{
    if (self = [super init])
    {
        var bundle = [CPBundle bundleForClass:[self class]];
        _usedIcon = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"used.png"]];
    }
    
    return self
}

- (CPImage)isUsed
{
    if (_used)
    {
        return _usedIcon
    }
    else
    {
        return [[CPImage alloc] init];
    }
}

- (CPString)description
{
    return [self name];
}

@end


