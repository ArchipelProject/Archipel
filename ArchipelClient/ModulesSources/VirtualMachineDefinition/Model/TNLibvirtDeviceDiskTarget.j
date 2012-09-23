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

TNLibvirtDeviceDiskTargetDevices        = [];
TNLibvirtDeviceDiskTargetDevicesIDE     = [];
TNLibvirtDeviceDiskTargetDevicesSCSI    = [];
TNLibvirtDeviceDiskTargetDevicesXEN     = [];
TNLibvirtDeviceDiskTargetDevicesVIRTIO  = [];
TNLibvirtDeviceDiskTargetDevicesSATA    = [];

TNLibvirtDeviceDiskTargetBusSATA        = @"sata";
TNLibvirtDeviceDiskTargetBusIDE         = @"ide";
TNLibvirtDeviceDiskTargetBusSCSI        = @"scsi";
TNLibvirtDeviceDiskTargetBusUSB         = @"usb";
TNLibvirtDeviceDiskTargetBusVIRTIO      = @"virtio";
TNLibvirtDeviceDiskTargetBusXEN         = @"xen";
TNLibvirtDeviceDiskTargetBuses          = [ TNLibvirtDeviceDiskTargetBusIDE,
                                            TNLibvirtDeviceDiskTargetBusSATA,
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

+ (void)initialize
{
    letters = ["a", "b", "c", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n",
                "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"];

    for (var i = 0; i < [letters count]; i++)
    {
        [TNLibvirtDeviceDiskTargetDevicesIDE addObject:@"hd" + [letters objectAtIndex:i]];
        [TNLibvirtDeviceDiskTargetDevicesSCSI addObject:@"sd" + [letters objectAtIndex:i]];
        [TNLibvirtDeviceDiskTargetDevicesXEN addObject:@"xvd" + [letters objectAtIndex:i]];
        [TNLibvirtDeviceDiskTargetDevicesVIRTIO addObject:@"vd" + [letters objectAtIndex:i]];
    }

    TNLibvirtDeviceDiskTargetDevices = [].concat( TNLibvirtDeviceDiskTargetDevicesIDE,
                                                TNLibvirtDeviceDiskTargetDevicesSCSI,
                                                TNLibvirtDeviceDiskTargetDevicesXEN,
                                                TNLibvirtDeviceDiskTargetDevicesVIRTIO);
}

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
