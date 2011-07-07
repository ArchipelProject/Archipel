/*
 * TNWindowAddContact.j
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
@import <AppKit/CPButton.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPWindow.j>

@import <TNKit/TNAlert.j>

@import <StropheCappuccino/PubSub/TNPubSubController.j>
@import <StropheCappuccino/TNStropheIMClient.j>

/*! @ingroup archipelcore
    subclass of CPWindow that allows to add a TNStropheContact
*/
@implementation TNContactsController: CPObject
{
    @outlet CPButton        buttonAdd;
    @outlet CPButton        buttonCancel;
    @outlet CPTextField     newContactJID;
    @outlet CPTextField     newContactName;
    @outlet CPView          mainContentView;

    TNAttachedWindow        _mainWindow;
    TNPubSubController      _pubsubController   @accessors(property=pubSubController);
}

#pragma mark -
#pragma mark Initialization

- (void)awakeFromCib
{
    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_performPushRosterAdded:) name:TNStropheRosterPushAddedContactNotification object:nil];
    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_performPushRosterRemoved:) name:TNStropheRosterPushRemovedContactNotification object:nil];

    [newContactName setToolTip:CPLocalizedString(@"The display name of the new contact", @"The display name of the new contact")];
    [newContactJID setToolTip:CPLocalizedString(@"The XMPP JID of the contact", @"The XMPP JID of the contact")];

    _mainWindow = [[TNAttachedWindow alloc] initWithContentRect:CPRectMake(0.0, 0.0, [mainContentView frameSize].width, [mainContentView frameSize].height) styleMask:CPClosableWindowMask | TNAttachedWhiteWindowMask];
    [_mainWindow setContentView:mainContentView];
    [_mainWindow setDefaultButton:buttonAdd];
}

#pragma mark -
#pragma mark Utilities

- (void)subscribeToPubSubNodeOfContactWithJID:(TNStropheJID)aJID
{
    var nodeName = @"/archipel/" + [aJID bare] + @"/events",
        server = [TNStropheJID stropheJIDWithString:@"pubsub." + [aJID domain]];

    if (![_pubsubController nodeWithName:nodeName])
        [_pubsubController subscribeToNodeWithName:nodeName server:server];
}

- (void)unsubscribeToPubSubNodeOfContactWithJID:(TNStropheJID)aJID
{
    var nodeName = "/archipel/" + [aJID bare] + "/events",
        server = [TNStropheJID stropheJIDWithString:@"pubsub." + [aJID domain]];

    if ([_pubsubController nodeWithName:nodeName])
        [_pubsubController unsubscribeFromNodeWithName:nodeName server:server]
}


#pragma mark -
#pragma mark Notification handlers

- (void)_didPubSubSubscriptionsRetrieved:(CPNotification)aNotification
{
    var eventNode = [[[aNotification object] nodes] objectAtIndex:0];

    [[CPNotificationCenter defaultCenter] removeObserver:self name:TNStrophePubSubSubscriptionsRetrievedNotification object:[aNotification object]];

    [eventNode unsubscribe];
}

- (void)_performPushRosterAdded:(CPNotification)aNotification
{
    var contact = [aNotification userInfo],
        JID     = [contact JID];

    [[[TNStropheIMClient defaultClient] roster] askAuthorizationTo:JID];
    [[[TNStropheIMClient defaultClient] roster] authorizeJID:JID];
    [self subscribeToPubSubNodeOfContactWithJID:JID];
}

- (void)_performPushRosterRemoved:(CPNotification)aNotification
{
    var contact = [aNotification userInfo];

    [self unsubscribeToPubSubNodeOfContactWithJID:[contact JID]];
}

#pragma mark -
#pragma mark Actions

/*! overide of the orderFront
    @param aSender the sender
*/
- (IBAction)showWindow:(id)aSender
{
    [newContactJID setStringValue:@""];
    [newContactName setStringValue:@""];

    [_mainWindow positionRelativeToView:aSender];
}

/*! close the main window
    @param aSender the sender
*/
- (IBAction)closeWindow:(id)aSender
{
    [_mainWindow close];
}

/*! add a contact according to the values of the outlets
    @param aSender the sender
*/
- (IBAction)addContact:(id)aSender
{
    var JID     = [TNStropheJID stropheJIDWithString:[newContactJID stringValue]],
        name    = [newContactName stringValue];

    if (![JID node] || ![JID domain] || [JID resource])
    {
        [TNAlert showAlertWithMessage:CPLocalizedString(@"JID is not valid", @"JID is not valid")
                          informative:CPLocalizedString(@"You must enter a JID using the form user@domain.", @"You must enter a JID using the form user@domain.")
                                style:CPCriticalAlertStyle];
        return;
    }
    [[[TNStropheIMClient defaultClient] roster] addContact:JID withName:name inGroupWithPath:nil];

    [_mainWindow close];

    CPLog.info(@"added contact " + JID);

    [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:CPLocalizedString(@"Contact", @"Contact")
                                                     message:CPLocalizedString(@"Contact ", @"Contact ") + JID + CPLocalizedString(@" has been added",  @" has been added")];
}

