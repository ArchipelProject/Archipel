/*
 * TNInterfaceDeviceDataView.j
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

@import "Model/TNLibvirtDeviceInterface.j"
@import "Model/TNLibvirtDeviceInterfaceFilterRef.j"
@import "Model/TNLibvirtDeviceInterfaceSource.j"
@import "Model/TNLibvirtDeviceInterfaceTarget.j"


var TNInterfaceDeviceDataViewIconNetwork,
    TNInterfaceDeviceDataViewIconUser,
    TNInterfaceDeviceDataViewIconBridge;


@implementation TNInterfaceDeviceDataView : TNBasicDataView
{
    @outlet CPImageView         imageIcon;
    @outlet CPTextField         fieldMAC;
    @outlet CPTextField         fieldType;
    @outlet CPTextField         fieldModel;
    @outlet CPTextField         fieldSource;
    @outlet CPTextField         fieldFilter;
    @outlet CPTextField         labelType;
    @outlet CPTextField         labelModel;
    @outlet CPTextField         labelSource;
    @outlet CPTextField         labelFilter;

    TNLibvirtDeviceInterface    _currentInterface;
}


#pragma mark -
#pragma mark Initialization

/*! initialize the data view
*/
- (void)initWithFrame:(CPRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        if (!TNInterfaceDeviceDataViewIconNetwork)
        {
            TNInterfaceDeviceDataViewIconNetwork = [[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:[self class]] pathForResource:@"nic_network.png"]];
            TNInterfaceDeviceDataViewIconUser = [[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:[self class]] pathForResource:@"nic_user.png"]];
            TNInterfaceDeviceDataViewIconBridge = [[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:[self class]] pathForResource:@"nic_bridge.png"]];
        }
    }

    return self;
}


#pragma mark -
#pragma mark Overides

/*! Set the current object Value
    @param aGraphicDevice the disk to represent
*/
- (void)setObjectValue:(TNLibvirtDeviceInterface)anInterface
{
    _currentInterface = anInterface;

    switch ([_currentInterface type])
    {
        case TNLibvirtDeviceInterfaceTypeNetwork:
            [imageIcon setImage:TNInterfaceDeviceDataViewIconNetwork];
            break;
        case TNLibvirtDeviceInterfaceTypeBridge:
            [imageIcon setImage:TNInterfaceDeviceDataViewIconBridge];
            break;
        case TNLibvirtDeviceInterfaceTypeUser:
            [imageIcon setImage:TNInterfaceDeviceDataViewIconUser];
            break;

    }

    [fieldMAC setStringValue:[[_currentInterface MAC] uppercaseString]];
    [fieldType setStringValue:[_currentInterface type]];
    [fieldModel setStringValue:[_currentInterface model]];
    [fieldSource setStringValue:[[_currentInterface source] sourceObject]];
    [fieldFilter setStringValue:[[_currentInterface filterref] name]];
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
        imageIcon = [aCoder decodeObjectForKey:@"imageIcon"];
        fieldMAC = [aCoder decodeObjectForKey:@"fieldMAC"];
        fieldType = [aCoder decodeObjectForKey:@"fieldType"];
        fieldModel = [aCoder decodeObjectForKey:@"fieldModel"];
        fieldSource = [aCoder decodeObjectForKey:@"fieldSource"];
        fieldFilter = [aCoder decodeObjectForKey:@"fieldFilter"];
        labelType = [aCoder decodeObjectForKey:@"labelType"];
        labelModel = [aCoder decodeObjectForKey:@"labelModel"];
        labelSource = [aCoder decodeObjectForKey:@"labelSource"];
        labelFilter = [aCoder decodeObjectForKey:@"labelFilter"];
    }

    return self;
}

/*! CPCoder compliance
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:imageIcon forKey:@"imageIcon"];

    [aCoder encodeObject:fieldMAC forKey:@"fieldMAC"];
    [aCoder encodeObject:fieldType forKey:@"fieldType"];
    [aCoder encodeObject:fieldModel forKey:@"fieldModel"];
    [aCoder encodeObject:fieldSource forKey:@"fieldSource"];
    [aCoder encodeObject:fieldFilter forKey:@"fieldFilter"];
    [aCoder encodeObject:labelType forKey:@"labelType"];
    [aCoder encodeObject:labelModel forKey:@"labelModel"];
    [aCoder encodeObject:labelSource forKey:@"labelSource"];
    [aCoder encodeObject:labelFilter forKey:@"labelFilter"];
}

@end
