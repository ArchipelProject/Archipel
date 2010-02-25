/*  
 * TNDatasourceDrives.j
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
@import <AppKit/AppKit.j>

@implementation TNDrive : CPObject
{
    CPString type      @accessors;
    CPString device    @accessors;
    CPString source    @accessors;
    CPString target    @accessors;
    CPString bus       @accessors;
}

+ (TNDrive)driveWithType:(CPString)aType device:(CPString)aDevice source:(CPString)aSource target:(CPString)aTarget bus:(CPString)aBus
{
    var drive = [[TNDrive alloc] init];
    [drive setType:aType];
    [drive setDevice:aDevice];
    [drive setSource:aSource];
    [drive setTarget:aTarget];
    [drive setBus:aBus];
    
    return drive;
}
@end

@implementation TNDatasourceDrives : CPObject
{
    CPArray drives @accessors;
}

- (id)init
{
    if (self = [super init])
    {
        [self setDrives:[[CPArray alloc] init]];
    }
    return self;
}

- (void)addDrive:(TNDrive)aDrive
{
    [[self drives] addObject:aDrive];
}

- (CPNumber)numberOfRowsInTableView:(CPTableView)aTable 
{
    return [[self drives] count];
}

- (id)tableView:(CPTableView)aTable objectValueForTableColumn:(CPNumber)aCol row:(CPNumber)aRow
{
    var identifier = [aCol identifier];

    return [[[self drives] objectAtIndex:aRow] valueForKey:identifier];
}
@end