/*
 * TNLibvirtDeviceInterfaceBandwidthInbound.j
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


@import "TNLibvirtBase.j"


/*! @ingroup virtualmachinedefinition
    Model for NIC bandwidth inbound
*/
@implementation TNLibvirtDeviceInterfaceBandwidthInbound : TNLibvirtBase
{
    CPString        _average    @accessors(property=average);
    CPString        _burst      @accessors(property=burst);
    CPString        _peak       @accessors(property=peak);
}


#pragma mark -
#pragma mark Class Method

/*! Create a new TNLibvirtBandwidthInbound object
    @param anAverage the value of average
    @param aPeak the value of peak
    @param aBurst the value of burst
*/
+ (TNLibvirtDeviceInterfaceBandwidthInbound)defaultBandwidthInboundWithAverage:(CPString)anAverage peak:(CPString)aPeak burst:(CPString)aBurst
{
    var inbound = [[TNLibvirtDeviceInterfaceBandwidthInbound alloc] init];

    [inbound setAverage:anAverage];
    [inbound setPeak:aPeak];
    [inbound setBurst:aBurst];

    return inbound;
}


#pragma mark -
#pragma mark Initialization

/*! initialize the object with a given XML node
    @param aNode the node to use
*/
- (id)initWithXMLNode:(TNXMLNode)aNode
{
    if (self = [super initWithXMLNode:aNode])
    {
        if ([aNode name] != @"inbound")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid inbound"];

        _average    = [aNode valueForAttribute:@"average"];
        _peak       = [aNode valueForAttribute:@"peak"];
        _burst      = [aNode valueForAttribute:@"burst"];
    }

    return self;
}


#pragma mark -
#pragma mark Generation

/*! return a TNXMLNode representing the object
    @return TNXMLNode
*/
- (TNXMLNode)XMLNode
{
    if (!_average)
        [CPException raise:@"Missing average" reason:@"average is required"];

    var node = [TNXMLNode nodeWithName:@"inbound"];

    if (_average)
        [node setValue:_average forAttribute:@"average"];
    if (_peak)
        [node setValue:_peak forAttribute:@"peak"];
    if (_burst)
        [node setValue:_burst forAttribute:@"burst"];

    return node;
}

@end