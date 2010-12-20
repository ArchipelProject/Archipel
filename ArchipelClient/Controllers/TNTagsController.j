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
@import <AppKit/AppKit.j>

TNArchipelTypeTags              = @"archipel:tags";
TNArchipelTypeTagsSetTags       = @"settags";


TNTagsControllerNodeReadyNotification = @"TNTagsControllerNodeReadyNotification";

/*! @ingroup archipelcore
    Tagging view
*/
@implementation TNTagsController : CPObject
{
    @outlet CPView      mainView            @accessors(readonly);

    TNStropheConnection _connection         @accessors(property=connection);
    TNPubSubController  _pubsubController   @accessors(property=pubSubController);
    TNPubSubNode        _pubsubTagsNode;

    BOOL                _alreadyReady;
    CPButton            _buttonSave;
    CPTokenField        _tokenFieldTags;
    id                  _currentRosterItem;
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
        tokenFrame;

    [mainView setBackgroundColor:[CPColor colorWithPatternImage:gradBG]];
    [mainView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];

    _currentRosterItem  = nil;
    _alreadyReady       = NO;

    _tokenFieldTags = [[CPTokenField alloc] initWithFrame:CPRectMake(0.0, 1.0, CPRectGetWidth(frame) - 45, 30)];
    [_tokenFieldTags setAutoresizingMask:CPViewWidthSizable];
    [_tokenFieldTags setDelegate:self];
    [mainView addSubview:_tokenFieldTags];


    _buttonSave = [CPButton buttonWithTitle:@"Tag"];
    [_buttonSave setBezelStyle:CPRoundedBezelStyle];
    [_buttonSave setAutoresizingMask:CPViewMinXMargin];
    [_buttonSave setFrameOrigin:CPPointMake(CPRectGetWidth(frame) - CPRectGetWidth([_buttonSave frame]) - 3, 3)];
    [_buttonSave setTarget:self];
    [_buttonSave setAction:@selector(performSetTags:)];
    [_buttonSave setEnabled:NO];

    [mainView addSubview:_buttonSave];

    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(didRosterItemChange:) name:TNArchipelNotificationRosterSelectionChanged object:nil];
    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(didRetrieveSubscriptions:) name:TNStrophePubSubSubscriptionsRetrievedNotification object:nil];

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
    var server = [TNStropheJID stropheJIDWithString:@"pubsub." + [[_currentRosterItem JID] domain]],
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

    [_tokenFieldTags setObjectValue:[]];

    if ([_currentRosterItem class] !== TNStropheContact)
    {
        [_buttonSave setEnabled:NO];

        [_tokenFieldTags setPlaceholderString:@"You can't assign tags here"];
        [_tokenFieldTags setEnabled:NO];
        [_tokenFieldTags setObjectValue:[]];
    }
    else
    {
        [[TNPermissionsCenter defaultCenter] setControl:_buttonSave segment:nil enabledAccordingToPermissions:[@"settags"] forEntity:_currentRosterItem specialCondition:YES];
        [[TNPermissionsCenter defaultCenter] setControl:_tokenFieldTags segment:nil enabledAccordingToPermissions:[@"settags"] forEntity:_currentRosterItem specialCondition:YES];

        [_tokenFieldTags setPlaceholderString:@"Enter coma separated tags"];
        [_tokenFieldTags setEnabled:YES];

        if (_currentRosterItem)
            [_tokenFieldTags setObjectValue:[self getTagsForJID:[_currentRosterItem JID]]];

    }
}


#pragma mark -
#pragma mark Actions

/*! Action that will remove all tags of the current entity, and readd the new ones
    @param sender the sender of the action
*/
- (IBAction)performSetTags:(id)sender
{
    if ([_currentRosterItem class] != TNStropheContact)
        return;

    var stanza      = [TNStropheStanza iqWithType:@"set"],
        content     = [_tokenFieldTags objectValue],
        tagsString  = @"";

    for (var i = 0; i < [content count]; i++)
        tagsString += [content objectAtIndex:i] + ";;";
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
            if (tag
                && (tag.indexOf(aSubstring) != -1)
                && ![availableTags containsObject:tag]
                && ![[_tokenFieldTags objectValue] containsObject:tag])
                [availableTags addObjectsFromArray:tag];
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
        [_tokenFieldTags setObjectValue:[self getTagsForJID:[_currentRosterItem JID]]];
}


/*! delegate of TNPermissionsController
*/
- (void)permissionCenter:(TNPermissionsCenter)aCenter updatePermissionForEntity:(TNStropheContact)anEntity
{
    if (anEntity === _currentRosterItem)
    {
        [aCenter setControl:_buttonSave segment:nil enabledAccordingToPermissions:[@"settags"] forEntity:_currentRosterItem specialCondition:YES];
        [aCenter setControl:_tokenFieldTags segment:nil enabledAccordingToPermissions:[@"settags"] forEntity:_currentRosterItem specialCondition:YES];
    }
}


@end