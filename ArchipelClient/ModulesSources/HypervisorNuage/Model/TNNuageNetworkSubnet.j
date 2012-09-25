/*
 * TNNuageNetworkSubnet.j
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
    Model for network IP
*/
@implementation TNNuageNetworkSubnet : TNNuageNetworkBase
{
    CPString                        _address        @accessors(property=address);
    CPString                        _netmask        @accessors(property=netmask);
    CPString                        _gateway        @accessors(property=gateway);
}


#pragma mark -
#pragma mark Class Method

+ (TNNuageNetworkSubnet)defaultNetworkSubnet
{
    var IP = [[TNNuageNetworkSubnet alloc] init];

    return IP;
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
        if ([aNode name] != @"subnet")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid subnet"];

        _address    = [aNode valueForAttribute:@"address"];
        _netmask    = [aNode valueForAttribute:@"netmask"];
        _gateway    = [aNode valueForAttribute:@"gateway"];
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
    var node = [TNXMLNode nodeWithName:@"subnet"];

    if (_address)
        [node setValue:_address forAttribute:@"address"];
    if (_netmask)
        [node setValue:_netmask forAttribute:@"netmask"];
    if (_gateway)
        [node setValue:_gateway forAttribute:@"gateway"];

    return node;
}

@end
