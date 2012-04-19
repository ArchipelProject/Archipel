/*
 * TNBasicDataView.j
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


@implementation TNBasicDataView : CPView
{
    CPColor         _backgroundTopColor;
    CPColor         _backgroundBottomColor;
    CPColor         _backgroundTopColorSelected;
    CPColor         _backgroundBottomColorSelected;
    CPDictionary    _subviewsColorsRegistry;

}

- (id)initWithRect:(CPRect)aRect
{
    if (self = [super initWithRect:aRect])
    {
        _backgroundTopColor = [CPColor redColor];
        _backgroundBottomColor = [CPColor blueColor];
    }

    return self;
}

- (void)setThemeState:(CPThemeState)aThemeState
{
    [super setThemeState:aThemeState];
    if (aThemeState == CPThemeStateSelectedDataView)
    {
        _subviewsColorsRegistry = [CPDictionary dictionary];
        for (var i = 0; i < [[self subviews] count]; i++)
        {
            var view = [[self subviews] objectAtIndex:i];
            if ([view isKindOfClass:CPTextField])
            {
                [_subviewsColorsRegistry setObject:[view textColor] forKey:[view description]];
                [view setTextColor:[CPColor whiteColor]];
            }

        }
        [self applyShadow:[CPColor colorWithHexString:@"2F5288"] offset:CPSizeMake(-1.0, -1.0)];
    }
}

- (void)unsetThemeState:(CPThemeState)aThemeState
{
    [super unsetThemeState:aThemeState];

    if (aThemeState == CPThemeStateSelectedDataView)
    {
        for (var i = 0; i < [[self subviews] count]; i++)
        {
            var view = [[self subviews] objectAtIndex:i];
            if ([view isKindOfClass:CPTextField])
            {
                if (_subviewsColorsRegistry)
                    [view setTextColor:[_subviewsColorsRegistry objectForKey:[view description]]];
            }

        }
        [self applyShadow];
    }

}


- (void)drawRect:(CGRect)aRect
{
    [super drawRect:aRect];

    var topColor = ([self hasThemeState:CPThemeStateSelectedDataView]) ? _backgroundTopColorSelected : _backgroundTopColor,
        bottomColor = ([self hasThemeState:CPThemeStateSelectedDataView]) ? _backgroundBottomColorSelected : _backgroundBottomColor,
        context = [[CPGraphicsContext currentContext] graphicsPort],
        gradientColor = [[topColor redComponent], [topColor greenComponent], [topColor blueComponent],1.0, [bottomColor redComponent], [bottomColor greenComponent], [bottomColor blueComponent],1.0],
        gradient = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(), gradientColor, [0,1], 2);

    CGContextSetStrokeColor(context, [CPColor colorWithHexString:@"E1E1E1"]);
    CGContextSetLineWidth(context, 1.0);
    CGContextBeginPath(context);

    aRect.origin.x -= 2;
    aRect.origin.y -= 2;
    aRect.size.width += 6;
    aRect.size.height += 1;

    CGContextAddPath(context, CGPathWithRoundedRectangleInRect(aRect, 0, 0, YES, YES, YES, YES));
    CGContextDrawLinearGradient(context, gradient, CGPointMake(CPRectGetMidX(aRect), 0.0), CGPointMake(CPRectGetMidX(aRect), aRect.size.height), 0);
    CGContextClosePath(context);
    CGContextStrokePath(context);
    CGContextFillPath(context);
}

/*! CPCoder compliance
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        _backgroundTopColor = [CPColor colorWithHexString:@"FBFBFB"];
        _backgroundBottomColor = [CPColor colorWithHexString:@"F9F9F9"];
        _backgroundTopColorSelected = [CPColor colorWithHexString:@"5F83B9"];
        _backgroundBottomColorSelected = [CPColor colorWithHexString:@"2D5086"];

        [self applyShadow];
    }

    return self;
}

@end
