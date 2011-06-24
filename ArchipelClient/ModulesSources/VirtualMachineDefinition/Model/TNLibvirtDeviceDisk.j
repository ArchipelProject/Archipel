/*
 * TNLibvirtDeviceDisk.j
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
    Model for disk
*/
@implementation TNLibvirtDeviceDisk : TNLibvirtBase
{
    CPString                    _device     @accessors(property=device);
    CPString                    _type       @accessors(property=type);
    TNLibvirtDeviceDiskSource   _source     @accessors(property=source);
    TNLibvirtDeviceDiskTarget   _target     @accessors(property=target);
    TNLibvirtDeviceDiskDriver   _driver     @accessors(property=driver);
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
        if ([aNode name] != @"disk")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid disk"];

        _device = [aNode valueForAttribute:@"device"];
        _type   = [aNode valueForAttribute:@"type"];

        _source = [[TNLibvirtDeviceDiskSource alloc] initWithXMLNode:[aNode firstChildWithName:@"source"]];
        _target = [[TNLibvirtDeviceDiskTarget alloc] initWithXMLNode:[aNode firstChildWithName:@"target"]];
        _driver = [[TNLibvirtDeviceDiskDriver alloc] initWithXMLNode:[aNode firstChildWithName:@"driver"]];
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
    if (!_type)
        [CPException raise:@"Missing disk type" reason:@"disk type is required"];

    var attributes = {@"type": _type};

    if (_device)
        attributes.device = _device;

    var node = [TNXMLNode nodeWithName:@"disk" andAttributes:attributes];

    if (_source)
    {
        [node addNode:[_source XMLNode]];
        [node up];
    }

    if (_target)
    {
        [node addNode:[_target XMLNode]];
        [node up];
    }
    
    if (_driver)
    {
        [node addNode:[_driver XMLNode]];
        [node up];
    }
    

    return node;
}

@end