/*! will ask for deleting the selected contact
    @param aSender the sender of the action
*/
- (void)deleteContact:(TNStropheContact)aContact
{
    if (![aContact isKindOfClass:TNStropheContact])
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:CPLocalizedString(@"User supression", @"User supression")
                                                         message:CPLocalizedString(@"You must choose a contact", @"You must choose a contact")
                                                            icon:TNGrowlIconError];
        return;
    }

    var alert = [TNAlert alertWithMessage:CPLocalizedString(@"Delete contact", @"Delete contact")
                                informative:CPLocalizedString(@"Are you sure you want to delete this contact?", @"Are you sure you want to delete this contact?")
                                 target:self
                                 actions:[[CPLocalizedString("Delete", "Delete"), @selector(performDeleteContact:)], [CPLocalizedString("Cancel", "Cancel"), nil]]];

    [alert setHelpTarget:self action:@selector(showHelpForDelete:)];
    [alert setUserInfo:aContact];
    [alert runModal];
}

/*! Action for the deleteContact:'s confirmation TNAlert.
    It will delete the contact
    @param aSender the sender of the action
*/
- (void)performDeleteContact:(id)userInfo
{
    var contact = userInfo;

    [self unsubscribeToPubSubNodeOfContactWithJID:[contact JID]];
    [[TNPermissionsCenter defaultCenter] uncachePermissionsForEntity:contact];

    [[[TNStropheIMClient defaultClient] roster] removeContact:contact];

    CPLog.info(@"contact " + [contact JID] + "removed");
    [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:CPLocalizedString(@"Contact", @"Contact")
                                                     message:CPLocalizedString(@"Contact ", @"Contact ") + [contact JID] + CPLocalizedString(@" has been removed", @" has been removed")];
}

/*! action sent by alert to show help for subscription
    @param aSender the sender of the action
*/
- (IBAction)showHelpForSubscription:(id)aSender
{
    window.open("http://www.google.fr/search?q=XMPP subscription request", "_new");
}

/*! action sent by alert to show help for subscription
    @param aSender the sender of the action
*/
- (IBAction)showHelpForDelete:(id)aSender
{
    window.open("http://www.google.fr/search?q=XMPP delete contact", "_new");
}

#pragma mark -
#pragma mark Delegate

/*! Delegate method of main TNStropheRoster.
    will be performed when a subscription request is sent
    @param requestStanza TNStropheStanza cotainining the subscription request
*/
- (void)roster:(TNStropheRoster)aRoster receiveSubscriptionRequest:(id)requestStanza
{
    var nick;

    if ([requestStanza firstChildWithName:@"nick"])
        nick = [[requestStanza firstChildWithName:@"nick"] text];
    else
        nick = [requestStanza from];

    var alert = [TNAlert alertWithMessage:CPLocalizedString(@"Subscription request", @"Subscription request")
                              informative:nick + CPLocalizedString(@" is asking you subscription. Do you want to authorize it ?", @" is asking you subscription. Do you want to authorize it ?")
                                   target:self
                                  actions:[[CPLocalizedString("Accept", "Accept"), @selector(performAuthorize:)],
                                            [CPLocalizedString("Decline", "Decline"), @selector(performRefuse:)]]];

    [alert setHelpTarget:self action:@selector(showHelpForSubscription:)];
    [alert setUserInfo:requestStanza]
    [alert runModal];
}

/*! Action of didReceiveSubscriptionRequest's confirmation alert.
    Will accept the subscription and try to register to Archipel pubsub nodes
*/
- (void)performAuthorize:(TNStropheStanza)aRequestStanza
{
    [self subscribeToPubSubNodeOfContactWithJID:[aRequestStanza from]];
    [[[TNStropheIMClient defaultClient] roster] answerAuthorizationRequest:aRequestStanza answer:YES];
}

/*! Action of didReceiveSubscriptionRequest's confirmation alert.
    Will refuse the subscription and try to unregister to Archipel pubsub nodes
*/
- (void)performRefuse:(TNStropheStanza)aRequestStanza
{
    [[[TNStropheIMClient defaultClient] roster] answerAuthorizationRequest:aRequestStanza answer:NO];
}

@end
