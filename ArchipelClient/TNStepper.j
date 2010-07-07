/*  
 * TNStepper.j
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


@import <AppKit/AppKit.j>

@implementation TNStepper: CPView
{
    id          _target     @accessors(property=target);
    SEL         _action     @accessors(property=action);
    int         _value      @accessors(property=value);
    int         _maxValue   @accessors(property=maxValue);
    int         _minValue   @accessors(property=minValue);
    
    CPButton    _buttonUp;
    CPButton    _buttonDown;
}


- (id)initWithFrame:(CPRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        var bundle = [CPBundle mainBundle];
        _value      = 0;
        _maxValue   = 10;
        _minValue   = -10;
        
        _buttonUp = [[CPButton alloc] initWithFrame:CPRectMake(0, 0, 15, 12)];
        [_buttonUp setTarget:self];
        [_buttonUp setAction:@selector(buttonDidClick:)];
        
        var bUpBezelColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
            [
                [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"TNStepper/stepper-up-bezel-left.png"] size:CPSizeMake(3, 12)],
                [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"TNStepper/stepper-up-bezel-center.png"] size:CPSizeMake(9, 12)],
                [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"TNStepper/stepper-up-bezel-right.png"] size:CPSizeMake(3, 12)]
            ] isVertical:NO]];
            
        var bUpBezelColorHighlighted = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
            [
                [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"TNStepper/stepper-up-bezel-left-highlight.png"] size:CPSizeMake(3, 12)],
                [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"TNStepper/stepper-up-bezel-center-highlight.png"] size:CPSizeMake(9, 12)],
                [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"TNStepper/stepper-up-bezel-right-highlight.png"] size:CPSizeMake(3, 12)]
            ] isVertical:NO]];
        
        var bUpBezelColorDisabled = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
            [
                [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"TNStepper/stepper-up-bezel-left-disabled.png"] size:CPSizeMake(3, 12)],
                [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"TNStepper/stepper-up-bezel-center-disabled.png"] size:CPSizeMake(9, 12)],
                [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"TNStepper/stepper-up-bezel-right-disabled.png"] size:CPSizeMake(3, 12)]
            ] isVertical:NO]];
        
        [_buttonUp setValue:bUpBezelColor forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered];
        [_buttonUp setValue:bUpBezelColorHighlighted forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered|CPThemeStateHighlighted];
        [_buttonUp setValue:bUpBezelColorDisabled forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered|CPThemeStateDisabled];
        
        [self addSubview:_buttonUp];
        
        
        _buttonDown = [[CPButton alloc] initWithFrame:CPRectMake(0, 12, 15, 12)];
        [_buttonDown setTarget:self];
        [_buttonDown setAction:@selector(buttonDidClick:)];
        
        var bDownBezelColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
            [
                [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"TNStepper/stepper-down-bezel-left.png"] size:CPSizeMake(3, 12)],
                [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"TNStepper/stepper-down-bezel-center.png"] size:CPSizeMake(9, 12)],
                [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"TNStepper/stepper-down-bezel-right.png"] size:CPSizeMake(3, 12)]
            ] isVertical:NO]];
            
        var bDownBezelColorHighlighted = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
            [
                [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"TNStepper/stepper-down-bezel-left-highlight.png"] size:CPSizeMake(3, 12)],
                [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"TNStepper/stepper-down-bezel-center-highlight.png"] size:CPSizeMake(9, 12)],
                [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"TNStepper/stepper-down-bezel-right-highlight.png"] size:CPSizeMake(3, 12)]
            ] isVertical:NO]];
            
        var bDownBezelColorDisabled = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
            [
                [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"TNStepper/stepper-down-bezel-left-disabled.png"] size:CPSizeMake(3, 12)],
                [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"TNStepper/stepper-down-bezel-center-disabled.png"] size:CPSizeMake(9, 12)],
                [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"TNStepper/stepper-down-bezel-right-disabled.png"] size:CPSizeMake(3, 12)]
            ] isVertical:NO]];
        
        [_buttonDown setValue:bDownBezelColor forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered];
        [_buttonDown setValue:bDownBezelColorHighlighted forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered|CPThemeStateHighlighted];
        [_buttonDown setValue:bDownBezelColorDisabled forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered|CPThemeStateDisabled];
        
        [self addSubview:_buttonDown];
    }
    return self;
}


- (IBAction)buttonDidClick:(id)sender
{
    if (sender == _buttonUp)
        _value = (_value + 1 > _maxValue) ? _maxValue : _value + 1;
    else
        _value = (_value - 1 < _minValue) ? _minValue : _value - 1;
        
    if (_target && _action && [_target respondsToSelector:_action])
        [_target performSelector:_action withObject:self];
}

- (void)setEnabled:(BOOL)isEnabled
{
    [_buttonUp setEnabled:isEnabled];
    [_buttonDown setEnabled:isEnabled];
}
