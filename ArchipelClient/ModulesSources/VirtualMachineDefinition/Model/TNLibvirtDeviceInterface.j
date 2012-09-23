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

@import "TNLibvirtBase.j"
@import "TNLibvirtDeviceInterfaceBandwidth.j"
@import "TNLibvirtDeviceInterfaceFilterRef.j"
@import "TNLibvirtDeviceInterfaceSource.j"
@import "TNLibvirtDeviceInterfaceTarget.j"
@import "TNLibvirtDeviceInterfaceVirtualPort.j"


TNLibvirtDeviceInterfaceModelNE2KISA    = @"ne2k_isa";
TNLibvirtDeviceInterfaceModelI82551     = @"i82551";
TNLibvirtDeviceInterfaceModelI82557b    = @"i82557b";
TNLibvirtDeviceInterfaceModelI82559ER   = @"i82559er";
TNLibvirtDeviceInterfaceModelNE2KPCI    = @"ne2k_pci";
TNLibvirtDeviceInterfaceModelPCNET      = @"pcnet";
TNLibvirtDeviceInterfaceModelRTL8139    = @"rtl8139";
TNLibvirtDeviceInterfaceModelE1000      = @"e1000";
TNLibvirtDeviceInterfaceModelVIRTIO     = @"virtio";

TNLibvirtDeviceInterfaceModels          = [ TNLibvirtDeviceInterfaceModelNE2KISA,
                                            TNLibvirtDeviceInterfaceModelI82551,
                                            TNLibvirtDeviceInterfaceModelI82557b,
                                            TNLibvirtDeviceInterfaceModelI82559ER,
                                            TNLibvirtDeviceInterfaceModelNE2KPCI,
                                            TNLibvirtDeviceInterfaceModelPCNET,
                                            TNLibvirtDeviceInterfaceModelRTL8139,
                                            TNLibvirtDeviceInterfaceModelE1000,
                                            TNLibvirtDeviceInterfaceModelVIRTIO];

TNLibvirtDeviceInterfaceTypeNetwork     = @"network";
TNLibvirtDeviceInterfaceTypeNuage       = @"nuage";
TNLibvirtDeviceInterfaceTypeBridge      = @"bridge";
TNLibvirtDeviceInterfaceTypeUser        = @"user";
TNLibvirtDeviceInterfaceTypeDirect      = @"direct";
TNLibvirtDeviceInterfaceTypes           = [ TNLibvirtDeviceInterfaceTypeNetwork,
                                            TNLibvirtDeviceInterfaceTypeBridge,
                                            TNLibvirtDeviceInterfaceTypeUser,
                                            TNLibvirtDeviceInterfaceTypeDirect,
                                            TNLibvirtDeviceInterfaceTypeNuage];

/*! @ingroup virtualmachinedefinition
    Model for inteface
*/
@implementation TNLibvirtDeviceInterface : TNLibvirtBase
{
    CPString                            _MAC                        @accessors(property=MAC);
    CPString                            _model                      @accessors(property=model);
    CPString                            _script                     @accessors(property=script);
    CPString                            _type                       @accessors(property=type);
    CPString                            _nuageNetworkName           @accessors(property=nuageNetworkName);
    CPString                            _nuageNetworkInterfaceIP    @accessors(property=nuageNetworkInterfaceIP);
    TNLibvirtDeviceInterfaceBandwidth   _bandwidth                  @accessors(property=bandwidth);
    TNLibvirtDeviceInterfaceFilterRef   _filterref                  @accessors(property=filterref);
    TNLibvirtDeviceInterfaceSource      _source                     @accessors(property=source);
    TNLibvirtDeviceInterfaceTarget      _target                     @accessors(property=target);
    TNLibvirtDeviceInterfaceVirtualPort _virtualPort                @accessors(property=virtualPort);
}


#pragma mark -
#pragma mark Initialization

/*! intialize the interface
*/
- (void)init
{
    if (self = [super init])
    {
        _filterref  = [[TNLibvirtDeviceInterfaceFilterRef alloc] init];
        _source     = [[TNLibvirtDeviceInterfaceSource alloc] init];
        _target     = [[TNLibvirtDeviceInterfaceTarget alloc] init];
        _bandwidth  = [[TNLibvirtDeviceInterfaceBandwidth alloc] init];
    }

    return self
}

/*! initialize the object with a given XML node
    @param aNode the node to use
*/
- (id)initWithXMLNode:(TNXMLNode)aNode
{
    if (self = [super initWithXMLNode:aNode])
    {
        if ([aNode name] != @"interface")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid interface"];

        _MAC                        = [[aNode firstChildWithName:@"mac"] valueForAttribute:@"address"];
        _model                      = [[aNode firstChildWithName:@"model"] valueForAttribute:@"type"];
        _script                     = [[aNode firstChildWithName:@"script"] valueForAttribute:@"path"];
        _type                       = [aNode valueForAttribute:@"type"];
        _nuageNetworkName           = [aNode valueForAttribute:@"nuage_network_name"];
        _nuageNetworkInterfaceIP    = [aNode valueForAttribute:@"nuage_network_interface_ip"];

        _bandwidth  = [[TNLibvirtDeviceInterfaceBandwidth alloc] initWithXMLNode:[aNode firstChildWithName:@"bandwidth"]];
        _filterref  = [[TNLibvirtDeviceInterfaceFilterRef alloc] initWithXMLNode:[aNode firstChildWithName:@"filterref"]];
        _source     = [[TNLibvirtDeviceInterfaceSource alloc] initWithXMLNode:[aNode firstChildWithName:@"source"]];
        _target     = [[TNLibvirtDeviceInterfaceTarget alloc] initWithXMLNode:[aNode firstChildWithName:@"target"]];

        if ([aNode containsChildrenWithName:@"virtualport"])
            _virtualPort = [[TNLibvirtDeviceInterfaceVirtualPort alloc] initWithXMLNode:[aNode firstChildWithName:@"virtualport"]];
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
    if (_model)
    {
        [node addChildWithName:@"model" andAttributes:{"type": _model}];
        [node up];
    }
    if (_filterref)
    {
        [node addNode:[_filterref XMLNode]];
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
    if (_bandwidth)
    {
        [node addNode:[_bandwidth XMLNode]];
        [node up];
    }
    if (_nuageNetworkName)
    {
        [node setValue:_nuageNetworkName forAttribute:@"nuage_network_name"];
    }

    if (_nuageNetworkInterfaceIP)
    {
        [node setValue:_nuageNetworkInterfaceIP forAttribute:@"nuage_network_interface_ip"];
    }

    if (_virtualPort)
    {
        [node addNode:[_virtualPort XMLNode]];
        [node up];
    }

    return node;
}

@end
