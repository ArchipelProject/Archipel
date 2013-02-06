/*
 * TNSampleToolbarModule.j
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

@import <AppKit/CPSound.j>
@import <AppKit/CPTableView.j>
@import <AppKit/CPTextField.j>

@import <StropheCappuccino/MUC/TNStropheMUCRoom.j>
@import <TNKit/TNAlert.j>
@import <TNKit/TNMessageBoard.j>
@import <TNKit/TNTableViewDataSource.j>

@import "../../Model/TNModule.j"

@global CPLocalizedString
@global CPLocalizedStringFromTableInBundle


/*! @defgroup  mucchat Module Conference
    @desc This module handles MUC for all Archipel users
*/


/*! @ingroup mucchat
    Main module controller

    Please respect the pragma marks as musch as possible.
*/
@implementation TNMUCChatController : TNModule
{
    @outlet CPScrollView        scrollViewMessageContainer;
    @outlet CPScrollView        scrollViewPeople;
    @outlet CPTextField         fieldPreferencesDefaultRoom;
    @outlet CPTextField         fieldPreferencesDefaultService;
    @outlet CPTextField         labelConferenceRoom;
    @outlet CPTextField         labelConferenceServer;
    @outlet CPTextField         textFieldMessage;
    @outlet CPView              viewConferenceInfo;
    @outlet CPView              viewMessage;

    CPArray                     _toolbarItemImages;
    CPSound                     _audioTagReceive;
    CPTableView                 _tableViewPeople;
    int                         _numberOfNotices;
    TNMessageBoard              _messageBoard;
    TNStropheMUCRoom            _session;
    TNTableViewDataSource       _peopleDatasource;
}

#pragma mark -
#pragma mark Initialization

/*! call at cib awaking
*/
- (void)awakeFromCib
{
    _messageBoard = [[TNMessageBoard alloc] initWithFrame:[scrollViewMessageContainer bounds]];
    [scrollViewMessageContainer setDocumentView:_messageBoard];
    [_messageBoard setFrameSize:[scrollViewMessageContainer contentSize]];

    _peopleDatasource   = [[TNTableViewDataSource alloc] init];
    _tableViewPeople    = [[CPTableView alloc] initWithFrame:[scrollViewPeople bounds]];

    [scrollViewPeople setAutohidesScrollers:YES];
    [scrollViewPeople setDocumentView:_tableViewPeople];

    [_tableViewPeople setUsesAlternatingRowBackgroundColors:YES];
    [_tableViewPeople setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [_tableViewPeople setAllowsColumnResizing:YES];
    [_tableViewPeople setAllowsEmptySelection:YES];
    [_tableViewPeople setAllowsMultipleSelection:YES];
    [_tableViewPeople setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [_tableViewPeople setTarget:self];
    [_tableViewPeople setDoubleAction:@selector(didDoubleClick:)]

    var columnNickname    = [[CPTableColumn alloc] initWithIdentifier:@"nickname"];

    [columnNickname setWidth:250];
    [[columnNickname headerView] setStringValue:CPBundleLocalizedString(@"Nickname", @"Nickname")];
    [columnNickname setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"nickname" ascending:YES]];
    [_tableViewPeople addTableColumn:columnNickname];

    [_peopleDatasource setTable:_tableViewPeople];
    [_peopleDatasource setSearchableKeyPaths:[@"JID.bare"]];
    [_tableViewPeople setDataSource:_peopleDatasource];

    var bundle = [CPBundle bundleForClass:[self class]],
        sound = [bundle pathForResource:@"Stoof.wav"];

    _audioTagReceive = [[CPSound alloc] initWithContentsOfFile:sound byReference:NO];

    [viewMessage setBackgroundColor:[CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"bg-controls.png"]]]];
    [viewConferenceInfo setBackgroundColor:[CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"bg-info.png"]]]];
    [viewConferenceInfo applyShadow];

    _toolbarItemImages = [
        [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"icon.png"] size:CGSizeMake(32,32)],
        [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"icon-x.png"] size:CGSizeMake(32,32)],
        [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"icon-x.png"] size:CGSizeMake(32,32)],
        [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"icon-x.png"] size:CGSizeMake(32,32)],
        [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"icon-x.png"] size:CGSizeMake(32,32)],
        [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"icon-x.png"] size:CGSizeMake(32,32)],
        [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"icon-x.png"] size:CGSizeMake(32,32)]
    ];

    _numberOfNotices = 0;

    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(stropheConnected:) name:TNStropheConnectionStatusConnectedNotification object:nil];
    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(stropheWillDisconnect:) name:TNStropheConnectionStatusWillDisconnectNotification object:nil];

    var defaults = [CPUserDefaults standardUserDefaults];

    [defaults registerDefaults:[CPDictionary dictionaryWithObjectsAndKeys:
        [bundle objectForInfoDictionaryKey:@"TNArchipelMUCDefaultService"], @"TNArchipelMUCDefaultService",
        [bundle objectForInfoDictionaryKey:@"TNArchipelMUCDefaultRoom"], @"TNArchipelMUCDefaultRoom"
    ]];
}


