/*
 * TNLibvirtNetwork.j
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
@import "TNLibvirtNetworkBridge.j"
@import "TNLibvirtNetworkForward.j"
@import "TNLibvirtNetworkIP.j"

/*! @ingroup hypervisornetworks
    Model for network
*/
@implementation TNLibvirtNetwork : TNLibvirtNetworkBase
{
    CPString                        _name               @accessors(property=name);
    CPString                        _UUID               @accessors(property=UUID);
    TNLibvirtNetworkBridge          _bridge             @accessors(property=bridge);
    TNLibvirtNetworkForward         _forward            @accessors(property=forward);
    TNLibvirtNetworkIP              _IP                 @accessors(property=IP);

    // extended attributes
    BOOL                            _autostart          @accessors(getter=isAutostart, setter=setAutostart:);
    BOOL                            _active             @accessors(property=isActive, setter=setActive:);
}


#pragma mark -
#pragma mark Class Method

+ (TNLibvirtNetwork)defaultNetworkWithName:(CPString)aName UUID:(CPString)anUUID
{
    var network = [[TNLibvirtNetwork alloc] init];

    [network setName:aName];
    [network setUUID:anUUID];

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
        if ([aNode name] != @"network")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid network"];

        _name = [[aNode firstChildWithName:@"name"] text];
        _UUID = [[aNode firstChildWithName:@"uuid"] text];

        if ([aNode firstChildWithName:@"bridge"])
            _bridge = [[TNLibvirtNetworkBridge alloc] initWithXMLNode:[aNode firstChildWithName:@"bridge"]];
        if ([aNode firstChildWithName:@"forward"])
            _forward = [[TNLibvirtNetworkForward alloc] initWithXMLNode:[aNode firstChildWithName:@"forward"]];
        if ([aNode firstChildWithName:@"ip"])
            _IP = [[TNLibvirtNetworkIP alloc] initWithXMLNode:[aNode firstChildWithName:@"ip"]];

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
    if (!_UUID)
        [CPException raise:@"Missing UUID" reason:@"UUID is required"];

    var node = [TNXMLNode nodeWithName:@"network"];

    if (_name)
    {
        [node addChildWithName:@"name"];
        [node addTextNode:_name];
        [node up];
    }

    if (_UUID)
    {
        [node addChildWithName:@"uuid"];
        [node addTextNode:_UUID];
        [node up];
    }

    if (_bridge)
    {
        [node addNode:[_bridge XMLNode]];
        [node up];
    }

    if (_forward)
    {
        [node addNode:[_forward XMLNode]];
        [node up];
    }

    if (_IP)
    {
        [node addNode:[_IP XMLNode]];
        [node up];
    }


    return node;
}

@end