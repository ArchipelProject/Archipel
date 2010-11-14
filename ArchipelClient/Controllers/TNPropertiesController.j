/*
 * TNViewProperties.j
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
@import <StropheCappuccino/StropheCappuccino.j>

/*! @ingroup archipelcore
    subclass of CPView that represent the bottom-left property panel.
    it allows to change nickname of a TNStropheContact and give informations about it.
*/
@implementation TNPropertiesController: CPObject
{
    @outlet CPView          mainView            @accessors(readonly);
    @outlet TNEditableLabel entryName           @accessors(readonly);
    @outlet CPButton        entryAvatar;
    @outlet CPImageView     entryStatusIcon;
    @outlet CPImageView     imageEventSubscription;
    @outlet CPTextField     entryDomain;
    @outlet CPTextField     entryResource;
    @outlet CPTextField     entryStatus;
    @outlet CPTextField     labelDomain;
    @outlet CPTextField     labelResource;
    @outlet CPTextField     labelStatus;
    @outlet CPTextField     newNickName;


    TNStropheContact        _entity             @accessors(getter=entity);
    TNStropheRoster         _roster             @accessors(property=roster);
    TNAvatarController      _avatarManager      @accessors(getter=avatarManager);
    TNPubSubController      _pubSubController   @accessors(property=pubSubController);

    CPImage                 _unknownUserImage;
    CPImage                 _pubsubImage;
    CPImage                 _pubsubDisabledImage;
    CPNumber                _height;
    BOOL                    _isCollapsed;
}


//#pragma mark -
//#pragma mark Initialization

/*! initialize some values on CIB awakening
*/
- (void)awakeFromCib
{
    var bundle = [CPBundle mainBundle],
        center = [CPNotificationCenter defaultCenter];

    _height                 = 180;
    _isCollapsed            = YES;
    _unknownUserImage       = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"user-unknown.png"]];
    _groupUserImage         = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"groups.png"] size:CGSizeMake(16,16)];
    _pubsubImage            = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"pubsub.png"]];
    _pubsubDisabledImage    = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"pubsub-disabled.png"]];

    [mainView setBackgroundColor:[CPColor colorWithHexString:@"D8DFE8"]];

    [entryName setFont:[CPFont boldSystemFontOfSize:13]];
    [entryName setTextColor:[CPColor colorWithHexString:@"8D929D"]];
    [entryName setTarget:self];
    [entryName setAction:@selector(changeNickName:)];

    [entryAvatar setBordered:NO];
    [entryAvatar setAutoresizingMask:CPViewMaxXMargin | CPViewMinXMargin];
    [entryAvatar setImageScaling:CPScaleProportionally];
    [entryAvatar setImage:_unknownUserImage];
    [imageEventSubscription setToolTip:@"Click on avatar to change it."];

    [imageEventSubscription setImageScaling:CPScaleProportionally];
    [imageEventSubscription setHidden:YES];

    [center addObserver:self selector:@selector(changeNickNameNotification:) name:CPTextFieldDidBlurNotification object:entryName];
}


// #pragma mark -
// #pragma mark Notification handlers

/*! message performed when contact update its presence in order to update information
*/
- (void)reload:(CPNotification)aNotification
{
    //setTimeout(function(){[self reload]}, 1000);
    [self reload]
}

/*! triggered when contact change the nickname
    @param aNotification the notification
*/
- (void)changeNickNameNotification:(CPNotification)aNotification
{
    if (([_entity class] == TNStropheContact) && ([_entity nickname] != [entryName stringValue]))
    {
        [_roster changeNickname:[entryName stringValue] ofContactWithJID:[_entity JID]];
    }
    else if (([_entity class] == TNStropheGroup) && ([_entity name] != [entryName stringValue]))
    {
        var defaults    = [CPUserDefaults standardUserDefaults],
            oldKey      = TNArchipelRememberOpenedGroup + [_entity name];

        [_entity changeName:[entryName stringValue]];

        [defaults removeObjectForKey:oldKey];
    }
}

//#pragma mark -
//#pragma mark Setters

