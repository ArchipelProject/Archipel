/*
 * CPView+ApplyShadow.j
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
@import <AppKit/CPTextField.j>


/*! @ingroup categories
    Allow to apply a nice shadow effect on all CPTextField subview
*/
@implementation CPView (ApplyShadow)

/*! Apply shadow to all labels
    @param aShadowColor CPColor of the shadow
    @param anOffset CGSize represeting the offset
*/
- (void)applyShadow:(CPColor)aShadowColor offset:(CGSize)anOffset
{
    var subviews = [CPArray arrayWithArray:[self subviews]];

    for (var i = 0; i < [subviews count]; i++)
    {
        var v = [subviews objectAtIndex:i];
        if ([v isKindOfClass:CPTextField] && ![v isEditable])
        {
            [v setValue:aShadowColor forThemeAttribute:@"text-shadow-color"];
            [v setValue:anOffset forThemeAttribute:@"text-shadow-offset"];
        }
    }
}

/*! Apply white shadow to all labels
*/
- (void)applyShadow
{
    [self applyShadow:[CPColor whiteColor] offset:CGSizeMake(0.0, 1.0)];
}

- (void)applyGlow
{
    [self applyGlow:[CPColor whiteColor] spread:10 size:CGSizeMake(0, 0)];
}

- (void)applyGlow:(CPColor)aColor spread:(int)aSpreadValue size:(CGSize)aSize
{
    var CSSString = aColor ? aSize.height + "px " + aSize.width + "px  " + aSpreadValue + "px " + [aColor cssString] : @"";

    self._DOMElement.style.boxShadow = CSSString;
    self._DOMElement.style.MozBoxShadow = CSSString;
    self._DOMElement.style.WebkitBoxShadow = CSSString;
}

@end
