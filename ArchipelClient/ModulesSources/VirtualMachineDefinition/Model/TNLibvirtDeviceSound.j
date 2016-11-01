/*
 * TNLibvirtDeviceSound.j
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


TNLibvirtDeviceSoundModelES1370             = @"es1370";
TNLibvirtDeviceSoundModelSB16               = @"sb16";
TNLibvirtDeviceSoundModelAC97               = @"ac97";
TNLibvirtDeviceSoundModelICH6               = @"ich6";
TNLibvirtDeviceSoundModelUSB                = @"usb";

TNLibvirtDeviceSoundModels = [TNLibvirtDeviceSoundModelES1370,
                              TNLibvirtDeviceSoundModelSB16,
                              TNLibvirtDeviceSoundModelAC97,
                              TNLibvirtDeviceSoundModelICH6,
                              TNLibvirtDeviceSoundModelUSB];

TNLibvirtDeviceSoundCodecTypeDUPLEX         = "duplex";
TNLibvirtDeviceSoundCodecTypeMICRO          = "micro";

TNLibvirtDeviceSoundCodecTypes = [TNLibvirtDeviceSoundCodecTypeDUPLEX,
                                  TNLibvirtDeviceSoundCodecTypeMICRO];



/*! @ingroup virtualmachinedefinition
    Model for sound
*/
@implementation TNLibvirtDeviceSound : TNLibvirtBase
{
    CPString                            _model      @accessors(property=model);
    CPString                            _type       @accessors(property=type);
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
        if ([aNode name] != @"sound")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid sound card"];

        _model  = [aNode valueForAttribute:@"model"];
        if ([aNode containsChildrenWithName:@"codec"])
            _type             = [[aNode firstChildWithName:@"codec"] valueForAttribute:@"type"];
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
    if (!_model)
        [CPException raise:@"Missing sound model" reason:@"sound model is required"];

    var node = [TNXMLNode nodeWithName:@"sound" andAttributes:{@"model": _model}];

    if (_type)
    {
        [node addChildWithName:@"codec" andAttributes:{@"type": _type}];
        [node up];
    }

    return node;
}

@end
