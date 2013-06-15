/*
 * TNCalendarView.j
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

@import <LPKit/LPCalendarView.j>

@implementation TNCalendarView : LPCalendarView

+ (id)themeAttributes
{
    var mainBundle    = [CPBundle mainBundle],
        bgImage       = CPColorWithImages(@"LPCalendarView/background.png", 1.0, 21.0, mainBundle),
        headerBgImage = CPColorWithImages(@"LPCalendarView/header-background.png", 182.0, 40.0, mainBundle),
        prevImage     = CPColorWithImages(@"LPCalendarView/previous.png", 16.0, 16.0, mainBundle),
        nextImage     = CPColorWithImages(@"LPCalendarView/next.png", 16.0, 16.0, mainBundle),
        bezelColor    = CPColorWithImages([[@"LPCalendarView/default-tile-bezel-left.png", 1.0, 21.0, mainBundle], [@"LPCalendarView/default-tile-bezel-center.png", 21.0, 21.0, mainBundle], nil]);

    return @{
            @"grid-color"                        :[CPColor colorWithHexString:@"ccc"],
            @"background-color"                  :bgImage,
            @"header-height"                     :40,
            @"header-background-color"           :headerBgImage,
            @"header-font"                       :[CPFont boldSystemFontOfSize:11.0],
            @"header-text-color"                 :[CPColor colorWithHexString:@"333"],
            @"header-text-shadow-color"          :[CPColor whiteColor],
            @"header-text-shadow-offset"         :CGSizeMake(1.0, 1.0),
            @"header-alignment"                  :CPCenterTextAlignment,
            @"header-button-offset"              :CGSizeMake(10, 7),
            @"header-prev-button-image"          :prevImage,
            @"header-next-button-image"          :nextImage,
            @"header-weekday-offset"             :25,
            @"header-weekday-label-font"         :[CPFont systemFontOfSize:9.0],
            @"header-weekday-label-color"        :[CPColor colorWithWhite:0 alpha:0.57],
            @"header-weekday-label-shadow-color" :[CPColor colorWithWhite:1 alpha:0.8],
            @"header-weekday-label-shadow-offset":CGSizeMake(0.0, 1.0),
            @"tile-size"                         :CGSizeMake(27, 21),
            @"tile-font"                         :[CPFont boldSystemFontOfSize:11.0],
            @"tile-text-color"                   :[CPColor colorWithHexString:@"333"],
            @"tile-text-shadow-color"            :[CPColor colorWithWhite:1 alpha:0.8],
            @"tile-text-shadow-offset"           :CGSizeMake(1.0, 1.0),
            @"tile-bezel-color"                  :bezelColor
            };
}


- (id)initWithFrame:(CGRect)aFrame
{
    // aFrame.size.width = 195;
    // aFrame.size.height = 172;

    if (self = [super initWithFrame:aFrame])
    {
        var mainBundle                    = [CPBundle mainBundle],
            highlightedBezelColor         = CPColorWithImages([nil, [@"LPCalendarView/highlighted-tile-bezel.png",          21.0, 21.0, mainBundle], nil]),
            selectedBezelColor            = CPColorWithImages([nil, [@"LPCalendarView/selected-tile-bezel.png",             15.0, 15.0, mainBundle], nil]),
            selectedHighlightedBezelColor = CPColorWithImages([nil, [@"LPCalendarView/selected-highlighted-tile-bezel.png", 15.0, 15.0, mainBundle], nil]),
            disabledSelectedBezelColor    = CPColorWithImages([nil, [@"LPCalendarView/selected-disabled-tile-bezel.png",    21.0, 21.0, mainBundle], nil]);

        [self setValue:highlightedBezelColor forThemeAttribute:@"tile-bezel-color" inState:CPThemeStateHighlighted];
        [self setValue:[CPColor colorWithHexString:@"555"] forThemeAttribute:@"tile-text-color" inState:CPThemeStateHighlighted];
        [self setValue:[CPColor colorWithHexString:@"fff"] forThemeAttribute:@"tile-text-color" inState:CPThemeStateSelected];
        [self setValue:[CPColor colorWithWhite:0 alpha:0.4] forThemeAttribute:@"tile-text-shadow-color" inState:CPThemeStateSelected];
        [self setValue:selectedBezelColor forThemeAttribute:@"tile-bezel-color" inState:CPThemeStateSelected];
        [self setValue:selectedHighlightedBezelColor forThemeAttribute:@"tile-bezel-color" inState:CPThemeStateHighlighted | CPThemeStateSelected];
        [self setValue:[CPColor colorWithWhite:0 alpha:0.3] forThemeAttribute:@"tile-text-color" inState:CPThemeStateDisabled];
        [self setValue:disabledSelectedBezelColor forThemeAttribute:@"tile-bezel-color" inState:CPThemeStateSelected | CPThemeStateDisabled];
        [self setValue:[CPColor colorWithWhite:0 alpha:0.4] forThemeAttribute:@"tile-text-color" inState:CPThemeStateSelected | CPThemeStateDisabled];
        [self setValue:[CPColor clearColor] forThemeAttribute:@"tile-text-shadow-color" inState:CPThemeStateSelected | CPThemeStateDisabled];
    }

    return self;
}

@end