- (void)setEntity:(id)anEntity
{
    var center      = [CPNotificationCenter defaultCenter],
        oldEntity   = _entity;

    if (oldEntity && ([oldEntity class] == TNStropheContact))
    {
        [center removeObserver:self name:TNStropheContactVCardReceivedNotification object:oldEntity];
        [center removeObserver:self name:TNStropheContactPresenceUpdatedNotification object:oldEntity];
    }

    _entity = anEntity;

    if (_entity && ([_entity class] == TNStropheContact))
    {
        [center addObserver:self selector:@selector(reload:) name:TNStropheContactVCardReceivedNotification object:_entity];
        [center addObserver:self selector:@selector(reload:) name:TNStropheContactPresenceUpdatedNotification object:_entity];
    }
}


//#pragma mark -
//#pragma mark Utilities

- (void)setAvatarManager:(TNAvatarManager)anAvatarManager
{
    _avatarManager = anAvatarManager;

    [entryAvatar setTarget:self];
    [entryAvatar setAction:@selector(openAvatarManager:)];
}

/*! hide the panel
*/
- (void)hideView
{
    if (_isCollapsed)
        return;

    var defaults = [CPUserDefaults standardUserDefaults];

    _isCollapsed = YES;

    [[mainView superview] setPosition:[[mainView superview] bounds].size.height ofDividerAtIndex:0];
}

/*! show the panel
*/
- (void)showView
{
    if (!_isCollapsed)
        return;

    var defaults = [CPUserDefaults standardUserDefaults];

    _isCollapsed = NO;

    [[mainView superview] setPosition:([[mainView superview] bounds].size.height - _height) ofDividerAtIndex:0];

}

/*! reload the panel
*/
- (void)reload
{
    if (!_entity)
    {
        [self hideView];
        return;
    }

    if ([_entity class] === TNStropheContact)
    {
        [labelResource setStringValue:@"Resource :"];
        [labelStatus setHidden:NO];
        [labelDomain setHidden:NO];
        [entryAvatar setHidden:NO];
        [imageEventSubscription setHidden:NO];

        [entryStatusIcon setImage:[_entity statusIcon]];
        [entryName setStringValue:[_entity nickname]];
        [entryDomain setStringValue:[[_entity JID] domain]];
        [entryResource setStringValue:[[_entity resources] lastObject]];
        [entryStatus setStringValue:[_entity XMPPStatus]];

        if ([_entity avatar])
            [entryAvatar setImage:[_entity avatar]];
        else
            [entryAvatar setImage:_unknownUserImage];

        if (_avatarManager)
            [_avatarManager setEntity:_entity];

        if ([_pubSubController nodeWithName:@"/archipel/" + [[_entity JID] bare] + @"/events"])
        {
            [imageEventSubscription setImage:_pubsubImage];
            [imageEventSubscription setToolTip:@"You are registred to the entity events."];
        }
        else
        {
            [imageEventSubscription setImage:_pubsubDisabledImage];
            [imageEventSubscription setToolTip:@"You are not registred to the entity events."];
        }

    }
    else if ([_entity class] == TNStropheGroup)
    {
        var population = ([_entity count] > 1) ? [_entity count] + @" contacts in group" : [_entity count] + @" contact in group";

        [labelResource setStringValue:@"Contents :"];
        [labelStatus setHidden:YES];
        [labelDomain setHidden:YES];
        [entryAvatar setHidden:YES];
        [imageEventSubscription setHidden:YES];

        [entryStatusIcon setImage:_groupUserImage];
        [entryName setStringValue:[_entity name]];
        [entryDomain setStringValue:@""];
        [entryResource setStringValue:population];
        [entryStatus setStringValue:@""];
    }

    [self showView];
}


//#pragma mark -
//#pragma mark Actions

/*! opens the avatar manager window if any
    @param sender the sender
*/
- (IBAction)openAvatarManager:(id)sender
{
    if (_avatarManager)
    {
        [_avatarManager showWindow:sender];
    }
    else
        CPLog.warn("no avatar manager set.");
}

/*! action sent by the TNEditableLabel when ok. Will blur it
    @param sender the sender
*/
- (IBAction)changeNickName:(id)sender
{
    [[mainView window] makeFirstResponder:[entryName previousResponder]];
}


@end