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

@implementation TNInstalledAppliance : CPObject
{
    CPString    name            @accessors;
    CPString    path            @accessors;
    CPString    comment         @accessors;
    CPString    UUID            @accessors;
    CPString    _status         @accessors(setter=setStatus:, getter=statusString);
    
    CPImage     _usedIcon;
    CPImage     _installingIcon;
    CPImage     _noneIcon;
}

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

- (id)init
{
    if (self = [super init])
    {
        var bundle      = [CPBundle mainBundle];
        _usedIcon       = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"button-icons/button-icon-check.png"] size:CPSizeMake(16, 16)];
        _installingIcon = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"spinner.gif"] size:CPSizeMake(16, 16)];
        _noneIcon       = nil;//[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"button-icons/button-icon-cancel.png"] size:CPSizeMake(16, 16)];
    }
    
    return self
}

- (CPImage)status
{
    if (_status == TNArchipelApplianceStatusInstalled)
        return _usedIcon;
    else if (_status == TNArchipelApplianceStatusInstalling)
        return _installingIcon;
    else
        return _noneIcon;
}

- (CPString)description
{
    return [self name];
}

@end


