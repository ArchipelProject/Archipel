/*
 * TNLibvirtNetworkForward.j
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
@import "TNLibvirtNetworkForwardInterface.j"

TNLibvirtNetworkForwardModeNAT          = @"nat";
TNLibvirtNetworkForwardModeRoute        = @"route";
TNLibvirtNetworkForwardModeBridge       = @"bridge";
TNLibvirtNetworkForwardModePrivate      = @"private";
TNLibvirtNetworkForwardModeVEPA         = @"vepa";
TNLibvirtNetworkForwardModePrivate      = @"private";
TNLibvirtNetworkForwardModePassthrough  = @"passthrough";
TNLibvirtNetworkForwardModeIsolated     = @"isolated";

TNLibvirtNetworkForwardModes            = [ TNLibvirtNetworkForwardModeBridge,
                                            TNLibvirtNetworkForwardModePrivate,
                                            TNLibvirtNetworkForwardModeNAT,
                                            TNLibvirtNetworkForwardModeRoute,
                                            TNLibvirtNetworkForwardModeIsolated];


/*! @ingroup hypervisornetworks
    Model for network forward
*/
@implementation TNLibvirtNetworkForward : TNLibvirtNetworkBase
{
    CPArray     _interfaces     @accessors(property=interfaces);
    CPString    _dev            @accessors(property=dev);
    CPString    _mode           @accessors(property=mode);
}

#pragma mark -
#pragma mark Class Method

+ (TNLibvirtNetworkForward)defaultNetworkForwardWithMode:(CPString)aMode
{
    var forward = [[TNLibvirtNetworkForward alloc] init];

    [forward setMode:aMode];

    return forward;
}

#pragma mark -
#pragma mark Initialization

- (TNLibvirtNetworkForward)init
{
    if (self = [super init])
    {
        _interfaces = [CPArray array];
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
        if ([aNode name] != @"forward")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid forward"];

        _mode       = [aNode valueForAttribute:@"mode"];
        _dev        = [aNode valueForAttribute:@"dev"];
        _interfaces = [CPArray array];

        var interfaceNodes = [aNode ownChildrenWithName:@"interface"];
        for (var i = 0; i < [interfaceNodes count]; i++)
            [_interfaces addObject:[[TNLibvirtNetworkForwardInterface alloc] initWithXMLNode:[interfaceNodes objectAtIndex:i]]];

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
    if (!_mode)
        return;

    var node = [TNXMLNode nodeWithName:@"forward"];

    if (_mode)
    {
        [node setValue:_mode forAttribute:@"mode"];
    }

    if (_dev)
    {
        [node setValue:_dev forAttribute:@"dev"];
    }

    for (var i = 0; i < [_interfaces count]; i++)
    {
        [node addNode:[[_interfaces objectAtIndex:i] XMLNode]];
        [node up];
    }

    return node;
}

@end