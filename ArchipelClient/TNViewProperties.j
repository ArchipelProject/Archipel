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

    [self setBackgroundColor:[CPColor colorWithHexString:@"D8DFE8"]];

    [entryName setFont:[CPFont boldSystemFontOfSize:13]];
    [entryName setTextColor:[CPColor colorWithHexString:@"8D929D"]];

    [entryAvatar setBordered:NO];
    [entryAvatar setAutoresizingMask:CPViewMaxXMargin | CPViewMinXMargin];
    [entryAvatar setImageScaling:CPScaleProportionally];

    [entryName setTarget:self];
    [entryName setAction:@selector(changeNickName:)];

    _unknownUserImage   = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"user-unknown.png"]];
    _groupUserImage     = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"groups.png"] size:CGSizeMake(16,16)];

    [center addObserver:self selector:@selector(changeNickNameNotification:) name:CPTextFieldDidBlurNotification object:entryName];
    [center addObserver:self selector:@selector(reload:) name:TNStropheContactPresenceUpdatedNotification object:nil];
    [center addObserver:self selector:@selector(reload:) name:TNStropheContactVCardReceivedNotification object:nil];

    [[self superview] setPosition:[[self superview] bounds].size.height ofDividerAtIndex:0];
}


- (void)setAvatarManager:(TNAvatarManager)anAvatarManager
{
    _avatarManager = anAvatarManager;

    [entryAvatar setTarget:self];
    [entryAvatar setAction:@selector(openAvatarManager:)];
}

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


/*! hide the panel
*/
- (void)hide
{
    if (_isCollapsed)
        return;

    var defaults = [TNUserDefaults standardUserDefaults];

    _isCollapsed = YES;
    
    if ([defaults boolForKey:@"TNArchipelUseAnimations"])
    {
        var anim = [[TNAnimation alloc] initWithDuration:0.3 animationCurve:CPAnimationEaseInOut];

        [anim setDelegate:self];
        [anim setFrameRate:0.0];
        [anim startAnimation];
    }
    else
    {
        [self animation:nil valueForProgress:1.0];
    }
}

/*! show the panel
*/
- (void)show
{
    if (!_isCollapsed)
        return;

    var defaults = [TNUserDefaults standardUserDefaults];

    _isCollapsed = NO;

    if ([defaults boolForKey:@"TNArchipelUseAnimations"])
    {
        var anim = [[TNAnimation alloc] initWithDuration:0.3 animationCurve:CPAnimationEaseInOut];
        
        [anim setDelegate:self];
        [anim setFrameRate:0.0];
        [anim startAnimation];
    }
    else
    {
        [self animation:nil valueForProgress:1.0];
    }
}

- (void)animation:(CPAnimation)anAnimation valueForProgress:(float)aValue
{
    var position = _isCollapsed ? ([[self superview] bounds].size.height - _height) + (_height * aValue) : ([[self superview] bounds].size.height) - (_height * aValue);

    [[self superview] setPosition:position ofDividerAtIndex:0];
}



/*! message performed when contact update its presence in order to update information
*/
- (void)reload:(CPNotification)aNotification
{
    [self reload];
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

    [self show];

    if ([_entity class] == TNStropheContact)
    {
        [labelResource setStringValue:@"Resource :"];
        [labelStatus setHidden:NO];
        [labelDomain setHidden:NO];
        [entryAvatar setHidden:NO];

        [entryName setStringValue:[_entity nickname]];

        [entryDomain setStringValue:[_entity domain]];
        [entryResource setStringValue:[[_entity resources] lastObject]];
        [entryStatusIcon setImage:[_entity statusIcon]];
        if ([_entity avatar])
            [entryAvatar setImage:[_entity avatar]];
        else
            [entryAvatar setImage:_unknownUserImage];

        [entryStatus setStringValue:[_entity XMPPStatus]];

        if (_avatarManager)
        {
            [_avatarManager setEntity:_entity];
        }
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

}


/*! Re
*/

- (void)changeNickNameNotification:(CPNotification)aNotification
{
    if (([_entity class] == TNStropheContact) && ([_entity nickname] != [entryName stringValue]))
        [_roster changeNickname:[entryName stringValue] ofContactWithJID:[_entity JID]];
    else if (([_entity class] == TNStropheGroup) && ([_entity name] != [entryName stringValue]))
    {
        var defaults    = [TNUserDefaults standardUserDefaults],
            oldKey      = TNArchipelRememberOpenedGroup + [_entity name];

        [_entity changeName:[entryName stringValue]];

        [defaults removeObjectForKey:oldKey];
    }
}

/*! action sent by the TNEditableLabel when ok. Will blur it
    @param sender the sender
*/
- (IBAction)changeNickName:(id)sender
{
    //[entryName _inputElement].blur();
    [[self window] makeFirstResponder:[entryName previousResponder]];
}

@end