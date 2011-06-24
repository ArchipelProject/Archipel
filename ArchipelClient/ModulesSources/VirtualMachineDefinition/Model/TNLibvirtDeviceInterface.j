/*  
 * TNLibvirtDeviceInterface.j
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


@implementation TNLibvirtDeviceInterface : TNLibvirtBase
{
    CPString                    _type           @accessors(property=type);
    CPString                    _MAC            @accessors(property=MAC);
    CPString                    _script         @accessors(property=script);
    CPString                    _model          @accessors(property=model);
    CPString                    _filter         @accessors(property=filter);
    TNLibvirtDeviceInterfaceSource    _source         @accessors(property=source);
    TNLibvirtDeviceInterfaceTarget    _target         @accessors(property=target);
}

- (TNXMLNode)XMLNode
{
    if (!_type)
        [CPException raise:@"Missing interface type" reason:@"interface type is required"];

    var node = [TNXMLNode nodeWithName:@"interface" andAttributes:{@"type": _type}];
    
    if (_MAC)
    {
        [node addChildWithName:@"mac" andAttributes:{"address": _MAC}];
        [node up];
    }
    if (_script)
    {
        [node addChildWithName:@"script" andAttributes:{"path": _script}];
        [node up];
    }
    if (_filter)
    {
        [node addChildWithName:@"filterref" andAttributes:{"filter": _filter}];
        [node up];
    }
    if (_model)
    {
        [node addChildWithName:@"model" andAttributes:{"type": _model}];
        [node up];
    }
    if (_source)
    {
        [node addNode:[_source XMLNode]];
        [node up];
    }
    if (_target)
    {
        [node addNode:[_target XMLNode]];
        [node up];
    }
    
    return node;
}

@end
