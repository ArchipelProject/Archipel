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

/*! @ingroup virtualmachinedefinition
    this object represent a virtual drive
*/
@implementation TNDrive : CPObject
{
    CPString _bus       @accessors(property=bus);
    CPString _cache     @accessors(property=cache);
    CPString _device    @accessors(property=device);
    CPString _source    @accessors(property=source);
    CPString _target    @accessors(property=target);
    CPString _type      @accessors(property=type);
}


#pragma mark -
#pragma mark Initialization

/*! initializes and returns TNDrive with given values
    @param aType the drive type
    @param aDevice the drive device
    @param aSource the drive source
    @param aTarget the drive target
    @param aBus the drive bus
    @return initialized TNDrive
*/
+ (TNDrive)driveWithType:(CPString)aType device:(CPString)aDevice source:(CPString)aSource target:(CPString)aTarget bus:(CPString)aBus cache:(CPString)aCacheMode
{
    var drive = [[TNDrive alloc] init];
    [drive setType:aType];
    [drive setDevice:aDevice];
    [drive setSource:aSource];
    [drive setTarget:aTarget];
    [drive setBus:aBus];
    [drive setCache:aCacheMode];

    return drive;
}

@end