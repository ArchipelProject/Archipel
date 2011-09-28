/*
 * TNLibvirtNetworkIPDHCP.j
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
@import "TNLibvirtNetworkIPDHCPHost.j"
@import "TNLibvirtNetworkIPDHCPRange.j"


/*! @ingroup hypervisornetworks
    Model for network IP DHCP
*/
@implementation TNLibvirtNetworkIPDHCP : TNLibvirtNetworkBase
{
    CPArray     _hosts          @accessors(property=hosts);
    CPArray     _ranges         @accessors(property=ranges);
}

#pragma mark -
#pragma mark Class Method

+ (TNLibvirtNetworkIPDHCP)defaultNetworkIPDHCP
{
    var dhcp = [[TNLibvirtNetworkIPDHCP alloc] init];

    return dhcp;
}

#pragma mark -
#pragma mark Initialization

- (TNLibvirtNetworkBridge)init
{
    if (self = [super init])
    {
        _ranges = [CPArray array];
        _hosts  = [CPArray array];
    }

    return self;
}

/*! initialize the object with a given XML node
    @param aNode the node to use
*/
- (id)initWithXMLNode:(TNXMLNode)aNode
{
    if (self = [super initWithXMLNode:aNode])
    {
        if ([aNode name] != @"dhcp")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid dhcp"];

        _ranges = [CPArray array];
        _hosts  = [CPArray array];

        var rangesNodes = [aNode ownChildrenWithName:@"range"];
        for (var i = 0; i < [rangesNodes count]; i++)
            [_ranges addObject:[[TNLibvirtNetworkIPDHCPRange alloc] initWithXMLNode:[rangesNodes objectAtIndex:i]]];

        var hostsNodes = [aNode ownChildrenWithName:@"host"];
        for (var i = 0; i < [hostsNodes count]; i++)
            [_hosts addObject:[[TNLibvirtNetworkIPDHCPHost alloc] initWithXMLNode:[hostsNodes objectAtIndex:i]]];
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
    var node = [TNXMLNode nodeWithName:@"dhcp"];

    if ([_ranges count] == 0 && [_hosts count] == 0)
        return;

    for (var i = 0; i < [_ranges count]; i++)
    {
        [node addNode:[[_ranges objectAtIndex:i] XMLNode]];
        [node up];
    }

    for (var i = 0; i < [_hosts count]; i++)
    {
        [node addNode:[[_hosts objectAtIndex:i] XMLNode]];
        [node up];
    }

    return node;
}

@end