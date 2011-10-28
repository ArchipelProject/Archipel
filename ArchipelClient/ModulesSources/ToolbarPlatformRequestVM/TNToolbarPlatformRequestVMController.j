/*
 * TNToolbarPlatformRequestVMController.j
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

@import <StropheCappuccino/PubSub/TNPubSubNode.j>
@import <StropheCappuccino/TNStropheConnection.j>



var TNArchipelNSPlatform                            = @"archipel:platform",
    TNArchipelActionPlatformAllocVM                 = @"allocvm",
    TNArchipelNodeNamePlatformRequestIn             = @"/archipel/platform/requests/in",
    TNArchipelNodeNamePlatformRequestOut            = @"/archipel/platform/requests/out";

/*! @defgroup  toolbarplatformvmrequest Module Toolbar Platform VM Request
    @desc This module displays a toolbar item that can send platform wide Virtual machine request
*/


/*! @ingroup toolbarplatformvmrequest
    The module main controller
*/
@implementation TNToolbarPlatformRequestVMController : TNModule
{
    CPDictionary            _currentRequests;
    TNPubSubNode            _pubSubRequestIn;
    TNPubSubNode            _pubSubRequestOut;
    TNStropheConnection     _connection;
}


#pragma mark -
#pragma mark Intialization

- (void)willLoad
{
    [super willLoad];

    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(didStropheConnected:) name:TNStropheConnectionStatusConnectedNotification object:nil];
}


#pragma mark -
#pragma mark Notification handlers

/*! called when Strophe is connected. it will initialize the pubsub engines
    @param aNotification the notification object
*/
- (void)didStropheConnected:(CPNotification)aNotification
{
    _connection         = [aNotification object];
    _currentRequests    = [CPDictionary dictionary];

    _pubSubRequestIn    = [TNPubSubNode pubSubNodeWithNodeName:TNArchipelNodeNamePlatformRequestIn connection:_connection pubSubServer:nil]
    _pubSubRequestOut   = [TNPubSubNode pubSubNodeWithNodeName:TNArchipelNodeNamePlatformRequestOut connection:_connection pubSubServer:nil]

    [_pubSubRequestOut setDelegate:self];
    [_pubSubRequestOut recoverSubscriptions];

    [_toolbarItem setEnabled:NO];
}


#pragma mark -
#pragma mark Timers handlers

- (void)checkPlatformAnswers:(CPTimer)aTimer
{
    var requestUUID = [aTimer userInfo],
        anwsers     = [_currentRequests objectForKey:requestUUID],
        maxValue    = 0,
        selectedPublisher;

    if ([anwsers count] == 0)
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Platform Request" message:@"Nobody has answered to your request" icon:TNGrowlIconWarning];
        return;
    }

    for (var i = 0; i < [anwsers count]; i++)
    {
        var anwser  = [anwsers objectAtIndex:i],
            score   = [anwser objectForKey:@"score"];

        if (MAX(maxValue, score) == score)
            selectedPublisher = [anwser objectForKey:@"publisher"];
    }

    [self allocVirtualMachineOnHypervisor:[TNStropheJID stropheJIDWithString:selectedPublisher]];
}


#pragma mark -
#pragma mark Processing

/*! send the allocvm command to the given XMPP entity
    @param aJid TNStropheJID representing the taret
*/
- (void)allocVirtualMachineOnHypervisor:(TNStropheJID)aJid
{
    var stanza  = [TNStropheStanza iqWithType:@"set"],
        uid     = [_connection getUniqueId],
        params  = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];

    [stanza setTo:aJid];
    [stanza setID:uid];
    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelNSPlatform}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelActionPlatformAllocVM}];

    [_connection registerSelector:@selector(_didAllocVirtualMachine:) ofObject:self withDict:params];
    [_connection send:stanza];
}

/*! compute the allocvm result
    @params aStanza the stanza containing the answer
*/
- (void)_didAllocVirtualMachine:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Platform Request" message:@"Your virtual machine request has been handled by " + [[aStanza from] bare]];
    else
        [self handleIqErrorFromStanza:aStanza];
}


#pragma mark -
#pragma mark Actions

/*! Publish a new request to the request in node
    @param aSender the sender of the action
*/
- (IBAction)toolbarItemClicked:(id)aSender
{
    var uuid = [CPString UUID],
        requestNode = [[TNXMLNode alloc] initWithName:@"archipel" andAttributes:{"uuid": uuid, "action": TNArchipelActionPlatformAllocVM}];

    // register the current request in the registry
    [_currentRequests setObject:[CPArray array] forKey:uuid];

    [_pubSubRequestIn publishItem:requestNode];

    [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Platform Request" message:@"Your request has been sent to the platform"];
    [CPTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(checkPlatformAnswers:) userInfo:uuid repeats:NO];
}


#pragma mark -
#pragma mark Delegates

/*! delegate of TNPubSubNode
*/
- (void)pubSubNode:(TNPubSubNode)aPubSubNode retrievedSubscriptions:(BOOL)areSubscriptionsRetrieved
{
    if (areSubscriptionsRetrieved)
    {
        CPLog.info("sucessfully subscriptions retreived for node " + [aPubSubNode name]);
        if ([aPubSubNode numberOfSubscriptions] == 0)
            [aPubSubNode subscribe];
        [_toolbarItem setEnabled:YES];
    }
    else
    {
        [_toolbarItem setEnabled:NO];
        CPLog.error("cannot retrieve subscriptions for node " + [aPubSubNode name]);
    }
}

/*! delegate of TNPubSubNode
*/
- (void)pubSubNode:(TNPubSubNode)aPubSubNode subscribed:(BOOL)isSubscribed
{
    if (isSubscribed)
        CPLog.info("sucessfully subscribed to node " + [aPubSubNode name]);
    else
        CPLog.error("cannot subscribe to node " + [aPubSubNode name]);
}


/*! delegate of TNPubSubNode
*/
- (void)pubSubNode:(TNPubSubNode)aPubSubNode receivedEvent:(TNSTropheStanza)aStanza
{
    var answerNode          = [aStanza firstChildWithName:@"archipel"],
        requestUUID         = [answerNode valueForAttribute:@"uuid"],
        score               = [[answerNode valueForAttribute:@"score"] floatValue],
        publisher           = [[aStanza firstChildWithName:@"item"] valueForAttribute:@"publisher"],
        infos               = [CPDictionary dictionaryWithObjectsAndKeys:publisher, @"publisher", score, @"score"];

    [[_currentRequests objectForKey:requestUUID] addObject:infos];
}

@end
