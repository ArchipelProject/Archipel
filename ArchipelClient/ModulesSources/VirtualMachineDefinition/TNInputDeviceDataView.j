/*
 * TNInputDeviceDataView.j
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

@import "../../Views/TNBasicDataView.j"
@import "Model/TNLibvirtDeviceInput.j"

var TNInputDeviceDataViewIconTablet,
    TNInputDeviceDataViewIconMouse;


/*! @ingroup virtualmachinedefinition
    This is a representation of a data view for displaying a input device
*/
@implementation TNInputDeviceDataView : TNBasicDataView
{
    @outlet CPTextField     fieldType;
    @outlet CPTextField     fieldBus;
    @outlet CPTextField     labelType;
    @outlet CPTextField     labelBus;
    @outlet CPImageView     imageIcon;

    TNLibvirtDeviceInput    _currentInputDevice;
}


#pragma mark -
#pragma mark Initialization

+ (void)initialize
{
    var bundle = [CPBundle bundleForClass:TNInputDeviceDataView];

    TNInputDeviceDataViewIconTablet = CPImageInBundle(@"icon-tablet.png", CGSizeMake(26.0, 26.0), bundle);
    TNInputDeviceDataViewIconMouse = CPImageInBundle(@"icon-mouse.png"  , CGSizeMake(26.0, 26.0), bundle);
}


#pragma mark -
#pragma mark Overides

/*! Set the current object Value
    @param anInputDevice the input device to represent
*/
- (void)setObjectValue:(TNLibvirtDeviceInput)anInputDevice
{
    _currentInputDevice = anInputDevice;

    [imageIcon setImage:([_currentInputDevice type] == TNLibvirtDeviceInputTypesTypeTablet) ? TNInputDeviceDataViewIconTablet : TNInputDeviceDataViewIconMouse];
    [fieldType setStringValue:[_currentInputDevice type]];
    [fieldBus setStringValue:[_currentInputDevice bus]];
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
        fieldType = [aCoder decodeObjectForKey:@"fieldType"];
        fieldBus = [aCoder decodeObjectForKey:@"fieldBus"];
        labelType = [aCoder decodeObjectForKey:@"labelType"];
        labelBus = [aCoder decodeObjectForKey:@"labelBus"];
        imageIcon = [aCoder decodeObjectForKey:@"imageIcon"];
    }

    return self;
}

/*! CPCoder compliance
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:fieldType forKey:@"fieldType"];
    [aCoder encodeObject:fieldBus forKey:@"fieldBus"];
    [aCoder encodeObject:labelType forKey:@"labelType"];
    [aCoder encodeObject:labelBus forKey:@"labelBus"];
    [aCoder encodeObject:imageIcon forKey:@"imageIcon"];
}

@end
