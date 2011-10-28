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

TNArchipelApplianceStatusInstalled  = @"installed";
TNArchipelApplianceStatusInstalling = @"installing";
TNArchipelApplianceStatusNone       = @"none";

var TNInstalledApplianceIconUsed,
    TNInstalledApplianceIconInstalling,
    TNInstalledApplianceIconNone;


/*! @ingroup virtualmachinepackaging
    represent an installed appliance
*/
@implementation TNInstalledAppliance : CPObject
{
    CPString    _comment        @accessors(property=comment);
    CPString    _name           @accessors(property=name);
    CPString    _path           @accessors(property=path);
    CPString    _status         @accessors(setter=setStatus:, getter=statusString);
    CPString    _UUID           @accessors(property=UUID);
}

#pragma mark -
#pragma mark  Initialization

+ (void)initialize
{
    var bundle = [CPBundle mainBundle];
    TNInstalledApplianceIconUsed       = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"IconsButtons/check.png"] size:CPSizeMake(12, 12)];
    TNInstalledApplianceIconInstalling = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"spinner.gif"] size:CPSizeMake(16, 16)];
    TNInstalledApplianceIconNone       = nil;

}

/*! initialize and return a TNInstalledAppliance with given values
    @param aName the name of the appliance
    @param anUUID the UUID of the appliance
    @param aPath the path of the appliance
    @param aComment the comment of the appliance
    @param aStatus the stats of the appliance
    @return initialized instance of TNInstalledAppliance
*/
+ (TNInstalledAppliance)InstalledApplianceWithName:(CPString)aName UUID:(CPString)anUUID path:(CPString)aPath comment:(CPString)aComment status:(CPString)aStatus
{
    var appliance = [[TNInstalledAppliance alloc] init];
    [appliance setName:aName];
    [appliance setPath:aPath];
    [appliance setUUID:anUUID];
    [appliance setStatus:aStatus];
    [appliance setComment:aComment];

    return appliance;
}


#pragma mark -
#pragma mark Accessors

- (CPImage)status
{
    if (_status == TNArchipelApplianceStatusInstalled)
        return TNInstalledApplianceIconUsed;
    else if (_status == TNArchipelApplianceStatusInstalling)
        return TNInstalledApplianceIconInstalling;
    else
        return TNInstalledApplianceIconNone;
}

- (CPString)description
{
    return _name;
}

@end


