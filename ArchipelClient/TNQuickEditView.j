/*  
 * TNQuickEditView.j
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
@import <AppKit/AppKit.j>

TNQuickEditViewPadding = 20.0;

@implementation TNQuickEditView : CPWindow
{
    CPImageView     _cursorView;
    CPView          _propertyView;
    id              _object         @accessors(getter=object);
}

- (void)initWithObjectFrame:(CGRect)aFrame size:(CGSize)aSize view:(id)aView
{
    // TODO : Make something to convert the coordinates
    // alert(aFrame.origin.y);
    // var y = aFrame.origin.y - (aSize.height / 2);
    // var x = aFrame.origin.x + (aFrame.size.width);
    
    var winFrame = CGRectMake(x, y, aSize.width, aSize.height);
    
    if (self = [super initWithContentRect:winFrame styleMask:CPBorderlessWindowMask])
    {
        var bundle          = [CPBundle bundleForClass:[self class]];
        var bgImage         = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"bg-pview.png"]];
        var background      = [CPColor colorWithPatternImage:bgImage];
        var modifiedFrame   = winFrame;
        
        modifiedFrame.size.width    -= TNQuickEditViewPadding;
        modifiedFrame.size.height   -= TNQuickEditViewPadding;
        modifiedFrame.origin.x      = TNQuickEditViewPadding / 2;
        modifiedFrame.origin.y      = TNQuickEditViewPadding / 2;
        
        _propertyView = [[CPView alloc] initWithFrame:modifiedFrame];
        [_propertyView setAutoresizingMask:CPViewHeightSizable|CPViewWidthSizable];
        [_propertyView setBackgroundColor:background];
        [_propertyView setBorderedWithHexColor:@"#a5a5a5"];
        [_propertyView setBorderRadius:3];
        
        [[self contentView] addSubview:_propertyView];
        [[self contentView] setBackgroundColor:[CPColor redColor]];
        
        var y = modifiedFrame.size.height / 2 - 5;
        var x = 1;
        _cursorView = [[CPImageView alloc] initWithFrame:CGRectMake(x, y, 10, 19)];
        [_cursorView setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"arrow.png"]]];
        
        [[self contentView] addSubview:_cursorView];
        [self setLevel:CPFloatingWindowLevel];
        [self setAcceptsMouseMovedEvents:YES];
        _objectView = _object;
    }
    
    return self;
}

@end