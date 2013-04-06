/*
 * TNUserChat.j
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

@import <AppKit/CPButton.j>
@import <AppKit/CPImageView.j>
@import <AppKit/CPSound.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPView.j>

@import <TNKit/TNMessageBoard.j>

@import "../../Model/TNModule.j"
@import "TNDetachedChatController.j"

@global CPLocalizedString
@global CPLocalizedStringFromTableInBundle


/*! @defgroup  userchat Module User Chat
    @desc This module allows to chat with entities
*/


/*! @ingroup userchat
    The module main controller
*/
@implementation TNUserChatController : TNModule
{
    @outlet CPButton            buttonClear;
    @outlet CPButton            buttonDetach;
    @outlet CPImageView         imageSpinnerWriting;
    @outlet CPTextField         fieldMessage;
    @outlet CPTextField         fieldPreferencesMaxChatMessage;
    @outlet CPView              viewControls;
    @outlet CPScrollView        messagesScrollView;

    CPArray                     _messages;
    CPDictionary                _detachedChats;
    CPSound                     _soundMessage;
    CPSound                     _soundReceived;
    CPSound                     _soundSent;
    CPTimer                     _composingMessageTimer;
    TNMessageBoard              _messageBoard;
}


#pragma mark -
#pragma mark Initialization

/*! called at cib awakening
*/
- (void)awakeFromCib
{
    var bundle      = [CPBundle bundleForClass:[self class]],
        mainBundle  = [CPBundle mainBundle],
        defaults    = [CPUserDefaults standardUserDefaults],
        frame       = [[messagesScrollView contentView] bounds],
        controlsBg  = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"bg-controls.png"]];

    [viewControls setBackgroundColor:[CPColor colorWithPatternImage:controlsBg]];

    //controls buttons
    var imageClear  = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/clean.png"] size:CGSizeMake(16, 16)],
        imageDetach = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/fullscreen.png"] size:CGSizeMake(16, 16)];

    [buttonClear setImage:imageClear];
    [buttonDetach setImage:imageDetach];

    var inset = CGInsetMake(2, 2, 2, 5);
    [buttonClear setValue:inset forThemeAttribute:@"content-inset"];
    [buttonDetach setValue:inset forThemeAttribute:@"content-inset"];

    // register defaults defaults
    [defaults registerDefaults:[CPDictionary dictionaryWithObjectsAndKeys:
            [bundle objectForInfoDictionaryKey:@"TNUserChatMaxMessageStore"], @"TNUserChatMaxMessageStore",
            [CPDictionary dictionary], @"TNUserChatMessageStore"
    ]];

    _detachedChats = [CPDictionary dictionary];
    _messages = [CPArray array];

    [messagesScrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [messagesScrollView setAutohidesScrollers:YES];

    frame.size.height = 0;
    _messageBoard = [[TNMessageBoard alloc] initWithFrame:frame];
    [_messageBoard setAutoresizingMask:CPViewWidthSizable];

    [messagesScrollView setDocumentView:_messageBoard];


    [imageSpinnerWriting setImage:[[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"spinner.gif"]]];
    [imageSpinnerWriting setHidden:YES];

    [fieldMessage addObserver:self forKeyPath:@"stringValue" options:CPKeyValueObservingOptionNew context:nil];

    _soundMessage   = [[CPSound alloc] initWithContentsOfFile:[bundle pathForResource:@"Receive.wav"] byReference:NO];
    _soundReceived  = [[CPSound alloc] initWithContentsOfFile:[bundle pathForResource:@"received.wav"] byReference:NO];
    _soundSent      = [[CPSound alloc] initWithContentsOfFile:[bundle pathForResource:@"sent.wav"] byReference:NO];

    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_didReceiveMessage:) name:TNStropheContactMessageReceivedNotification object:nil];
}


#pragma mark -
#pragma mark TNModule overrides

/*! called when module is loaded
*/
- (BOOL)willLoad
{
    if (![super willLoad])
        return NO;

    var center = [CPNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(_didReceiveMessageComposing:) name:TNStropheContactMessageComposingNotification object:_entity];
    [center addObserver:self selector:@selector(_didReceiveMessagePause:) name:TNStropheContactMessagePausedNotification object:_entity];

    var frame = [[messagesScrollView documentView] bounds];

    [_messageBoard removeAllViews:nil];

    _messages = [CPArray array];

    [self restore];

    var frame = [[messagesScrollView documentView] frame],
        newScrollOrigin = CPMakePoint(0.0, frame.size.height);

    [_messageBoard scrollPoint:newScrollOrigin];

    return YES;
}

