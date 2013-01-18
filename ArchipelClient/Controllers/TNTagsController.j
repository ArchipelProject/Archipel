/*
 * TNTagView.j
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
@import <AppKit/CPImage.j>
@import <AppKit/CPTokenField.j>
@import <AppKit/CPView.j>

@import <StropheCappuccino/PubSub/TNPubSubController.j>
@import <StropheCappuccino/PubSub/TNPubSubNode.j>
@import <StropheCappuccino/TNStropheContact.j>
@import <StropheCappuccino/TNStropheJID.j>

@import "TNPermissionsCenter.j"

@class CPLocalizedString
@global TNArchipelNotificationRosterSelectionChanged


var TNArchipelTypeTags              = @"archipel:tags",
    TNArchipelTypeTagsSetTags       = @"settags";


TNTagsControllerNodeReadyNotification = @"TNTagsControllerNodeReadyNotification";

/*! @ingroup archipelcore
    Tagging view
*/
@implementation TNTagsController : CPObject
{
    @outlet CPView          mainView            @accessors(readonly);
    @outlet CPTokenField    tokenFieldTags;
    @outlet CPButton        buttonSave;

    TNPubSubController      _pubsubController   @accessors(getter=pubSubController);
    TNPubSubNode            _pubsubTagsNode;

    BOOL                    _alreadyReady;
    id                      _currentRosterItem;
}


#pragma mark -
#pragma mark Setters

- (void)setPubSubController:(TNPubSubController)aController
{
    if (aController === _pubsubController)
        return;

    _pubsubController = aController;

    [[CPNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didRetrieveSubscriptions:)
                                                 name:TNStrophePubSubSubscriptionsRetrievedNotification
                                               object:_pubsubController];
}

#pragma mark -
#pragma mark Initialization

/*! Configure the view at cib awaking
*/
- (void)awakeFromCib
{
    var frame = [mainView frame],
        bundle = [CPBundle bundleForClass:[self class]],
        gradBG = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"Backgrounds/background-tags.png"]],
        imageTag = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"IconsButtons/tag-set.png"] size:CPSizeMake(16, 16)],
        tokenFrame;

    [mainView setBackgroundColor:[CPColor colorWithPatternImage:gradBG]];
    [mainView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];

    _currentRosterItem  = nil;
    _alreadyReady       = NO;

    // tokenFieldTags = [[CPTokenField alloc] initWithFrame:CPRectMake(0.0, 1.0, CPRectGetWidth(frame) - 33, 24)];
    // [tokenFieldTags setAutoresizingMask:CPViewWidthSizable];
    [tokenFieldTags setDelegate:self];
    [tokenFieldTags setEditable:YES];
    [tokenFieldTags setEnabled:NO];
    [tokenFieldTags setPlaceholderString:CPLocalizedString(@"You can't assign tags here", @"You can't assign tags here")];
    [tokenFieldTags setTarget:self];
    [tokenFieldTags setAction:@selector(performSetTags:)];

    [buttonSave setImage:imageTag];
    [buttonSave setTarget:self];
    [buttonSave setAction:@selector(performSetTags:)];
    [buttonSave setEnabled:NO];

    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(didRosterItemChange:) name:TNArchipelNotificationRosterSelectionChanged object:nil];

    [[TNPermissionsCenter defaultCenter] addDelegate:self];
}


#pragma mark -
#pragma mark Utility methods

/*! return all tags used for the given JID
    @param aJID the JID to match
    @return CPArray containings the tags associated to the JID
*/
- (CPArray)getTagsForJID:(TNStropheJID)aJID
{
    var ret = [CPArray array];

    for (var i = 0; i < [[_pubsubTagsNode content] count]; i++)
    {
        var tag = [[[_pubsubTagsNode content] objectAtIndex:i] firstChildWithName:@"tag"];
        if ([tag valueForAttribute:@"jid"] == [aJID bare])
        {
            if ([[tag valueForAttribute:@"tags"] length] > 0)
                [ret addObjectsFromArray:[tag valueForAttribute:@"tags"].split(";;")];
            break;
        }
    }

    return ret;
}

/*! called when pubsub is recovered
*/
- (void)didRetrieveSubscriptions:(CPNotification)aNotification
{
    var server = [TNStropheJID stropheJIDWithString:@"pubsub." + [[[TNStropheIMClient defaultClient] JID] domain]],
        nodeName = @"/archipel/tags";

    _pubsubTagsNode = [_pubsubController nodeWithName:nodeName];

    if (!_pubsubTagsNode)
        [_pubsubController subscribeToNodeWithName:nodeName server:server nodeDelegate:self];
    else
    {
        [_pubsubTagsNode setDelegate:self];
        [_pubsubTagsNode retrieveItems];
    }

}

