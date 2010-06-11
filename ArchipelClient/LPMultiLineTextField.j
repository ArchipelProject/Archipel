/*
 * LPMultiLineTextField.j
 *
 * Created by Ludwig Pettersson on January 22, 2010.
 * 
 * The MIT License
 * 
 * Copyright (c) 2010 Ludwig Pettersson
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 * 
 */
@import <AppKit/CPTextField.j>

var CPTextFieldInputOwner = nil;

@implementation LPMultiLineTextField : CPTextField
{
    id _DOMTextareaElement;
    CPString _stringValue;
}

- (DOMElement)_DOMTextareaElement
{
    if (!_DOMTextareaElement)
    {
        _DOMTextareaElement = document.createElement("textarea");
        _DOMTextareaElement.style.position = @"absolute";
        _DOMTextareaElement.style.background = @"none";
        _DOMTextareaElement.style.border = @"0";
        _DOMTextareaElement.style.outline = @"0";
        _DOMTextareaElement.style.zIndex = @"100";
        _DOMTextareaElement.style.resize = @"none";
        _DOMTextareaElement.style.padding = @"0";
        _DOMTextareaElement.style.margin = @"0";
        
        _DOMTextareaElement.onblur = function(){
                [[CPTextFieldInputOwner window] makeFirstResponder:nil];
                CPTextFieldInputOwner = nil;
            };
        
        self._DOMElement.appendChild(_DOMTextareaElement);
    }
    
    return _DOMTextareaElement;
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
    }
    return self;
}

- (void)setEditable:(BOOL)shouldBeEditable
{
    [self _DOMTextareaElement].style.cursor = shouldBeEditable ? @"cursor" : @"default";
    [super setEditable:shouldBeEditable];
}

- (void)selectText:(id)sender
{
    [self _DOMTextareaElement].select();
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    var contentView = [self layoutEphemeralSubviewNamed:@"content-view"
                                             positioned:CPWindowAbove
                        relativeToEphemeralSubviewNamed:@"bezel-view"];
    [contentView setHidden:YES];
    
    var DOMElement = [self _DOMTextareaElement],
        contentInset = [self currentValueForThemeAttribute:@"content-inset"],
        bounds = [self bounds];
    
    DOMElement.style.top = contentInset.top + @"px";
    DOMElement.style.bottom = contentInset.bottom + @"px";
    DOMElement.style.left = contentInset.left + @"px";
    DOMElement.style.right = contentInset.right + @"px";
    
    DOMElement.style.width = (CGRectGetWidth(bounds) - contentInset.left - contentInset.right) + @"px";
    DOMElement.style.height = (CGRectGetHeight(bounds) - contentInset.top - contentInset.bottom) + @"px";
        
    DOMElement.style.color = [[self currentValueForThemeAttribute:@"text-color"] cssString];
    DOMElement.style.font = [[self currentValueForThemeAttribute:@"font"] cssString];
    DOMElement.value = _stringValue || @"";
}

- (void)mouseDown:(CPEvent)anEvent
{
    if ([self isEditable] && [self isEnabled])
        [[[self window] platformWindow] _propagateCurrentDOMEvent:YES];
    else
        [super mouseDown:anEvent];
}

- (void)keyDown:(CPEvent)anEvent
{
    if ([anEvent keyCode] === CPTabKeyCode)
    {
        if ([anEvent modifierFlags] & CPShiftKeyMask)
            [[self window] selectPreviousKeyView:self];
        else
            [[self window] selectNextKeyView:self];
 
        if ([[[self window] firstResponder] respondsToSelector:@selector(selectText:)])
            [[[self window] firstResponder] selectText:self];
 
        [[[self window] platformWindow] _propagateCurrentDOMEvent:NO];
    }
    else
        [[[self window] platformWindow] _propagateCurrentDOMEvent:YES];
    
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
}

- (void)keyUp:(CPEvent)anEvent
{
    if (_stringValue !== [self stringValue])
    {
        _stringValue = [self stringValue];
        
        if (!_isEditing)
        {
            _isEditing = YES;
            [self textDidBeginEditing:[CPNotification notificationWithName:CPControlTextDidBeginEditingNotification object:self userInfo:nil]];
        }
 
        [self textDidChange:[CPNotification notificationWithName:CPControlTextDidChangeNotification object:self userInfo:nil]];
    }
 
    [[[self window] platformWindow] _propagateCurrentDOMEvent:YES];
}

- (BOOL)performKeyEquivalent:(CPEvent)anEvent
{
    [[[self window] platformWindow] _propagateCurrentDOMEvent:YES];
    return YES;
}

- (BOOL)becomeFirstResponder
{
    _stringValue = [self stringValue];
    
    [self setThemeState:CPThemeStateEditing];
    
    setTimeout(function(){
        [self _DOMTextareaElement].focus();
        CPTextFieldInputOwner = self;
    }, 0.0);
    
    [self textDidFocus:[CPNotification notificationWithName:CPTextFieldDidFocusNotification object:self userInfo:nil]];
    
    return YES;
}

- (BOOL)resignFirstResponder
{
    [self unsetThemeState:CPThemeStateEditing];
    
    [self setStringValue:[self stringValue]];
    
    [self _DOMTextareaElement].blur();

    //post CPControlTextDidEndEditingNotification
    if (_isEditing)
    {
        _isEditing = NO;
        [self textDidEndEditing:[CPNotification notificationWithName:CPControlTextDidEndEditingNotification object:self userInfo:nil]];

        if ([self sendsActionOnEndEditing])
            [self sendAction:[self action] to:[self target]];
    }
    
    [self textDidBlur:[CPNotification notificationWithName:CPTextFieldDidBlurNotification object:self userInfo:nil]];
    
    return YES;
}

- (CPString)stringValue
{
    return (!!_DOMTextareaElement) ? _DOMTextareaElement.value : @"";
}

- (void)setStringValue:(CPString)aString
{
    _stringValue = aString;
    [self setNeedsLayout];
}

@end