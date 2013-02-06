/*
 * TNLibvirtDeviceHostDev.j
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
@import "TNLibvirtDeviceHostDevSource.j"
@import "TNLibvirtDeviceHostDevBoot.j"
@import "TNLibvirtDeviceHostDevRom.j"


TNLibvirtDeviceHostDevModeSubsystem     = @"subsystem";
TNLibvirtDeviceHostDevModes             = [TNLibvirtDeviceHostDevModeSubsystem];

TNLibvirtDeviceHostDevTypePCI           = @"PCI";
TNLibvirtDeviceHostDevTypeUSB           = @"USB";
TNLibvirtDeviceHostDevTypes             = [TNLibvirtDeviceHostDevTypePCI, TNLibvirtDeviceHostDevTypeUSB];


/*! @ingroup virtualmachinedefinition
    Model for hostdev
*/
@implementation TNLibvirtDeviceHostDev : TNLibvirtBase
{
    BOOL                            _managed    @accessors(getter=isManaged, setter=setManaged:);
    CPString                        _mode       @accessors(property=mode);
    CPString                        _type       @accessors(property=type);

    TNLibvirtDeviceHostDevBoot      _boot       @accessors(property=boot);
    TNLibvirtDeviceHostDevRom       _rom        @accessors(property=rom);
    TNLibvirtDeviceHostDevSource    _source     @accessors(property=source);
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
        if ([aNode name] != @"hostdev")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid hostdev"];

        if ([aNode valueForAttribute:@"managed"])
            _managed = [aNode valueForAttribute:@"managed"] == @"yes" ? YES : NO;

        _mode = [aNode valueForAttribute:@"mode"];
        _type = [aNode valueForAttribute:@"type"];

        if ([aNode containsChildrenWithName:@"boot"])
            _boot = [[TNLibvirtDeviceHostDevBoot alloc] initWithXMLNode:[aNode firstChildWithName:@"boot"]];
        if ([aNode containsChildrenWithName:@"rom"])
            _rom = [[TNLibvirtDeviceHostDevRom alloc] initWithXMLNode:[aNode firstChildWithName:@"rom"]];
        if ([aNode containsChildrenWithName:@"source"])
            _source = [[TNLibvirtDeviceHostDevSource alloc] initWithXMLNode:[aNode firstChildWithName:@"source"]];
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
    var node = [TNXMLNode nodeWithName:@"hostdev"];

    if (_type)
        [node setValue:_type forAttribute:@"type"];
    if (_mode)
        [node setValue:_mode forAttribute:@"mode"];
    if (_managed !== nil)
        [node setValue:_managed ? @"yes" : @"false" forAttribute:@"managed"];

    if (_source)
    {
        [node addNode:[_source XMLNode]];
        [node up];
    }
    if (_boot)
    {
        [node addNode:[_boot XMLNode]];
        [node up];
    }
    if (_rom)
    {
        [node addNode:[_rom XMLNode]];
        [node up];
    }

    return node;
}

@end