#pragma mark -
#pragma mark Notifications handlers

/*! this handler is triggered when user changes the selected item in roster
    It will populate the content of the CPTokenField with entity tags
    @param aNotification CPNotification the notification that triggers the message
*/
- (void)didRosterItemChange:(CPNotification)aNotification
{
    _currentRosterItem = [aNotification object];

    [tokenFieldTags setObjectValue:[]];

    if (![_currentRosterItem isKindOfClass:TNStropheContact])
    {
        [tokenFieldTags setPlaceholderString:@"You can't assign tags here"];
        [buttonSave setEnabled:NO];
        [tokenFieldTags setEnabled:NO];
        [tokenFieldTags setObjectValue:[]];
    }
    else
    {
        [[TNPermissionsCenter defaultCenter] setControl:buttonSave segment:nil enabledAccordingToPermissions:[@"settags"] forEntity:_currentRosterItem specialCondition:YES];
        [[TNPermissionsCenter defaultCenter] setControl:tokenFieldTags segment:nil enabledAccordingToPermissions:[@"settags"] forEntity:_currentRosterItem specialCondition:YES];

        [tokenFieldTags setPlaceholderString:@"Enter coma separated tags"];
        [tokenFieldTags setEnabled:YES];
        [buttonSave setEnabled:YES];

        if (_currentRosterItem)
            [tokenFieldTags setObjectValue:[self getTagsForJID:[_currentRosterItem JID]]];
    }
}


#pragma mark -
#pragma mark Actions

/*! Action that will remove all tags of the current entity, and readd the new ones
    @param sender the sender of the action
*/
- (IBAction)performSetTags:(id)sender
{
    if (![_currentRosterItem isKindOfClass:TNStropheContact])
        return;

    var stanza      = [TNStropheStanza iqWithType:@"set"],
        content     = [tokenFieldTags objectValue],
        tagsString  = @"";

    for (var i = 0; i < [content count]; i++)
        tagsString += [[content objectAtIndex:i] lowercaseString] + ";;";
    tagsString = tagsString.slice(0,tagsString.length - 2);

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeTags}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeTagsSetTags,
        "tags": tagsString}];

    [_currentRosterItem sendStanza:stanza andRegisterSelector:nil ofObject:nil];
}


#pragma mark -
#pragma mark Delegates

/*! delegate of CPTokenField that will return the list of available tags
*/
- (void)tokenField:(CPTokenField)aTokenField completionsForSubstring:(CPString)aSubstring indexOfToken:(int)anIndex indexOfSelectedItem:(int)anIndex
{
    var availableTags = [CPArray array];

    for (var i = 0; i < [[_pubsubTagsNode content] count]; i++)
    {
        var tags = [[[[_pubsubTagsNode content] objectAtIndex:i] firstChildWithName:@"tag"] valueForAttribute:@"tags"].split(";;");

        for (var j = 0; j < [tags count]; j++)
        {
            var tag = [tags objectAtIndex:j];
            if (tag && (tag.indexOf(aSubstring) != -1) && ![availableTags containsObject:tag] && ![[tokenFieldTags objectValue] containsObject:tag])
                [availableTags addObject:tag];
        }
    }

    return availableTags;
}

/*! delegate of TNPubSubNode that will recover the content of the node after an event
*/
- (void)pubSubNode:(TNPubSubNode)aPubSubMode receivedEvent:(TNStropheStanza)aStanza
{
    [_pubsubTagsNode retrieveItems];
}

- (void)pubSubNode:(TNPubSubNode)aPubSubMode subscribed:(BOOL)isSubscribed
{
    if (isSubscribed)
        [_pubsubTagsNode retrieveItems];
}

- (void)pubSubNode:(TNPubSubNode)aPubSubMode retrievedItems:(BOOL)isRetrieved
{
    if (isRetrieved && !_alreadyReady)
    {
        _alreadyReady = YES;
        [[CPNotificationCenter defaultCenter] postNotificationName:TNTagsControllerNodeReadyNotification object:aPubSubMode];
    }

    if (_currentRosterItem)
        [tokenFieldTags setObjectValue:[self getTagsForJID:[_currentRosterItem JID]]];
}


/*! delegate of TNPermissionsController
*/
- (void)permissionCenter:(TNPermissionsCenter)aCenter updatePermissionForEntity:(TNStropheContact)anEntity
{
    if (anEntity === _currentRosterItem)
    {
        [aCenter setControl:buttonSave segment:nil enabledAccordingToPermissions:[@"settags"] forEntity:_currentRosterItem specialCondition:YES];
        [aCenter setControl:tokenFieldTags segment:nil enabledAccordingToPermissions:[@"settags"] forEntity:_currentRosterItem specialCondition:YES];
    }
}


@end
