/*
 * TNCharacterDeviceDataView.j
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

@import "Model/TNLibvirtDeviceCharacter.j"

var TNGraphicDeviceDataViewIconVNC,
    TNGraphicDeviceDataViewIconRDP,
    TNGraphicDeviceDataViewIconSPICE;

@implementation TNCharacterDeviceDataView : TNBasicDataView
{
    TNLibvirtDeviceCharacter    _currentCharacterDevice;
}


#pragma mark -
#pragma mark Initialization

+ (void)initialize
{
    // pass
}

#pragma mark -
#pragma mark Overides

/*! Set the current object Value
    @param aGraphicDevice the graphic device to represent
*/
- (void)setObjectValue:(TNLibvirtDeviceCharacter)aCharacterDevice
{
    _currentCharacterDevice = aCharacterDevice;
}


#pragma mark -
#pragma mark CPCoding

/*! CPCoder compliance
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        // imageIcon = [aCoder decodeObjectForKey:@"imageIcon"];
    }

    return self;
}

/*! CPCoder compliance
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    // [aCoder encodeObject:fieldKeymap forKey:@"fieldKeymap"];
}

@end