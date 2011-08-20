/*
 * main.j
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
@import <AppKit/CPSound.j>

@import "Categories/CPBundle+Localizable.j"

@import "AppController.j"

/*! @mainpage
    @htmlonly <pre>@endhtmlonly
    @htmlinclude ../README.markdown
    @htmlonly </pre>@endhtmlonly

    Archipel is a free software distributed under the the terms of @ref license "AGPL".

    @page license License
    @htmlonly <pre>@endhtmlonly
    @htmlinclude ../LICENSE
    @htmlonly </pre>@endhtmlonly
*/

function gameOver(code)
{
    var container = document.getElementById("container"),
        sound = [[CPSound alloc] initWithContentsOfURL:[CPURL URLWithString:@"Resources/incompatible.wav"] byReference:NO];
    container.style.color = "white";
    container.style.width = "100%";
    container.style.left = "0px";
    container.style.top = "200px";
    container.style.fontSize = "11px";
    container.style.textAlign = "center";
    container.innerHTML = "<h2>Game Over</h2><br/>You're browser seems uncompatible with feature code <code>" +
        code + "</code><br/>You should use Chromium or Safari or any decent browser actually";

    [sound play];
}

function main(args, namedArgs)
{
    // put needed features here in this array. If one fails, game over
    var features = [CPHTMLCanvasFeature],
        browserIsCompatible = YES;

    if ([CPPlatform isBrowser])
    {
        for (i = 0; i < features.length; i++)
        {
            if (!CPFeatureIsCompatible(features[i]))
            {
                gameOver(features[i]);
                browserIsCompatible = NO;
                break;
            }
        }
    }

    if (browserIsCompatible)
        CPApplicationMain(args, namedArgs);
}
