/*  
 * TNGrowl.j
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

TNGrowlDefaultDisplayTime               = 5.0;
TNGrowlViewWillRemoveViewNotification   = @"TNGrowlViewWillRemoveViewNotification";
TNGrowlDefaultCenter                    = nil;

@implementation TNGrowlView : CPView
{
    CPImageView _icon;
    CPTextField _title;
    CPTextField _message;
    CPTimer     _timer;
    float       _lifeTime;
}

- (id)initWithFrame:(CPRect)aFrame title:(CPString)aTitle message:(CPString)aMessage icon:(CPImage)anIcon lifeTime:(float)aLifeTime background:(CPColor)aBackground
{
    if (self = [super initWithFrame:aFrame])
    {
        _lifeTime   = aLifeTime;
        _icon       = [[CPImageView alloc] initWithFrame:CGRectMake(8, 8, 64, 64)];
        _title      = [[CPTextField alloc] initWithFrame:CGRectMake(78, 5, aFrame.size.width - 78, 20)];
        _message    = [[CPTextField alloc] initWithFrame:CGRectMake(78, 20, aFrame.size.width - 78, aFrame.size.height - 25)];
        
        
        [_icon setImage:anIcon];
        [_icon setBorderRadius:5];
        [_title setStringValue:aTitle];
        [_title setFont:[CPFont boldSystemFontOfSize:12]];
        [_title setTextColor:[CPColor whiteColor]];
        [_title setAutoresizingMask:CPViewWidthSizable];
        [_message setStringValue:aMessage];
        [_message setLineBreakMode:CPLineBreakByWordWrapping];
        [_message setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
        [_message setTextColor:[CPColor whiteColor]];
        
        [self addSubview:_icon];
        [self addSubview:_title];
        [self addSubview:_message];
        
        [self setBackgroundColor:aBackground];
        [self setBorderRadius:5];
        [self setAlphaValue:0.8];
        
        _timer = [CPTimer scheduledTimerWithTimeInterval:_lifeTime target:self selector:@selector(willBeRemoved:) userInfo:nil repeats:NO];
    }
    
    return self;
}

- (void)mouseDown:(CPEvent)anEvent
{
    if ([anEvent type] == CPLeftMouseDown)
    {
        [_timer invalidate];
        [self willBeRemoved:nil];
    }
    
    [super mouseDown:anEvent];
}

- (void)willBeRemoved:(CPTimer)aTimer
{
    var center = [CPNotificationCenter defaultCenter];
    
    [center postNotificationName:TNGrowlViewWillRemoveViewNotification object:self];
}

@end

@implementation TNGrowlCenter : CPObject
{
    CPArray     _notifications;
    CPView      _view @accessors(getter=view, setter=setView:);
    CPRect      _notificationFrame;
    float       _defaultLifeTime @accessors(getter=lifeDefaultTime, setter=setDefaultLifeTime:);
    CPColor     _backgroundColor @accessors(getter=backgroundColor, setter=setBackgroundColor:);
    CPImage     _defaultIcon @accessors(getter=defaultIcon, setter=setDefaultIcon:);
}

+ (id)defaultCenter
{
    if (!TNGrowlDefaultCenter)
    {
        TNGrowlDefaultCenter = [[TNGrowlCenter alloc] init];
    }
    
    return TNGrowlDefaultCenter;
}

- (id)init
{
    if (self = [super init])
    {
        _notifications      = [CPArray array];
        _notificationFrame  = CGRectMake(10,10,250,80);
        _defaultLifeTime    = TNGrowlDefaultDisplayTime;
        _defaultIcon        = nil;
    }
    
    return self;
}

- (void)pushNotificationWithTitle:(CPString)aTitle message:(CPString)aMessage icon:(CPImage)anIcon
{
    var icon        = (anIcon) ? anIcon : _defaultIcon;
    var center      = [CPNotificationCenter defaultCenter];
    var notifView   = [[TNGrowlView alloc] initWithFrame:_notificationFrame title:aTitle message:aMessage icon:icon lifeTime:_defaultLifeTime background:_backgroundColor];
    var frame       = [_view frame];
    var notifFrame  = CPRectCreateCopy(_notificationFrame);
    var animParams  = [CPDictionary dictionaryWithObjectsAndKeys:notifView, CPViewAnimationTargetKey, CPViewAnimationFadeInEffect, CPViewAnimationEffectKey];
    var anim        = [[CPViewAnimation alloc] initWithViewAnimations:[animParams]];
    
    [center addObserver:self selector:@selector(didReceivedNotificationEndLifeTime:) name:TNGrowlViewWillRemoveViewNotification object:notifView];
    
    for (var i = 0; i < [_notifications count]; i++)
    {
        var isViewInThisFrame = NO;
        
        for (var j = 0; j < [_notifications count]; j++)
        {
            var tmpFrame = [[_notifications objectAtIndex:j] frame];
            
            if (notifFrame.origin.y == tmpFrame.origin.y)
            {
                isViewInThisFrame = YES;
                
                break;
            }
        }
        if (!isViewInThisFrame)
            break;
        notifFrame.origin.y += _notificationFrame.size.height + 10;
    }
    
    notifFrame.origin.x = frame.size.width - _notificationFrame.size.width - 20;
    
    [_notifications addObject:notifView];
    [notifView setFrame:notifFrame];
    
    [_view addSubview:notifView];
    
    [anim setDuration:0.3];
    [anim startAnimation];
}

- (void)didReceivedNotificationEndLifeTime:(CPNotification)aNotification
{
    var center      = [CPNotificationCenter defaultCenter];
    var senderView  = [aNotification object];
    var animView    = [CPDictionary dictionaryWithObjectsAndKeys:senderView, CPViewAnimationTargetKey, CPViewAnimationFadeOutEffect, CPViewAnimationEffectKey];
    var anim        = [[CPViewAnimation alloc] initWithViewAnimations:[animView]];

    [center removeObserver:self name:TNGrowlViewWillRemoveViewNotification object:senderView];

    [anim setDuration:0.3];
    [anim setDelegate:self];
    [anim startAnimation];
}

- (void)animationDidEnd:(CPAnimation)anAnimation
{
    var senderView = [[[anAnimation viewAnimations] objectAtIndex:0] objectForKey:CPViewAnimationTargetKey];
    
    [_notifications removeObject:senderView];
    [senderView removeFromSuperview];
}

@end