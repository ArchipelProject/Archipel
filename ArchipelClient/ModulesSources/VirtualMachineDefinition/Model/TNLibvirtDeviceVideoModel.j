/*
 * TNLibvirtDeviceVideoModel.j
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


TNLibvirtDeviceVideoModelVGA        = @"vga";
TNLibvirtDeviceVideoModelCIRRUS     = @"cirrus";
TNLibvirtDeviceVideoModelVMVGA      = @"vmvga";
TNLibvirtDeviceVideoModelXEN        = @"xen";
TNLibvirtDeviceVideoModelVBOX       = @"vbox";
TNLibvirtDeviceVideoModelQXL        = @"qxl";

TNLibvirtDeviceVideoModels          = [ TNLibvirtDeviceVideoModelVGA,
                                        TNLibvirtDeviceVideoModelCIRRUS,
                                        TNLibvirtDeviceVideoModelVMVGA,
                                        TNLibvirtDeviceVideoModelXEN,
                                        TNLibvirtDeviceVideoModelVBOX,
                                        TNLibvirtDeviceVideoModelQXL];


/*! @ingroup virtualmachinedefinition
    Model for video model
*/
@implementation TNLibvirtDeviceVideoModel : TNLibvirtBase
{
    CPString    _heads  @accessors(property=heads);
    CPString    _type   @accessors(property=type);
    CPString    _vram   @accessors(property=vram);
}


#pragma mark -
#pragma mark Initialization

/*! initialize the TNLibvirtDeviceVideoModel
*/
- (TNLibvirtDeviceVideoModel)init
{
    if (self = [super init])
    {
        _type = TNLibvirtDeviceVideoModelCIRRUS;
        _vram = @"9216";
        _head = @"1";
    }

    return self;
}

/*! initialize the object with a given XML node
    @param aNode the node to use
*/
- (id)initWithXMLNode:(TNXMLNode)aNode
{
    if (self = [super initWithXMLNode:aNode])
    {
        if ([aNode name] != @"model")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid video model"];

        _type = [aNode valueForAttribute:@"type"];
        _vram = [aNode valueForAttribute:@"vram"];
        _heads = [aNode valueForAttribute:@"heads"];
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
        [CPException raise:@"Missing video model type" reason:@"video model type is required"];

    var node = [TNXMLNode nodeWithName:@"model" andAttributes:{@"type": _type}];

    if (_vram)
        [node setValue:_vram forAttribute:@"vram"];
    if (_heads)
        [node setValue:_heads forAttribute:@"heads"];

    return node;
}

@end
