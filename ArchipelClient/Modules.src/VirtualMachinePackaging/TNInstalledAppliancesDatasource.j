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
}

+ (TNInstalledAppliance)InstalledApplianceWithName:(CPString)aName UUID:(CPString)anUUID path:(CPString)aPath comment:(CPString)aComment
{
    var appliance = [[TNInstalledAppliance alloc] init];
    [appliance setName:aName];
    [appliance setPath:aPath];
    [appliance setUUID:anUUID];
    [appliance setComment:aComment];
    
    return appliance;
}

- (CPString)description
{
    return [self name];
}

@end


@implementation TNInstalledAppliancesDatasource : CPObject
{
    CPArray _content @accessors(getter=content);
}

- (id)init
{
    if (self = [super init])
    {
        _content = [CPArray array];
    }
    return self;
}

- (void)addInstalledAppliance:(TNInstalledAppliance)anInstalledAppliance
{
    [_content addObject:anInstalledAppliance];
}

// Datasource impl.
- (CPNumber)numberOfRowsInTableView:(CPTableView)aTable
{
    return [_content count];
}

- (id)tableView:(CPTableView)aTable objectValueForTableColumn:(CPNumber)aCol row:(CPNumber)aRow
{
    var identifier = [aCol identifier];

    return [[_content objectAtIndex:aRow] valueForKey:identifier];
}
@end