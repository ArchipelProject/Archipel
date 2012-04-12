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
    TNInterfaceDeviceDataViewIconNuage,
    TNInterfaceDeviceDataViewIconUser,
    TNInterfaceDeviceDataViewIconBridge,
    TNInterfaceDeviceDataViewIconDirect;


/*! @ingroup virtualmachinedefinition
    This is a representation of a data view for displaying a interface device
*/
@implementation TNInterfaceDeviceDataView : TNBasicDataView
{
    @outlet CPImageView         imageIcon;
    @outlet CPTextField         fieldFilter;
    @outlet CPTextField         fieldInLimit;
    @outlet CPTextField         fieldMAC;
    @outlet CPTextField         fieldModel;
    @outlet CPTextField         fieldOutLimit;
    @outlet CPTextField         fieldSource;
    @outlet CPTextField         fieldType;
    @outlet CPTextField         labelFilter;
    @outlet CPTextField         labelInLimit;
    @outlet CPTextField         labelModel;
    @outlet CPTextField         labelOutLimit;
    @outlet CPTextField         labelSource;
    @outlet CPTextField         labelType;

    TNLibvirtDeviceInterface    _currentInterface;
}


#pragma mark -
#pragma mark Initialization

/*! initialize the graphics
*/
+ (void)initialize
{
    var bundle = [CPBundle bundleForClass:TNInterfaceDeviceDataView];

    TNInterfaceDeviceDataViewIconNetwork = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"nic_network.png"]];
    TNInterfaceDeviceDataViewIconUser = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"nic_user.png"]];
    TNInterfaceDeviceDataViewIconBridge = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"nic_bridge.png"]];
    TNInterfaceDeviceDataViewIconDirect = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"nic_direct.png"]];
    TNInterfaceDeviceDataViewIconNuage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"nic_nuage.png"]];
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
        case TNLibvirtDeviceInterfaceTypeNuage:
            [imageIcon setImage:TNInterfaceDeviceDataViewIconNuage];
            break;
        case TNLibvirtDeviceInterfaceTypeNetwork:
            [imageIcon setImage:TNInterfaceDeviceDataViewIconNetwork];
            break;
        case TNLibvirtDeviceInterfaceTypeBridge:
            [imageIcon setImage:TNInterfaceDeviceDataViewIconBridge];
            break;
        case TNLibvirtDeviceInterfaceTypeUser:
            [imageIcon setImage:TNInterfaceDeviceDataViewIconUser];
            break;
        case TNLibvirtDeviceInterfaceTypeDirect:
            [imageIcon setImage:TNInterfaceDeviceDataViewIconDirect];
            break;
    }

    [fieldMAC setStringValue:[[_currentInterface MAC] uppercaseString]];
    if ([_currentInterface type] == TNLibvirtDeviceInterfaceTypeNuage)
        [fieldType setStringValue:[[_currentInterface type] capitalizedString] + @" (" + [_currentInterface nuageNetworkName] + ")"];
    else
        [fieldType setStringValue:[_currentInterface type]];
    [fieldModel setStringValue:[_currentInterface model]];
    [fieldSource setStringValue:[[_currentInterface source] sourceObject]];
    [fieldFilter setStringValue:[[_currentInterface filterref] name] || @"None"];

    [fieldInLimit setHidden:YES];
    [labelInLimit setHidden:YES];
    if ([[_currentInterface bandwidth] inbound])
    {
        var average = [[[_currentInterface bandwidth] inbound] average] || @"None",
            peak = [[[_currentInterface bandwidth] inbound] peak] || @"None",
            burst = [[[_currentInterface bandwidth] inbound] burst] || @"None";
        [fieldInLimit setStringValue:[CPString stringWithFormat:@"%s/%s/%s", average, peak, burst]];
        [fieldInLimit setHidden:NO];
        [labelInLimit setHidden:NO];
    }

    [fieldOutLimit setHidden:YES];
    [labelOutLimit setHidden:YES];
    if ([[_currentInterface bandwidth] outbound])
    {
        var average = [[[_currentInterface bandwidth] outbound] average] || @"None",
            peak = [[[_currentInterface bandwidth] outbound] peak] || @"None",
            burst = [[[_currentInterface bandwidth] outbound] burst] || @"None";
        [fieldOutLimit setStringValue:[CPString stringWithFormat:@"%s/%s/%s", average, peak, burst]];
        [fieldOutLimit setHidden:NO];
        [labelOutLimit setHidden:NO];
    }
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
        fieldFilter = [aCoder decodeObjectForKey:@"fieldFilter"];
        fieldInLimit = [aCoder decodeObjectForKey:@"fieldInLimit"];
        fieldMAC = [aCoder decodeObjectForKey:@"fieldMAC"];
        fieldModel = [aCoder decodeObjectForKey:@"fieldModel"];
        fieldOutLimit = [aCoder decodeObjectForKey:@"fieldOutLimit"];
        fieldSource = [aCoder decodeObjectForKey:@"fieldSource"];
        fieldType = [aCoder decodeObjectForKey:@"fieldType"];
        labelFilter = [aCoder decodeObjectForKey:@"labelFilter"];
        labelInLimit = [aCoder decodeObjectForKey:@"labelInLimit"];
        labelModel = [aCoder decodeObjectForKey:@"labelModel"];
        labelOutLimit = [aCoder decodeObjectForKey:@"labelOutLimit"];
        labelSource = [aCoder decodeObjectForKey:@"labelSource"];
        labelType = [aCoder decodeObjectForKey:@"labelType"];
    }

    return self;
}

/*! CPCoder compliance
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:imageIcon forKey:@"imageIcon"];

    [aCoder encodeObject:fieldFilter forKey:@"fieldFilter"];
    [aCoder encodeObject:fieldInLimit forKey:@"fieldInLimit"];
    [aCoder encodeObject:fieldMAC forKey:@"fieldMAC"];
    [aCoder encodeObject:fieldModel forKey:@"fieldModel"];
    [aCoder encodeObject:fieldOutLimit forKey:@"fieldOutLimit"];
    [aCoder encodeObject:fieldSource forKey:@"fieldSource"];
    [aCoder encodeObject:fieldType forKey:@"fieldType"];
    [aCoder encodeObject:labelFilter forKey:@"labelFilter"];
    [aCoder encodeObject:labelInLimit forKey:@"labelInLimit"];
    [aCoder encodeObject:labelModel forKey:@"labelModel"];
    [aCoder encodeObject:labelOutLimit forKey:@"labelOutLimit"];
    [aCoder encodeObject:labelSource forKey:@"labelSource"];
    [aCoder encodeObject:labelType forKey:@"labelType"];
}

@end
