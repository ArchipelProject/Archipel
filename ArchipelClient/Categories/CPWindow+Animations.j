/*!

    Created by Randy Luecke April 22nd 2011
    Copyright RCLConcepts, LLC.
    All right reserved.


    This code is available under the MIT license.
*/


/*!
    Window Animations:

    Usage: This category extends CPWindow to allow for
    prettier open and close animations.

    You can specify where you want the animation to originate from,
    and the speed you want the animation to happen.

    By defaut the animation is 230ms long and originates from the
    center of the window.
*/

CPWindowAnimationCornerTopLeft      = "0% 0%";
CPWindowAnimationCornerTopCenter    = "50% 0%";
CPWindowAnimationCornerTopRight     = "100% 0%";

CPWindowAnimationCornerMiddleLeft   = "0% 50%";
CPWindowAnimationCornerMiddleCenter = "50% 50%";
CPWindowAnimationCornerMiddleRight  = "100% 50%";

CPWindowAnimationCornerBottomLeft   = "0% 100%";
CPWindowAnimationCornerBottomCenter = "50% 100%";
CPWindowAnimationCornerBottomRight  = "100% 100%";

@implementation CPWindow (OpenCloseAnimations)

/*!
    The length of the animation. Values in ms. This defaults to 230ms;
*/
- (void)setAnimationLength:(float)aDuration
{
    self.animationLength = aDuration;
}

/*!
    Set the corner from which you want to animate from.
    This defaults to the center
*/
- (void)setAnimationLocation:(WindowAnimationCorner)aCorner
{
    self.animationOrigin = aCorner;
}

- (void)orderFontWithAnimation:(id)sender
{
    [self orderFront:self];

    var time = self.animationLength || "230",
        corner = self.animationOrigin || CPWindowAnimationCornerMiddleCenter;

    // apply the transforms
    _DOMElement.style.WebkitTransitionDuration = time + "ms";
    _DOMElement.style.WebkitTransitionTimingFunction = "ease-in-out";
    _DOMElement.style.WebkitTransitionProperty = "-webkit-transform, opacity";
    _DOMElement.style.WebkitTransformOrigin = corner;

    _DOMElement.style.MozTransitionDuration = time + "ms";;
    _DOMElement.style.MozTransitionTimingFunction = "ease-in-out";
    _DOMElement.style.MozTransitionProperty = "-moz-transform, opacity";
    _DOMElement.style.MozTransformOrigin = corner;

    _DOMElement.style.transitionDuration = time + "ms";;
    _DOMElement.style.transitionTimingFunction = "ease-in-out";
    _DOMElement.style.transitionProperty = "transform, opacity";
    _DOMElement.style.transformOrigin = corner;

    // set initial value
    _DOMElement.style.WebkitTransform = "scale(0)";
    _DOMElement.style.MozTransform = "scale(0)";
    _DOMElement.style.transform = "scale(0)";
    _DOMElement.style.opacity = 0;

    var cleanUp =  function(){
        _DOMElement.style.width = "1px";
        _DOMElement.style.height = "1px";

        _DOMElement.style.WebkitTransitionDuration = "";
        _DOMElement.style.WebkitTransitionTimingFunction = "";
        _DOMElement.style.WebkitTransitionProperty = "";
        _DOMElement.style.WebkitTransformOrigin = "";

        _DOMElement.style.MozTransitionDuration = "";
        _DOMElement.style.MozTransitionTimingFunction = "";
        _DOMElement.style.MozTransitionProperty = "";
        _DOMElement.style.MozTransformOrigin = "";

        _DOMElement.style.transitionDuration = "";
        _DOMElement.style.transitionTimingFunction = "";
        _DOMElement.style.transitionProperty = "";
        _DOMElement.style.transformOrigin = "";
        this.removeEventListener(@"webkitTransitionEnd");
        this.removeEventListener(@"transitionend");
    };

    _DOMElement.addEventListener(@"webkitTransitionEnd", cleanUp, YES);
    _DOMElement.addEventListener(@"transitionend", cleanUp, YES);

    // animate it
    window.setTimeout(function(){
        // the _DOMElement is almost always 1x1px so we need to fix that.
        _DOMElement.style.width = _frame.size.width + "px";
        _DOMElement.style.height = _frame.size.height + "px";

        _DOMElement.style.WebkitTransform = "scale(1)";
        _DOMElement.style.MozTransform = "scale(1)";
        _DOMElement.style.transform = "scale(1)";
        _DOMElement.style.opacity = 1;
    },0);
}

- (void)orderOutWithAnimation:(id)sender
{

    var time = self.animationLength || "230",
        corner = self.animationOrigin || CPWindowAnimationCornerMiddleCenter;

    // apply the transforms
    _DOMElement.style.WebkitTransitionDuration = time + "ms";;
    _DOMElement.style.WebkitTransitionTimingFunction = "ease-in-out";
    _DOMElement.style.WebkitTransitionProperty = "-webkit-transform, opacity";
    _DOMElement.style.WebkitTransformOrigin = corner;

    _DOMElement.style.MozTransitionDuration = time + "ms";;
    _DOMElement.style.MozTransitionTimingFunction = "ease-in-out";
    _DOMElement.style.MozTransitionProperty = "-moz-transform, opacity";
    _DOMElement.style.MozTransformOrigin = corner;

    _DOMElement.style.transitionDuration = time + "ms";;
    _DOMElement.style.transitionTimingFunction = "ease-in-out";
    _DOMElement.style.transitionProperty = "transform, opacity";
    _DOMElement.style.transformOrigin = corner;

    // set initial value
    _DOMElement.style.WebkitTransform = "scale(1)";
    _DOMElement.style.MozTransform = "scale(1)";
    _DOMElement.style.transform = "scale(1)";
    _DOMElement.style.opacity = 1;

    var cleanUp = function(){
        _DOMElement.style.width = "1px";
        _DOMElement.style.height = "1px";

        _DOMElement.style.WebkitTransitionDuration = "";
        _DOMElement.style.WebkitTransitionTimingFunction = "";
        _DOMElement.style.WebkitTransitionProperty = "";
        _DOMElement.style.WebkitTransformOrigin = "";

        _DOMElement.style.MozTransitionDuration = "";
        _DOMElement.style.MozTransitionTimingFunction = "";
        _DOMElement.style.MozTransitionProperty = "";
        _DOMElement.style.MozTransformOrigin = "";

        _DOMElement.style.transitionDuration = "";
        _DOMElement.style.transitionTimingFunction = "";
        _DOMElement.style.transitionProperty = "";
        _DOMElement.style.transformOrigin = "";

        this.removeEventListener(@"webkitTransitionEnd");
        this.removeEventListener(@"transitionend");

        [self orderOut:self];
    }

    _DOMElement.addEventListener(@"webkitTransitionEnd", cleanUp, YES);
    _DOMElement.addEventListener(@"transitionend", cleanUp, YES);

    // animate it
    window.setTimeout(function(){
        // the _DOMElement is almost always 1x1px so we need to fix that.
        _DOMElement.style.width = _frame.size.width + "px";
        _DOMElement.style.height = _frame.size.height + "px";

        _DOMElement.style.WebkitTransform = "scale(0)";
        _DOMElement.style.MozTransform = "scale(0)";
        _DOMElement.style.transform = "scale(0)";
        _DOMElement.style.opacity = 0;

    },0);
}
@end