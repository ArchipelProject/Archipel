/*
 * TNLibvirtDevices.j
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

@import <Foundation/Foundation.j>
@import <StropheCappuccino/TNXMLNode.j>

@import "TNLibvirtBase.j";


/*! @ingroup virtualmachinedefinition
    Model for devices
*/
@implementation TNLibvirtDevices : TNLibvirtBase
{
    CPArray     _disks          @accessors(property=disks);
    CPArray     _graphics       @accessors(property=graphics);
    CPArray     _inputs         @accessors(property=inputs);
    CPArray     _interfaces     @accessors(property=interfaces);
    CPString    _emulator       @accessors(property=emulator);
}


#pragma mark -
#pragma mark Initialization

- (TNLibvirtDevices)init
{
    if (self = [super init])
    {
        _disks      = [CPArray array];
        _graphics   = [CPArray array];
        _inputs     = [CPArray array];
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
        if ([aNode name] != @"devices")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid devices"];

        _emulator   = [[aNode firstChildWithName:@"emulator"] text];
        _disks      = [CPArray array];
        _graphics   = [CPArray array];
        _inputs     = [CPArray array];
        _interfaces = [CPArray array];

        var diskNodes = [aNode ownChildrenWithName:@"disk"];
        for (var i = 0; i < [diskNodes count]; i++)
            [_disks addObject:[[TNLibvirtDeviceDisk alloc] initWithXMLNode:[diskNodes objectAtIndex:i]]];

        var interfaceNodes = [aNode ownChildrenWithName:@"interface"];
        for (var i = 0; i < [interfaceNodes count]; i++)
            [_interfaces addObject:[[TNLibvirtDeviceInterface alloc] initWithXMLNode:[interfaceNodes objectAtIndex:i]]];

        var graphicNodes = [aNode ownChildrenWithName:@"graphics"];
        for (var i = 0; i < [graphicNodes count]; i++)
            [_graphics addObject:[[TNLibvirtDeviceGraphics alloc] initWithXMLNode:[graphicNodes objectAtIndex:i]]];

        var inputNodes = [aNode ownChildrenWithName:@"input"];
        for (var i = 0; i < [inputNodes count]; i++)
            [_inputs addObject:[[TNLibvirtDeviceInput alloc] initWithXMLNode:[inputNodes objectAtIndex:i]]];
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
    var node = [TNXMLNode nodeWithName:@"devices"];

    if (_emulator)
    {
        [node addChildWithName:@"emulator"];
        [node addTextNode:_emulator];
        [node up];
    }

    for (var i = 0; i < [_disks count]; i++)
    {
        [node addNode:[[_disks objectAtIndex:i] XMLNode]];
        [node up];
    }

    for (var i = 0; i < [_interfaces count]; i++)
    {
        [node addNode:[[_interfaces objectAtIndex:i] XMLNode]];
        [node up];
    }

    for (var i = 0; i < [_graphics count]; i++)
    {
        [node addNode:[[_graphics objectAtIndex:i] XMLNode]];
        [node up];
    }

    for (var i = 0; i < [_inputs count]; i++)
    {
        [node addNode:[[_inputs objectAtIndex:i] XMLNode]];
        [node up];
    }

    return node;
}

@end
