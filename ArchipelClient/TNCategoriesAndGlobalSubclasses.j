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

@import "Resources/dateFormat.js";
@import <AppKit/CPTabView.j>

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
    CPColor     _oldColor;
    id          _previousResponder  @accessors(property=previousResponder);
}

- (void)mouseDown:(CPEvent)anEvent
{
    [self setEditable:YES];
    [self selectAll:nil];
    
    [super mouseDown:anEvent];
}

- (void)textDidFocus:(CPNotification)aNotification
{
    [super textDidFocus:aNotification];
    [self setTextColor:[CPColor whiteColor]];
    
    
}

- (void)textDidBlur:(CPNotification)aNotification
{
    [super textDidBlur:aNotification];
    [self setEditable:NO];
    [self setSelectedRange:CPMakeRange(0, 0)];
    [self setTextColor:[CPColor grayColor]];
    
    
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
    // [alert setWindowStyle:CPHUDBackgroundWindowMask];
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
    [alert setAlertStyle:aStyle];
    [alert setDelegate:aDelegate];

    for (var i = 0; i < [someButtons count]; i++)
        [alert addButtonWithTitle:[someButtons objectAtIndex:i]];

    [alert runModal];
}

+ (void)alertWithTitle:(CPString)aTitle message:(CPString)aMessage style:(CPNumber)aStyle delegate:(id)aDelegate buttons:(CPArray)someButtons tag:(int)aTag
{
    var alert = [[CPAlert alloc] init];
    [alert setTitle:aTitle];
    [alert setMessageText:aMessage];
    [alert setAlertStyle:aStyle];
    [alert setDelegate:aDelegate];

    for (var i = 0; i < [someButtons count]; i++)
        [alert addButtonWithTitle:[someButtons objectAtIndex:i]];

    [alert runModal];
    
}

// -(void)keyDown:(CPEvent)anEvent
// {
//     if ([anEvent keyCode] == CPEscapeKeyCode)
//     {
//         [self _notifyDelegate:[_buttons objectAtIndex:0]];
//     }
//     [super keyDown:anEvent];
// }

@end

@implementation TNAlert : CPObject
{
    id      _delegate   @accessors(property=delegate);
    id      _userInfo   @accessors(property=userInfo);
    CPAlert _alert      @accessors(getter=alert);
    CPArray _actions;
}

+ (void)alertWithTitle:(CPString)aTitle message:(CPString)aMessage delegate:(id)aDelegate actions:(CPArray)someActions
{
    var tnalert = [[TNAlert alloc] initWithTitle:aTitle message:aMessage delegate:aDelegate actions:someActions];
    
    return tnalert;
}

+ (void)alertWithTitle:(CPString)aTitle message:(CPString)aMessage informativeMessage:(CPString)anInfo delegate:(id)aDelegate actions:(CPArray)someActions
{
    var tnalert = [[TNAlert alloc] initWithTitle:aTitle message:aMessage informativeMessage:anInfo delegate:aDelegate actions:someActions];
    
    return tnalert;
}

- (TNAlert)initWithTitle:(CPString)aTitle message:(CPString)aMessage delegate:(id)aDelegate actions:(CPArray)someActions
{
    if (self = [super init])
    {
        _alert      = [[CPAlert alloc] init];
        _actions    = someActions;
        _delegate   = aDelegate;
        
        [_alert setTitle:aTitle];
        [_alert setMessageText:aMessage];
        [_alert setDelegate:self];
        
        for (var i = 0; i < [_actions count]; i++)
            [_alert addButtonWithTitle:[[_actions objectAtIndex:i] objectAtIndex:0]];
    }
    
    return self;
}

- (TNAlert)initWithTitle:(CPString)aTitle message:(CPString)aMessage informativeMessage:(CPString)anInfo delegate:(id)aDelegate actions:(CPArray)someActions
{
    if (self = [self initWithTitle:aTitle message:aMessage delegate:aDelegate actions:someActions])
    {
        [_alert setInformativeText:anInfo];
    }
    
    return self;
}

- (void)runModal
{
    [_alert runModal];
}

