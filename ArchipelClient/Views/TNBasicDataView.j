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
    CPColor _backgroundTopColor;
    CPColor _backgroundBottomColor;
    CPColor _backgroundTopColorSelected;
    CPColor _backgroundBottomColorSelected;
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
        _backgroundTopColorSelected = [CPColor colorWithHexString:@"E7E7E7"];
        _backgroundBottomColorSelected = [CPColor colorWithHexString:@"F4F4F4"];

        [self applyShadow];
    }

    return self;
}

@end
