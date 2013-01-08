/*
 * NTModalWindow.j
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

/*! @ingroup archipelcore
    a nice modal CPWindow
*/
@implementation TNModalWindow: CPPanel

- (id)initWithContentRect:(CPRect)aFrame styleMask:(id)aMask
{
    if ([CPPlatform isBrowser])
    {
        if (self = [super initWithContentRect:aFrame styleMask:CPBorderlessWindowMask])
        {
            _windowView._DOMElement.style.background        = "#F4F4F4";
            _windowView._DOMElement.style.background        = "-webkit-gradient(linear, left top, left bottom, from(#F4F4F4), to(#D2D2D2))";
            _windowView._DOMElement.style.background        = "-moz-linear-gradient(-90deg, #F4F4F4, #D2D2D2)";
            _windowView._DOMElement.style.border            = "1px solid white";
            _windowView._DOMElement.style.borderRadius      = "6px";
            _windowView._DOMElement.style.MozBorderRadius   = "6px";
            _windowView._DOMElement.style.webkitBoxShadow   = "0px 0px 10px #8DB9D1";
            _windowView._DOMElement.style.MozBoxShadow      = "0px 0px 10px #8DB9D1";
        }
    }
    else
        self = [super initWithContentRect:aFrame styleMask:aMask];

     return self;
}
@end
