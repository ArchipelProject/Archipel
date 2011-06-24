/*
 * TNLibvirtBase.j
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


/*! @ingroup virtualmachinedefinition
    Base class of all libvirt models object
*/
@implementation TNLibvirtBase : CPObject


#pragma mark -
#pragma mark Initialization

/*! initialize the object with a given XML node
    @param aNode the node to use
*/
- (TNLibvirtBase)initWithXMLNode:(TNXMLNode)aNode
{
    if (!aNode || (typeof(aNode) == @"undefined"))
        return nil;

    if (self = [super init])
        return self;
}


#pragma mark -
#pragma mark Generation

/*! return a TNXMLNode representing the object
    @return TNXMLNode
*/
- (TNXMLNode)XMLNode
{
    return nil;
}

#pragma mark -
#pragma mark Overides

- (CPString)description
{
    return [[self XMLNode] stringValue];
}

@end
