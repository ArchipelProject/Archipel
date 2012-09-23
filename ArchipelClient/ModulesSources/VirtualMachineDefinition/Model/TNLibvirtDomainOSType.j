/*
 * TNLibvirtDomainOSType.j
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

TNLibvirtDomainOSTypeTypeLinux  = @"linux";
TNLibvirtDomainOSTypeTypeHVM    = @"hvm";

@import "TNLibvirtBase.j";


/*! @ingroup virtualmachinedefinition
    Model for OS Type
*/
@implementation TNLibvirtDomainOSType : TNLibvirtBase
{
    CPString    _architecture       @accessors(property=architecture);
    CPString    _machine            @accessors(property=machine);
    CPString    _type               @accessors(property=type);
}


#pragma mark -
#pragma mark Initialization

/*! initialize the object with a given XML node
    @param aNode the node to use
*/
- (id)initWithXMLNode:(TNXMLNode)aNode domainType:(CPString)aDomainType
{
    if (self = [super initWithXMLNode:aNode])
    {
        if ([aNode name] != @"type")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid os type"];

        _architecture       = [aNode valueForAttribute:@"arch"];
        _machine            = [aNode valueForAttribute:@"machine"];
        _type               = [aNode text];

        // We have to fake a good return from libvirt for Xen as some informations are missing
        // For HVM if we set <type machine='xenfv' arch='x86_64|i686'>hvm</type> we dump <type>hvm</type>
        // For PVM if we set <type machine='xenpv' arch='x86_64|i686'>xen</type> we dump <type>linux</type>
        // No way to get the arch for Xen Guest domain as in HVM it boot's on 16bits real mode
        // Regarding PVM, no way to know if we boot a kernel in 32/64b too
        if (aDomainType == TNLibvirtDomainTypeXen)
        {
            if (_type == TNLibvirtDomainOSTypeTypeLinux)
            {
                _architecture       = @"i686";
                _machine            = @"xenpv";
                _type               = TNLibvirtDomainTypeXen;
            }

            if (_type == TNLibvirtDomainOSTypeTypeHVM)
            {
                _architecture       = @"i686";
                _machine            = @"xenfv";
                _type               = TNLibvirtDomainOSTypeTypeHVM;
            }
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
    var node = [TNXMLNode nodeWithName:@"type"];

    if (_machine)
        [node setValue:_machine forAttribute:@"machine"];

    if (_architecture)
        [node setValue:_architecture forAttribute:@"arch"];

    [node addTextNode:_type];

    return node;
}

@end
