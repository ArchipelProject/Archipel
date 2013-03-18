/*
 * TNNuageNetworkBandwidthOutbound.j
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

@import "TNNuageNetworkBase.j"


/*! @ingroup hypervisornetworks
    Model for network bandwidth outbound
*/
@implementation TNNuageNetworkBandwidthOutbound : TNNuageNetworkBase
{
    CPString        _burst      @accessors(property=burst);
    CPString        _peak       @accessors(property=peak);
}


#pragma mark -
#pragma mark Class Method

/*! Create a new TNNuageNetworkBandwidthOutbound object
    @param aPeak the value of peak
    @param aBurst the value of burst
*/
+ (TNNuageNetworkBandwidthOutbound)defaultNetworkBandwidthOutboundWithPeak:(CPString)aPeak burst:(CPString)aBurst
{
    var outbound = [[TNNuageNetworkBandwidthOutbound alloc] init];

    [outbound setPeak:aPeak];
    [outbound setBurst:aBurst];

    return outbound;
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
        if ([aNode name] != @"outbound")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid outbound"];

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
    var node = [TNXMLNode nodeWithName:@"outbound"];

    if (_peak)
        [node setValue:_peak forAttribute:@"peak"];
    if (_burst)
        [node setValue:_burst forAttribute:@"burst"];

    return node;
}

@end
