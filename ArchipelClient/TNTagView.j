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


TNArchipelTypeTags          = @"archipel:tags";
TNArchipelTypeTagsGet       = @"gettags";
TNArchipelTypeTagsSet       = @"settags";
TNArchipelTypeTagsAll       = @"alltags";
TNArchipelTypeTagsRegistry  = @"tagsregistry";

TNArchipelPushNotificationTags = @"archipel:push:tags";

@implementation TNTagView : CPView
{
    CPArray             _allTags;
    CPButton            _buttonSave;
    CPTokenField        _tokenFieldTags;
    id                  _currentRosterItem;
    CPDictionary        _tagsRegistry       @accessors(getter=tagsRegistry);
    TNStropheConnection _connection         @accessors(property=connection);
}


#pragma mark -
#pragma mark Initialization

- (void)awakeFromCib
{
    var frame = [self frame],
        tokenFrame;

    _allTags            = [CPArray array];
    _tagsRegistry       = [CPDictionary dictionary];
    _currentRosterItem  = nil;

    _tokenFieldTags = [CPTokenField textFieldWithStringValue:@"" placeholder:@"You can't assign tags here" width:frame.size.width - 37];
    tokenFrame = [_tokenFieldTags frame];
    tokenFrame.size.height += 2;
    tokenFrame.origin = CPPointMake(0, -1);
    [_tokenFieldTags setFrame:tokenFrame];
    [_tokenFieldTags setAutoresizingMask:CPViewWidthSizable];
    [_tokenFieldTags setEnabled:NO];
    [_tokenFieldTags setDelegate:self];

    [self addSubview:_tokenFieldTags];


    _buttonSave = [CPButton buttonWithTitle:@"Tag"];
    [_buttonSave setBezelStyle:CPHUDBezelStyle];
    [_buttonSave setAutoresizingMask:CPViewMinXMargin];
    [_buttonSave setFrameOrigin:CPPointMake(frame.size.width - [_buttonSave frame].size.width - 3, 3)];
    [_buttonSave setTarget:self];
    [_buttonSave setAction:@selector(performSetTags:)];
    [_buttonSave setEnabled:NO];

    [self addSubview:_buttonSave];

    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(didRosterItemChange:) name:TNArchipelNotificationRosterSelectionChanged object:nil];
    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(didRosterRetrieve:) name:TNStropheRosterRetrievedNotification object:nil];
}

#pragma mark -
#pragma mark PubSub

- (void)registerForPushTagsNotification
{
    var params = [[CPDictionary alloc] init];

   [params setValue:@"message" forKey:@"name"];
   [params setValue:@"headline" forKey:@"type"];
   [params setValue:{"matchBare": YES} forKey:@"options"];
   [params setValue:"http://jabber.org/protocol/pubsub#event" forKey:@"namespace"];

   [_connection registerSelector:@selector(_onPubSubEvents:) ofObject:self withDict:params];
}

- (void)_onPubSubEvents:(TNStropheStanza)aStanza
{
    var pushType    = [[aStanza firstChildWithName:@"push"] valueForAttribute:@"xmlns"];

    if (pushType == TNArchipelPushNotificationTags)
        [self getTags:nil];

    return YES;
}


#pragma mark -
#pragma mark Notifications handlers

- (void)didRosterItemChange:(CPNotification)aNotification
{
    var roster = [aNotification object];

    _currentRosterItem = [roster currentItem];

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
        [_buttonSave setEnabled:YES];

        [_tokenFieldTags setPlaceholderString:@"Enter coma separated tags"];
        [_tokenFieldTags setEnabled:YES];

        [self getTags:nil];
        [self getAllTags];
    }
}

- (void)didRosterRetrieve:(CPNotification)aNotification
{
    var roster = [aNotification object];

    CPLog.info("retreiving tags for all items.");

    for (var i = 0; i < [[roster contacts] count]; i++)
        [self getTags:[[roster contacts] objectAtIndex:i]];
    CPLog.info("tags registry populated");

    [self registerForPushTagsNotification];
}


#pragma mark -
#pragma mark XMPP System

- (void)getTags:(TNStropheContact)aSpecificContact
{
    var stanza  = [TNStropheStanza iqWithType:@"get"],
        contact = (aSpecificContact) ? aSpecificContact : _currentRosterItem;

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeTags}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeTagsGet}];

    if (_currentRosterItem)
        [_tokenFieldTags setPlaceholderString:@"Retrieving tags..."];

    [contact sendStanza:stanza andRegisterSelector:@selector(didGetTags:) ofObject:self];
}

