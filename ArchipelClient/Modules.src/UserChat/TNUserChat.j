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

- (void)awakeFromCib
{
    var center = [CPNotificationCenter defaultCenter];
    
    [center addObserver:self selector:@selector(didReceivedMessage:) name:TNStropheContactMessageReceivedNotification object:nil];
}

- (void)willLoad
{
    // message sent when view will be added from superview;

}

- (void)willUnload
{
   // message sent when view will be removed from superview;
}

- (void)willShow 
{
    // message sent when the tab is clicked
}

- (void)willHide 
{
    // message sent when the tab is changed
}

- (void)appendMessageToBoard:(CPString)aMessage from:(CPString)aSender
{
    var newMessage  = aSender + " : " + aMessage;
    var content     = [[self fieldMessagesBoard] stringValue] + "\n" + newMessage;

    [[self fieldMessagesBoard] setStringValue:content];
}

- (void)didReceivedMessage:(CPNotification)aNotification
{
    var stanza = [aNotification object];
    console.log([stanza getValueForAttribute:@"from"].split("/")[0] +  "==" +[[self contact] jid])
    if ([stanza getValueForAttribute:@"from"].split("/")[0] == [[self contact] jid])
    {
        [self appendMessageToBoard:$([stanza getFirstChildrenWithName:@"body"]).text() from:[stanza getValueForAttribute:@"from"]];
    }
}


- (IBAction)sendMessage:(id)sender
{
    [[self contact] sendMessage:[[self fieldMessage] stringValue]];
    [self appendMessageToBoard:[[self fieldMessage] stringValue] from:@"me"];
    [[self fieldMessage] setStringValue:@""];
}
@end



