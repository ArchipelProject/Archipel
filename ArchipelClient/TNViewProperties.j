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
@implementation TNViewProperties: CPView
{
    @outlet CPButton        entryAvatar;
    @outlet CPImageView     entryStatusIcon;
    @outlet CPTextField     entryDomain;
    @outlet CPTextField     entryResource;
    @outlet CPTextField     entryStatus;
    @outlet CPTextField     labelDomain;
    @outlet CPTextField     labelResource;
    @outlet CPTextField     labelStatus;
    @outlet CPTextField     newNickName;
    @outlet TNEditableLabel entryName       @accessors;

    TNStropheContact        _entity         @accessors(property=entity);
    TNStropheRoster         _roster         @accessors(property=roster);
    TNAvatarManager         _avatarManager  @accessors(getter=avatarManager);

    CPImage                 _unknownUserImage;
    CPNumber                _height;
    BOOL                    _isCollapsed;
}


#pragma mark -
#pragma mark Initialization

/*! init the class
    @param aRect CPRect containing frame informations
*/
- (id)initWithFrame:(CPRect)aRect
{
    _height         = 180;
    _isCollapsed    = YES;

    aRect.size.height = _height;
    self = [super initWithFrame:aRect];

    return self;
}

/*! initialize some values on CIB awakening
*/
- (void)awakeFromCib
{
    var bundle = [CPBundle mainBundle],
        center = [CPNotificationCenter defaultCenter];

    _unknownUserImage   = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"user-unknown.png"]];
    _groupUserImage     = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"groups.png"] size:CGSizeMake(16,16)];

    [self setBackgroundColor:[CPColor colorWithHexString:@"D8DFE8"]];

    [entryName setFont:[CPFont boldSystemFontOfSize:13]];
    [entryName setTextColor:[CPColor colorWithHexString:@"8D929D"]];
    [entryName setTarget:self];
    [entryName setAction:@selector(changeNickName:)];

    [entryAvatar setBordered:NO];
    [entryAvatar setAutoresizingMask:CPViewMaxXMargin | CPViewMinXMargin];
    [entryAvatar setImageScaling:CPScaleProportionally];
    [entryAvatar setImage:_unknownUserImage];

    [center addObserver:self selector:@selector(changeNickNameNotification:) name:CPTextFieldDidBlurNotification object:entryName];
    [center addObserver:self selector:@selector(reload:) name:TNStropheContactPresenceUpdatedNotification object:nil];
    [center addObserver:self selector:@selector(reload:) name:TNStropheContactVCardReceivedNotification object:nil];

    [[self superview] setPosition:[[self superview] bounds].size.height ofDividerAtIndex:0];
}


#pragma mark -
#pragma mark Notification handlers

/*! message performed when contact update its presence in order to update information
*/
- (void)reload:(CPNotification)aNotification
{
    [self reload];
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
        var defaults    = [TNUserDefaults standardUserDefaults],
            oldKey      = TNArchipelRememberOpenedGroup + [_entity name];

        [_entity changeName:[entryName stringValue]];

        [defaults removeObjectForKey:oldKey];
    }
}


#pragma mark -
#pragma mark Utilities

- (void)setAvatarManager:(TNAvatarManager)anAvatarManager
{
    _avatarManager = anAvatarManager;

    [entryAvatar setTarget:self];
    [entryAvatar setAction:@selector(openAvatarManager:)];
}

/*! hide the panel
*/
- (void)hide
{
    if (_isCollapsed)
        return;

    var defaults = [TNUserDefaults standardUserDefaults];

    _isCollapsed = YES;

    [[self superview] setPosition:[[self superview] bounds].size.height ofDividerAtIndex:0];
}

/*! show the panel
*/
- (void)show
{
    if (!_isCollapsed)
        return;

    var defaults = [TNUserDefaults standardUserDefaults];

    _isCollapsed = NO;

    [[self superview] setPosition:([[self superview] bounds].size.height - _height) ofDividerAtIndex:0];

}

/*! reload the panel
*/
- (void)reload
{
    if (!_entity)
    {
        [self hide];
        return;
    }

    if ([_entity class] == TNStropheContact)
    {
        [labelResource setStringValue:@"Resource :"];
        [labelStatus setHidden:NO];
        [labelDomain setHidden:NO];
        [entryAvatar setHidden:NO];

        [entryStatusIcon setImage:[_entity statusIcon]];
        [entryName setStringValue:[_entity nickname]];
        [entryDomain setStringValue:[_entity domain]];
        [entryResource setStringValue:[[_entity resources] lastObject]];
        [entryStatus setStringValue:[_entity XMPPStatus]];

        if ([_entity avatar])
            [entryAvatar setImage:[_entity avatar]];
        else
            [entryAvatar setImage:_unknownUserImage];

        if (_avatarManager)
            [_avatarManager setEntity:_entity];
    }
    else if ([_entity class] == TNStropheGroup)
    {
        var population = ([_entity count] > 1) ? [_entity count] + @" contacts in group" : [_entity count] + @" contact in group";

        [labelResource setStringValue:@"Contents :"];
        [labelStatus setHidden:YES];
        [labelDomain setHidden:YES];
        [entryAvatar setHidden:YES];

        [entryStatusIcon setImage:_groupUserImage];
        [entryName setStringValue:[_entity name]];
        [entryDomain setStringValue:@""];
        [entryResource setStringValue:population];
        [entryStatus setStringValue:@""];
    }

    [self show];
}


#pragma mark -
#pragma mark Actions

/*! opens the avatar manager window if any
    @param sender the sender
*/
- (IBAction)openAvatarManager:(id)sender
{
    if (_avatarManager)
    {
        [_avatarManager center];
        [_avatarManager makeKeyAndOrderFront:sender];
    }
    else
        CPLog.warn("no avatar manager set.");
}

/*! action sent by the TNEditableLabel when ok. Will blur it
    @param sender the sender
*/
- (IBAction)changeNickName:(id)sender
{
    [[self window] makeFirstResponder:[entryName previousResponder]];
}


@end