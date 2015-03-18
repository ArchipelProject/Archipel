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

var switchKnobWidth     = 30,
    switchKnobHeight    = 25;

/*! @ingroup archipelcore
    Themed LPSwitch
*/
@implementation TNSwitch : LPSwitch

+ (CPDictionary)themeAttributes
{
    var mainBundle                     = [CPBundle mainBundle],
        switchWidth                    = 77,
        switchHeight                   = 25,
        offBackgroundImage             = CPColorWithImages(@"LPSwitch/switch-off-background.png",   switchWidth, switchHeight, mainBundle),
        onBackgroundImage              = CPColorWithImages(@"LPSwitch/switch-on-background.png",    switchWidth, switchHeight, mainBundle),
        knobBackgroundImage            = CPColorWithImages(@"LPSwitch/switch-knob.png",             switchKnobWidth, switchKnobHeight, mainBundle),
        highlightedKnobBackgroundImage = CPColorWithImages(@"LPSwitch/switch-knob-highlighted.png", switchKnobWidth, switchKnobHeight, mainBundle);

    return @{
            @"off-background-color"         :offBackgroundImage,
            @"on-background-color"          :onBackgroundImage,
            @"knob-background-color"        :knobBackgroundImage,
            @"knob-size"                    :CGSizeMake(30,25),
            @"label-offset"                 :CGSizeMake(12,6),
            @"off-label-font"               :[CPFont boldSystemFontOfSize:11],
            @"off-label-text-color"         :[CPColor colorWithWhite:0 alpha:0.7],
            @"off-label-text-shadow-color"  :[CPColor colorWithWhite:1 alpha:0.8],
            @"off-label-text-shadow-offset" :CGSizeMake(0,1),
            @"on-label-font"                :[CPFont boldSystemFontOfSize:11],
            @"on-label-text-color"          :[CPColor colorWithWhite:1 alpha:1.0],
            @"on-label-text-shadow-color"   :[CPColor colorWithWhite:0.3 alpha:0.8],
            @"on-label-text-shadow-offset"  :CGSizeMake(0,1),
           }
}


- (id)initWithFrame:(CGRect)aFrame
{
    aFrame.size.width = 77;
    aFrame.size.height = 25;

    if (self = [super initWithFrame:aFrame])
    {
        var mainBundle                     = [CPBundle mainBundle],
            highlightedKnobBackgroundImage = CPColorWithImages(@"LPSwitch/switch-knob-highlighted.png",        switchKnobWidth, switchKnobHeight, mainBundle),
            offBackgroundImageDisabled     = CPColorWithImages(@"LPSwitch/switch-off-background-disabled.png", aFrame.size.width, aFrame.size.height, mainBundle),
            knobBackgroundDisabled         = CPColorWithImages(@"LPSwitch/switch-knob-disabled.png",           switchKnobWidth, switchKnobHeight, mainBundle);

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
