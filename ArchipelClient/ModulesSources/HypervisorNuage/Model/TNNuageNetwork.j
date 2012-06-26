/*
 * TNNuageNetwork.j
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
@import "TNNuageNetworkIP.j"

TNNuageNetworkTypeIPV4  = @"ipv4";
TNNuageNetworkTypeIPV6  = @"ipv6";

TNNuageNetworkTypes     = [TNNuageNetworkTypeIPV4, TNNuageNetworkTypeIPV6];

/*! @ingroup hypervisornetworks
    Model for network
*/
@implementation TNNuageNetwork : TNNuageNetworkBase
{
    CPString                    _name               @accessors(property=name);
    CPString                    _type               @accessors(property=type);
    CPString                    _domain             @accessors(property=domain);
    CPString                    _zone               @accessors(property=zone);
    TNNuageNetworkBandwidth     _bandwidth          @accessors(property=bandwidth);
    TNNuageNetworkIP            _IP                 @accessors(property=IP);
}


#pragma mark -
#pragma mark Class Method

+ (TNNuageNetwork)defaultNetworkWithName:(CPString)aName type:(CPString)aType
{
    var network = [[TNNuageNetwork alloc] init];

    [network setName:aName];
    [network setType:aType];

    return network;
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
        if ([aNode name] != @"nuage_network")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid nuage_network"];

        _name   = [aNode valueForAttribute:@"name"];
        _type   = [aNode valueForAttribute:@"type"];
        _domain = [aNode valueForAttribute:@"domain"];
        _zone   = [aNode valueForAttribute:@"zone"];

        if ([aNode firstChildWithName:@"ip"])
            _IP = [[TNNuageNetworkIP alloc] initWithXMLNode:[aNode firstChildWithName:@"ip"]];
        if ([aNode firstChildWithName:@"bandwidth"])
            _bandwidth = [[TNNuageNetworkBandwidth alloc] initWithXMLNode:[aNode firstChildWithName:@"bandwidth"]];
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
    if (!_name)
        [CPException raise:@"Missing name" reason:@"name is required"];
    if (!_type)
        [CPException raise:@"Missing type" reason:@"type is required"];
    if (!_domain)
        [CPException raise:@"Missing domain" reason:@"domain is required"];
    if (!_zone)
        [CPException raise:@"Missing zone" reason:@"zone is required"];

    var node = [TNXMLNode nodeWithName:@"nuage_network" andAttributes:{"name": _name, "type": _type, "domain": _domain, "zone": _zone}];

    if (_IP)
    {
        [node addNode:[_IP XMLNode]];
        [node up];
    }

    if (_bandwidth)
    {
        [node addNode:[_bandwidth XMLNode]];
        [node up];
    }

    return node;
}

@end
