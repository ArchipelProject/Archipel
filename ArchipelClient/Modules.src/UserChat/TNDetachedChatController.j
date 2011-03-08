/*
 * TNDetachedChatController.j
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


if ([CPPlatform isBrowser])
    var TNDetachedChatControllerDefaultFrame = CPRectMake(100, 100, 400, 370);
else
    var TNDetachedChatControllerDefaultFrame = CPRectMake(100, 100, 400, 395);


/*! @ingroup userchat
    controller of a detached chat window
*/
@implementation TNDetachedChatController : CPObject
{
    CPArray             _messageHistory         @accessors(property=messageHistory);
    id                  _delegate               @accessors(property=delegate);
    TNStropheContact    _entity                 @accessors(property=entity);

    CPImageView         _viewAvatar;
    CPPlatformWindow    _platformWindow;
    CPScrollView        _scrollView;
    CPTextField         _fieldMessage;
    CPWindow            _window;
    TNMessageBoard      _messageBoard;
}

#pragma mark -
#pragma mark Initialization

/*! initialize the controller
*/
- (void)initWithEntity:(TNStropheContact)anEntity
{
    if (self = [super init])
    {
        _entity = anEntity;

        if ([CPPlatform isBrowser])
            _window = [[CPWindow alloc] initWithContentRect:TNDetachedChatControllerDefaultFrame styleMask:CPTitledWindowMask | CPClosableWindowMask | CPMiniaturizableWindowMask | CPResizableWindowMask | CPBorderlessBridgeWindowMask];
        else
            _window = [[CPWindow alloc] initWithContentRect:TNDetachedChatControllerDefaultFrame styleMask:CPTitledWindowMask | CPClosableWindowMask | CPMiniaturizableWindowMask | CPResizableWindowMask];
        [_window setTitle:@"Archipel - Chat with " + [_entity nickname] || [[_entity JID] bare]];
        [[_window contentView] setBackgroundColor:[CPColor colorWithHexString:@"f4f4f4"]];
        [[_window contentView] setAutoresizingMask:nil];

        _scrollView = [[CPScrollView alloc] initWithFrame:CPRectMake(0, 0, 400, 322)];
        [_scrollView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
        [_scrollView setBorderedWithHexColor:@"#C0C7D2"];
        [_scrollView setBackgroundColor:[CPColor whiteColor]];
        [_scrollView setAutohidesScrollers:YES];
        [[_window contentView] addSubview:_scrollView];

        _messageBoard = [[TNMessageBoard alloc] initWithFrame:CPRectMake(0, 0, 400, 322)];
        [_messageBoard setAutoresizingMask:CPViewWidthSizable]
        [_scrollView setDocumentView:_messageBoard];

        _fieldMessage = [[CPTextField alloc] initWithFrame:CPRectMake(50, 332, 338, 29)];
        [_fieldMessage setEditable:YES];
        [_fieldMessage setBezeled:YES];
        [_fieldMessage setTarget:self];
        [_fieldMessage setAction:@selector(sendMessage:)];
        [_fieldMessage setAutoresizingMask: CPViewWidthSizable | CPViewMinYMargin];
        [[_window contentView] addSubview:_fieldMessage];

        _viewAvatar = [[CPImageView alloc] initWithFrame:CPRectMake(2, 326, 42, 42)];
        [_viewAvatar setImageScaling:CPScaleProportionally];
        [_viewAvatar setBackgroundColor:[CPColor blackColor]];
        [_viewAvatar setImage:[_entity avatar]];
        [_viewAvatar setAutoresizingMask:CPViewMinYMargin];
        [[_window contentView] addSubview:_viewAvatar];

        if ([CPPlatform isBrowser])
        {
            _platformWindow = [[CPPlatformWindow alloc] initWithContentRect:TNDetachedChatControllerDefaultFrame];
            [_window setPlatformWindow:_platformWindow];
            [_platformWindow orderFront:nil];
            [_platformWindow setTitle:[_window title]];
        }
    }

    return self;
}


#pragma mark -
#pragma mark Notification handler

/*! called when a new message is received
    @param aNotification the notification containing the message information
*/
- (void)_didReceiveMessage:(CPNotification)aNotification
{
    if ([[aNotification object] JID] == [_entity JID])
    {
        var stanza =  [[_entity messagesQueue] objectAtIndex:[[_entity messagesQueue] count] - 1];

        if ([stanza containsChildrenWithName:@"body"])
        {
            var messageBody = [[stanza firstChildWithName:@"body"] text];

            [self appendMessageToBoard:messageBody from:[_entity nickname]];
        }
    }

    if (_delegate && [_delegate respondsToSelector:@selector(_didReceiveMessage:)] && [_delegate isVisible])
        [_delegate _didReceiveMessage:aNotification];
}


/*! called when contact update vCard
*/
- (void)_didUpdateVCard:(CPNotification)aNotification
{
    [_viewAvatar setImage:[_entity avatar]];
}

/*! called when contact update nickname
*/
- (void)_didUpdateNickname:(CPNotification)aNotification
{
    [_window setTitle:@"Archipel - Chat with " + [_entity nickname] || [[_entity JID] bare]];
    if ([CPPlatform isBrowser])
        [_platformWindow setTitle:[_window title]];
}

/*! called when the window is closed
    it will remove observers
    @param aNotification the notification that triggers the message
*/
- (void)_windowWillClose:(CPNotification)aNotification
{
    [[CPNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark -
#pragma mark Utilities

/*! display the new chat window
*/
- (void)showWindow
{
    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_didReceiveMessage:) name:TNStropheContactMessageReceivedNotification object:_entity];
    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_didUpdateVCard:) name:TNStropheContactVCardReceivedNotification object:_entity];
    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_didUpdateNickname:) name:TNStropheContactNicknameUpdatedNotification object:_entity];
    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_windowWillClose:) name:CPWindowWillCloseNotification object:_window];

    [_messageBoard removeAllMessages:nil];
    if (_messageHistory)
    {
        for (var i = 0; i < [_messageHistory count]; i++)
        {
            var message = [_messageHistory objectAtIndex:i],
                avatar = nil;

            if ([message objectForKey:@"name"] != @"me")
                avatar = [_entity avatar];
            else
                avatar = [[TNStropheIMClient defaultClient] avatar];

            [_messageBoard addMessage:[message objectForKey:@"message"] from:[message objectForKey:@"name"] date:[message objectForKey:@"date"] color:[message objectForKey:@"color"] avatar:avatar];
        }

        var newScrollOrigin = CPMakePoint(0.0, [[_scrollView documentView] frame].size.height);
        [_messageBoard scrollPoint:newScrollOrigin];
    }

    [_window center];
    [_window setFrame:TNDetachedChatControllerDefaultFrame];
    [_window makeKeyAndOrderFront:nil];
    [[_window contentView] setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
}

