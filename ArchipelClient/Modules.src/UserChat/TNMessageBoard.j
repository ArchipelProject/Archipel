/*  
 * TNMessageView.j
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
@import "TNMessageView.j";

@implementation TNMessageBoard : CPView 
{
    CPArray     _messageDicts;
    CPArray     _messageViews;
}

- (id)initWithFrame:(CPRect)aFrame
{
    if(self = [super initWithFrame:aFrame]) 
    {
        _messageViews   = [CPArray array];
        _messageDicts   = [CPArray array];
        
        var center = [CPNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(didResize:) name:CPViewFrameDidChangeNotification object:self];
    }
    
    return self;
}

- (void)didResize:(CPNotification)aNotification
{
    //[self reload];
}

- (void)reload
{
    for (var i = 0; i < [_messageViews count]; i++)
    {
        var view = [_messageViews objectAtIndex:i];
        [view removeFromSuperview];
    }
    [_messageViews removeAllObjects];
    
    var frame = [self frame];
    frame.size.height = 0;
    
    [self setFrame:frame];
    
    for(var i = 0; i < [_messageDicts count]; i++)
    {
        var messageDict = [_messageDicts objectAtIndex:i];
        var author      = [messageDict objectForKey:@"author"];
        var message     = [messageDict objectForKey:@"message"];
        var date        = [messageDict objectForKey:@"date"];
        var color       = [messageDict objectForKey:@"color"];
        
        [self addMessage:message from:author color:color date:date];
    }
    
}

- (CPRect)nextPosition
{
    var position;
    var lastMessageView;
    
    if (lastMessageView = [_messageViews lastObject])
    {
        position = [lastMessageView frame]
        position.origin.y = position.origin.y + position.size.height;
        return position;
    }
    
    return CGRectMake(0, 0, [self bounds].size.width, 0);
}

- (void)addMessage:(CPString)aMessage from:(CPString)anAuthor color:(CPColor)aColor date:(CPDate)aDate
{
    var position    = [self nextPosition];
    var messageView = [[TNMessageView alloc] initWithFrame:position
                                                    author:anAuthor
                                                   subject:@"Subject"
                                                   message:aMessage
                                                 timestamp:aDate
                                           backgroundColor:aColor];

    [_messageViews addObject:messageView];
    [self addSubview:messageView];
    
    var boardFrame = [self frame];
    boardFrame.size.height += [messageView frame].size.height; 
    
    [self setFrame:boardFrame];
    
    [_messageDicts addObject:[CPDictionary dictionaryWithObjectsAndKeys:anAuthor, @"author", aMessage, @"message", aDate, @"date", aColor, @"color"]];
    
}

- (IBAction)removeAllMessages:(id)aSender
{
    [_messageDicts removeAllObjects];
    [self reload]
}


@end
