/*
 * TNLibvirtNetworkIPTFTP.j
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


@import "TNLibvirtNetworkBase.j"


/*! @ingroup hypervisornetworks
    Model for network IP TFTP
*/
@implementation TNLibvirtNetworkIPTFTP : TNLibvirtNetworkBase
{
    CPString    _root           @accessors(property=root);
}


#pragma mark -
#pragma mark Class Method

+ (TNLibvirtNetworkIPTFTP)defaultNetworkIPTFTPWithRoot:(CPString)aRoot
{
    var tftp = [[TNLibvirtNetworkIPTFTP alloc] init];

    [tftp setRoot:aRoot];

    return tftp;
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
        if ([aNode name] != @"tftp")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid tftp"];

        _root   = [aNode valueForAttribute:@"root"];
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
    if (!_root)
        [CPException raise:@"Missing root" reason:@"root is required"];

    var node = [TNXMLNode nodeWithName:@"tftp"];

    if (_root)
    {
        [node setValue:_root forAttribute:@"root"];
    }

    return node;
}

@end