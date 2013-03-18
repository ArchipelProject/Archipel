/*
 * TNNuageDataView.j
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

@import <AppKit/CPView.j>
@import <AppKit/CPImageView.j>
@import <AppKit/CPTextField.j>

@import "../../Views/TNBasicDataView.j"

var TNNuageDataViewIcon,
    TNNuageDataViewIconWhite;

/*! @ingroup hypervisornetworks
    This class represent a network DataView
*/
@implementation TNNuageDataView : TNBasicDataView
{
    @outlet CPImageView         imageIcon;
    @outlet CPTextField         fieldAddress;
    @outlet CPTextField         fieldDomain;
    @outlet CPTextField         fieldGateway;
    @outlet CPTextField         fieldInLimit;
    @outlet CPTextField         fieldName;
    @outlet CPTextField         fieldNetmask;
    @outlet CPTextField         fieldOutLimit;
    @outlet CPTextField         fieldType;
    @outlet CPTextField         fieldZone;

    @outlet CPTextField         labelInLimit;
    @outlet CPTextField         labelOutLimit;

    TNNuage                     _nuage;
}

#pragma mark -
#pragma mark Overrides

+ (void)initialize
{
    var bundle = [CPBundle bundleForClass:TNNuageDataView];

    TNNuageDataViewIcon = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"nuage.png"]]
    TNNuageDataViewIconWhite = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"nuage-white.png"]]
}

/*! Message used by CPOutlineView to set the value of the object
    @param aContact TNStropheContact to represent
*/
- (void)setObjectValue:(id)aNuage
{
    _nuage = aNuage;

    [fieldName setStringValue:[_nuage name]];
    [fieldType setStringValue:[_nuage type] || @""];
    [fieldDomain setStringValue:[_nuage domain] || @""];
    [fieldZone setStringValue:[_nuage zone]];
    [fieldAddress setStringValue:[[_nuage subnet] address] || @"Auto"];
    [fieldNetmask setStringValue:[[_nuage subnet] netmask] || @"Auto"];
    [fieldGateway setStringValue:[[_nuage subnet] gateway] || @"Auto"];


    [fieldInLimit setHidden:YES];
    [labelInLimit setHidden:YES];
    if ([[_nuage bandwidth] inbound])
    {
        var peak = [[[_nuage bandwidth] inbound] peak] || @"None",
            burst = [[[_nuage bandwidth] inbound] burst] || @"None";
        [fieldInLimit setStringValue:[CPString stringWithFormat:@"%s/%s", peak, burst]];
        [fieldInLimit setHidden:NO];
        [labelInLimit setHidden:NO];
    }

    [fieldOutLimit setHidden:YES];
    [labelOutLimit setHidden:YES];
    if ([[_nuage bandwidth] outbound])
    {
        var peak = [[[_nuage bandwidth] outbound] peak] || @"None",
            burst = [[[_nuage bandwidth] outbound] burst] || @"None";
        [fieldOutLimit setStringValue:[CPString stringWithFormat:@"%s/%s", peak, burst]];
        [fieldOutLimit setHidden:NO];
        [labelOutLimit setHidden:NO];
    }
}


- (void)setThemeState:(int)aThemeState
{
    [super setThemeState:aThemeState];

    if (aThemeState == CPThemeStateSelectedDataView)
        [imageIcon setImage:TNNuageDataViewIconWhite];
}

- (void)unsetThemeState:(int)aThemeState
{
    [super unsetThemeState:aThemeState];

    if (aThemeState == CPThemeStateSelectedDataView)
        [imageIcon setImage:TNNuageDataViewIcon];
}

#pragma mark -
#pragma mark CPCoding compliance

/*! CPCoder compliance
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        imageIcon = [aCoder decodeObjectForKey:@"imageIcon"];

        fieldName = [aCoder decodeObjectForKey:@"fieldName"];
        fieldType = [aCoder decodeObjectForKey:@"fieldType"];
        fieldAddress = [aCoder decodeObjectForKey:@"fieldAddress"];
        fieldNetmask = [aCoder decodeObjectForKey:@"fieldNetmask"];
        fieldGateway = [aCoder decodeObjectForKey:@"fieldGateway"];
        fieldInLimit = [aCoder decodeObjectForKey:@"fieldInLimit"];
        fieldOutLimit = [aCoder decodeObjectForKey:@"fieldOutLimit"];
        fieldDomain = [aCoder decodeObjectForKey:@"fieldDomain"];
        fieldZone = [aCoder decodeObjectForKey:@"fieldZone"];

        labelInLimit = [aCoder decodeObjectForKey:@"labelInLimit"];
        labelOutLimit = [aCoder decodeObjectForKey:@"labelOutLimit"];

        [imageIcon setImage:TNNuageDataViewIcon];
    }

    return self;
}

/*! CPCoder compliance
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:imageIcon forKey:@"imageIcon"];

    [aCoder encodeObject:fieldName forKey:@"fieldName"];
    [aCoder encodeObject:fieldType forKey:@"fieldType"];
    [aCoder encodeObject:fieldAddress forKey:@"fieldAddress"];
    [aCoder encodeObject:fieldNetmask forKey:@"fieldNetmask"];
    [aCoder encodeObject:fieldGateway forKey:@"fieldGateway"];
    [aCoder encodeObject:fieldInLimit forKey:@"fieldInLimit"];
    [aCoder encodeObject:fieldOutLimit forKey:@"fieldOutLimit"];
    [aCoder encodeObject:fieldDomain forKey:@"fieldDomain"];
    [aCoder encodeObject:fieldZone forKey:@"fieldZone"];

    [aCoder encodeObject:labelInLimit forKey:@"labelInLimit"];
    [aCoder encodeObject:labelOutLimit forKey:@"labelOutLimit"];
}

@end
