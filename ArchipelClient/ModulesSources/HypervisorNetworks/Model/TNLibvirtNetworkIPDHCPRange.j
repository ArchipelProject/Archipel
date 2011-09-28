/*
 * TNLibvirtNetworkIPDHCPRange.j
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
    Model for network IP DHCP range
*/
@implementation TNLibvirtNetworkIPDHCPRange : TNLibvirtNetworkBase
{
    CPString        _end        @accessors(property=end);
    CPString        _start      @accessors(property=start);
}


#pragma mark -
#pragma mark Class Method

+ (TNLibvirtNetworkIPDHCPRange)defaultNetworkIPDHCPRangeWithStart:(CPString)aStart end:(CPString)aEnd
{
    var range = [[TNLibvirtNetworkIPDHCPRange alloc] init];

    [range setStart:aStart];
    [range setEnd:aEnd];

    return range;
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
        if ([aNode name] != @"range")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid range"];

        _start  = [aNode valueForAttribute:@"start"];
        _end    = [aNode valueForAttribute:@"end"];
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
    if (!_start)
        [CPException raise:@"Missing start" reason:@"start is required"];
    if (!_end)
        [CPException raise:@"Missing end" reason:@"end is required"];

    var node = [TNXMLNode nodeWithName:@"range"];

    if (_start)
        [node setValue:_start forAttribute:@"start"];

    if (_end)
        [node setValue:_end forAttribute:@"end"];

    return node;
}

@end