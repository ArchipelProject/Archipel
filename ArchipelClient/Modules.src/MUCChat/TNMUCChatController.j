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
@import <AppKit/AppKit.j>


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
    @outlet CPTextField         textFieldMessage;
    @outlet CPTextField         fieldPreferencesDefaultService;
    @outlet CPTextField         fieldPreferencesDefaultRoom;

    CPArray                     _toolbarItemImages;
    CPTableView                 _tableViewPeople;
    int                         _numberOfNotices;
    TNMessageBoard              _messageBoard;
    TNStropheMUCRoom            _session;
    TNTableViewDataSource       _peopleDatasource;
    DOMElement                  _audioTagReceive;
}

#pragma mark -
#pragma mark Initialization

/*! call at cib awaking
*/
- (void)awakeFromCib
{
    [scrollViewMessageContainer setBorderedWithHexColor:@"#C0C7D2"];

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
    [[columnNickname headerView] setStringValue:@"Nickname"];
    [columnNickname setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"nickname" ascending:YES]];
    [_tableViewPeople addTableColumn:columnNickname];

    [_peopleDatasource setTable:_tableViewPeople];
    [_peopleDatasource setSearchableKeyPaths:[@"JID"]];
    [_tableViewPeople setDataSource:_peopleDatasource];

    var bundle = [CPBundle bundleForClass:[self class]],
        sound = [bundle pathForResource:@"Stoof.aiff"];

    _audioTagReceive = document.createElement('audio');
    _audioTagReceive.setAttribute("src", sound);
    _audioTagReceive.setAttribute("autobuffer", "autobuffer");
    document.body.appendChild(_audioTagReceive);

    _toolbarItemImages = [
        [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"icon.png"] size:CPSizeMake(32,32)],
        [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"icon-1.png"] size:CPSizeMake(32,32)],
        [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"icon-2.png"] size:CPSizeMake(32,32)],
        [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"icon-3.png"] size:CPSizeMake(32,32)],
        [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"icon-4.png"] size:CPSizeMake(32,32)],
        [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"icon-5.png"] size:CPSizeMake(32,32)],
        [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"icon-5more.png"] size:CPSizeMake(32,32)]
    ];

    _numberOfNotices = 0;

    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(stropheConnected:) name:TNStropheConnectionStatusConnected object:nil];
    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(stropheWillDisconnect:) name:TNStropheConnectionStatusWillDisconnect object:nil];

    var defaults = [TNUserDefaults standardUserDefaults];

    [defaults registerDefaults:[CPDictionary dictionaryWithObjectsAndKeys:
        [bundle objectForInfoDictionaryKey:@"TNArchipelMUCDefaultService"], @"TNArchipelMUCDefaultService",
        [bundle objectForInfoDictionaryKey:@"TNArchipelMUCDefaultRoom"], @"TNArchipelMUCDefaultRoom"
    ]];

}


#pragma mark -
#pragma mark TNModule overrides

/*! this message is called when module becomes visible
*/
- (void)willShow
{
    [super willShow];
    _numberOfNotices = 0;
    [_toolbarItem setImage:_toolbarItemImages[0]];
    [_toolbar _reloadToolbarItems];
    [self reload:nil];
    [_messageBoard reload];
    [self scrollToBottom];
}

