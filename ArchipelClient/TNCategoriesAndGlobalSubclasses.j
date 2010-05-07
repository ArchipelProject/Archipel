/*
 * TNCategoriesAndGlobalSubclasses.j
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

@import "Resources/DateFormat.js";

/*! @ingroup utils
    Categories that make CPTabView like iTunes' one
*/
@implementation CPTabView (myTabView)

- (void)_createBezelBorder
{
    var bounds = [self bounds];
     bounds.size.width += 7.0;
     bounds.origin.x -= 7.0;

    _labelsView = [[_CPTabLabelsView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(bounds), 0.0)];

     [_labelsView setTabView:self];
     [_labelsView setAutoresizingMask:CPViewWidthSizable];

     [self addSubview:_labelsView];

}

- (CGRect)contentRect
{
    var contentRect = CGRectMakeCopy([self bounds]);

    if (_tabViewType == CPTopTabsBezelBorder)
    {
        var labelsViewHeight = 33.0//[_CPTabLabelsView height],
            auxiliaryViewHeight = _auxiliaryView ? CGRectGetHeight([_auxiliaryView frame]) : 0.0,
            separatorViewHeight = 0.0;

        contentRect.origin.y += labelsViewHeight + auxiliaryViewHeight + separatorViewHeight;
        contentRect.size.height -= labelsViewHeight + auxiliaryViewHeight + separatorViewHeight * 2.0;
    }

    return contentRect;
}

@end

/*! @ingroup utils
    Categories that make CPTabView like iTunes' one
*/
@implementation _CPTabLabelsView (MyLabelView)

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        _tabLabels = [];
        var bundle = [CPBundle mainBundle];

        [self setBackgroundColor:[CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPiTunesTabView/tabViewLabelBackground.png"]]]]

        [self setFrameSize:CGSizeMake(CGRectGetWidth(aFrame), 33.0)];
    }

    return self;
}
- (void)layoutSubviews
{
    var index = 0,
        count = _tabLabels.length,
        width = 110.0,
        x = 15;

    for (; index < count; ++index)
    {
        var label = _tabLabels[index],
            frame = CGRectMake(x, 15.0, width, 20.0);

        [label setFrame:frame];
        x = CGRectGetMaxX(frame);
        x += 1.0;
    }
}
@end

/*! @ingroup utils
    Categories that make CPTabView like iTunes' one
*/
@implementation _CPTabLabel (myTabLabel)