#pragma mark -
#pragma mark TNModule overrides

/*! Called when the module has been loaded
*/
- (BOOL)willLoad
{
    if (![super willLoad])
        return NO;

    [self connectToRoom];

    return YES;
}

/*! this message is called when module becomes visible
*/
- (BOOL)willShow
{
    if (![super willShow])
        return NO;

    _numberOfNotices = 0;
    [[self UIItem] setImage:_toolbarItemImages[0]];
    [_UIObject _reloadToolbarItems];
    [self reload:nil];
    [_messageBoard reloadData];
    [self scrollToBottom];

    return YES;
}

/*! called when user saves preferences
*/
- (void)savePreferences
{
    var defaults    = [CPUserDefaults standardUserDefaults],
        center      = [CPNotificationCenter defaultCenter],
        oldService  = [defaults objectForKey:@"TNArchipelMUCDefaultService"],
        oldRoom     = [defaults objectForKey:@"TNArchipelMUCDefaultRoom"];

    [defaults setObject:[fieldPreferencesDefaultService stringValue] forKey:@"TNArchipelMUCDefaultService"];
    [defaults setObject:[fieldPreferencesDefaultRoom stringValue] forKey:@"TNArchipelMUCDefaultRoom"];

    if ((oldService != [fieldPreferencesDefaultService stringValue])
        || (oldRoom != [fieldPreferencesDefaultRoom stringValue]))
        {
            [_session leave];
            [self connectToRoom];
        }
}

/*! called when user gets preferences
*/
- (void)loadPreferences
{
    var defaults = [CPUserDefaults standardUserDefaults];

    [fieldPreferencesDefaultService setStringValue:[defaults objectForKey:@"TNArchipelMUCDefaultService"]];
    [fieldPreferencesDefaultRoom setStringValue:[defaults objectForKey:@"TNArchipelMUCDefaultRoom"]];
}


#pragma mark -
#pragma mark Notification handlers

/*! triggered when main stropheconnection is connected
    it will connect to the room
    @param aNotification the notification that triggers the message
*/
- (void)stropheConnected:(CPNotification)aNotification
{
    [self connectToRoom];
}

/*! triggered when main stropheconnection is disconnecting
    it will connect to the room
    @param aNotification the notification that triggers the message
*/
- (void)stropheWillDisconnect:(CPNotification)aNotification
{
    [_session leave];
}


#pragma mark -
#pragma mark Utilities

/*! Connect to the conference room
*/
- (void)connectToRoom
{
    var center = [CPNotificationCenter defaultCenter],
        defaults = [CPUserDefaults standardUserDefaults],
        roomName = [defaults objectForKey:@"TNArchipelMUCDefaultRoom"],
        serviceName = [defaults objectForKey:@"TNArchipelMUCDefaultService"];

    [center removeObserver:self name:TNStropheMUCContactJoinedNotification object:[_session roster]];
    [center removeObserver:self name:TNStropheMUCContactLeftNotification object:[_session roster]];

     _session = [TNStropheMUCRoom joinRoom:roomName
                                 onService:serviceName
                           usingConnection:[[TNStropheIMClient defaultClient] connection]
                                  withNick:[[[TNStropheIMClient defaultClient] JID] node]];

    [_session setDelegate:self];
    [center addObserver:self selector:@selector(reload:) name:TNStropheMUCContactJoinedNotification object:[_session roster]];
    [center addObserver:self selector:@selector(reload:) name:TNStropheMUCContactLeftNotification object:[_session roster]];
    [labelConferenceServer setStringValue:serviceName];
    [labelConferenceRoom setStringValue:roomName];
    [self reload:nil];

    [_session join];
}

/*! reload the content of the MessageBoard
    @param aNotification the notification that triggers the message
*/
- (void)reload:(CPNotification)aNotification
{
    [_peopleDatasource removeAllObjects];
    for (var i = 0; i < [[[_session roster] contacts] count]; i++)
        [_peopleDatasource addObject:[[[_session roster] contacts] objectAtIndex:i]];

    [_tableViewPeople reloadData];
}

