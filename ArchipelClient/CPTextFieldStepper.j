/*
 * CPTextFieldStepper.j
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

var CPStepperButtonsSize = CPSizeMake(19, 13);

function PatternColor()
{
 if (arguments.length < 3)
 {
     var slices = arguments[0],
         imageSlices = [],
         bundle = [CPBundle bundleForClass:CPTextFieldStepper];

     for (var i = 0; i < slices.length; ++i)
     {
         var slice = slices[i];

         imageSlices.push(slice ? [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:slice[0]] size:CGSizeMake(slice[1], slice[2])] : nil);
     }

     if (arguments.length == 2)
         return [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:imageSlices isVertical:arguments[1]]];
     else
         return [CPColor colorWithPatternImage:[[CPNinePartImage alloc] initWithImageSlices:imageSlices]];
 }
 else if (arguments.length == 3)
 {
     return [CPColor colorWithPatternImage:PatternImage(arguments[0], arguments[1], arguments[2])];
 }
 else
 {
     return nil;
 }
}

/*! CPTextFieldStepper is a subclass of CPStepper. it contains a textfield that displays the current stepper value
*/
@implementation CPTextFieldStepper : CPStepper
{
    CPTextField    _textField;
}


#pragma mark -
#pragma mark Initialization

/*! Initializes a CPTextFieldStepper with given values
    @param aValue the initial value of the CPStepper
    @param minValue the minimal acceptable value of the stepper
    @param maxValue the maximal acceptable value of the stepper
    @return Initialized CPStepper
*/
+ (CPTextFieldStepper)stepperWithInitialValue:(float)aValue minValue:(float)aMinValue maxValue:(float)aMaxValue
{
    var stepper = [[CPTextFieldStepper alloc] initWithFrame:CPRectMake(0, 0, 100, 25)];
    [stepper setDoubleValue:aValue];
    [stepper setMinValue:aMinValue];
    [stepper setMaxValue:aMaxValue];

    return stepper;
}

/*! Initializes a CPStepper with default values:
        - minValue = -100
        - maxValue = 100
        - value = 0
    @return Initialized CPStepper
*/
+ (CPTextFieldStepper)stepper
{
    return [CPTextFieldStepper stepperWithInitialValue:0.0 minValue:0.0 maxValue:59.0];
}


