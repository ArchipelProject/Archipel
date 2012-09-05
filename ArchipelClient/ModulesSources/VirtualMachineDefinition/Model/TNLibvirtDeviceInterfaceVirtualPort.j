/*
 * TNLibvirtDeviceInterfaceVirtualPort.j
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
@import "TNLibvirtDeviceInterfaceVirtualPortParameters.j"

/*! @ingroup virtualmachinedefinition
    Model for interface virtual port
*/
@implementation TNLibvirtDeviceInterfaceVirtualPort : TNLibvirtBase
{
    CPString    _type       @accessors(property=type);
    CPArray     _parameters @accessors(property=parameters);
}


#pragma mark -
#pragma mark Initialization

- (TNLibvirtDeviceInterfaceVirtualPort)init
{
    if (self = [super init])
    {
        _parameters  = [CPArray array];
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
        if ([aNode name] != @"virtualport")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid interface virtualport"];

        _parameters  = [CPArray array];

        _type = [aNode valueForAttribute:@"type"];

        var parametersNodes = [aNode ownChildrenWithName:@"parameters"];
        for (var i = 0; i < [parametersNodes count]; i++)
            [_parameters addObject:[[TNLibvirtDeviceInterfaceVirtualPortParameters alloc] initWithXMLNode:[parametersNodes objectAtIndex:i]]];
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
    var node = [TNXMLNode nodeWithName:@"virtualport"];

    if (_type)
        [node setValue:_type forAttribute:@"type"];

    for (var i = 0; i < [_parameters count]; i++)
    {
        [node addNode:[[_parameters objectAtIndex:i] XMLNode]];
        [node up];
    }

    return node;
}

@end
