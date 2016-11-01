/*
 * TNLibvirtDomainCpuTopology.j
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
    Model for domain CPU topology
*/
@implementation TNLibvirtDomainCpuTopology : TNLibvirtBase
{
    CPString                    _sockets            @accessors(property=sockets);
    CPString                    _cores              @accessors(property=cores);
    CPString                    _threads            @accessors(property=threads);
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
        if ([aNode name] != @"topology")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid cpu topology"];

        _sockets            = [aNode valueForAttribute:@"sockets"];
        _cores              = [aNode valueForAttribute:@"cores"];
        _threads            = [aNode valueForAttribute:@"threads"];
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
    var node = [TNXMLNode nodeWithName:@"topology"];

    if (_sockets)
    {
        [node setValue:_sockets forAttribute:@"sockets"];
        [node up];
    }
    if (_cores)
    {
        [node setValue:_cores forAttribute:@"cores"];
        [node up];
    }
    if (_threads)
    {
        [node setValue:_threads forAttribute:@"threads"];
        [node up];
    }

    return node;
}

@end
