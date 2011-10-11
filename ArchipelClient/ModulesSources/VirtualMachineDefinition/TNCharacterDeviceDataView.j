/*
 * TNCharacterDeviceDataView.j
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

@import "Model/TNLibvirtDeviceCharacter.j"

var TNCharacterDeviceDataViewIconCONSOLE,
    TNCharacterDeviceDataViewIconSERIAL,
    TNCharacterDeviceDataViewIconCHANNEL,
    TNCharacterDeviceDataViewIconPARALLEL;

/*! @ingroup virtualmachinedefinition
    This is a representation of a character device in the table
*/
@implementation TNCharacterDeviceDataView : TNBasicDataView
{
    @outlet     CPImageView     imageIcon;

    @outlet     CPTextField     fieldProtocolType;
    @outlet     CPTextField     fieldSourceHost;
    @outlet     CPTextField     fieldSourceMode;
    @outlet     CPTextField     fieldSourcePath;
    @outlet     CPTextField     fieldSourceService;
    @outlet     CPTextField     fieldTargetAddress;
    @outlet     CPTextField     fieldTargetName;
    @outlet     CPTextField     fieldTargetPort;
    @outlet     CPTextField     fieldTargetType;
    @outlet     CPTextField     fieldType;

    @outlet     CPTextField     labelSource;
    @outlet     CPTextField     labelTarget;
    @outlet     CPTextField     labelProtocol;

    @outlet     CPTextField     labelTitle;
    @outlet     CPTextField     labelProtocolType;
    @outlet     CPTextField     labelSourceHost;
    @outlet     CPTextField     labelSourceMode;
    @outlet     CPTextField     labelSourcePath;
    @outlet     CPTextField     labelSourceService;
    @outlet     CPTextField     labelTargetAddress;
    @outlet     CPTextField     labelTargetName;
    @outlet     CPTextField     labelTargetPort;
    @outlet     CPTextField     labelTargetType;

    TNLibvirtDeviceCharacter    _currentCharacterDevice;
}


#pragma mark -
#pragma mark Initialization

+ (void)initialize
{
    var bundle = [CPBundle bundleForClass:TNCharacterDeviceDataView];

    TNCharacterDeviceDataViewIconCONSOLE    = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"character_console.png"]];
    TNCharacterDeviceDataViewIconSERIAL     = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"character_serial.png"]];
    TNCharacterDeviceDataViewIconCHANNEL    = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"character_channel.png"]];
    TNCharacterDeviceDataViewIconPARALLEL   = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"character_parallel.png"]];
}

#pragma mark -
#pragma mark Overides

/*! Set the current object Value
    @param aGraphicDevice the graphic device to represent
*/
- (void)setObjectValue:(TNLibvirtDeviceCharacter)aCharacterDevice
{
    _currentCharacterDevice = aCharacterDevice;

    [fieldType removeFromSuperview];
    [self addSubview:fieldType];

    switch ([_currentCharacterDevice kind])
    {
        case TNLibvirtDeviceCharacterKindConsole:
            [imageIcon setImage:TNCharacterDeviceDataViewIconCONSOLE];
            break;

        case TNLibvirtDeviceCharacterKindSerial:
            [imageIcon setImage:TNCharacterDeviceDataViewIconSERIAL];
            break;

        case TNLibvirtDeviceCharacterKindChannel:
            [imageIcon setImage:TNCharacterDeviceDataViewIconCHANNEL];
            break;

        case TNLibvirtDeviceCharacterKindParallel:
            [imageIcon setImage:TNCharacterDeviceDataViewIconPARALLEL];
            break;
    }

    [labelTitle setStringValue:[CPString stringWithFormat:CPLocalizedString(@"%s %s device", @"%s %s device"),
                                                            [[_currentCharacterDevice type] uppercaseString],
                                                            [[_currentCharacterDevice kind] lowercaseString]]];

    [fieldType setStringValue:[[_currentCharacterDevice type] uppercaseString]];

    [fieldSourceHost setStringValue:[[_currentCharacterDevice source] host] || @"None"];
    [fieldSourceMode setStringValue:[[_currentCharacterDevice source] mode] || @"None"];
    [fieldSourcePath setStringValue:[[_currentCharacterDevice source] path] || @"None"];
    [fieldSourceService setStringValue:[[_currentCharacterDevice source] service] || @"None"];

    [fieldTargetAddress setStringValue:[[_currentCharacterDevice target] address] || @"None"];
    [fieldTargetName setStringValue:[[_currentCharacterDevice target] name] || @"None"];
    [fieldTargetPort setStringValue:[[_currentCharacterDevice target] port] || @"None"];
    [fieldTargetType setStringValue:[[_currentCharacterDevice target] type] || @"None"];

    [fieldProtocolType setStringValue:[[_currentCharacterDevice protocol] type] || @"None"];
}


