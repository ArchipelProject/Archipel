/*
Copyright (c) 2011 Elias Klughammer (elias.klughammer [at] me [dot] com)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

@import <Foundation/Foundation.j>
@import <AppKit/CPViewAnimation.j>


@implementation EKShakeAnimation : CPObject
{
    id      target;
    int     currentStep;
    int     delta;
    CGRect  targetFrame;
    int     steps;
    float   stepDuration;
    CPTimer timer;
}

- (id)initWithView:(id)aView
{
    if (self = [super init])
    {
        target       = aView;
        targetFrame  = [target frame];
        currentStep  = 1;
        delta        = 7;
        steps        = 5;
        stepDuration = 0.07;
        timer        = [CPTimer scheduledTimerWithTimeInterval:stepDuration target:self selector:@selector(timerDidFire) userInfo:nil repeats:YES];

        [timer fire];
    }

    return self;
}

- (void)timerDidFire
{
    if (currentStep === steps)
    {
        [timer invalidate];

        setTimeout(function()
        {
            [self animateToFrame:targetFrame];
        }, stepDuration);
    }
    else
    {
        var prefix = (currentStep % 2 === 1) ? -1 : 1;

        [self animateToFrame:CGRectMake(targetFrame.origin.x + delta * prefix,
                                        targetFrame.origin.y,
                                        targetFrame.size.width,
                                        targetFrame.size.height)];

        currentStep++;
    }
}

- (void)animateToFrame:(CGRect)aFrame
{
    var animation = [[CPViewAnimation alloc] initWithViewAnimations:[
        [CPDictionary dictionaryWithJSObject:{
            CPViewAnimationTargetKey:target,
            CPViewAnimationStartFrameKey:targetFrame,
            CPViewAnimationEndFrameKey:aFrame
        }]]];
    [animation setAnimationCurve:CPAnimationLinear];
    [animation setDuration:stepDuration];
    [animation startAnimation];
    targetFrame = aFrame;
}

@end
