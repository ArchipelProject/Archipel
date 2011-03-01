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
@import <AppKit/AppKit.j>


TNArchipelNodeNamePlatformRequestIn             = @"/archipel/platform/requests/in";
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

    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(didStropheConnected:) name:TNStropheConnectionStatusConnected object:nil];
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
}


#pragma mark -
#pragma mark Timers handlers

- (void)checkPlatformAnswers:(CPTimer)aTimer
{
    var requestUUID = [aTimer userInfo];

    CPLog.warn([_currentRequests objectForKey:requestUUID]);
}


#pragma mark -
#pragma mark Actions

/*! Publish a new request to the request in node
    @param aSender the sender of the action
*/
- (IBAction)toolbarItemClicked:(id)aSender
{
    var uuid = [CPString UUID],
        requestNode = [[TNXMLNode alloc] initWithName:@"archipel" andAttributes:{"uuid": uuid}];

    // register the current request in the registry
    [_currentRequests setObject:[CPArray array] forKey:uuid];

    [_pubSubRequestIn publishItem:requestNode];

    [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Platform Request" message:@"Your request has been sent to the plateform"];
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
    }
    else
        CPLog.error("cannot retrieve subscriptions for node " + [aPubSubNode name]);
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
