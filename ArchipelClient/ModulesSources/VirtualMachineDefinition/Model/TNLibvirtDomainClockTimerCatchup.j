/*
 * TNLibvirtDomainClockTimerCatchup.j
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

@import "TNLibvirtBase.j"


/*! @ingroup virtualmachinedefinition
    Model for clock timer catchup
*/
@implementation TNLibvirtDomainClockTimerCatchup : TNLibvirtBase
{
    CPString    _threshold  @accessors(property=threshold);
    CPString    _slew       @accessors(property=slew);
    CPString    _limit      @accessors(property=limit);
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
        if ([aNode name] != @"catchup")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid clock timer catchup"];

        _threshold  = [aNode valueForAttribute:@"threshold"];
        _slew       = [aNode valueForAttribute:@"slew"];
        _limit      = [aNode valueForAttribute:@"limit"];
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
    var node = [TNXMLNode nodeWithName:@"catchup"];

    if (_threshold)
        [node setValue:_threshold forAttribute:@"threshold"];

    if (_slew)
        [node setValue:_slew forAttribute:@"slew"];

    if (_limit)
        [node setValue:_limit forAttribute:@"limit"];

    return node;
}

@end
