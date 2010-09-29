/*
 * TNCellApplianceStatus.j
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

@implementation TNCellApplianceStatus : CPView
{
    CPImageView     _imageStatus;
    CPTextField     _fieldStatus;
    CPImage         _iconInstalled;
    CPImage         _iconInstalling;
    CPImage         _iconNotInstalled;
    CPImage         _iconError;
}

- (id)init
{
    if (self = [super init])
    {
        _imageStatus = [[CPImageView alloc] initWithFrame:CGRectMake(0, 3, 16, 16)];
        _fieldStatus = [[CPTextField alloc] initWithFrame:CGRectMake(15, 2, 200, 100)];

        [self addSubview:_imageStatus];
        [self addSubview:_fieldStatus];

        [_fieldStatus setValue:[CPColor whiteColor] forThemeAttribute:@"text-color" inState:CPThemeStateSelected];
        [_fieldStatus setValue:[CPFont boldSystemFontOfSize:12] forThemeAttribute:@"font" inState:CPThemeStateSelected];

        var bundle          = [CPBundle bundleForClass:[self class]];
        _iconInstalled      = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"installed.png"]];
        _iconInstalling     = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"installing.gif"]];
        _iconNotInstalled   = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"notinstalled.png"]];
        _iconError          = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"error.png"]];
    }

    return self;
}

- (void)setObjectValue:(id)aStatus
{
    [_fieldStatus setStringValue:TNArchipelApplianceStatusString[aStatus]];
    [_fieldStatus sizeToFit];

    if (aStatus == TNArchipelApplianceInstalled)
        [_imageStatus setImage:_iconInstalled];
    else if (aStatus == TNArchipelApplianceInstalling)
        [_imageStatus setImage:_iconInstalling];
    else if (aStatus == TNArchipelApplianceInstallationError)
        [_imageStatus setImage:_iconError];
    else if (aStatus == TNArchipelApplianceNotInstalled)
        [_imageStatus setImage:_iconNotInstalled];
    else
        [_imageStatus setImage:nil];
}

/*! implement theming in order to allow change color of selected item
*/
- (void)setThemeState:(id)aState
{
    [super setThemeState:aState];
    [_fieldStatus setThemeState:aState];
    [_fieldStatus sizeToFit];
}

/*! implement theming in order to allow change color of selected item
*/
- (void)unsetThemeState:(id)aState
{
    [super unsetThemeState:aState];
    [_fieldStatus unsetThemeState:aState];
    [_fieldStatus sizeToFit];
}

/*! CPCoder compliance
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        _fieldStatus        = [aCoder decodeObjectForKey:@"_fieldStatus"];
        _imageStatus        = [aCoder decodeObjectForKey:@"_imageStatus"];
        _iconNotInstalled   = [aCoder decodeObjectForKey:@"_iconNotInstalled"];
        _iconInstalled      = [aCoder decodeObjectForKey:@"_iconInstalled"];
        _iconInstalling     = [aCoder decodeObjectForKey:@"_iconInstalling"];
        _iconError          = [aCoder decodeObjectForKey:@"_iconError"];
    }

    return self;
}

/*! CPCoder compliance
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:_fieldStatus forKey:@"_fieldStatus"];
    [aCoder encodeObject:_imageStatus forKey:@"_imageStatus"];
    [aCoder encodeObject:_iconNotInstalled forKey:@"_iconNotInstalled"];
    [aCoder encodeObject:_iconInstalled forKey:@"_iconInstalled"];
    [aCoder encodeObject:_iconInstalling forKey:@"_iconInstalling"];
    [aCoder encodeObject:_iconError forKey:@"_iconError"];
}
@end