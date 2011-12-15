/*
 * TNLibvirtDeviceHostDevRom.j
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


TNLibvirtDeviceHostDevRomBarON  = @"on";
TNLibvirtDeviceHostDevRomBarOFF = @"off";

TNLibvirtDeviceHostDevRomBars   = [TNLibvirtDeviceHostDevRomBarON, TNLibvirtDeviceHostDevRomBarOFF];


/*! @ingroup virtualmachinedefinition
    Model for hostdev's rom
*/
@implementation TNLibvirtDeviceHostDevRom : TNLibvirtBase
{
    CPString    _bar  @accessors(property=bar);
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
        if ([aNode name] != @"rom")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid hostdev rom"];

        _bar = [aNode valueForAttribute:@"bar"];
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
    var node = [TNXMLNode nodeWithName:@"rom"];

    if (_bar)
        [node setValue:_bar forAttribute:@"bar"];

    return node;
}

@end