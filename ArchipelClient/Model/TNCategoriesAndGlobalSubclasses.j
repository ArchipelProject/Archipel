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

@import <AppKit/CPTabView.j>
@import <AppKit/CPBox.j>

@import "../Resources/dateFormat.js"

/*! @defgroup utils Archipel Utilities
    @desc Simples categories or subclass in order to live ina better world
*/


/*! @ingroup utils
    Make CPTabView border editable
*/
@implementation CPTabView (borderEditable)

- (void)setBorderColor:(CPColor)aColor
{
    [box setBorderColor:aColor];
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

    for (var i = 0; i < 32; i++)
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
    add expandAll to CPOutlineView
*/
@implementation CPOutlineView (TNKit)

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
    var defaults    = [CPUserDefaults standardUserDefaults];

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

/*! @ingroup utils
    CPDate with format
*/
@implementation CPDate (TNKit)

+ (CPString)dateWithFormat:(CPString)aFormat
{
    var theDate = new Date();

    return theDate.dateFormat(aFormat);
}

- (CPString)format:(CPString)aFormat
{
    return self.dateFormat(aFormat);
}

- (CPString)description
{
    return self.dateFormat(@"Y-m-d H:i:s");
}
@end

/*! @ingroup utils
    CPWindow that fade in and fade out
*/
@implementation CPWindow (TNKit)

- (IBAction)orderFront:(id)sender
{
    var defaults = [CPUserDefaults standardUserDefaults];

    if ([defaults boolForKey:@"TNArchipelUseAnimations"] && ![self isVisible])
    {
        var animView    = [CPDictionary dictionaryWithObjectsAndKeys:[self contentView], CPViewAnimationTargetKey, CPViewAnimationFadeInEffect, CPViewAnimationEffectKey],
            anim        = [[CPViewAnimation alloc] initWithViewAnimations:[animView]];

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
@end

/*! @ingroup utils
    Groups name are uppercase
*/
@implementation TNStropheGroup (TNKit)
- (CPString)description
{
    return [_name uppercaseString];
}
@end

/*! @ingroup utils
    implement Cmd+A in CPTableView
*/
@implementation CPTableView (TNKit)

- (void)keyDown:(CPEvent)anEvent
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

/*! @ingroup utils
    herrr... I don't know what is this :)
*/
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

/*! @ingroup utils
    some cool stuff in CPSearchField
*/
@implementation CPSearchField (cancelButton)

- (CPButton)cancelButton
{
    return _cancelButton;
}

- (void)keyDown:(CPEvent)anEvent
{
    if ([anEvent keyCode] == CPEscapeKeyCode)
        [self _searchFieldCancel:self];

    [super keyDown:anEvent];
}
@end