/*  
 * TNLibvirtDomainFeatures.j
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


@implementation TNLibvirtDomainFeatures : TNLibvirtBase
{
    BOOL    _PAE    @accessors(getter=isPAE, setter=setPAE:);
    BOOL    _ACPI   @accessors(getter=isACPI, setter=setACPI:);
    BOOL    _APIC   @accessors(getter=isAPIC, setter=setAPIC:);
    BOOL    _HAP    @accessors(getter=isHAP, setter=setHAP:);
}

- (TNXMLNode)XMLNode
{
    var node = [TNXMLNode nodeWithName:@"features"];
    
    if (_PAE)
    {
        [node addChildWithName:@"pae"];
        [node up];
    }
    if (_ACPI)
    {
        [node addChildWithName:@"acpi"];
        [node up];
    }
    
    if (_APIC)
    {
        [node addChildWithName:@"apic"];
        [node up];
    }
    if (_HAP)
    {
        [node addChildWithName:@"hap"];
        [node up];
    }
    
    return node;
}
@end
