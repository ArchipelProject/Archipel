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

TNLibvirtDeviceInterfaceSourceModeVEPA          = @"vepa";
TNLibvirtDeviceInterfaceSourceModeBridge        = @"bridge";
TNLibvirtDeviceInterfaceSourceModePrivate       = @"private";
TNLibvirtDeviceInterfaceSourceModePassthrough   = @"passthrough";

TNLibvirtDeviceInterfaceSourceModes             = [ TNLibvirtDeviceInterfaceSourceModeVEPA,
                                                    TNLibvirtDeviceInterfaceSourceModeBridge,
                                                    TNLibvirtDeviceInterfaceSourceModePrivate,
                                                    TNLibvirtDeviceInterfaceSourceModePassthrough];


/*! @ingroup virtualmachinedefinition
    Model for interface source
*/
@implementation TNLibvirtDeviceInterfaceSource : TNLibvirtBase
{
    CPString    _address        @accessors(property=address);
    CPString    _bridge         @accessors(property=bridge);
    CPString    _device         @accessors(property=device);
    CPString    _mode           @accessors(property=mode);
    CPString    _network        @accessors(property=network);
    CPString    _port           @accessors(property=port);
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
        if ([aNode name] != @"source")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid interface source"];

        _address    = [aNode valueForAttribute:@"address"];
        _bridge     = [aNode valueForAttribute:@"bridge"];
        _device     = [aNode valueForAttribute:@"dev"];
        _mode       = [aNode valueForAttribute:@"mode"];
        _network    = [aNode valueForAttribute:@"network"];
        _port       = [aNode valueForAttribute:@"port"];
    }

    return self;
}


#pragma mark -
#pragma mark Setters / Getters

/*! return the current source object, _bridge, _device or _network
    @return CPString containing the source object
*/
- (CPString)sourceObject
{
    if (_bridge)
        return _bridge;
    if (_network)
        return _network;
    if (_device)
        return _device;
}


#pragma mark -
#pragma mark Generation

/*! return a TNXMLNode representing the object
    @return TNXMLNode
*/
- (TNXMLNode)XMLNode
{
    var node = [TNXMLNode nodeWithName:@"source"];

    if (_bridge)
        [node setValue:_bridge forAttribute:@"bridge"];
    if (_device)
        [node setValue:_device forAttribute:@"dev"];
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
