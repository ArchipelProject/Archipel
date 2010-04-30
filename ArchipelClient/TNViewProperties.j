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
    @outlet TNEditableLabel entryName       @accessors;
    @outlet CPImageView     entryStatusIcon @accessors;
    @outlet CPImageView     entryAvatar     @accessors;
    @outlet CPTextField     entryDomain     @accessors;
    @outlet CPTextField     entryResource   @accessors;
    @outlet CPTextField     entryShow       @accessors;
    @outlet CPTextField     newNickName     @accessors;

    TNStropheRoster         _roster         @accessors(getter=roster, setter=setRoster:);
    TNStropheContact        _entity         @accessors(getter=_entity, setter=setEntity:);
    CPImage                 _unknownUserImage;

    CPNumber                _height;
}

/*! init the class
    @param aRect CPRect containing frame informations
*/
- (id)initWithFrame:(CPRect)aRect
{
    _height = 180;

    aRect.size.height = _height;
    self = [super initWithFrame:aRect];

    return self;
}

/*! initialize some values on CIB awakening
*/
- (void)awakeFromCib
{
    [self setAutoresizingMask: CPViewNotSizable];

    [self setBackgroundColor:[CPColor colorWithHexString:@"D8DFE8"]];
    [entryName setFont:[CPFont boldSystemFontOfSize:13]];
    [entryName setTextColor:[CPColor colorWithHexString:@"8D929D"]];

    [entryAvatar setBorderedWithHexColor:@"#a5a5a5"];
    [entryAvatar setBackgroundColor:[CPColor whiteColor]];
    
    [self setHidden:YES];

    [entryName setTarget:self];
    [entryName setAction:@selector(changeNickName:)];
    
    var bundle = [CPBundle mainBundle];
    _unknownUserImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"user-unknown.png"]];
    
    var center = [CPNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(_didLabelEntryNameBlur:) name:CPTextFieldDidBlurNotification object:entryName];
    [center addObserver:self selector:@selector(_didContactUpdatePresence:) name:TNStropheContactPresenceUpdatedNotification object:nil];
    [center addObserver:self selector:@selector(_didContactUpdatePresence:) name:TNStropheContactVCardReceivedNotification object:nil];
}

/*! hide the panel
*/
- (void)hide
{
    if ([self superview])
    {
        var splitView = [self superview];

        [self setHidden:YES];
        [splitView setPosition:[splitView bounds].size.height ofDividerAtIndex:0];
    }
}

/*! show the panel
*/
- (void)show
{
    var splitView = [self superview];

    [self setHidden:NO];
    [splitView setPosition:([splitView bounds].size.height - _height) ofDividerAtIndex:0];
}

/*! reload the panel
*/
- (void)reload
{
    if ((!_entity) || ([_entity class] == TNStropheGroup))
    {
        [self hide];
        return;
    }
    [self show];
    
    [entryName setStringValue:[_entity nickname]];
    [entryDomain setStringValue:[_entity domain]];
    [entryResource setStringValue:[_entity resource]];
    [entryStatusIcon setImage:[_entity statusIcon]];
    if ([_entity avatar])
        [entryAvatar setImage:[_entity avatar]];
    else
        [entryAvatar setImage:_unknownUserImage];
        
    [entryShow setStringValue:[_entity show]];
}

/*! message performed when contact update its presence in order to update information
*/
- (void)_didContactUpdatePresence:(CPNotification)aNotification
{
    if ((!_entity) || ([_entity class] == TNStropheGroup))
    {
        [self hide];
        return;
    }
    
    [entryStatusIcon setImage:[_entity statusIcon]];
    
    if ([_entity avatar])
        [entryAvatar setImage:[_entity avatar]];
    else
        [entryAvatar setImage:_unknownUserImage];
        
    [entryResource setStringValue:[_entity resource]];
    [entryShow setStringValue:[_entity show]];
}

/*! message performed when the TNEditableLabel hase been changed
    will call doChangeNickName
    @param aNotification the blur notification
*/
- (void)_didLabelEntryNameBlur:(CPNotification)aNotification
{
    [self doChangeNickName];
}

/*! action sent by the TNEditableLabel when ok. Will blur it
    @param sender the sender
*/
- (IBAction)changeNickName:(id)sender
{
    [sender _inputElement].blur();
}

/*! it will update the name of the current TNStropheContact
*/
- (void)doChangeNickName
{
    var theJid = [_entity jid];
    var theName = [entryName stringValue];

    [_roster changeNickname:theName forJID:theJid];
    [entryName setStringValue:theName];

    // [[TNViewLog sharedLogger] log:@"new nickname for contact " + theJid + " : " + theName];
}

@end