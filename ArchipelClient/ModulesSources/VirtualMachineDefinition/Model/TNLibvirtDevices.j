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

@import "TNLibvirtBase.j"
@import "TNLibvirtDeviceCharacter.j"
@import "TNLibvirtDeviceDisk.j"
@import "TNLibvirtDeviceFilesystem.j"
@import "TNLibvirtDeviceGraphic.j"
@import "TNLibvirtDeviceHostDev.j"
@import "TNLibvirtDeviceInput.j"
@import "TNLibvirtDeviceInterface.j"
@import "TNLibvirtDeviceController.j"

/*! @ingroup virtualmachinedefinition
    Model for devices
*/
@implementation TNLibvirtDevices : TNLibvirtBase
{
    CPArray                 _characters     @accessors(property=characters);
    CPArray                 _disks          @accessors(property=disks);
    CPArray                 _filesystems    @accessors(property=filesystems);
    CPArray                 _graphics       @accessors(property=graphics);
    CPArray                 _hostdevs       @accessors(property=hostdevs);
    CPArray                 _inputs         @accessors(property=inputs);
    CPArray                 _interfaces     @accessors(property=interfaces);
    CPArray                 _controllers    @accessors(property=controllers);
    CPString                _emulator       @accessors(property=emulator);

    TNLibvirtDeviceVideo    _video          @accessors(property=video);
}


#pragma mark -
#pragma mark Initialization

- (TNLibvirtDevices)init
{
    if (self = [super init])
    {
        _characters  = [CPArray array];
        _disks       = [CPArray array];
        _filesystems = [CPArray array];
        _graphics    = [CPArray array];
        _hostdevs    = [CPArray array];
        _inputs      = [CPArray array];
        _interfaces  = [CPArray array];
        _controllers = [CPArray array];
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

        _emulator    = [[aNode firstChildWithName:@"emulator"] text];
        _characters  = [CPArray array];
        _disks       = [CPArray array];
        _filesystems = [CPArray array];
        _graphics    = [CPArray array];
        _hostdevs    = [CPArray array];
        _inputs      = [CPArray array];
        _interfaces  = [CPArray array];
        _controllers = [CPArray array];

        var diskNodes = [aNode ownChildrenWithName:@"disk"];
        for (var i = 0; i < [diskNodes count]; i++)
            [_disks addObject:[[TNLibvirtDeviceDisk alloc] initWithXMLNode:[diskNodes objectAtIndex:i]]];

        var interfaceNodes = [aNode ownChildrenWithName:@"interface"];
        for (var i = 0; i < [interfaceNodes count]; i++)
            [_interfaces addObject:[[TNLibvirtDeviceInterface alloc] initWithXMLNode:[interfaceNodes objectAtIndex:i]]];

        var graphicNodes = [aNode ownChildrenWithName:@"graphics"];
        for (var i = 0; i < [graphicNodes count]; i++)
            [_graphics addObject:[[TNLibvirtDeviceGraphic alloc] initWithXMLNode:[graphicNodes objectAtIndex:i]]];

        var inputNodes = [aNode ownChildrenWithName:@"input"];
        for (var i = 0; i < [inputNodes count]; i++)
            [_inputs addObject:[[TNLibvirtDeviceInput alloc] initWithXMLNode:[inputNodes objectAtIndex:i]]];

        var consoleNodes = [aNode ownChildrenWithName:@"console"];
        for (var i = 0; i < [consoleNodes count]; i++)
            [_characters addObject:[[TNLibvirtDeviceCharacter alloc] initWithXMLNode:[consoleNodes objectAtIndex:i]]];

        var serialNodes = [aNode ownChildrenWithName:@"serial"];
        for (var i = 0; i < [serialNodes count]; i++)
            [_characters addObject:[[TNLibvirtDeviceCharacter alloc] initWithXMLNode:[serialNodes objectAtIndex:i]]];

        var channelNodes = [aNode ownChildrenWithName:@"channel"];
        for (var i = 0; i < [channelNodes count]; i++)
            [_characters addObject:[[TNLibvirtDeviceCharacter alloc] initWithXMLNode:[channelNodes objectAtIndex:i]]];

        var parallelNodes = [aNode ownChildrenWithName:@"parallel"];
        for (var i = 0; i < [parallelNodes count]; i++)
            [_characters addObject:[[TNLibvirtDeviceCharacter alloc] initWithXMLNode:[parallelNodes objectAtIndex:i]]];

        var hostdevNodes = [aNode ownChildrenWithName:@"hostdev"];
        for (var i = 0; i < [hostdevNodes count]; i++)
            [_hostdevs addObject:[[TNLibvirtDeviceHostDev alloc] initWithXMLNode:[hostdevNodes objectAtIndex:i]]];

        var filesystemNodes = [aNode ownChildrenWithName:@"filesystem"];
        for (var i = 0; i < [filesystemNodes count]; i++)
            [_filesystems addObject:[[TNLibvirtDeviceFilesystem alloc] initWithXMLNode:[filesystemNodes objectAtIndex:i]]];

        var controllerNodes = [aNode ownChildrenWithName:@"controller"];
        for (var i = 0; i < [controllerNodes count]; i++)
            [_controllers addObject:[[TNLibvirtDeviceController alloc] initWithXMLNode:[controllerNodes objectAtIndex:i]]];

        if  ([aNode firstChildWithName:@"video"])
            _video = [[TNLibvirtDeviceVideo alloc] initWithXMLNode:[aNode firstChildWithName:@"video"]];
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

    for (var i = 0; i < [_characters count]; i++)
    {
        [node addNode:[[_characters objectAtIndex:i] XMLNode]];
        [node up];
    }

    for (var i = 0; i < [_hostdevs count]; i++)
    {
        [node addNode:[[_hostdevs objectAtIndex:i] XMLNode]];
        [node up];
    }

    for (var i = 0; i < [_filesystems count]; i++)
    {
        [node addNode:[[_filesystems objectAtIndex:i] XMLNode]];
        [node up];
    }

    for (var i = 0; i < [_controllers count]; i++)
    {
        [node addNode:[[_controllers objectAtIndex:i] XMLNode]];
        [node up];
    }

    if (_video)
    {
        [node addNode:[_video XMLNode]];
        [node up];
    }

    return node;
}

@end