- (void)alertDidEnd:(CPAlert)theAlert returnCode:(int)returnCode
{
    var selector = [[_actions objectAtIndex:returnCode] objectAtIndex:1];
    CPLog.debug(selector);
    if ([_delegate respondsToSelector:selector])
        [_delegate performSelector:selector withObject:_userInfo];
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

- (void)recoverExpandedWithBaseKey:(CPString)aBaseKey itemKeyPath:(CPString)aKeyPath
{
    var defaults    = [TNUserDefaults standardUserDefaults];
    
    for (var count = 0; [self itemAtRow:count]; count++)
    {
        var item = [self itemAtRow:count];
        
        if ([self isExpandable:item])
        {
            var key =  aBaseKey + [item valueForKey:aKeyPath];
            if (([defaults objectForKey:key] == "expanded") || ([defaults objectForKey:key] == nil))
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
- (CPString)description
{
    return self.dateFormat(@"Y-m-d H:i:s");
}
@end

@implementation CPWindow (fadeInWindow)

- (IBAction)orderFront:(id)sender
{
    if (![self isVisible])
    {
        var animView    = [CPDictionary dictionaryWithObjectsAndKeys:[self contentView], CPViewAnimationTargetKey, CPViewAnimationFadeInEffect, CPViewAnimationEffectKey];
        var anim        = [[CPViewAnimation alloc] initWithViewAnimations:[animView]];

        [anim setDuration:0.3];
        [anim startAnimation];
    }
    
    [_platformWindow orderFront:self];
    [_platformWindow order:CPWindowAbove window:self relativeTo:nil];
    
    if (_firstResponder === self || !_firstResponder)
        [self makeFirstResponder:[self initialFirstResponder]];
    
    if (!CPApp._keyWindow)
        [self makeKeyWindow];
    
    if (!CPApp._mainWindow)
        [self makeMainWindow];
}
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
@end

@implementation TNStropheGroup (majName)
- (CPString)description
{
    return [_name uppercaseString];
}
@end

@implementation CPTableView (PommeA)

-(void)keyDown:(CPEvent)anEvent
{
    if ((([anEvent keyCode] == 65) && ([anEvent modifierFlags] == CPCommandKeyMask) && [self allowsMultipleSelection]))
    {
        var indexes = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, [self numberOfRows])];
        
        [self selectRowIndexes:indexes byExtendingSelection:NO];
        return;
    }
    [self interpretKeyEvents:[anEvent]];
}
@end

@implementation TNButtonBarPopUpButton: CPButton

- (void)mouseDown:(CPEvent)anEvent
{
    var wp = CPPointMake(16, 12);

    wp = [self convertPoint:wp toView:nil];
    
    var fake = [CPEvent mouseEventWithType:CPRightMouseDown
                        location:wp
                        modifierFlags:0 timestamp:[anEvent timestamp]
                        windowNumber:[anEvent windowNumber]
                        context:nil
                        eventNumber:0
                        clickCount:1
                        pressure:1];

    [CPMenu popUpContextMenu:[self menu] withEvent:fake forView:self];
}
@end

@implementation CPSearchField (cancelButton)

- (CPButton)cancelButton
{
    return _cancelButton;
}

-(void)keyDown:(CPEvent)anEvent
{
    if ([anEvent keyCode] == CPEscapeKeyCode)
        [self _searchFieldCancel:self];

    [super keyDown:anEvent];
}
@end


@implementation TNWhiteWindow: CPWindow

- (id)initWithContentRect:(CPRect)aFrame styleMask:(id)aMask
{
    if (self = [super initWithContentRect:CPRectMake(0,0,478,261) styleMask:CPBorderlessWindowMask])
    {
        var bundle  = [CPBundle mainBundle];
        var frame   = [[self contentView] frame];
        var size    = CPSizeMake(frame.size.width -100, frame.size.height -100);
                
        var bgImage     = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"loginbg.png"] size:size];
        
        [self setBackgroundColor:[CPColor colorWithPatternImage:bgImage]];
    }
    
    return self;
}

@end
