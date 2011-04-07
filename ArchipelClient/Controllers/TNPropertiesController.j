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

@import <AppKit/CPButton.j>
@import <AppKit/CPImage.j>
@import <AppKit/CPImageView.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPView.j>

@import <StropheCappuccino/PubSub/TNPubSubController.j>
@import <StropheCappuccino/TNStropheContact.j>
@import <TNKit/TNFlipView.j>

@import "TNContactsController.j"
@import "TNAvatarController.j"


/*! @ingroup archipelcore
    subclass of CPView that represent the bottom-left property panel.
    it allows to change nickname of a TNStropheContact and give informations about it.
*/
@implementation TNPropertiesController: CPObject
{
    @outlet CPView                  frontView;
    @outlet CPView                  backView;
    @outlet TNEditableLabel         entryName           @accessors(readonly);
    @outlet CPButton                entryAvatar;
    @outlet CPImageView             entryStatusIcon;
    @outlet CPButton                buttonEventSubscription;
    @outlet CPButton                buttonFrontViewFlip;
    @outlet CPButton                buttonBackViewFlip;
    @outlet CPTextField             entryType;
    @outlet CPTextField             labelType;
    @outlet CPTextField             entryDomain;
    @outlet CPTextField             entryResource;
    @outlet CPTextField             entryStatus;
    @outlet CPTextField             labelDomain;
    @outlet CPTextField             labelResource;
    @outlet CPTextField             labelStatus;
    @outlet CPTextField             newNickName;
    @outlet CPTextField             labelVCardFN;
    @outlet CPTextField             labelVCardLocality;
    @outlet CPTextField             labelVCardCompany;
    @outlet CPTextField             labelVCardRole;
    @outlet CPTextField             labelVCardEmail;
    @outlet CPTextField             labelVCardWebiste;
    @outlet CPImageView             imageViewVCardPhoto;
    @outlet TNContactsController    contactsController;

    TNFlipView                      _mainView           @accessors(getter=mainView);
    BOOL                            _enabled            @accessors(getter=isEnabled);
    TNAvatarController              _avatarManager      @accessors(getter=avatarManager);
    TNPubSubController              _pubSubController   @accessors(property=pubSubController);
    TNStropheContact                _entity             @accessors(getter=entity);

    BOOL                            _isCollapsed;
    CPImage                         _pubsubDisabledImage;
    CPImage                         _pubsubImage;
    CPImage                         _unknownUserImage;
    CPNumber                        _height;
}


#pragma mark -
#pragma mark Initialization

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

    _mainView = [[TNFlipView alloc] initWithFrame:[frontView bounds]];
    [_mainView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [_mainView setBackgroundColor:[CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"Backgrounds/property-bg.png"]]]];
    [frontView setFrameOrigin:CPPointMakeZero()];
    [backView setFrameOrigin:CPPointMakeZero()];
    [backView setBackgroundColor:[CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"Backgrounds/vcard-bg.png"]]]];
    [_mainView setFrontView:frontView];
    [_mainView setBackView:backView];
    // [_mainView setBackgroundColor:[CPColor blueColor]];

    [frontView setBackgroundColor:[CPColor colorWithHexString:@"D8DFE8"]];

    [entryName setFont:[CPFont boldSystemFontOfSize:13]];
    [entryName setTextColor:[CPColor colorWithHexString:@"515151"]];
    [entryName setTarget:self];
    [entryName setAction:@selector(changeNickName:)];
    [entryName setToolTip:@"Click here to change the displayed named of the current contact or group"];

    [entryAvatar setBordered:NO];
    [entryAvatar setAutoresizingMask:CPViewMaxXMargin | CPViewMinXMargin];
    [entryAvatar setImageScaling:CPScaleProportionally];
    [entryAvatar setImage:_unknownUserImage];
    [entryAvatar setToolTip:@"Click here to choose the avatar of the current contact (this only works with Archipel contacts, not users)"];

    [buttonEventSubscription setToolTip:@"Click on avatar to change it."];
    [buttonEventSubscription setBordered:NO];
    [buttonEventSubscription setImageScaling:CPScaleProportionally];
    [buttonEventSubscription setHidden:YES];

    [entryResource setToolTip:@"The resource of the contact"];
    [entryDomain setToolTip:@"The domain (XMPP server) of the contact"];
    [entryStatus setToolTip:@"The current status of the contact"];
    [entryType setToolTip:@"The type of contact (hypervisor, virtual machine or user)"];

    [imageViewVCardPhoto setImageScaling:CPScaleProportionally];

    [center addObserver:self selector:@selector(changeNickNameNotification:) name:CPTextFieldDidBlurNotification object:entryName];

    [buttonFrontViewFlip setTarget:_mainView];
    [buttonFrontViewFlip setBordered:NO];
    [buttonFrontViewFlip setAction:@selector(flip:)];
    [buttonFrontViewFlip setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"snap.png"]]];
    [buttonFrontViewFlip setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"snap-pressed.png"]]];
    [buttonBackViewFlip setTarget:_mainView];
    [buttonBackViewFlip setBordered:NO];
    [buttonBackViewFlip setAction:@selector(flip:)];
    [buttonBackViewFlip setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"snap.png"]]];
    [buttonBackViewFlip setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"snap-pressed.png"]]];
}


