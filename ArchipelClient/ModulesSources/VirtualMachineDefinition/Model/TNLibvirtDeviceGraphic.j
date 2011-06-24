/*  
 * TNLibvirtDeviceGraphic.j
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


@implementation TNLibvirtDeviceGraphic : TNLibvirtBase
{
    CPString    _type           @accessors(property=type);
    CPString    _display        @accessors(property=display);
    int         _port           @accessors(property=port);
    BOOL        _autoPort       @accessors(getter=isAutoPort, setter=setAutoPort:);
    BOOL        _multiUser      @accessors(getter=isMultiUser, setter=setMultiUser:);
    BOOL        _fullScreen     @accessors(getter=isFullScreen, setter=setFullScreen:);
}

- (TNXMLNode)XMLNode
{
    if (!_type)
        [CPException raise:@"Missing graphic type" reason:@"graphic type is required"];
    
    var node = [TNXMLNode nodeWithName:@"graphic" andAttributes:{@"type": _type}];
    
    if (_display)
        [node setValue:_display forAttribute:@"display"];
    if (_port)
        [node setValue:[_port stringValue] forAttribute:@"port"];
    if (_autoPort != nil)
        [node setValue:(_autoPort ? @"yes" : @"no") forAttribute:@"autoport"];
    if (_multiUser != nil)
        [node setValue:(_multiUser ? @"yes" : @"no") forAttribute:@"multiUser"];
    if (_fullScreen != nil)
        [node setValue:(_fullScreen ? @"yes" : @"no") forAttribute:@"fullscreen"];

    return node;
}

@end
