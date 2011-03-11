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


@implementation TNCalendarView : LPCalendarView
{

}

+ (id)themeAttributes
{
    var mainBundle = [CPBundle mainBundle],
        bgImage = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"LPCalendarView/background.png"] size:CGSizeMake(1.0, 21.0)]],
        headerBgImage = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"LPCalendarView/header-background.png"] size:CGSizeMake(182.0, 40.0)]],
        prevImage = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"LPCalendarView/previous.png"] size:CGSizeMake(16.0, 16.0)]],
        nextImage = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"LPCalendarView/next.png"] size:CGSizeMake(16.0, 16.0)]],
        bezelColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
                        [
                            [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"LPCalendarView/default-tile-bezel-left.png"] size:CGSizeMake(1.0, 21.0)],
                            [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"LPCalendarView/default-tile-bezel-center.png"] size:CGSizeMake(21.0, 21.0)],
                            nil
                        ]
                    isVertical:NO]];

    return [CPDictionary dictionaryWithObjectsAndKeys:  [CPColor colorWithHexString:@"ccc"],    @"grid-color",
                                                        bgImage,                                @"background-color",
                                                        40,                                     @"header-height",
                                                        headerBgImage,                          @"header-background-color",
                                                        [CPFont boldSystemFontOfSize:11.0],     @"header-font",
                                                        [CPColor colorWithHexString:@"333"],    @"header-text-color",
                                                        [CPColor whiteColor],                   @"header-text-shadow-color",
                                                        CGSizeMake(1.0, 1.0),                   @"header-text-shadow-offset",
                                                        CPCenterTextAlignment,                  @"header-alignment",
                                                        CGSizeMake(10, 7),                      @"header-button-offset",
                                                        prevImage,                              @"header-prev-button-image",
                                                        nextImage,                              @"header-next-button-image",
                                                        25,                                     @"header-weekday-offset",
                                                        [CPFont systemFontOfSize:9.0],          @"header-weekday-label-font",
                                                        [CPColor colorWithWhite:0 alpha:0.57],  @"header-weekday-label-color",
                                                        [CPColor colorWithWhite:1 alpha:0.8],   @"header-weekday-label-shadow-color",
                                                        CGSizeMake(0.0, 1.0),                   @"header-weekday-label-shadow-offset",
                                                        CGSizeMake(27, 21),                     @"tile-size",
                                                        [CPFont boldSystemFontOfSize:11.0],     @"tile-font",
                                                        [CPColor colorWithHexString:@"333"],    @"tile-text-color",
                                                        [CPColor colorWithWhite:1 alpha:0.8],   @"tile-text-shadow-color",
                                                        CGSizeMake(1.0, 1.0),                   @"tile-text-shadow-offset",
                                                        bezelColor,                             @"tile-bezel-color"];
}


- (id)initWithFrame:(CGRect)aFrame
{
    // aFrame.size.width = 195;
    // aFrame.size.height = 172;

    if (self = [super initWithFrame:aFrame])
    {
        var mainBundle  = [CPBundle mainBundle],
            highlightedBezelColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
                    [
                        nil,
                        [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"LPCalendarView/highlighted-tile-bezel.png"] size:CGSizeMake(21.0, 21.0)],
                        nil
                    ]
                isVertical:NO]],
            selectedBezelColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
                    [
                        nil,
                        [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"LPCalendarView/selected-tile-bezel.png"] size:CGSizeMake(15.0, 15.0)],
                        nil
                    ]
                isVertical:NO]],
            selectedHighlightedBezelColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
                    [
                        nil,
                        [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"LPCalendarView/selected-highlighted-tile-bezel.png"] size:CGSizeMake(15.0, 15.0)],
                        nil
                    ]
                isVertical:NO]],
            disabledSelectedBezelColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
                    [
                        nil,
                        [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"LPCalendarView/selected-disabled-tile-bezel.png"] size:CGSizeMake(21.0, 21.0)],
                        nil
                    ]
                isVertical:NO]];

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