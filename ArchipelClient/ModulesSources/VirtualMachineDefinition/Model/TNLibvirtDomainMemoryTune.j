/*
 * TNLibvirtDomainMemoryTune.j
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
    Model for memory tuning
*/
@implementation TNLibvirtDomainMemoryTune : TNLibvirtBase
{
    int     _hardLimit          @accessors(property=hardLimit);
    int     _minGuarantee       @accessors(property=minGuarantee);
    int     _softLimit          @accessors(property=softLimit);
    int     _swapHardLimit      @accessors(property=swapHardLimit);
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
        if ([aNode name] != @"memtune")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid memtune"];

        _hardLimit      = [[[aNode firstChildWithName:@"hard_limit"] text] intValue];
        _minGuarantee   = [[[aNode firstChildWithName:@"min_guarantee"] text] intValue];
        _softLimit      = [[[aNode firstChildWithName:@"soft_limit"] text] intValue];
        _swapHardLimit  = [[[aNode firstChildWithName:@"swap_hard_limit"] text] intValue];
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
    var node = [TNXMLNode nodeWithName:@"memtune"];

    if (_hardLimit)
    {
        [node addChildWithName:@"hard_limit"];
        [node addTextNode:[_hardLimit stringValue]];
        [node up];
    }
    if (_softLimit)
    {
        [node addChildWithName:@"soft_limit"];
        [node addTextNode:[_softLimit stringValue]];
        [node up];
    }

    if (_swapHardLimit)
    {
        [node addChildWithName:@"swap_hard_limit"];
        [node addTextNode:[_swapHardLimit stringValue]];
        [node up];
    }
    if (_minGuarantee)
    {
        [node addChildWithName:@"min_guarantee"];
        [node addTextNode:[_minGuarantee stringValue]];
        [node up];
    }

    return node;
}

@end
