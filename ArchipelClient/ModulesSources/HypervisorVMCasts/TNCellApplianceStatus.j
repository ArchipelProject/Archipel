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

@import <AppKit/CPImage.j>
@import <AppKit/CPImageView.j>
@import <AppKit/CPTextField.j>


var TNCellApplianceStatusIconInstalled,
    TNCellApplianceStatusIconInstalling,
    TNCellApplianceStatusIconNotInstalled,
    TNCellApplianceStatusIconError;

/*! @ingroup hypervisorvmcasts
    View that that represent the datacell for column status
*/
@implementation TNCellApplianceStatus : CPView
{
    CPImageView     _imageStatus;
    CPTextField     _fieldStatus;
}

#pragma mark -
#pragma mark Initialization

+ (void)initialize
{
    var bundle  = [CPBundle mainBundle];

    TNCellApplianceStatusIconInstalled      = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"IconsStatus/green.png"] size:CPSizeMake(8.0, 8.0)];
    TNCellApplianceStatusIconNotInstalled   = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"IconsStatus/gray.png"] size:CPSizeMake(8.0, 8.0)];
    TNCellApplianceStatusIconError          = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"IconsStatus/red.png"] size:CPSizeMake(8.0, 8.0)];
    TNCellApplianceStatusIconInstalling     = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"spinner.gif"] size:CPSizeMake(8.0, 8.0)];
}


/*! initialize the view
*/
- (id)init
{
    if (self = [super init])
    {
        _imageStatus = [[CPImageView alloc] initWithFrame:CGRectMake(0, 8, 8, 8)];
        _fieldStatus = [[CPTextField alloc] initWithFrame:CGRectMake(15, 2, 200, 100)];

        [self addSubview:_imageStatus];
        [self addSubview:_fieldStatus];

        [_fieldStatus setValue:[CPColor whiteColor] forThemeAttribute:@"text-color" inState:CPThemeStateSelected];
        [_fieldStatus setValue:[CPFont boldSystemFontOfSize:12] forThemeAttribute:@"font" inState:CPThemeStateSelected];
    }

    return self;
}

/*! set the object value of the cell
    @pathForResource aStatus the status to display
*/
- (void)setObjectValue:(id)aStatus
{
    [_fieldStatus setStringValue:TNArchipelApplianceStatusString[aStatus]];
    [_fieldStatus sizeToFit];

    if (aStatus == TNArchipelApplianceInstalled)
        [_imageStatus setImage:TNCellApplianceStatusIconInstalled]
    else if (aStatus == TNArchipelApplianceInstalling)
        [_imageStatus setImage:TNCellApplianceStatusIconInstalling];
    else if (aStatus == TNArchipelApplianceInstallationError)
        [_imageStatus setImage:TNCellApplianceStatusIconError];
    else if (aStatus == TNArchipelApplianceNotInstalled)
        [_imageStatus setImage:TNCellApplianceStatusIconNotInstalled];
    else
        [_imageStatus setImage:nil];
}

#pragma mark -
#pragma mark Theming
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


#pragma mark -
#pragma mark CPCoding compliance

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        _fieldStatus = [aCoder decodeObjectForKey:@"_fieldStatus"];
        _imageStatus = [aCoder decodeObjectForKey:@"_imageStatus"];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:_fieldStatus forKey:@"_fieldStatus"];
    [aCoder encodeObject:_imageStatus forKey:@"_imageStatus"];
}

@end
