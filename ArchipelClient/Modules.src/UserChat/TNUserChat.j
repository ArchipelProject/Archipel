/*  
 * TNViewHypervisorControl.j
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
 
@import "../../TNModule.j";

@implementation TNUserChat : TNModule 
{
    @outlet CPTextField     fieldUserJid        @accessors;
    @outlet CPTextField     fieldMessagesBoard  @accessors;
    @outlet CPTextField     fieldMessage        @accessors;
}

- (void)willLoad
{
    console.log("registering for object " + [[self contact] jid])
    var center = [CPNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(didReceivedMessage:) name:TNStropheContactMessageReceivedNotification object:[self contact]];
    
    // restaure conversation from local storage
    console.log("restauring token " + "communicationWith" + [[self contact] jid]);
    var lastConversation = JSON.parse(localStorage.getItem("communicationWith" + [[self contact] jid]));
    [[self fieldMessagesBoard] setStringValue:lastConversation];
}

- (void)willUnload
{
    var center = [CPNotificationCenter defaultCenter];
    [center removeObserver:self];
    
    // save conversation into local storage
    [[self contact] freeMessagesQueue];
    
    localStorage.setItem("communicationWith" + [[self contact] jid], JSON.stringify([[self fieldMessagesBoard] stringValue]));
    console.log("saving token " + "communicationWith" + [[self contact] jid]);
    [[self fieldMessagesBoard] setStringValue:@""];
}

- (void)willShow 
{    
    var messageQueue = [[self contact] messagesQueue];
    
    // for (var i = 0; i < [messageQueue count]; i++)
    // {
    //     var stanza = [messageQueue objectAtIndex:i];
    // 
    //     [self appendMessageToBoard:$([stanza getFirstChildWithName:@"body"]).text() from:[stanza getValueForAttribute:@"from"]];
    //     [[self contact] freeMessagesQueue];   
    // }
    var stanza;
    while (stanza = [[self contact] popMessagesQueue])
    {    
        [self appendMessageToBoard:[[stanza getFirstChildWithName:@"body"] text] from:[stanza getValueForAttribute:@"from"]];
    }
}

- (void)willHide 
{
    // save the conversation with local storage
}

- (void)appendMessageToBoard:(CPString)aMessage from:(CPString)aSender
{
    var newMessage  = aSender + " : " + aMessage;
    var content     = [[self fieldMessagesBoard] stringValue] + "\n" + newMessage;

    [[self fieldMessagesBoard] setStringValue:content];
}

- (void)didReceivedMessage:(CPNotification)aNotification
{
    var stanza =  [[self contact] popMessagesQueue];
   
    //if ([stanza getValueForAttribute:@"from"].split("/")[0] == [[self contact] jid])
    //{
        [self appendMessageToBoard:[[stanza getFirstChildWithName:@"body"] text] from:[stanza getValueForAttribute:@"from"]];
    //}
}


- (IBAction)sendMessage:(id)sender
{
    [[self contact] sendMessage:[[self fieldMessage] stringValue]];
    [self appendMessageToBoard:[[self fieldMessage] stringValue] from:@"me"];
    [[self fieldMessage] setStringValue:@""];
}
@end