/*! append message to the board
    @param aMessage the message
    @param aSender the sender of the message
*/
- (void)appendMessageToBoard:(CPString)aMessage from:(CPString)aSender
{
    var color           = (aSender == @"me") ? [CPColor colorWithHexString:@"d9dfe8"] : [CPColor colorWithHexString:@"ffffff"],
        date            = [CPDate date],
        newMessageDict  = [CPDictionary dictionaryWithObjectsAndKeys:aSender, @"name", aMessage, @"message", color, @"color", date, @"date"],
        frame           = [[_scrollView documentView] frame],
        avatar          = nil;

    if (aSender != @"me")
        avatar = [_entity avatar];
    else
        avatar = [[TNStropheIMClient defaultClient] avatar];

    [_messageBoard addMessage:aMessage from:aSender date:date color:color avatar:avatar];

    // scroll to bottom;
    var newScrollOrigin = CPMakePoint(0.0, frame.size.height);
    [_messageBoard scrollPoint:newScrollOrigin];
}


#pragma mark -
#pragma mark Actions

/*! send a message to the contact
    @param aSender the sender of the action
*/
- (IBAction)sendMessage:(id)aSender
{
    [self appendMessageToBoard:[aSender stringValue] from:@"me"];
    [_entity sendMessage:[aSender stringValue]];

    if (_delegate && ([_delegate entity] == _entity) && [_delegate respondsToSelector:@selector(appendMessageToBoard:from:)] && [_delegate isVisible])
        [_delegate appendMessageToBoard:[aSender stringValue] from:@"me"];

    [aSender setStringValue:@""];
}


@end