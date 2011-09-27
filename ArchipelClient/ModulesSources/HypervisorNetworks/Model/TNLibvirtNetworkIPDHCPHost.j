/*
 * TNLibvirtNetworkIPDHCPHost.j
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


/*! @ingroup hypervisornetworks
    Model for network IP DHC Host
*/
@implementation TNLibvirtNetworkIPDHCPHost : TNLibvirtNetworkBase
{
    CPString        _MAC        @accessors(property=mac);
    CPString        _name       @accessors(property=name);
    CPString        _IP         @accessors(property=IP);
}


#pragma mark -
#pragma mark Class Method

+ (TNLibvirtNetworkIPDHCPHost)defaultNetworkDHCPHostWithName:(CPString)aName MAC:(CPString)aMAC IP:(CPString)anIP
{
    var host = [[TNLibvirtNetworkIPDHCPHost alloc] init];

    [host setName:aName];
    [host setMac:aMAC];
    [host setIP:anIP];

    return host;
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
        if ([aNode name] != @"host")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid host"];

        _name   = [aNode valueForAttribute:@"name"];
        _MAC    = [aNode valueForAttribute:@"mac"];
        _IP     = [aNode valueForAttribute:@"ip"];
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
    if (!_IP)
        [CPException raise:@"Missing IP" reason:@"IP is required"];
    if (!_MAC)
        [CPException raise:@"Missing mac" reason:@"Mac is required"];
    if (!_name)
        [CPException raise:@"Missing name" reason:@"name is required"];

    var node = [TNXMLNode nodeWithName:@"host"];

    if (_name)
        [node setValue:_name forAttribute:@"name"];
    if (_MAC)
        [node setValue:_MAC forAttribute:@"mac"];
    if (_IP)
        [node setValue:_IP forAttribute:@"ip"];

    return node;
}

@end