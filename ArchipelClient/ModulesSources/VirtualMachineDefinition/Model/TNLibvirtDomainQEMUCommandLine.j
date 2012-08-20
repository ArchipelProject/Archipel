/*
 * TNLibvirtDomainQEMUCommandLine.j
 *
 * Copyright (C) 2012 Parspooyesh co
 * Author: Behrooz Shabani <everplays@gmail.com>
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
@import "TNLibvirtDomainQEMUCommandLineArgument.j";

/*! @ingroup virtualmachinedefinition
    Model for QEMU Command Line
*/
@implementation TNLibvirtDomainQEMUCommandLine : TNLibvirtBase
{
    CPArray                         _args @accessors(property=args);
}


#pragma mark -
#pragma mark Initialization

/*! initialize the CommandLine
*/
- (void)init
{
    if (self = [super init])
    {
        _args = [CPArray array];
    }

    return self;
}

/*! initialize the object with a given XML node
    @param aNode the node to use
*/
- (id)initWithXMLNode:(TNXMLNode)aNode
{
    if (self = [super initWithXMLNode:aNode])
    {
        if ([aNode name] != @"commandline")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid commandline"];

        _args        = [CPArray array];
        var argNodes = [aNode childrenWithName:@"arg"];
        for (var i = 0; i < [argNodes count]; i++)
            [_args addObject:[[TNLibvirtDomainQEMUCommandLineArgument alloc] initWithXMLNode:[argNodes objectAtIndex:i]]];
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
    var node = [TNXMLNode nodeWithName:@"commandline"];

    [node setNamespace:"http://libvirt.org/schemas/domain/qemu/1.0"];

    for (var i = 0; i < [_args count]; i++)
    {
        [node addNode:[[_args objectAtIndex:i] XMLNode]];
        [node up];
    }

    return node;
}

@end

