/*
 * TNLibvirtDeviceControllerAddress.j
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

/*! @ingroup virtualmachinedefinition
    Model for controller's addresses
*/
@implementation TNLibvirtDeviceControllerAddress : TNLibvirtBase
{
    CPString    _type           @accessors(property=type);
    CPString    _domain         @accessors(property=domain);
    CPString    _bus            @accessors(property=bus);
    CPString    _slot           @accessors(property=slot);
    CPString    _function       @accessors(property=function);
    CPString    _multifunction  @accessors(property=multifunction);
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
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid controller address"];

        _type           = [aNode valueForAttribute:@"type"];
        _domain         = [aNode valueForAttribute:@"domain"];
        _bus            = [aNode valueForAttribute:@"bus"];
        _slot           = [aNode valueForAttribute:@"slot"];
        _function       = [aNode valueForAttribute:@"function"];
        _multifunction  = [aNode valueForAttribute:@"multifunction"];
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

    if (_type)
        [node setValue:_type forAttribute:@"type"];

    if (_domain)
        [node setValue:_domain forAttribute:@"domain"];

    if (_bus)
        [node setValue:_bus forAttribute:@"bus"];

    if (_slot)
        [node setValue:_slot forAttribute:@"slot"];

    if (_function)
        [node setValue:_function forAttribute:@"function"];

    if (_multifunction)
        [node setValue:_multifunction forAttribute:@"multifunction"];

    return node;
}

@end

