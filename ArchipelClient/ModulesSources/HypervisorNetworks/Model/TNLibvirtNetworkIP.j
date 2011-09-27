/*
 * TNLibvirtNetworkIP.j
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
@import "TNLibvirtNetworkIPDHCP.j"
@import "TNLibvirtNetworkIPTFTP.j"


/*! @ingroup hypervisornetworks
    Model for network IP
*/
@implementation TNLibvirtNetworkIP : TNLibvirtNetworkBase
{
    CPString                        _address        @accessors(property=address);
    CPString                        _netmask        @accessors(property=netmask);
    CPString                        _prefix         @accessors(property=prefix);
    CPString                        _family         @accessors(property=family);

    TNLibvirtNetworkIPDHCP          _DHCP           @accessors(property=DHCP);
    TNLibvirtNetworkIPTFTP          _TFTP           @accessors(property=TFTP);
}


#pragma mark -
#pragma mark Class Method

+ (TNLibvirtNetworkIP)defaultNetworkIPWithAddress:(CPString)anAddress
{
    var IP = [[TNLibvirtNetworkIP alloc] init];

    [IP setAddress:anAddress];

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
        if ([aNode name] != @"ip")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid IP"];

        _address    = [aNode valueForAttribute:@"address"];
        _netmask    = [aNode valueForAttribute:@"netmask"];
        _prefix     = [aNode valueForAttribute:@"prefix"];
        _family     = [aNode valueForAttribute:@"family"];

        if ([aNode containsChildrenWithName:@"dhcp"])
            _DHCP = [[TNLibvirtNetworkIPDHCP alloc] initWithXMLNode:[aNode firstChildWithName:@"dhcp"]];

        if ([aNode containsChildrenWithName:@"tftp"])
            _TFTP = [[TNLibvirtNetworkIPTFTP alloc] initWithXMLNode:[aNode firstChildWithName:@"tftp"]];

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
    if (!_address)
        [CPException raise:@"Missing address" reason:@"address is required"];

    var node = [TNXMLNode nodeWithName:@"ip"];

    if (_address)
        [node setValue:_address forAttribute:@"address"];
    if (_netmask)
        [node setValue:_netmask forAttribute:@"netmask"];
    if (_prefix)
        [node setValue:_prefix forAttribute:@"prefix"];
    if (_family)
        [node setValue:_family forAttribute:@"family"];

    if (_DHCP)
    {
        [node addNode:[_DHCP XMLNode]];
        [node up];
    }

    if (_TFTP)
    {
        [node addNode:[_TFTP XMLNode]];
        [node up];
    }

    return node;
}

@end