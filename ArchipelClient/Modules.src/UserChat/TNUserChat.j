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
@import <AppKit/AppKit.j>
@import <AppKit/CPCollectionView.j>

@import "TNMessageView.j"


@implementation TNUserChat : TNModule 
{
    @outlet CPTextField     fieldUserJid            @accessors;
    @outlet CPTextField     fieldMessage            @accessors;
    @outlet CPScrollView    messageScrollView       @accessors;
    @outlet CPImageView     imageSpinnerWriting     @accessors;
    
    CPCollectionView        messageCollectionView   @accessors;
    
    CPArray                 _messages;
    CPTimer                 _composingMessageTimer;
}

- (void)awakeFromCib
{
    _messages = [CPArray array];
    
    [[self messageScrollView] setBorderedWithHexColor:@"#9e9e9e"];
    [[self messageScrollView] setAutoresizingMask:CPViewWidthSizable];
    
    var frame           = [[[self messageScrollView] documentView] bounds];
    var messageView     = [[TNMessageView alloc] initWithFrame:CGRectMakeZero()];
    
    [messageView setAutoresizingMask:CPViewWidthSizable];
    
    messageCollectionView = [[CPCollectionView alloc] initWithFrame:frame];
    [[self messageCollectionView] setAutoresizingMask:CPViewWidthSizable];
    [[self messageCollectionView] setMinItemSize:CGSizeMake(100, 60)];
    [[self messageCollectionView] setMaxItemSize:CGSizeMake(1700, 2024)];
    [[self messageCollectionView] setMaxNumberOfColumns:1];
    [[self messageCollectionView] setVerticalMargin:2.0];
    [[self messageCollectionView] setSelectable:NO]
    [[self messageCollectionView] setItemPrototype:[[CPCollectionViewItem alloc] init]];
    [[[self messageCollectionView] itemPrototype] setView:messageView];
    [[self messageCollectionView] setContent:_messages];
    
    [[self messageScrollView] setDocumentView:messageCollectionView];
    
    var mainBundle = [CPBundle mainBundle];
    [[self imageSpinnerWriting] setImage:[[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"spinner.gif"]]];
    [[self imageSpinnerWriting] setHidden:YES];
    
    [[self fieldMessage] addObserver:self forKeyPath:@"stringValue" options:CPKeyValueObservingOptionNew context:nil]
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context 
{
    if ([object stringValue] == @"")
    {
        [[self entity] sendComposePaused];
    }
    else
    {   
        if (_composingMessageTimer)
            [_composingMessageTimer invalidate];
            
        _composingMessageTimer = [CPTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(sendComposingPaused:) userInfo:nil repeats:NO];
        [[self entity] sendComposing];
    }
        
}

- (void)sendComposingPaused:(CPTimer)aTimer
{
    [[self entity] sendComposePaused];
}

- (void)willLoad
{   
    var center = [CPNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(didReceivedMessage:) name:TNStropheContactMessageReceivedNotification object:[self entity]];
    [center addObserver:self selector:@selector(didReceivedMessageComposing:) name:TNStropheContactMessageComposing object:[self entity]];
    [center addObserver:self selector:@selector(didReceivedMessagePause:) name:TNStropheContactMessagePaused object:[self entity]];
    
    
    var frame = [[[self messageScrollView] documentView] bounds];
    [[self messageCollectionView] setFrame:frame];
    
    var lastConversation = JSON.parse(localStorage.getItem("communicationWith" + [[self entity] jid]));
    
    if (lastConversation)
    {
        for (var i = 0; i < lastConversation.length; i++)
        {   
            var dict        = lastConversation[i];
            var aSender     = dict._buckets.name        // yes I know this is awful. But 
            var aMessage    = dict._buckets.message;    // I've passed 2 hours, and I'm tired of this shitty bug.
            var aColor      = dict._buckets.color;
            
            if (! aColor)
                aColor = "ffffff";
                
            [_messages addObject:[CPDictionary dictionaryWithObjectsAndKeys:aSender, @"name", aMessage, @"message", aColor, @"color"]];
        }
    }
    
    [[self messageCollectionView] reloadContent];
    var frame = [[[self messageScrollView] documentView] frame];
    newScrollOrigin = CPMakePoint(0.0, frame.size.height);   
    [messageCollectionView scrollPoint:newScrollOrigin];
}

- (void)willUnload
{      
    var center = [CPNotificationCenter defaultCenter];
    [center removeObserver:self];
      
    localStorage.setItem("communicationWith" + [[self entity] jid], JSON.stringify(_messages));

    [_messages removeAllObjects];
    [[self messageCollectionView] reloadContent];
}

- (void)willShow 
{    
    var messageQueue = [[self entity] messagesQueue];
    var stanza;
    
    
    //for (var i = 0; i < messageQueue.length; i++ )
    while (stanza = [[self entity] popMessagesQueue])
    {   
        if ([stanza containsChildrenWithName:@"body"])
        {
            [self appendMessageToBoard:[[stanza firstChildWithName:@"body"] text] from:[stanza valueForAttribute:@"from"]];
        }
    }
    
    [[self entity] freeMessagesQueue];
}

- (void)willHide 
{
    // save the conversation with local storage
}

- (void)appendMessageToBoard:(CPString)aMessage from:(CPString)aSender
{
    var color = (aSender == @"me") ? "d9dfe8" : "ffffff";
        
    var newMessageDict = [CPDictionary dictionaryWithObjectsAndKeys:aSender, @"name", aMessage, @"message", color, @"color"];
    
    [_messages addObject:newMessageDict];
    [[self messageCollectionView] reloadContent];
    
    // scroll to bottom;
    var frame = [[[self messageScrollView] documentView] frame];
    newScrollOrigin = CPMakePoint(0.0, frame.size.height);   
    [messageCollectionView scrollPoint:newScrollOrigin];
}

- (void)didReceivedMessage:(CPNotification)aNotification
{   
    if ([[aNotification object] jid] == [[self entity] jid])
    {
        var stanza =  [[self entity] popMessagesQueue];
        
        if ([stanza containsChildrenWithName:@"body"])
        {
            [[self imageSpinnerWriting] setHidden:YES];
            [self appendMessageToBoard:[[stanza firstChildWithName:@"body"] text] from:[stanza valueForAttribute:@"from"]];
        }
    }
    else
    {
        _audioTagReceive.play();
    }
}

- (void)didReceivedMessageComposing:(CPNotification)aNotification
{
    [[self imageSpinnerWriting] setHidden:NO];
}

- (void)didReceivedMessagePause:(CPNotification)aNotification
{
    [[self imageSpinnerWriting] setHidden:YES];
}


- (IBAction)sendMessage:(id)sender
{
     if (_composingMessageTimer)
            [_composingMessageTimer invalidate];
    
    [[self entity] sendMessage:[[self fieldMessage] stringValue]];
    [self appendMessageToBoard:[[self fieldMessage] stringValue] from:@"me"];
    [[self fieldMessage] setStringValue:@""];
}

- (IBAction)clearHistory:(id)sender
{
    localStorage.removeItem("communicationWith" + [[self entity] jid]);
    [_messages removeAllObjects];
    [[self messageCollectionView] reloadContent];
}
@end