#pragma mark -
#pragma mark Notification handlers

/*! message performed when contact update its presence in order to update information
*/
- (void)reload:(CPNotification)aNotification
{
    [self reload]
}

/*! triggered when contact change the nickname
    @param aNotification the notification
*/
- (void)changeNickNameNotification:(CPNotification)aNotification
{
    var roster = [[TNStropheIMClient defaultClient] roster];

    if (([_entity isKindOfClass:TNStropheContact]) && ([_entity nickname] != [entryName stringValue]))
    {
        [roster changeNickname:[entryName stringValue] ofContact:_entity];
    }
    else if (([_entity isKindOfClass:TNStropheGroup]) && ([_entity name] != [entryName stringValue]))
    {
        var defaults    = [CPUserDefaults standardUserDefaults],
            oldKey      = TNArchipelRememberOpenedGroup + [_entity name];

        [roster changeName:[entryName stringValue] ofGroup:_entity];

        [defaults removeObjectForKey:oldKey];
    }
}

#pragma mark -
#pragma mark Setters

- (void)setEntity:(id)anEntity
{
    var center      = [CPNotificationCenter defaultCenter],
        oldEntity   = _entity;

    if (oldEntity && [oldEntity isKindOfClass:TNStropheContact])
    {
        [center removeObserver:self name:TNStropheContactVCardReceivedNotification object:oldEntity];
        [center removeObserver:self name:TNStropheContactPresenceUpdatedNotification object:oldEntity];
    }

    _entity = anEntity;

    if (_entity && ([_entity isKindOfClass:TNStropheContact]))
    {
        [center addObserver:self selector:@selector(reload:) name:TNStropheContactVCardReceivedNotification object:_entity];
        [center addObserver:self selector:@selector(reload:) name:TNStropheContactPresenceUpdatedNotification object:_entity];
    }
}

