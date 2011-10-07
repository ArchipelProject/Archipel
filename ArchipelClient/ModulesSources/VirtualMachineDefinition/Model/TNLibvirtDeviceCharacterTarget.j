/*
 * TNLibvirtDeviceCharacterSource.j
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


TNLibvirtDeviceConsoleTargetTypeVIRTIO   = @"virtio";


/*! @ingroup virtualmachinedefinition
    Model for device console targets
*/
@implementation TNLibvirtDeviceCharacterTarget : TNLibvirtBase
{
    CPString    _type       @accessors(property=type);
    CPString    _address    @accessors(property=address);
    CPString    _port       @accessors(property=port);
    CPString    _name       @accessors(property=name);
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
        if ([aNode name] != @"target")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid character device target"];

        _type       = [aNode valueForAttribute:@"type"];
        _address    = [aNode valueForAttribute:@"address"];
        _port       = [aNode valueForAttribute:@"port"];
        _name       = [aNode valueForAttribute:@"name"];
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
    if (!_port)
        [CPException raise:@"Missing character device target port" reason:@"character device target port is required"];

    var node = [TNXMLNode nodeWithName:@"target"];

    if (_type)
        [node setValue:_type forAttribute:@"type"];
    if (_address)
        [node setValue:_address forAttribute:@"address"];
    if (_port)
        [node setValue:_port forAttribute:@"port"];
    if (_name)
        [node setValue:_name forAttribute:@"name"];

    return node;
}

@end
