/*  
 * TNLibvirtDeviceInterfaceFilter.j
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
    Model for inteface
*/
@implementation TNLibvirtDeviceInterfaceFilterRef : TNLibvirtBase
{
    CPString        _filter         @accessors(property=name);
    CPArray         _parameters     @accessors(property=parameters);
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
        if ([aNode name] != @"filterref")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid filterref"];

        _filter     = [aNode valueForAttribute:@"filter"];
        _parameters = [CPArray array];

        var paramNodes = [aNode ownChildrenWithName:@"parameter"];
        for (var i = 0; i < [paramNodes count]; i++)
        {
            var name = [[paramNodes objectAtIndex:i] valueForAttribute:@"name"],
                value = [[paramNodes objectAtIndex:i] valueForAttribute:@"value"];
            [_parameters addObject:[CPDictionary dictionaryWithObjectsAndKeys:name, @"name", value, @"value"]];
        }
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
    if (!_filter)
        [CPException raise:@"Missing filter" reason:@"filter is required"];

    var node = [TNXMLNode nodeWithName:@"filterref" andAttributes:{@"filter": _filter}];

    for (var i = 0; i < [_parameters count]; i++)
    {
        [node addChildWithName:@"parameter" andAttributes:{
            @"name": [[_parameters objectAtIndex:i] valueForKey:@"name"],
            @"value": [[_parameters objectAtIndex:i] valueForKey:@"value"]
        }];
        [node up];
    }

    return node;
}

@end