#pragma mark -
#pragma mark CPCoding

/*! CPCoder compliance
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        imageIcon           = [aCoder decodeObjectForKey:@"imageIcon"];
        labelProtocol       = [aCoder decodeObjectForKey:@"labelProtocol"];
        labelSource         = [aCoder decodeObjectForKey:@"labelSource"];
        labelTarget         = [aCoder decodeObjectForKey:@"labelTarget"];
        labelTitle          = [aCoder decodeObjectForKey:@"labelTitle"];

        fieldProtocolType   = [aCoder decodeObjectForKey:@"fieldProtocolType"];
        fieldSourceHost     = [aCoder decodeObjectForKey:@"fieldSourceHost"];
        fieldSourceMode     = [aCoder decodeObjectForKey:@"fieldSourceMode"];
        fieldSourcePath     = [aCoder decodeObjectForKey:@"fieldSourcePath"];
        fieldSourceService  = [aCoder decodeObjectForKey:@"fieldSourceService"];
        fieldTargetAddress  = [aCoder decodeObjectForKey:@"fieldTargetAddress"];
        fieldTargetName     = [aCoder decodeObjectForKey:@"fieldTargetName"];
        fieldTargetPort     = [aCoder decodeObjectForKey:@"fieldTargetPort"];
        fieldTargetType     = [aCoder decodeObjectForKey:@"fieldTargetType"];
        fieldType           = [aCoder decodeObjectForKey:@"fieldType"];

        labelProtocolType   = [aCoder decodeObjectForKey:@"labelProtocolType"];
        labelSourceHost     = [aCoder decodeObjectForKey:@"labelSourceHost"];
        labelSourceMode     = [aCoder decodeObjectForKey:@"labelSourceMode"];
        labelSourcePath     = [aCoder decodeObjectForKey:@"labelSourcePath"];
        labelSourceService  = [aCoder decodeObjectForKey:@"labelSourceService"];
        labelTargetAddress  = [aCoder decodeObjectForKey:@"labelTargetAddress"];
        labelTargetName     = [aCoder decodeObjectForKey:@"labelTargetName"];
        labelTargetPort     = [aCoder decodeObjectForKey:@"labelTargetPort"];
        labelTargetType     = [aCoder decodeObjectForKey:@"labelTargetType"];
    }

    return self;
}

/*! CPCoder compliance
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:imageIcon forKey:@"imageIcon"];
    [aCoder encodeObject:labelProtocol forKey:@"labelProtocol"];
    [aCoder encodeObject:labelSource forKey:@"labelSource"];
    [aCoder encodeObject:labelTarget forKey:@"labelTarget"];
    [aCoder encodeObject:labelTitle forKey:@"labelTitle"];

    [aCoder encodeObject:fieldProtocolType forKey:@"fieldProtocolType"];
    [aCoder encodeObject:fieldSourceHost forKey:@"fieldSourceHost"];
    [aCoder encodeObject:fieldSourceMode forKey:@"fieldSourceMode"];
    [aCoder encodeObject:fieldSourcePath forKey:@"fieldSourcePath"];
    [aCoder encodeObject:fieldSourceService forKey:@"fieldSourceService"];
    [aCoder encodeObject:fieldTargetAddress forKey:@"fieldTargetAddress"];
    [aCoder encodeObject:fieldTargetName forKey:@"fieldTargetName"];
    [aCoder encodeObject:fieldTargetPort forKey:@"fieldTargetPort"];
    [aCoder encodeObject:fieldTargetType forKey:@"fieldTargetType"];
    [aCoder encodeObject:fieldType forKey:@"fieldType"];

    [aCoder encodeObject:labelProtocolType forKey:@"labelProtocolType"];
    [aCoder encodeObject:labelSourceHost forKey:@"labelSourceHost"];
    [aCoder encodeObject:labelSourceMode forKey:@"labelSourceMode"];
    [aCoder encodeObject:labelSourcePath forKey:@"labelSourcePath"];
    [aCoder encodeObject:labelSourceService forKey:@"labelSourceService"];
    [aCoder encodeObject:labelTargetAddress forKey:@"labelTargetAddress"];
    [aCoder encodeObject:labelTargetName forKey:@"labelTargetName"];
    [aCoder encodeObject:labelTargetPort forKey:@"labelTargetPort"];
    [aCoder encodeObject:labelTargetType forKey:@"labelTargetType"];
}

@end