/*
 * TNLibvirtNetworkBridge.j
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
    Model for network bridge
*/
@implementation TNLibvirtNetworkBridge : TNLibvirtNetworkBase
{
    CPString        _name           @accessors(property=name);
    BOOL            _stp            @accessors(getter=isSTPEnabled, setter=setEnableSTP:);
    CPString        _delay          @accessors(property=delay);
}


#pragma mark -
#pragma mark Class Method

+ (TNLibvirtNetworkBridge)defaultNetworkBridgeWithName:(CPString)aName
{
    var bridge = [[TNLibvirtNetworkBridge alloc] init];

    [bridge setName:aName];

    return bridge;
}


#pragma mark -
#pragma mark Initialization

- (TNLibvirtNetworkBridge)init
{
    if (self = [super init])
    {
        _stp = NO;
        _delay = @"0";
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
        if ([aNode name] != @"bridge")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid bridge"];

        _name   = [aNode valueForAttribute:@"name"];
        _stp    = ([aNode valueForAttribute:@"stp"] == "on");
        _delay  = [aNode valueForAttribute:@"delay"];
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

    var node = [TNXMLNode nodeWithName:@"bridge"];

    if (_name)
        [node setValue:_name forAttribute:@"name"];
    if (_stp)
        [node setValue:_stp ? @"on" : @"off" forAttribute:@"stp"];
    if (_delay)
        [node setValue:_delay forAttribute:@"delay"];

    return node;
}

@end