/*
 * TNSwitch.j
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


@import <LPKit/LPSwitch.j>


/*! @ingroup archipelcore
    Themed LPSwitch
*/
@implementation TNSwitch : LPSwitch

+ (id)themeAttributes
{
    var mainBundle = [CPBundle mainBundle],
        switchSize = CGSizeMake(77, 25),
        offBackgroundImage = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"LPSwitch/switch-off-background.png"] size:switchSize]],
        onBackgroundImage = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"LPSwitch/switch-on-background.png"] size:switchSize]],
        knobBackgroundImage = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"LPSwitch/switch-knob.png"] size:switchSize]],
        highlightedKnobBackgroundImage = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"LPSwitch/switch-knob-highlighted.png"] size:switchSize]];

    return [CPDictionary dictionaryWithObjects:[offBackgroundImage, onBackgroundImage, knobBackgroundImage, CGSizeMake(30,25), CGSizeMake(12,5),
                                                [CPFont boldSystemFontOfSize:11], [CPColor colorWithWhite:0 alpha:0.7], [CPColor colorWithWhite:1 alpha:0.8], CGSizeMake(0,1),
                                                [CPFont boldSystemFontOfSize:11], [CPColor colorWithWhite:1 alpha:1.0], [CPColor colorWithWhite:0.3 alpha:0.8], CGSizeMake(0,1)]
                                       forKeys:[@"off-background-color", @"on-background-color", @"knob-background-color", @"knob-size", @"label-offset",
                                                @"off-label-font", @"off-label-text-color", @"off-label-text-shadow-color", @"off-label-text-shadow-offset",
                                                @"on-label-font", @"on-label-text-color", @"on-label-text-shadow-color", @"on-label-text-shadow-offset"]];
}


+ (TNSwitch)switchWithFrame:(CGRect)aFrame
{
    var mainBundle  = [CPBundle mainBundle],
        aSwitch     = [[TNSwitch alloc] initWithFrame:aFrame],
        switchSize  = CGSizeMake(77, 25),
        highlightedKnobBackgroundImage = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"LPSwitch/switch-knob-highlighted.png"] size:switchSize]];

    [aSwitch setValue:highlightedKnobBackgroundImage forThemeAttribute:@"knob-background-color" inState:CPThemeStateNormal | CPThemeStateHighlighted];

    return aSwitch;
}

- (id)initWithFrame:(CGRect)aFrame
{
    aFrame.size.width = 77;
    aFrame.size.height = 25;

    if (self = [super initWithFrame:aFrame])
    {
        var mainBundle  = [CPBundle mainBundle],
            switchSize  = CGSizeMake(aFrame.size.width, aFrame.size.height),
            highlightedKnobBackgroundImage = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"LPSwitch/switch-knob-highlighted.png"] size:switchSize]],
            offBackgroundImageDisabled = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"LPSwitch/switch-off-background-disabled.png"] size:switchSize]],
            knobBackgroundDisabled = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"LPSwitch/switch-knob-disabled.png"] size:switchSize]];

        [self setValue:highlightedKnobBackgroundImage forThemeAttribute:@"knob-background-color" inState:CPThemeStateNormal | CPThemeStateHighlighted];

        [self setValue:offBackgroundImageDisabled forThemeAttribute:@"off-background-color" inState:CPThemeStateDisabled];
        [self setValue:offBackgroundImageDisabled forThemeAttribute:@"on-background-color" inState:CPThemeStateDisabled];

        [self setValue:knobBackgroundDisabled forThemeAttribute:@"knob-background-color" inState:CPThemeStateDisabled];

        [self setValue:CGSizeMake(30, aFrame.height) forThemeAttribute:@"knob-size"];

        [self setValue:[CPColor grayColor] forThemeAttribute:@"off-label-text-color" inState:CPThemeStateDisabled];
        [self setValue:[CPColor grayColor] forThemeAttribute:@"on-label-text-color" inState:CPThemeStateDisabled];
    }

    return self;
}



@end
