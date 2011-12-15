/*
 * TNLibvirtDeviceHostDevSource.j
 *
 * Copyright (C) 2010  Antoine Mercadal <antoine.mercadal@inframonde.eu>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 3.0 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

@import <Foundation/Foundation.j>
@import <StropheCappuccino/TNXMLNode.j>

@import "TNLibvirtBase.j"
@import "TNLibvirtDeviceHostDevSourceVendor.j"
@import "TNLibvirtDeviceHostDevSourceProduct.j"
@import "TNLibvirtDeviceHostDevSourceAddress.j"


/*! @ingroup virtualmachinedefinition
    Model for hostdev's source
*/
@implementation TNLibvirtDeviceHostDevSource : TNLibvirtBase
{
    TNLibvirtDeviceHostDevSourceAddress _address    @accessors(property=address);
    TNLibvirtDeviceHostDevSourceProduct _product    @accessors(property=product);
    TNLibvirtDeviceHostDevSourceVendor  _vendor     @accessors(property=vendor);
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
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid hostdev source"];

        if ([aNode containsChildrenWithName:@"address"])
            _address = [[TNLibvirtDeviceHostDevSourceAddress alloc] initWithXMLNode:[aNode firstChildWithName:@"address"]];
        if ([aNode containsChildrenWithName:@"product"])
            _product = [[TNLibvirtDeviceHostDevSourceProduct alloc] initWithXMLNode:[aNode firstChildWithName:@"product"]];
        if ([aNode containsChildrenWithName:@"vendor"])
            _vendor = [[TNLibvirtDeviceHostDevSourceVendor alloc] initWithXMLNode:[aNode firstChildWithName:@"vendor"]];
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
    var node = [TNXMLNode nodeWithName:@"source"];

    if (_address)
    {
        [node addNode:[_address XMLNode]];
        [node up];
    }
    if (_product)
    {
        [node addNode:[_product XMLNode]];
        [node up];
    }
    if (_vendor)
    {
        [node addNode:[_vendor XMLNode]];
        [node up];
    }

    return node;
}

@end