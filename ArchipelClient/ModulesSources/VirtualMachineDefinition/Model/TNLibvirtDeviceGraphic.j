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

TNLibvirtDeviceGraphicTypeVNC           = @"vnc";
TNLibvirtDeviceGraphicTypeSDL           = @"sdl";
TNLibvirtDeviceGraphicTypeRDP           = @"rdp";
TNLibvirtDeviceGraphicTypeSPICE         = @"spice";
TNLibvirtDeviceGraphicTypeDESKTOP       = @"desktop";

TNLibvirtDeviceGraphicVNCKeymapFR           = @"fr";
TNLibvirtDeviceGraphicVNCKeymapFR_CH        = @"fr-ch";
TNLibvirtDeviceGraphicVNCKeymapEN_US        = @"en-us";
TNLibvirtDeviceGraphicVNCKeymapEN_GB        = @"en-gb";
TNLibvirtDeviceGraphicVNCKeymapDE           = @"de";
TNLibvirtDeviceGraphicVNCKeymapES           = @"es";
TNLibvirtDeviceGraphicVNCKeymapNO           = @"no";
TNLibvirtDeviceGraphicVNCKeymapHU           = @"hu";
TNLibvirtDeviceGraphicVNCKeymapIT           = @"it";
TNLibvirtDeviceGraphicVNCKeymapNL_BE        = @"nl-be";
TNLibvirtDeviceGraphicVNCKeymapPT           = @"pt";


TNLibvirtDeviceGraphicVNCKeymaps        = [ TNLibvirtDeviceGraphicVNCKeymapEN_US,
                                            TNLibvirtDeviceGraphicVNCKeymapEN_GB,
                                            TNLibvirtDeviceGraphicVNCKeymapFR,
                                            TNLibvirtDeviceGraphicVNCKeymapFR_CH,
                                            TNLibvirtDeviceGraphicVNCKeymapDE,
                                            TNLibvirtDeviceGraphicVNCKeymapES,
                                            TNLibvirtDeviceGraphicVNCKeymapNO,
                                            TNLibvirtDeviceGraphicVNCKeymapHU,
                                            TNLibvirtDeviceGraphicVNCKeymapIT,
                                            TNLibvirtDeviceGraphicVNCKeymapNL_BE,
                                            TNLibvirtDeviceGraphicVNCKeymapPT];


/*! @ingroup virtualmachinedefinition
    Model for graphics
*/
@implementation TNLibvirtDeviceGraphic : TNLibvirtBase
{
    BOOL        _autoPort       @accessors(getter=isAutoPort, setter=setAutoPort:);
    BOOL        _fullScreen     @accessors(getter=isFullScreen, setter=setFullScreen:);
    BOOL        _multiUser      @accessors(getter=isMultiUser, setter=setMultiUser:);
    CPString    _display        @accessors(property=display);
    CPString    _keymap         @accessors(property=keymap);
    CPString    _listen         @accessors(property=listen);
    CPString    _password       @accessors(property=password);
    CPString    _port           @accessors(property=port);
    CPString    _type           @accessors(property=type);
}


#pragma mark -
#pragma mark Initialization

/*! initialize the TNLibvirtDeviceGraphic
*/
- (TNLibvirtDeviceGraphic)init
{
    if (self = [super init])
    {
        _keymap = TNLibvirtDeviceGraphicVNCKeymapEN_US;
        _type = TNLibvirtDeviceGraphicTypeVNC;
        _autoPort = YES;
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
        if ([aNode name] != @"graphics")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid graphics"];

        _autoPort   = ([aNode valueForAttribute:@"autoport"] == @"yes") ? YES : NO;
        _display    = [aNode valueForAttribute:@"display"];
        _fullScreen = ([aNode valueForAttribute:@"fullscreen"] == @"yes") ? YES : NO;
        _keymap     = [aNode valueForAttribute:@"keymap"];
        _listen     = [aNode valueForAttribute:@"listen"];
        _multiUser  = ([aNode valueForAttribute:@"multiUser"] == @"yes") ? YES : NO;
        _password   = [aNode valueForAttribute:@"passwd"];
        _port       = [aNode valueForAttribute:@"port"];
        _type       = [aNode valueForAttribute:@"type"];
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
        [CPException raise:@"Missing graphic type" reason:@"graphic type is required"];

    var node = [TNXMLNode nodeWithName:@"graphics" andAttributes:{@"type": _type}];

    if (_display)
        [node setValue:_display forAttribute:@"display"];
    if (_port)
        [node setValue:_port forAttribute:@"port"];
    if (_keymap)
        [node setValue:_keymap forAttribute:@"keymap"];
    if (_listen)
        [node setValue:_listen forAttribute:@"listen"];
    if (_password)
        [node setValue:_password forAttribute:@"passwd"];
    if (_autoPort != nil)
        [node setValue:(_autoPort ? @"yes" : @"no") forAttribute:@"autoport"];
    if (_multiUser != nil)
        [node setValue:(_multiUser ? @"yes" : @"no") forAttribute:@"multiUser"];
    if (_fullScreen != nil)
        [node setValue:(_fullScreen ? @"yes" : @"no") forAttribute:@"fullscreen"];

    return node;
}

@end
