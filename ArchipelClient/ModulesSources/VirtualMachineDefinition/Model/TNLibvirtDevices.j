/*  
 * TNLibvirtDevices.j
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


@implementation TNLibvirtDevices : TNLibvirtBase
{
    CPString    _emulator       @accessors(property=emulator);
    CPArray     _disks          @accessors(property=disks);
    CPArray     _interfaces     @accessors(property=interfaces);
    CPArray     _graphics       @accessors(property=graphics);
    CPArray     _inputs         @accessors(property=inputs);
}

- (TNXMLNode)XMLNode
{
    var node = [TNXMLNode nodeWithName:@"devices"];
    
    if (_emulator)
    {
        [node addChildWithName:@"emulator"];
        [node addTextNode:_emulator];
        [node up];
    }
    
    for (var i = 0; i < [_disks count]; i++)
    {
        [node addNode:[[_disks objectAtIndex:i] XMLNode]];
        [node up];
    }
    
    for (var i = 0; i < [_interfaces count]; i++)
    {
        [node addNode:[[_interfaces objectAtIndex:i] XMLNode]];
        [node up];
    }
    
    for (var i = 0; i < [_graphics count]; i++)
    {
        [node addNode:[[_graphics objectAtIndex:i] XMLNode]];
        [node up];
    }
    
    for (var i = 0; i < [_inputs count]; i++)
    {
        [node addNode:[[_inputs objectAtIndex:i] XMLNode]];
        [node up];
    }
    
    
    return node;
}


@end
