/*
 * TNLibvirtDeviceVideoAddress.j
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


//address slot='0x02' bus='0x00' domain='0x0000' type='pci' function='0x0'/>

/*! @ingroup virtualmachinedefinition
    Model for video address
*/
@implementation TNLibvirtDeviceVideoAddress : TNLibvirtBase
{
    CPString    _bus        @accessors(property=bus);
    CPString    _domain     @accessors(property=domain);
    CPString    _function   @accessors(property=func);
    CPString    _slot       @accessors(property=slot);
    CPString    _type       @accessors(property=type);
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
        if ([aNode name] != @"address")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid video address"];

        _bus = [aNode valueForAttribute:@"bus"];
        _domain = [aNode valueForAttribute:@"domain"];
        _function = [aNode valueForAttribute:@"function"];
        _slot = [aNode valueForAttribute:@"slot"];
        _type = [aNode valueForAttribute:@"type"];
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
    var node = [TNXMLNode nodeWithName:@"address"];

    if (_bus)
        [node setValue:_bus forAttribute:@"bus"];
    if (_domain)
        [node setValue:_domain forAttribute:@"domain"];
    if (_function)
        [node setValue:_function forAttribute:@"function"];
    if (_slot)
        [node setValue:_slot forAttribute:@"slot"];
    if (_type)
        [node setValue:_type forAttribute:@"type"];

    return node;
}

@end