/*! called when user saves preferences
*/
- (void)savePreferences
{
    var defaults    = [TNUserDefaults standardUserDefaults],
        center      = [CPNotificationCenter defaultCenter],
        oldService  = [defaults objectForKey:@"TNArchipelMUCDefaultService"],
        oldRoom     = [defaults objectForKey:@"TNArchipelMUCDefaultRoom"];

    [defaults setObject:[fieldPreferencesDefaultService stringValue] forKey:@"TNArchipelMUCDefaultService"];
    [defaults setObject:[fieldPreferencesDefaultRoom stringValue] forKey:@"TNArchipelMUCDefaultRoom"];

    if ((oldService != [fieldPreferencesDefaultService stringValue])
        || (oldRoom != [fieldPreferencesDefaultRoom stringValue]))
        {
            [_session leave];

            [center removeObserver:self name:TNStropheMUCContactJoinedNotification object:[_session roster]];
            [center removeObserver:self name:TNStropheMUCContactLeftNotification object:[_session roster]];

            _session = [TNStropheMUCRoom joinRoom:[defaults objectForKey:@"TNArchipelMUCDefaultRoom"]
                                        onService:[defaults objectForKey:@"TNArchipelMUCDefaultService"]
                                  usingConnection:_connection
                                         withNick:[_connection JID]];
            [_session join];
            [_session setDelegate:self];

            [center addObserver:self selector:@selector(reload:) name:TNStropheMUCContactJoinedNotification object:[_session roster]];
            [center addObserver:self selector:@selector(reload:) name:TNStropheMUCContactLeftNotification object:[_session roster]];

            [self reload:nil];
        }
}

/*! called when user gets preferences
*/
- (void)loadPreferences
{
    var defaults = [TNUserDefaults standardUserDefaults];

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
    var center = [CPNotificationCenter defaultCenter],
        defaults = [TNUserDefaults standardUserDefaults];

    _session = [TNStropheMUCRoom joinRoom:[defaults objectForKey:@"TNArchipelMUCDefaultRoom"]
                                onService:[defaults objectForKey:@"TNArchipelMUCDefaultService"]
                          usingConnection:[aNotification object]
                                 withNick:[[aNotification object] JID]];

    [_session setDelegate:self];
    [center addObserver:self selector:@selector(reload:) name:TNStropheMUCContactJoinedNotification object:[_session roster]];
    [center addObserver:self selector:@selector(reload:) name:TNStropheMUCContactLeftNotification object:[_session roster]];

    [_session join];
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
    var index   = [[_tableViewPeople selectedRowIndexes] firstIndex],
        member  = [_peopleDatasource objectAtIndex:index];

    if (![_roster containsJID:[member JID]])
    {
        var alert = [TNAlert alertWithTitle:@"Adding contact"
                                    message:@"Would you like to add " + [member nickname] + @" to your roster"
                                   delegate:self
                                    actions:[["Add contact", @selector(performAddToRoster:)], ["Cancel", nil]]];
        [alert setUserInfo:member];
        [alert runModal];
    }
}

/*! will add the user from table in the roster if not already present.
    @param someUserInfo userInfo of the TNAlert
*/
- (void)performAddToRoster:(id)someUserInfo
{
    var member  = someUserInfo;

    [_roster addContact:[member nickname] withName:[member nickname] inGroupWithName:@"General"];
    [_roster askAuthorizationTo:[member nickname]];
    [_roster authorizeJID:[member nickname]];
}


#pragma mark -
#pragma mark Delegates

/*! TNStropheMUCRoom delegate triggered on new message
    @param aRoom the TNStropheMUCRoom that send the message
    @param aMessage CPDictionary containing the message information
*/
- (void)mucRoom:(TNStropheMUCRoom)aRoom receivedMessage:(CPDictionary)aMessage
{
    var color = ([aMessage valueForKey:@"from"] == [_connection JID]) ? [CPColor colorWithHexString:@"d9dfe8"] : [CPColor colorWithHexString:@"ffffff"],
        isNotice = ([aMessage valueForKey:"body"].indexOf([_connection JID].split("@")[0]) != -1)

    if (isNotice)
        color = [CPColor colorWithHexString:@"D1E28B"];

    [_messageBoard addMessage:[aMessage valueForKey:"body"]
                         from:[[aMessage valueForKey:"from"] nickname]
                         date:[aMessage valueForKey:"time"]
                        color:color];

    [self scrollToBottom];

    if (!_isVisible && isNotice && _toolbarItemImages)
    {
        _numberOfNotices++;
        var index = _numberOfNotices > 6 ? 6 : _numberOfNotices;

        [_toolbarItem setImage:_toolbarItemImages[index]];
        [_toolbar _reloadToolbarItems];
        _audioTagReceive.play();
    }
}

@end