- (void)didGetTags:(TNStropheStanza)aStanza
{
    if (_currentRosterItem)
        [_tokenFieldTags setPlaceholderString:@"Enter coma separated tags"];

    if ([aStanza type] == @"result")
    {
        var tags    = [aStanza childrenWithName:@"tag"],
            content = [CPArray array];

        for (var i = 0; i < [tags count]; i++)
            [content addObject:[[tags objectAtIndex:i] text]];

        [_tagsRegistry setObject:content forKey:[aStanza fromBare]];

        if (_currentRosterItem)
            [_tokenFieldTags setObjectValue:content];
    }
    else
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Tags" message:@"can't get tags"];
    }
    return NO;
}

- (void)getAllTags
{
    var stanza  = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeTags}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeTagsAll}];

    [_currentRosterItem sendStanza:stanza andRegisterSelector:@selector(didGetAllTags:) ofObject:self];
}

- (void)didGetAllTags:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        var tags    = [aStanza childrenWithName:@"tag"];

        [_allTags removeAllObjects];

        for (var i = 0; i < [tags count]; i++)
            [_allTags addObject:[[tags objectAtIndex:i] text]];
    }
    else
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Tags" message:@"can't get all tags"];
    }

    return NO;
}

// - (void)getTagsRegistry
// {
//     var stanza  = [TNStropheStanza iqWithType:@"get"];
//
//     [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeTags}];
//     [stanza addChildWithName:@"archipel" andAttributes:{
//         "action": TNArchipelTypeTagsRegistry}];
//
//     [_currentRosterItem sendStanza:stanza andRegisterSelector:@selector(didGetTagsRegistry:) ofObject:self];
// }
//
// - (void)didGetTagsRegistry:(TNStropheStanza)aStanza
// {
//     if ([aStanza type] == @"result")
//     {
//         users = [aStanza childrenWithName:@"user"];
//
//         for (var i = 0; i < [users count]; i++)
//         {
//             var user = [users objectAtIndex:i],
//                 tags = [user childrenWithName:@"tag"],
//                 jid  = [user valueForAttribute:@"jid"].split("/")[0];
//
//             CPLog.debug("PARSING INFO FOR USER " + jid);
//
//             [_tagsRegistry setObject:[CPArray array] forKey:jid];
//
//             for (var j = 0; j < [tags count]; j++)
//             {
//                 CPLog.debug("FOUND TAG " + [tags objectAtIndex:j]);
//                 [[_tagsRegistry objectForKey:jid] addObject:[[tags objectAtIndex:j] text]];
//             }
//         }
//
//         CPLog.info("FINALLY : " + _tagsRegistry);
//     }
//     else
//     {
//         [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Tags" message:@"can't get all tags"];
//     }
//
//     return NO;
// }

- (void)setTags
{
    if ([_currentRosterItem class] != TNStropheContact)
        return;

    var stanza  = [TNStropheStanza iqWithType:@"set"],
        content = [_tokenFieldTags objectValue];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeTags}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeTagsSet}];

    for (var i = 0; i < [content count]; i++)
    {
        [stanza addChildWithName:@"tag"];
        [stanza addTextNode:[[content objectAtIndex:i] lowercaseString]]
        [stanza up];
    }

    [_currentRosterItem sendStanza:stanza andRegisterSelector:@selector(didSetTags:) ofObject:self];
}

- (void)didSetTags:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        [self getTags:nil];
    }
    else
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Tags" message:@"can't set tags"];
    }

    return NO;
}



#pragma mark -
#pragma mark Actions

- (IBAction)performSetTags:(id)sender
{
    [self setTags];
}




#pragma mark -
#pragma mark CPTokenField delegate

- (void)tokenField:(CPTokenField)aTokenField completionsForSubstring:(CPString)aSubstring indexOfToken:(int)anIndex indexOfSelectedItem:(int)anIndex
{
    var availableTags = [CPArray array];

    for (var i = 0; i < [_allTags count]; i++)
    {
        var tag = [_allTags objectAtIndex:i];

        if (tag.indexOf(aSubstring) != -1)
            [availableTags addObject:tag];
    }

    return availableTags;
}



@end