/*! scrolls the MessageBoard to the bottom
*/
- (void)scrollToBottom
{
    if (!_messageBoard)
        return;

    var verticalOffset = [_messageBoard boundsSize].height - [[scrollViewMessageContainer contentView] boundsSize].height;
    [[scrollViewMessageContainer contentView] scrollToPoint:CGPointMake(0,verticalOffset)];
    [scrollViewMessageContainer reflectScrolledClipView:[scrollViewMessageContainer contentView]];
}


#pragma mark -
#pragma mark Actions

/*! send a message to the MUC
    @param aSender the sender of the object
*/
- (IBAction)sendMessageToMuc:(id)aSender
{
    if ([textFieldMessage stringValue] != @"")
    {
        [_session sayToRoom:[textFieldMessage stringValue]];
        [textFieldMessage setStringValue:@""];
    }
}

/*! will add the user from table in the roster if not already present. but ask confirmation before
    @param aSender the sender of the object
*/
- (IBAction)didDoubleClick:(id)aSender
{
    if ([_tableViewPeople numberOfSelectedRows] == 0)
        return;

    var member  = [_peopleDatasource objectAtIndex:[_tableViewPeople selectedRow]];

    if (![[[TNStropheIMClient defaultClient] roster] containsJID:[member JID]])
    {
        var alert = [TNAlert alertWithMessage:CPBundleLocalizedString(@"Adding contact", @"Adding contact")
                                    informative:CPBundleLocalizedString(@"Would you like to add ", @"Would you like to add ") + [member nickname] + CPBundleLocalizedString(@" to your roster", @" to your roster")
                                     target:self
                                    actions:[[CPBundleLocalizedString(@"Add contact", @"Add contact"), @selector(performAddToRoster:)], [CPBundleLocalizedString(@"Cancel", @"Cancel"), nil]]];
        [alert setUserInfo:member];
        [alert runModal];
    }
}

/*! will add the user from table in the roster if not already present.
    @param someUserInfo userInfo of the TNAlert
*/
- (void)performAddToRoster:(id)someUserInfo
{
    var member  = someUserInfo,
        JID     = [member JID];

    [JID setDomain:[JID domain].replace("conference.", "")];
    [[[TNStropheIMClient defaultClient] roster] addContact:JID withName:[member nickname] inGroupWithPath:nil];
    [[[TNStropheIMClient defaultClient] roster] askAuthorizationTo:JID];
    [[[TNStropheIMClient defaultClient] roster] authorizeJID:JID];
}


#pragma mark -
#pragma mark Delegates

/*! TNStropheMUCRoom delegate triggered on new message
    @param aRoom the TNStropheMUCRoom that send the message
    @param aMessage CPDictionary containing the message information
*/
- (void)mucRoom:(TNStropheMUCRoom)aRoom receivedMessage:(CPDictionary)aMessage
{
    var color = ([[[TNStropheIMClient defaultClient] JID] node] == [[[aMessage objectForKey:@"from"] JID] resource]) ? TNMessageViewBubbleColorNormal : TNMessageViewBubbleColorAlt,
        isNotice = ([aMessage objectForKey:"body"].indexOf([[[TNStropheIMClient defaultClient] JID] node]) != -1),
        avatar,
        position;

    if (isNotice)
        color = TNMessageViewBubbleColorNotice;

    if ([[[TNStropheIMClient defaultClient] JID] node] == [[[aMessage objectForKey:@"from"] JID] resource])
    {
        avatar = [[TNStropheIMClient defaultClient] avatar];
        position= TNMessageViewAvatarPositionLeft;
    }
    else
    {
        position= TNMessageViewAvatarPositionRight;
    }

    [_messageBoard addMessage:[aMessage objectForKey:"body"]
                         from:[[aMessage objectForKey:"from"] nickname]
                         date:[aMessage objectForKey:"time"]
                        color:color
                        avatar:avatar
                        position:position];

    [self scrollToBottom];

    if (!_isVisible && isNotice && _toolbarItemImages)
    {
        // _numberOfNotices++;
        // var index = _numberOfNotices > 6 ? 6 : _numberOfNotices;
        // [[self UIItem] setImage:_toolbarItemImages[index]];
        // [_UIObject _reloadToolbarItems];
        [_audioTagReceive play];
    }
}

@end


// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNMUCChatController], comment);
}
