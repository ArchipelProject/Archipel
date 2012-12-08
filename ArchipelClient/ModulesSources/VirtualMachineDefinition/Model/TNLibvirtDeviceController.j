/*
 * TNLibvirtDeviceController.j
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

@import "TNLibvirtDeviceControllerAddress.j"


TNLibvirtDeviceControllerTypeIDE            = @"ide";
TNLibvirtDeviceControllerTypeFDC            = @"fdc";
TNLibvirtDeviceControllerTypeSCSI           = @"scsi";
TNLibvirtDeviceControllerTypeSATA           = @"sata";
TNLibvirtDeviceControllerTypeUSB            = @"usb";
TNLibvirtDeviceControllerTypeCCID           = @"ccid";
TNLibvirtDeviceControllerTypeVIRTIOSERIAL   = @"virtio-serial";

TNLibvirtDeviceControllerTypes = [TNLibvirtDeviceControllerTypeIDE,
                                  TNLibvirtDeviceControllerTypeFDC,
                                  TNLibvirtDeviceControllerTypeSCSI,
                                  TNLibvirtDeviceControllerTypeSATA,
                                  TNLibvirtDeviceControllerTypeUSB,
                                  TNLibvirtDeviceControllerTypeCCID,
                                  TNLibvirtDeviceControllerTypeVIRTIOSERIAL];

TNLibvirtDeviceControllerModelAUTO              = "auto";
TNLibvirtDeviceControllerModelBUSLOGIC          = "buslogic";
TNLibvirtDeviceControllerModelIBMVSCSI          = "ibmvscsi";
TNLibvirtDeviceControllerModelLSILOGIC          = "lsilogic";
TNLibvirtDeviceControllerModelLSIAS1068         = "lsias1068";
TNLibvirtDeviceControllerModelVIRTIOSCSI        = "virtio-scsi";
TNLibvirtDeviceControllerModelVMPVSCSI          = "vmpvscsi";
TNLibvirtDeviceControllerModelPIIX3UHCI         = "piix3-uhci";
TNLibvirtDeviceControllerModelPIIX34UHCI        = "piix4-uhci";
TNLibvirtDeviceControllerModelEHCI              = "ehci";
TNLibvirtDeviceControllerModelICH9EHCI1         = "ich9-ehci1";
TNLibvirtDeviceControllerModelICH9UHCI1         = "ich9-uhci1";
TNLibvirtDeviceControllerModelICH9UHCI2         = "ich9-uhci2";
TNLibvirtDeviceControllerModelICH9UHCI3         = "ich9-uhci3";
TNLibvirtDeviceControllerModelVT82C686BUHCI     = "vt82c686b-uhci";
TNLibvirtDeviceControllerModelPCIOHCI           = "pci-ohci";
TNLibvirtDeviceControllerModelNECXHCI           = "nec-xhci";
TNLibvirtDeviceControllerModelNONE              = "none";


TNLibvirtDeviceControllerModels = [TNLibvirtDeviceControllerModelAUTO,
                                   TNLibvirtDeviceControllerModelBUSLOGIC,
                                   TNLibvirtDeviceControllerModelIBMVSCSI,
                                   TNLibvirtDeviceControllerModelLSILOGIC,
                                   TNLibvirtDeviceControllerModelLSIAS1068,
                                   TNLibvirtDeviceControllerModelVIRTIOSCSI,
                                   TNLibvirtDeviceControllerModelVMPVSCSI,
                                   TNLibvirtDeviceControllerModelPIIX3UHCI,
                                   TNLibvirtDeviceControllerModelPIIX34UHCI,
                                   TNLibvirtDeviceControllerModelEHCI,
                                   TNLibvirtDeviceControllerModelICH9EHCI1,
                                   TNLibvirtDeviceControllerModelICH9UHCI1,
                                   TNLibvirtDeviceControllerModelICH9UHCI2,
                                   TNLibvirtDeviceControllerModelICH9UHCI3,
                                   TNLibvirtDeviceControllerModelVT82C686BUHCI,
                                   TNLibvirtDeviceControllerModelPCIOHCI,
                                   TNLibvirtDeviceControllerModelNECXHCI,
                                   TNLibvirtDeviceControllerModelNONE];



/*! @ingroup virtualmachinedefinition
    Model for controllers
*/
@implementation TNLibvirtDeviceController : TNLibvirtBase
{
    CPString                            _type       @accessors(property=type);
    CPString                            _index      @accessors(property=index);
    CPString                            _model      @accessors(property=model);
    CPString                            _port       @accessors(property=port);
    CPString                            _vector     @accessors(property=vector);

    TNLibvirtDeviceControllerAddress    _address    @accessors(property=vector);
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
        if ([aNode name] != @"controller")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid controller"];

        _type   = [aNode valueForAttribute:@"type"];
        _index  = [aNode valueForAttribute:@"index"];
        _model  = [aNode valueForAttribute:@"model"];
        _port   = [aNode valueForAttribute:@"port"];
        _vector = [aNode valueForAttribute:@"vector"];

        if ([aNode containsChildrenWithName:@"address"])
            _address = [[TNLibvirtDeviceControllerAddress alloc] initWithXMLNode:[aNode firstChildWithName:@"address"]];

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
        [CPException raise:@"Missing controller type" reason:@"controller type is required"];

    if (_index === nil)
        [CPException raise:@"Missing controller index" reason:@"controller index is required"];

    var node = [TNXMLNode nodeWithName:@"controller" andAttributes:{@"type": _type, @"index": _index}];

    if (_model)
        [node setValue:_model forAttribute:@"model"];

    if (_port)
        [node setValue:_port forAttribute:@"port"];

    if (_vector)
        [node setValue:_vector forAttribute:@"vector"];

    if (_address)
    {
        [node addNode:[_address XMLNode]];
        [node up];
    }

    return node;
}

@end