/*! Initializes the CPTextFieldStepper with the textfield
    @param aFrame the frame of the control
    @return initialized CPTextFieldStepper
*/
- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        [_buttonUp setAutoresizingMask:CPViewMinXMargin];
        [_buttonDown setAutoresizingMask:CPViewMinXMargin];

        _textField = [[CPTextField alloc] initWithFrame:CPRectMake(0, 0, aFrame.size.width - CPStepperButtonsSize.width, aFrame.size.height)];
        [_textField setBezeled:YES];
        [_textField setEditable:NO];
        [_textField setAutoresizingMask:CPViewWidthSizable];
        [_textField bind:@"doubleValue" toObject:self withKeyPath:@"doubleValue" options:nil];
        [_textField setValue:CGInsetMake(0.0, 0.0, 0.0, 0.0) forThemeAttribute:@"bezel-inset"];
        [_textField setValue:CGInsetMake(7.0, 7.0, 5.0, 8.0) forThemeAttribute:@"content-inset"];


        var bezelUpSquareLeft = PatternColor(
                [
                    ["CPTextFieldStepper/stepper-textfield-bezel-big-up-left.png", 3.0, 13.0],
                    ["CPTextFieldStepper/stepper-textfield-bezel-big-up-center.png", 13.0, 13.0],
                    ["CPTextFieldStepper/stepper-textfield-bezel-big-up-right.png", 3.0, 13.0]
                ],
                NO),
            bezelDownSquareLeft = PatternColor(
                [
                    ["CPTextFieldStepper/stepper-textfield-bezel-big-down-left.png", 3.0, 12.0],
                    ["CPTextFieldStepper/stepper-textfield-bezel-big-down-center.png", 13.0, 12.0],
                    ["CPTextFieldStepper/stepper-textfield-bezel-big-down-right.png", 3.0, 12.0]
                ],
                NO),
            bezelUpDisabledSquareLeft = PatternColor(
                [
                    ["CPTextFieldStepper/stepper-textfield-bezel-big-disabled-up-left.png", 3.0, 13.0],
                    ["CPTextFieldStepper/stepper-textfield-bezel-big-disabled-up-center.png", 13.0, 13.0],
                    ["CPTextFieldStepper/stepper-textfield-bezel-big-disabled-up-right.png", 3.0, 13.0]
                ],
                NO),
            bezelDownDisabledSquareLeft = PatternColor(
                [
                    ["CPTextFieldStepper/stepper-textfield-bezel-big-disabled-down-left.png", 3.0, 12.0],
                    ["CPTextFieldStepper/stepper-textfield-bezel-big-disabled-down-center.png", 13.0, 12.0],
                    ["CPTextFieldStepper/stepper-textfield-bezel-big-disabled-down-right.png", 3.0, 12.0]
                ],
                NO),
            bezelUpHighlightedSquareLeft = PatternColor(
                [
                    [@"CPTextFieldStepper/stepper-textfield-bezel-big-highlighted-up-left.png", 3.0, 13.0],
                    [@"CPTextFieldStepper/stepper-textfield-bezel-big-highlighted-up-center.png", 13.0, 13.0],
                    [@"CPTextFieldStepper/stepper-textfield-bezel-big-highlighted-up-right.png", 3.0, 13.0]
                ],
                NO),
            bezelDownHighlightedSquareLeft = PatternColor(
                [
                    [@"CPTextFieldStepper/stepper-textfield-bezel-big-highlighted-down-left.png", 3.0, 12.0],
                    [@"CPTextFieldStepper/stepper-textfield-bezel-big-highlighted-down-center.png", 13.0, 12.0],
                    [@"CPTextFieldStepper/stepper-textfield-bezel-big-highlighted-down-right.png", 3.0, 12.0]
                ],
                NO),
            tfbezelColor = PatternColor(
                [
                    ["CPTextFieldStepper/stepper-textfield-bezel-big-bezel-square-0.png", 2.0, 3.0],
                    ["CPTextFieldStepper/stepper-textfield-bezel-big-bezel-square-1.png", 1.0, 3.0],
                    ["CPTextFieldStepper/stepper-textfield-bezel-big-bezel-square-2.png", 2.0, 3.0],
                    ["CPTextFieldStepper/stepper-textfield-bezel-big-bezel-square-3.png", 2.0, 1.0],
                    ["CPTextFieldStepper/stepper-textfield-bezel-big-bezel-square-4.png", 1.0, 1.0],
                    ["CPTextFieldStepper/stepper-textfield-bezel-big-bezel-square-5.png", 2.0, 1.0],
                    ["CPTextFieldStepper/stepper-textfield-bezel-big-bezel-square-6.png", 2.0, 2.0],
                    ["CPTextFieldStepper/stepper-textfield-bezel-big-bezel-square-7.png", 1.0, 2.0],
                    ["CPTextFieldStepper/stepper-textfield-bezel-big-bezel-square-8.png", 2.0, 2.0]
                ]),
            tfbezelDisabledColor = PatternColor(
                [
                    ["CPTextFieldStepper/stepper-textfield-bezel-big-disabled-bezel-square-0.png", 2.0, 3.0],
                    ["CPTextFieldStepper/stepper-textfield-bezel-big-disabled-bezel-square-1.png", 1.0, 3.0],
                    ["CPTextFieldStepper/stepper-textfield-bezel-big-disabled-bezel-square-2.png", 2.0, 3.0],
                    ["CPTextFieldStepper/stepper-textfield-bezel-big-disabled-bezel-square-3.png", 2.0, 1.0],
                    ["CPTextFieldStepper/stepper-textfield-bezel-big-disabled-bezel-square-4.png", 1.0, 1.0],
                    ["CPTextFieldStepper/stepper-textfield-bezel-big-disabled-bezel-square-5.png", 2.0, 1.0],
                    ["CPTextFieldStepper/stepper-textfield-bezel-big-disabled-bezel-square-6.png", 2.0, 2.0],
                    ["CPTextFieldStepper/stepper-textfield-bezel-big-disabled-bezel-square-7.png", 1.0, 2.0],
                    ["CPTextFieldStepper/stepper-textfield-bezel-big-disabled-bezel-square-8.png", 2.0, 2.0]
                ]);

        [_textField setValue:tfbezelColor forThemeAttribute:@"bezel-color"];
        [_textField setValue:tfbezelDisabledColor forThemeAttribute:@"bezel-color" inState:CPThemeStateBezeled | CPThemeStateDisabled];

        [_buttonUp setValue:bezelUpSquareLeft forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered];
        [_buttonUp setValue:bezelUpDisabledSquareLeft forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered | CPThemeStateDisabled];
        [_buttonUp setValue:bezelUpHighlightedSquareLeft forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered | CPThemeStateHighlighted];

        [_buttonDown setValue:bezelDownSquareLeft forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered];
        [_buttonDown setValue:bezelDownDisabledSquareLeft forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered | CPThemeStateDisabled];
        [_buttonDown setValue:bezelDownHighlightedSquareLeft forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered | CPThemeStateHighlighted];

        [self addSubview:_textField];
    }

    return self;
}

/*! set the CPTextFieldStepper enabled or not
    @param shouldEnabled BOOL that define if stepper is enabled or not.
*/
- (void)setEnabled:(BOOL)shouldEnabled
{
    [super setEnabled:shouldEnabled];
    [_textField setEnabled:shouldEnabled];
}

@end


@implementation CPTextFieldStepper (CPCodingCompliance)

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        _textField   = [aCoder decodeObjectForKey:@"_textField"];

    }
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:_textField forKey:@"_textField"];
}

@end