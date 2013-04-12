/*
 * TNGraphicDeviceDataView.j
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
@import "Model/TNLibvirtDeviceGraphic.j"

var TNGraphicDeviceDataViewIconVNC,
    TNGraphicDeviceDataViewIconRDP,
    TNGraphicDeviceDataViewIconSPICE;


/*! @ingroup virtualmachinedefinition
    This is a representation of a data view for displaying a graphic device
*/
@implementation TNGraphicDeviceDataView : TNBasicDataView
{
    @outlet CPImageView     imageIcon;
    @outlet CPTextField     fieldKeymap;
    @outlet CPTextField     fieldListen;
    @outlet CPTextField     fieldPassword;
    @outlet CPTextField     labelKeymap;
    @outlet CPTextField     labelListen;
    @outlet CPTextField     labelPassword;

    TNLibvirtDeviceGraphic  _currentGraphicDevice;
}


#pragma mark -
#pragma mark Initialization

+ (void)initialize
{
    var bundle = [CPBundle bundleForClass:TNGraphicDeviceDataView];

    TNGraphicDeviceDataViewIconVNC   = CPImageInBundle(@"icon-vnc.png",   CGSizeMake(26.0, 26.0), bundle);
    TNGraphicDeviceDataViewIconRDP   = CPImageInBundle(@"icon-rdp.png",   CGSizeMake(26.0, 26.0), bundle);
    TNGraphicDeviceDataViewIconSPICE = CPImageInBundle(@"icon-spice.png", CGSizeMake(26.0, 26.0), bundle);
}


#pragma mark -
#pragma mark Overides

/*! Set the current object Value
    @param aGraphicDevice the graphic device to represent
*/
- (void)setObjectValue:(TNLibvirtDeviceGraphic)aGraphicDevice
{
    _currentGraphicDevice = aGraphicDevice;

    var listenString = @"";

    listenString += ([_currentGraphicDevice listen] && ([_currentGraphicDevice listen] != @"")) ? [_currentGraphicDevice listen] : @"auto";
    listenString += @":";
    listenString += ([_currentGraphicDevice port] && ([_currentGraphicDevice port] != @"-1")) ? [_currentGraphicDevice port] : @"auto";

    switch ([_currentGraphicDevice type])
    {
        case TNLibvirtDeviceGraphicTypeVNC:
            [imageIcon setImage:TNGraphicDeviceDataViewIconVNC];
            break;
        case TNLibvirtDeviceGraphicTypeRDP:
            [imageIcon setImage:TNGraphicDeviceDataViewIconRDP];
            break;
        case TNLibvirtDeviceGraphicTypeSPICE:
            [imageIcon setImage:TNGraphicDeviceDataViewIconSPICE];
            break;
    }

    [fieldKeymap setStringValue:[_currentGraphicDevice keymap]];
    [fieldListen setStringValue:listenString];
    [fieldPassword setStringValue:([_currentGraphicDevice password]) ? @"Protected" : @"Not protected"];
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
        fieldKeymap = [aCoder decodeObjectForKey:@"fieldKeymap"];
        fieldListen = [aCoder decodeObjectForKey:@"fieldListen"];
        fieldPassword = [aCoder decodeObjectForKey:@"fieldPassword"];
        labelKeymap = [aCoder decodeObjectForKey:@"labelKeymap"];
        labelListen = [aCoder decodeObjectForKey:@"labelListen"];
        labelPassword = [aCoder decodeObjectForKey:@"labelPassword"];
        imageIcon = [aCoder decodeObjectForKey:@"imageIcon"];
    }

    return self;
}

/*! CPCoder compliance
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:fieldKeymap forKey:@"fieldKeymap"];
    [aCoder encodeObject:fieldListen forKey:@"fieldListen"];
    [aCoder encodeObject:fieldPassword forKey:@"fieldPassword"];
    [aCoder encodeObject:labelKeymap forKey:@"labelKeymap"];
    [aCoder encodeObject:labelListen forKey:@"labelListen"];
    [aCoder encodeObject:labelPassword forKey:@"labelPassword"];
    [aCoder encodeObject:imageIcon forKey:@"imageIcon"];
}

@end
