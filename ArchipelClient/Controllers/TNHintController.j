/*
 * TNHintController.j
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

@import <AppKit/CPWindow.j>
@import <AppKit/CPView.j>
@import <AppKit/CPImageView.j>
@import <AppKit/CPImage.j>
@import <AppKit/CPTextField.j>



/*! @ingroup archipelcore
    this controller manage the hint view
*/
@implementation TNHintController : CPObject
{
    @outlet CPButton        buttonOpenWiki;
    @outlet CPImageView     imageViewHint1;
    @outlet CPImageView     imageViewHint2;
    @outlet CPImageView     imageViewHint3;
    @outlet CPImageView     imageViewLogo;
    @outlet CPView          hintView;

    CPWindow                _mainWindow;
}

#pragma mark -
#pragma mark Initialization

/*! called at CIB awakening
*/
- (void)awakeFromCib
{
    /* hint window */
    var bundle = [CPBundle mainBundle];

    [imageViewLogo setImage:CPImageInBundle(@"Backgrounds/background-icon.png", nil, bundle)];
    [imageViewHint1 setImage:CPImageInBundle(@"hints/hint1.png", nil, bundle)];
    [imageViewHint2 setImage:CPImageInBundle(@"hints/hint2.png", nil, bundle)];
    [imageViewHint3 setImage:CPImageInBundle(@"hints/hint3.png", nil, bundle)];

    [buttonOpenWiki setTheme:[CPTheme defaultHudTheme]];

    _mainWindow = [[CPWindow alloc] initWithContentRect:[hintView bounds] styleMask:CPHUDBackgroundWindowMask | CPTitledWindowMask | CPClosableWindowMask];
    [[_mainWindow contentView] addSubview:hintView];

}


#pragma mark -
#pragma mark Actions

/*! Open the window
    @param aSender the sender of the action
*/
- (IBAction)showWindow:(id)aSender
{
    [_mainWindow center];
    [_mainWindow makeKeyAndOrderFront:aSender];
}

/*! Open the Wiki in a new window
    @param aSender the sender of the action
*/
- (IBAction)openDocumentation:(id)aSender
{
    window.open("https://github.com/archipelproject/archipel/wiki");
}

@end
