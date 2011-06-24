/*  
 * TNLibvirtDeviceInterfaceSource.j
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


@implementation TNLibvirtDeviceInterfaceSource : TNLibvirtBase
{
    CPString    _bridge         @accessors(property=bridge);
    CPString    _dev            @accessors(property=dev);
    CPString    _network        @accessors(property=network);
    CPString    _mode           @accessors(property=mode);
    CPString    _address        @accessors(property=address);
    CPString    _port           @accessors(property=port);
}

- (TNXMLNode)XMLNode
{
    var node = [TNXMLNode nodeWithName:@"source"];
    
    if (_bridge)
        [node setValue:_bridge forAttribute:@"bridge"];
    if (_dev)
        [node setValue:_dev forAttribute:@"dev"];
    if (_network)
        [node setValue:_network forAttribute:@"network"];
    if (_mode)
        [node setValue:_mode forAttribute:@"mode"];
    if (_address)
        [node setValue:_address forAttribute:@"address"];
    if (_port)
        [node setValue:_port forAttribute:@"port"];
    
    return node;
}

@end