- (void)setEnabled:(BOOL)shouldEnable
{
    _enabled = shouldEnable;
    [entryName setEnabled:shouldEnable];
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
- (void)hideView
{
    if (_isCollapsed)
        return;

    _isCollapsed = YES;

    [[_mainView superview] setPosition:[[_mainView superview] bounds].size.height ofDividerAtIndex:0];
}

/*! show the panel
*/
- (void)showView
{
    if (!_isCollapsed)
        return;

    _isCollapsed = NO;

    [[_mainView superview] setPosition:([[_mainView superview] bounds].size.height - _height) ofDividerAtIndex:0];
    [[CPNotificationCenter defaultCenter] postNotificationName:TNArchipelPropertiesViewDidShowNotification object:self];

}

/*! reload the panel
*/
- (void)reload
{
    if (!_entity || !_enabled)
    {
        [self hideView];
        return;
    }

    if ([_entity isKindOfClass:TNStropheContact])
    {
        [labelResource setStringValue:@"Resource :"];
        [labelStatus setHidden:NO];
        [labelDomain setHidden:NO];
        [labelType setHidden:NO];
        [entryAvatar setHidden:NO];
        [entryType setHidden:NO];

        [buttonEventSubscription setHidden:NO];

        [entryStatusIcon setImage:[_entity statusIcon]];
        [entryName setStringValue:[_entity nickname]];
        [entryDomain setStringValue:[[_entity JID] domain]];
        [entryResource setStringValue:[[_entity resources] lastObject]];
        [entryStatus setStringValue:[_entity XMPPStatus]];

        switch ([[[TNStropheIMClient defaultClient] roster] analyseVCard:[_entity vCard]])
        {
            case TNArchipelEntityTypeVirtualMachine:
                [entryType setStringValue:@"Virtual machine"];
                break;

            case TNArchipelEntityTypeHypervisor:
                [entryType setStringValue:@"Hypervisor"];
                break;

            default:
                [entryType setStringValue:@"User"];
        }

        if ([_entity avatar])
            [entryAvatar setImage:[_entity avatar]];
        else
            [entryAvatar setImage:_unknownUserImage];

        if (_avatarManager)
            [_avatarManager setEntity:_entity];

        if ([_pubSubController nodeWithName:@"/archipel/" + [[_entity JID] bare] + @"/events"])
        {
            [buttonEventSubscription setImage:_pubsubImage];
            [buttonEventSubscription setToolTip:@"You are registred to the entity events."];
        }
        else
        {
            [buttonEventSubscription setImage:_pubsubDisabledImage];
            [buttonEventSubscription setToolTip:@"You are not registred to the entity events."];
        }

        [labelVCardFN setStringValue:nil];
        [labelVCardLocality setStringValue:nil];
        [labelVCardCompany setStringValue:nil];
        [labelVCardRole setStringValue:nil];
        [labelVCardEmail setStringValue:nil]
        [labelVCardWebiste setStringValue:nil];
        [imageViewVCardPhoto setImage:nil];

        if ([_entity vCard])
        {
            var vCard = [_entity vCard];

            [labelVCardFN setStringValue:[[vCard firstChildWithName:@"FN"] text]];
            [labelVCardLocality setStringValue:[[vCard firstChildWithName:@"LOCALITY"] text]];
            [labelVCardCompany setStringValue:[[vCard firstChildWithName:@"ORGNAME"] text]];
            [labelVCardRole setStringValue:[[vCard firstChildWithName:@"TITLE"] text]];
            [labelVCardEmail setStringValue:[[vCard firstChildWithName:@"USERID"] text]]
            [labelVCardWebiste setStringValue:[[vCard firstChildWithName:@"URL"] text]];
            [imageViewVCardPhoto setImage:[_entity avatar] || _unknownUserImage];
        }

    }
    else if ([_entity isKindOfClass:TNStropheGroup])
    {
        var population = ([_entity count] > 1) ? [_entity count] + @" contacts in group" : [_entity count] + @" contact in group";

        [labelResource setStringValue:@"Contents :"];
        [labelStatus setHidden:YES];
        [labelDomain setHidden:YES];
        [labelType setHidden:YES];
        [entryAvatar setHidden:YES];
        [entryType setHidden:YES];

        [buttonEventSubscription setHidden:YES];

        [entryStatusIcon setImage:_groupUserImage];
        [entryName setStringValue:[_entity name]];
        [entryDomain setStringValue:@""];
        [entryResource setStringValue:population];
        [entryStatus setStringValue:@""];
    }

    [self showView];
}


#pragma mark -
#pragma mark Actions

/*! opens the avatar manager window if any
    @param sender the sender
*/
- (IBAction)openAvatarManager:(id)sender
{
    if (_avatarManager && [[[TNStropheIMClient defaultClient] roster] analyseVCard:[_entity vCard]] != TNArchipelEntityTypeUser)
        [_avatarManager showWindow:sender];
}

/*! action sent by the TNEditableLabel when ok. Will blur it
    @param sender the sender
*/
- (IBAction)changeNickName:(id)sender
{
    [[_mainView window] makeFirstResponder:[entryName previousResponder]];
}

/*! subscribe (unsubscribe) to (from) the entity pubsub if any
    @param aSender the sender
*/
- (IBAction)manageContactSubscription:(id)aSender
{
    if ([_pubSubController nodeWithName:@"/archipel/" + [[_entity JID] bare] + @"/events"])
        [contactsController unsubscribeToPubSubNodeOfContactWithJID:[_entity JID]];
    else
        [contactsController subscribeToPubSubNodeOfContactWithJID:[_entity JID]];

    [self reload];
}


@end