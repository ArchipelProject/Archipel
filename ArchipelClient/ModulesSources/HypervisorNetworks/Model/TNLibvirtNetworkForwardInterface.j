/*
 * TNLibvirtNetworkForwardInterface.j
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
    Model for network forward interface
*/
@implementation TNLibvirtNetworkForwardInterface : TNLibvirtNetworkBase
{
    CPString    _dev    @accessors(property=dev);
}

#pragma mark -
#pragma mark Class Method

+ (TNLibvirtNetworkForwardInterface)defaultNetworkForwardInterfaceWithDev:(CPString)aDev
{
    var interf = [[TNLibvirtNetworkForwardInterface alloc] init];

    [interf setDev:aDev];

    return interf;
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
        if ([aNode name] != @"interface")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid interface"];

        _dev   = [aNode valueForAttribute:@"dev"];
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
    if (!_dev)
        [CPException raise:@"Missing dev" reason:@"dev is required"];

    var node = [TNXMLNode nodeWithName:@"interface"];

    if (_dev)
    {
        [node setValue:_dev forAttribute:@"dev"];
    }

    return node;
}

@end