/*! called when module is unloaded
*/
- (void)willUnload
{
    [super willUnload];

    [self save];
    [_messages removeAllObjects];
    [_messageBoard removeAllViews:nil];

    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_didReceiveMessage:) name:TNStropheContactMessageReceivedNotification object:nil];
}

/*! called when module becomes visible
*/
- (BOOL)willShow
{
    if (![super willShow])
        return NO;

    var messageQueue = [_entity messagesQueue],
        stanza;

    while (stanza = [_entity popMessagesQueue])
    {
        if ([stanza containsChildrenWithName:@"body"])
        {
            var from    = ([stanza valueForAttribute:@"from"] == @"me") ? @"me" : [_entity name],
                message = [[stanza firstChildWithName:@"body"] text],
                color   = ([stanza valueForAttribute:@"from"] == @"me") ? [CPColor ] : [_entity name];

            [self appendMessageToBoard:message from:from];
        }
    }

    [_entity freeMessagesQueue];

    [[self view] setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [[self view] setFrame:[[[self view] superview] bounds]];

    return YES;
}

/*! called when user saves preferences
*/
- (void)savePreferences
{
    var defaults = [CPUserDefaults standardUserDefaults];

    [defaults setInteger:[fieldPreferencesMaxChatMessage intValue] forKey:@"TNUserChatMaxMessageStore"];
}

/*! called when user gets preferences
*/
- (void)loadPreferences
{
    var defaults = [CPUserDefaults standardUserDefaults];

    [fieldPreferencesMaxChatMessage setIntValue:[defaults integerForKey:@"TNUserChatMaxMessageStore"]];
}

#pragma mark -
#pragma mark Notification handlers

/*! performed when TNStropheContactMessageReceivedNotification is received from current entity.
    @param aNotification the notification containing the contact that send the notification
*/
- (void)_didReceiveMessage:(CPNotification)aNotification
{
    if ([[aNotification object] JID] == [_entity JID])
    {
        var stanza =  [_entity popMessagesQueue];

        if ([stanza containsChildrenWithName:@"body"])
        {
            var messageBody = [[stanza firstChildWithName:@"body"] text];

            [imageSpinnerWriting setHidden:YES];
            [self appendMessageToBoard:messageBody from:[_entity name]];
            CPLog.info(@"message received : " + messageBody);
            if (![_detachedChats containsKey:[[aNotification object] JID]])
                [_soundReceived play];
        }
    }
    else if (![_detachedChats containsKey:[[aNotification object] JID]])
    {
        [_soundMessage play];
    }
}

/*! performed when TNStropheContactMessageComposingNotification is received from current entity.
    @param aNotification the notification containing the contact that send the notification
*/
- (void)_didReceiveMessageComposing:(CPNotification)aNotification
{
    [imageSpinnerWriting setHidden:NO];
}

/*! performed when TNStropheContactMessagePausedNotification is received from current entity.
    @param aNotification the notification containing the contact that send the notification
*/
- (void)_didReceiveMessagePause:(CPNotification)aNotification
{
    [imageSpinnerWriting setHidden:YES];
}

/*! observe if user is typing. If yes then send the "compose" XMPP status.
    @param aKeyPath the key path observed
    @param anObject the object observed
    @param aChange changes
    @param aContext a context
*/
- (void)observeValueForKeyPath:(CPString)aKeyPath ofObject:(id)anObject change:(CPDictionary)aChange context:(id)aContext
{
    if ([anObject stringValue] == @"")
    {
        [_entity sendComposePaused];
    }
    else
    {
        if (_composingMessageTimer)
            [_composingMessageTimer invalidate];

        _composingMessageTimer = [CPTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(sendComposingPaused:) userInfo:nil repeats:NO];
        [_entity sendComposing];
    }

}


#pragma mark -
#pragma mark Utilities

/*! save the chat
*/
- (void)save
{
    var defaults        = [CPUserDefaults standardUserDefaults],
        max             = [_messages count],
        saveMax         = [defaults integerForKey:@"TNUserChatMaxMessageStore"],
        location        = ((max - saveMax) > 0) ? (max - saveMax) : 0,
        lenght          = (saveMax <= max) ? saveMax : max,
        messagesToSave;

    messagesToSave = [_messages subarrayWithRange:CPMakeRange(location, lenght)];

    CPLog.debug(@"count=" + [_messages count] + " location=" + location + " lenght:" + lenght);

    [[defaults objectForKey:@"TNUserChatMessageStore"] setObject:messagesToSave forKey:"communicationWith" + [_entity JID]];
}

/*! restore the chat
*/
- (void)restore
{
    var defaults = [CPUserDefaults standardUserDefaults],
        lastConversation = [[defaults objectForKey:@"TNUserChatMessageStore"] objectForKey:"communicationWith" + [_entity JID]];

    if (lastConversation)
        _messages = lastConversation;

    for (var j = 0; j < [lastConversation count]; j++)
    {
        var author      = [[lastConversation objectAtIndex:j] objectForKey:@"name"],
            message     = [[lastConversation objectAtIndex:j] objectForKey:@"message"],
            color       = [[lastConversation objectAtIndex:j] objectForKey:@"color"],
            date        = [[lastConversation objectAtIndex:j] objectForKey:@"date"],
            avatar      = nil,
            position    = nil;

        if (author != @"me")
        {
            avatar = [_entity avatar];
            position = TNMessageViewAvatarPositionRight;
        }
        else
        {
            avatar = [[TNStropheIMClient defaultClient] avatar];
            position = TNMessageViewAvatarPositionLeft;
        }

        [_messageBoard addMessage:message from:author date:date color:color avatar:avatar position:position];
    }
}

/*! this message is sent when user is not typing for some time
    @param aTimer the timer that call the selector
*/
- (void)sendComposingPaused:(CPTimer)aTimer
{
    [_entity sendComposePaused];
}

/*! append a new message to the message board
    @param aMessage the message body
    @param aSender the nickname of the sender
*/
- (void)appendMessageToBoard:(CPString)aMessage from:(CPString)aSender
{
    var color           = (aSender == @"me") ? TNMessageViewBubbleColorNormal : TNMessageViewBubbleColorAlt,
        date            = [CPDate date],
        newMessageDict  = [CPDictionary dictionaryWithObjectsAndKeys:aSender, @"name", aMessage, @"message", color, @"color", date, @"date"],
        frame           = [[messagesScrollView documentView] frame],
        avatar          = nil,
        position        = nil;

    [_messages addObject:newMessageDict];

    if (aSender != @"me")
    {
        avatar = [_entity avatar];
        position = TNMessageViewAvatarPositionRight;
    }
    else
    {
        avatar = [[TNStropheIMClient defaultClient] avatar];
        position = TNMessageViewAvatarPositionLeft;
    }

    [_messageBoard addMessage:aMessage from:aSender date:date color:color avatar:avatar position:position];

    // scroll to bottom;
    var newScrollOrigin = CPMakePoint(0.0, frame.size.height);
    [_messageBoard scrollPoint:newScrollOrigin];

    [self save];
}


#pragma mark -
#pragma mark Actions

/*! send a message to the contact containing the content of the outlet message CPTextField
    @param aSender the sender of the action
*/
- (IBAction)sendMessage:(id)aSender
{
     if (_composingMessageTimer)
            [_composingMessageTimer invalidate];

    [_entity sendMessage:[fieldMessage stringValue]];
    [self appendMessageToBoard:[fieldMessage stringValue] from:@"me"];
    [fieldMessage setStringValue:@""];
    [_soundSent play];
}

/*! Clear all localstorage  of the old messages
    @param aSender the sender of the action
*/
- (IBAction)clearHistory:(id)aSender
{
    var defaults = [CPUserDefaults standardUserDefaults];

    [defaults removeObjectForKey:"communicationWith" + [_entity JID]];

    [_messages removeAllObjects];
    [_messageBoard removeAllViews:nil];
}


/*! open the chat in w new window
*/
- (IBAction)detachChat:(id)aSender
{
    var detachedChatController = [[TNDetachedChatController alloc] initWithEntity:_entity];
    [detachedChatController setDelegate:self];
    [detachedChatController setMessageHistory:_messages];
    [detachedChatController showWindow];
    [_detachedChats setObject:detachedChatController forKey:[_entity JID]];
}


#pragma mark -
#pragma mark Delegate

/*! will be sent by TNDetachedChatController when a chat window is closed.
    it will clean up the _detachedChats dictionary
    @param aJID the closed chat window target
*/
- (void)detachedChatClosedForJID:(TNStropheJID)aJID
{
    [_detachedChats removeObjectForKey:aJID];
}
@end


// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNUserChatController], comment);
}
