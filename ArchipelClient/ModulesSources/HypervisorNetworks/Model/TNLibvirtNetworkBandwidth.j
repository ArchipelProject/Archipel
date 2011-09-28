/*
 * TNLibvirtNetworkBandwidth.j
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


@import "TNLibvirtNetworkBase.j"
@import "TNLibvirtNetworkBandwidthInbound.j"
@import "TNLibvirtNetworkBandwidthOutbound.j"


/*! @ingroup hypervisornetworks
    Model for network bandwidth
*/
@implementation TNLibvirtNetworkBandwidth : TNLibvirtNetworkBase
{
    TNLibvirtNetworkBandwidthInbound    _inbound   @accessors(property=inbound);
    TNLibvirtNetworkBandwidthOutbound   _outbound   @accessors(property=outbound);
}

#pragma mark -
#pragma mark Class Method

+ (TNLibvirtNetworkBandwidth)defaultNetworkBandwidth
{
    var bandwidth = [[TNLibvirtNetworkBandwidth alloc] init];

    return bandwidth;
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
        if ([aNode name] != @"bandwidth")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid bandwidth"];

        if ([aNode containsChildrenWithName:@"inbound"])
            _inbound = [[TNLibvirtNetworkBandwidthInbound alloc] initWithXMLNode:[aNode firstChildWithName:@"inbound"]];
        if ([aNode containsChildrenWithName:@"outbound"])
            _outbound = [[TNLibvirtNetworkBandwidthOutbound alloc] initWithXMLNode:[aNode firstChildWithName:@"outbound"]];
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
    var node = [TNXMLNode nodeWithName:@"bandwidth"];

    if (_inbound)
    {
        [node addNode:[_inbound XMLNode]];
        [node up];
    }

    if (_outbound)
    {
        [node addNode:[_outbound XMLNode]];
        [node up];
    }

    return node;
}

@end