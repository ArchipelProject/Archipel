/*
 * TNLineableView.j
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
@import <AppKit/CPView.j>

@implementation TNViewLineable : CPView
{
    CGPoint _origin;
    CGPoint _end;
    CPBezierPath _path;

    CPBezierPath _originPoint;
    CPBezierPath _endPoint;
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        _path = [CPBezierPath bezierPath];
        [_path setLineWidth:3];
    }
    return self;
}

- (void)drawRect:(CGRect)aRect
{
    [super drawRect:aRect];
    [_originPoint setLineWidth:5];
    [_endPoint setLineWidth:5];


    [[CPColor colorWithHexString:@"C4F66F"] set];
    [_path fill];


    [[CPColor colorWithHexString:@"619A00"] set];
    [_path stroke];

    [_originPoint stroke];
    [_endPoint stroke];
    [_originPoint fill];
    [_endPoint fill];
}

- (void)mouseDown:(CPEvent)anEvent
{
    var locationInWindow = [anEvent locationInWindow];
    _origin = [self convertPoint:locationInWindow fromView:nil];

    [_path moveToPoint:_origin];
    _originPoint = [CPBezierPath bezierPathWithOvalInRect:CGRectMake(_origin.x - 1 , _origin.y - 1.6 , 3, 3)];

    [self setNeedsDisplay:YES];
}

- (void)mouseUp:(CPEvent)anEvent
{
    [_path removeAllPoints];
    [_originPoint removeAllPoints];
    [_endPoint removeAllPoints];
    [self setNeedsDisplay:YES];
}

- (void)mouseDragged:(CPEvent)anEvent
{
    var locationInWindow = [anEvent locationInWindow];
    _end = [self convertPoint:locationInWindow fromView:nil];

    [_path removeAllPoints];
    [_path moveToPoint:_origin];
    [_path lineToPoint:_end];

    _endPoint = [CPBezierPath bezierPathWithOvalInRect:CGRectMake(_end.x - 1 , _end.y - 1, 3, 3)];

    [self setNeedsDisplay:YES];
}

@end
