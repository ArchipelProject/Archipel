/*  
 * TNLibvirtDeviceDisk.j
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


@implementation TNLibvirtDeviceDisk : TNLibvirtBase
{
    CPString            _type       @accessors(property=type);
    CPString            _device     @accessors(property=device);
    TNLibvirtDeviceDiskSource _source     @accessors(property=source);
    TNLibvirtDeviceDiskTarget _target     @accessors(property=target);
}

- (TNXMLNode)XMLNode
{
    if (!_type)
        [CPException raise:@"Missing disk type" reason:@"disk type is required"];
    
    var attributes = {@"type": _type};
    
    if (_device)
        attributes.device = _device;
    
    var node = [TNXMLNode nodeWithName:@"disk" andAttributes:attributes];
    
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
