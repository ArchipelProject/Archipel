/*
 * TNLibvirtDeviceDiskSource.j
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
    Model for disk sources
*/
@implementation TNLibvirtDeviceDiskSource : TNLibvirtBase
{
    CPArray     _hosts          @accessors(property=hosts);
    CPString    _device         @accessors(property=device);
    CPString    _file           @accessors(property=file);
    CPString    _name           @accessors(property=name);
    CPString    _protocol       @accessors(property=protocol);
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
        if ([aNode name] != @"source")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid disk source"];

        _device     = [aNode valueForAttribute:@"dev"];
        _file       = [aNode valueForAttribute:@"file"];
        _hosts      = [CPArray array];
        _name       = [aNode valueForAttribute:@"name"];
        _protocol   = [aNode valueForAttribute:@"protocol"];

        var hostNodes = [aNode ownChildrenWithName:@"host"];
        for (var i = 0; i < [hostNodes count]; i++)
            [_hosts addObject:[[TNLibvirtDeviceDiskSourceHost alloc] initWithXMLNode:[hostNodes objectAtIndex:i]]];
    }

    return self;
}


#pragma mark -
#pragma mark Setters / Getters

/*! return the current source object, path, network or file
    @return CPString containing the source object
*/
- (CPString)sourceObject
{
    if (_device)
        return _device;
    if (_file)
        return _file;
    if (_hosts)
        return _hosts;
}


#pragma mark -
#pragma mark Generation

/*! return a TNXMLNode representing the object
    @return TNXMLNode
*/
- (TNXMLNode)XMLNode
{
    var node = [TNXMLNode nodeWithName:@"source"];

    if (_file)
        [node setValue:_file forAttribute:@"file"];
    if (_device)
        [node setValue:_device forAttribute:@"dev"];
    if (_protocol)
        [node setValue:_protocol forAttribute:@"protocol"];
    if (_name)
        [node setValue:_name forAttribute:@"name"];

    for (var i = 0; [_hosts count]; i++)
    {
        [node addNode:[[hosts objectAtIndex:i] XMLNode]];
        [node up];
    }

    return node;
}


@end
