/*
 * TNLibvirtDeviceDiskTarget.j
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

TNLibvirtDeviceDiskTargetDeviceHda      = @"hda";
TNLibvirtDeviceDiskTargetDeviceHdb      = @"hdb";
TNLibvirtDeviceDiskTargetDeviceHdc      = @"hdc";
TNLibvirtDeviceDiskTargetDeviceHdd      = @"hdd";
TNLibvirtDeviceDiskTargetDeviceSda      = @"sda";
TNLibvirtDeviceDiskTargetDeviceSdb      = @"sdb";
TNLibvirtDeviceDiskTargetDeviceSdc      = @"sdc";
TNLibvirtDeviceDiskTargetDeviceSdd      = @"sdd";
TNLibvirtDeviceDiskTargetDeviceXVDA     = @"xvda";
TNLibvirtDeviceDiskTargetDeviceXVDB     = @"xvdb";
TNLibvirtDeviceDiskTargetDeviceXVDC     = @"xvdc";
TNLibvirtDeviceDiskTargetDeviceXVDD     = @"xvdd";
TNLibvirtDeviceDiskTargetDeviceVDA      = @"vda";
TNLibvirtDeviceDiskTargetDeviceVDB      = @"vdb";
TNLibvirtDeviceDiskTargetDeviceVDC      = @"vdc";
TNLibvirtDeviceDiskTargetDeviceVDD      = @"vdd";
TNLibvirtDeviceDiskTargetDevices        = [ TNLibvirtDeviceDiskTargetDeviceHda, TNLibvirtDeviceDiskTargetDeviceHdb,
                                            TNLibvirtDeviceDiskTargetDeviceHdc, TNLibvirtDeviceDiskTargetDeviceHdd,
                                            TNLibvirtDeviceDiskTargetDeviceSda, TNLibvirtDeviceDiskTargetDeviceSdb,
                                            TNLibvirtDeviceDiskTargetDeviceSdc, TNLibvirtDeviceDiskTargetDeviceSdd,
                                            TNLibvirtDeviceDiskTargetDeviceXVDA, TNLibvirtDeviceDiskTargetDeviceXVDB,
                                            TNLibvirtDeviceDiskTargetDeviceXVDC, TNLibvirtDeviceDiskTargetDeviceXVDD,
                                            TNLibvirtDeviceDiskTargetDeviceVDA, TNLibvirtDeviceDiskTargetDeviceVDB,
                                            TNLibvirtDeviceDiskTargetDeviceVDC, TNLibvirtDeviceDiskTargetDeviceVDD];

TNLibvirtDeviceDiskTargetDevicesIDE     = [ TNLibvirtDeviceDiskTargetDeviceHda, TNLibvirtDeviceDiskTargetDeviceHdb,
                                            TNLibvirtDeviceDiskTargetDeviceHdc, TNLibvirtDeviceDiskTargetDeviceHdd];

TNLibvirtDeviceDiskTargetDevicesSCSI    = [ TNLibvirtDeviceDiskTargetDeviceSda, TNLibvirtDeviceDiskTargetDeviceSdb,
                                            TNLibvirtDeviceDiskTargetDeviceSdc, TNLibvirtDeviceDiskTargetDeviceSdd];

TNLibvirtDeviceDiskTargetDevicesXEN     = [ TNLibvirtDeviceDiskTargetDeviceXVDA, TNLibvirtDeviceDiskTargetDeviceXVDB,
                                            TNLibvirtDeviceDiskTargetDeviceXVDC, TNLibvirtDeviceDiskTargetDeviceXVDD];

TNLibvirtDeviceDiskTargetDevicesVIRTIO  = [ TNLibvirtDeviceDiskTargetDeviceVDA, TNLibvirtDeviceDiskTargetDeviceVDB,
                                            TNLibvirtDeviceDiskTargetDeviceVDC, TNLibvirtDeviceDiskTargetDeviceVDD];


TNLibvirtDeviceDiskTargetBusIDE         = @"ide";
TNLibvirtDeviceDiskTargetBusSCSI        = @"scsi";
TNLibvirtDeviceDiskTargetBusUSB         = @"usb";
TNLibvirtDeviceDiskTargetBusVIRTIO      = @"virtio";
TNLibvirtDeviceDiskTargetBusXEN         = @"xen";
TNLibvirtDeviceDiskTargetBuses          = [ TNLibvirtDeviceDiskTargetBusIDE,
                                            TNLibvirtDeviceDiskTargetBusSCSI,
                                            TNLibvirtDeviceDiskTargetBusVIRTIO,
                                            TNLibvirtDeviceDiskTargetBusUSB,
                                            TNLibvirtDeviceDiskTargetBusXEN];


/*! @ingroup virtualmachinedefinition
    Model for disk target
*/
@implementation TNLibvirtDeviceDiskTarget : TNLibvirtBase
{
    CPString    _bus            @accessors(property=bus);
    CPString    _device         @accessors(property=device);
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
        if ([aNode name] != @"target")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid disk target"];

        _bus    = [aNode valueForAttribute:@"bus"];
        _device = [aNode valueForAttribute:@"dev"];
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
    var node = [TNXMLNode nodeWithName:@"target"];

    if (_bus)
        [node setValue:_bus forAttribute:@"bus"];
    if (_device)
        [node setValue:_device forAttribute:@"dev"];

    return node;
}
@end