- (void)setTabState:(CPTabState)aTabState
{
    var bundle = [CPBundle mainBundle];

    _CPTabLabelBackgroundColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
     [
         [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPiTunesTabView/CPiTunesTabLabelBackgroundLeft.png"] size:CGSizeMake(6.0, 18.0)],
         [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPiTunesTabView/CPiTunesTabLabelBackgroundCenter.png"] size:CGSizeMake(1.0, 18.0)],
         [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPiTunesTabView/CPiTunesTabLabelBackgroundRight.png"] size:CGSizeMake(6.0, 18.0)]
     ] isVertical:NO]];

    _CPTabLabelSelectedBackgroundColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
     [
         [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPiTunesTabView/CPiTunesTabLabelSelectedLeft.png"] size:CGSizeMake(3.0, 18.0)],
         [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPiTunesTabView/CPiTunesTabLabelSelectedCenter.png"] size:CGSizeMake(1.0, 18.0)],
         [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPiTunesTabView/CPiTunesTabLabelSelectedRight.png"] size:CGSizeMake(3.0, 18.0)]
     ] isVertical:NO]];

     [self setBackgroundColor:aTabState == CPSelectedTab ? _CPTabLabelSelectedBackgroundColor :_CPTabLabelBackgroundColor];
}

@end


/*! @ingroup utils
    Categories that allows CPView with border
*/
@implementation CPView (BorderedView)

- (void)setBordered
{
    _DOMElement.style.border = "1px solid black";
}

- (void)setBorderedWithHexColor:(CPString)aHexColor
{
    _DOMElement.style.border = "1px solid " + aHexColor;
}

- (void)setBorderRadius:(int)aRadius
{
    _DOMElement.style.borderRadius = aRadius + "px";
}
@end


/*! @ingroup utils
    Menu item with userInfo
*/
@implementation TNMenuItem : CPMenuItem
{
    CPString    stringValue @accessors;
    id          objectValue @accessors;
}
@end


/*! @ingroup utils
    Categories that allows CPString to generate UUID rfc4122 compliant
*/
@implementation CPString (CPStringWithUUIDSeparated)

+ (CPString)UUID
{
    var g = @"";

    for(var i = 0; i < 32; i++)
    {
        if ((i == 8) || (i == 12) || (i == 16) || (i == 20))
            g += '-';
        g += FLOOR(RAND() * 0xF).toString(0xF);
    }

    return g;
}
@end


/*! @ingroup utils
    A Label that is editable on click
*/
@implementation TNEditableLabel: CPTextField
{
    CPColor _oldColor;
}
- (void)mouseDown:(CPEvent)anEvent
{
    [self setEditable:YES];
    [self selectAll:nil];

    [super mouseDown:anEvent];
}

- (void)textDidBlur:(CPNotification)aNotification
{
    [self setEditable:NO];

    [super textDidBlur:aNotification];
}
@end


/*! @ingroup utils
    Categories that allows to create CPAlert quickly.
*/
@implementation CPAlert (CPAlertWithQuickModal)

+ (void)alertWithTitle:(CPString)aTitle message:(CPString)aMessage style:(CPNumber)aStyle
{
    var alert = [[CPAlert alloc] init];
    [alert setTitle:aTitle];
    [alert setMessageText:aMessage];
    //[alert setWindowStyle:CPHUDBackgroundWindowMask];
    [alert setAlertStyle:aStyle];
    [alert addButtonWithTitle:@"OK"];

    [alert runModal];
}

+ (void)alertWithTitle:(CPString)aTitle message:(CPString)aMessage
{
    [CPAlert alertWithTitle:aTitle message:aMessage style:CPInformationalAlertStyle];
}

+ (void)alertWithTitle:(CPString)aTitle message:(CPString)aMessage style:(CPNumber)aStyle delegate:(id)aDelegate buttons:(CPArray)someButtons
{
    var alert = [[CPAlert alloc] init];
    [alert setTitle:aTitle];
    [alert setMessageText:aMessage];
    //[alert setWindowStyle:CPHUDBackgroundWindowMask];
    [alert setAlertStyle:aStyle];
    [alert setDelegate:aDelegate];

    for (var i = 0; i < [someButtons count]; i++)
        [alert addButtonWithTitle:[someButtons objectAtIndex:i]];

    [alert runModal];
}

@end

@implementation CPOutlineView (expandAll)

/*! Expand all items in the view
*/
- (void)expandAll
{
    for (var count = 0; [self itemAtRow:count]; count++)
    {
        var item = [self itemAtRow:count];
        
        if ([self isExpandable:item])
        {
            [self expandItem:item];
        }
    }
}

- (void)collapseAll
{
    for (var count = 0; [self itemAtRow:count]; count++)
    {
        var item = [self itemAtRow:count];
        if ([self isExpandable:item])
        {
            [self collapseItem:item];
        }
    }
}
@end

@implementation CPDate (withFormat)

+ (CPString)dateWithFormat:(CPString)aFormat
{
    var theDate = new Date();
    return theDate.dateFormat(aFormat);
}
@end

// @implementation CPWindow (fadeInWindow)
// 
// - (IBAction)orderFront:(id)sender
// {
//     if (![self isVisible])
//     {
//         var animView    = [CPDictionary dictionaryWithObjectsAndKeys:[self contentView], CPViewAnimationTargetKey, CPViewAnimationFadeInEffect, CPViewAnimationEffectKey];
//         var anim        = [[CPViewAnimation alloc] initWithViewAnimations:[animView]];
// 
//         [anim setDuration:0.3];
//         [anim startAnimation];
//     }
//     
//     [_platformWindow orderFront:self];
//     [_platformWindow order:CPWindowAbove window:self relativeTo:nil];
//     
//     if (_firstResponder === self || !_firstResponder)
//         [self makeFirstResponder:[self initialFirstResponder]];
//     
//     if (!CPApp._keyWindow)
//         [self makeKeyWindow];
//     
//     if (!CPApp._mainWindow)
//         [self makeMainWindow];
// }
// 
// - (IBAction)orderOut:(id)sender
// {
//     var animView    = [CPDictionary dictionaryWithObjectsAndKeys:[self contentView], CPViewAnimationTargetKey, CPViewAnimationFadeOutEffect, CPViewAnimationEffectKey];
//     var anim        = [[CPViewAnimation alloc] initWithViewAnimations:[animView]];
// 
//     [anim setDuration:0.3];
//     [anim setDelegate:self]
//     [anim startAnimation];
// }
// 
// - (void)animationDidEnd:(CPViewAnimation)anAnimation
// {
//     if ([self _sharesChromeWithPlatformWindow])
//         [_platformWindow orderOut:self];
// 
//     if ([_delegate respondsToSelector:@selector(windowWillClose:)])
//         [_delegate windowWillClose:self];
// 
//     [_platformWindow order:CPWindowOut window:self relativeTo:nil];
// 
//     [self _updateMainAndKeyWindows];
// }
// 
// @end


@implementation TNStropheGroup (majName)
- (CPString)description
{
    return [_name uppercaseString];
}
@end

@implementation TNTableView : CPTableView
{
    
}

-(void)keyDown:(CPEvent)anEvent
{
    CPLog.debug([anEvent keyCode]);
    if (([anEvent keyCode] == 65) && ([anEvent modifierFlags] == CPCommandKeyMask))
    {
        var indexes = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, [self numberOfRows])];
        
        [self selectRowIndexes:indexes byExtendingSelection:NO];
        return;
    }
    [super keyDown:anEvent];
}
@end
