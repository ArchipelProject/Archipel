/*
 * TNUserAvatarController.j
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
@import <AppKit/CPMenu.j>
@import <AppKit/CPMenuItem.j>

@import <StropheCappuccino/TNStropheStanza.j>
@import <StropheCappuccino/TNXMLNode.j>
@import <StropheCappuccino/TNStropheIMClient.j>
@import <GrowlCappuccino/GrowlCappuccino.j>

@global TNUserAvatarSize


/*! @ingroup archipelcore
    representation of the current user avatar controller
*/
@implementation TNUserAvatarController : CPObject
{
    CPButton                _buttonAvatar           @accessors(property=buttonAvatar);
    CPImage                 _currentAvatar          @accessors(property=currentAvatar);
    CPMenu                  _menuAvatarSelection    @accessors(property=menuAvatarSelection);

    CPDictionary            _avatars;
    id                      _pListObject;
}


#pragma mark -
#pragma mark Initialization

/*! called at cib awakening
*/
- (void)awakeFromCib
{
    _avatars = [CPDictionary dictionary];
}


/*! get the avatar PList containing avatars meta informations
*/
- (void)loadAvatarMetaInfos
{
    var request     = [CPURLRequest requestWithURL:[CPURL URLWithString:@"Resources/Avatars/avatars.plist"]],
        connection  = [CPURLConnection connectionWithRequest:request delegate:self];

    [connection cancel];
    [connection start];
}

/*! load all avatars
*/
- (void)loadAvatars
{
    var avatarsArray    = [_pListObject objectForKey:@"Avatars"],
        bundle          = [CPBundle bundleForClass:[self class]];

    for (var i = 0; i < [avatarsArray count]; i++)
    {
        var avatarInfo  = [avatarsArray objectAtIndex:i],
            image       = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:[avatarInfo objectForKey:@"path"]] size:TNUserAvatarSize];

        [_avatars setObject:image forKey:[avatarInfo objectForKey:@"name"]];

        if (_menuAvatarSelection)
        {
            var menuItem = [[CPMenuItem alloc] initWithTitle:@"  " + [avatarInfo objectForKey:@"name"] action:nil keyEquivalent:nil];

            [menuItem setImage:image];
            [menuItem setTarget:self];
            [menuItem setAction:@selector(setAvatar:)];
            [_menuAvatarSelection addItem:menuItem];
        }
    }
}


#pragma mark -
#pragma mark Actions

/*! set the avatar as the current selected one
    @param aSender the sender of the action
*/
- (IBAction)setAvatar:(id)aSender
{
    [self setAvatarImage:[aSender image] withName:[aSender title]];
}


#pragma mark -
#pragma mark XMPP

/*! set the avatar
    @param anAvatarImage a CPImage image
    @param anAvatarName the name of the avatar
*/
- (void)setAvatarImage:(CPImage)anAvatarImage withName:(CPString)anAvatarName
{
    var vCard = [[TNStropheVCard alloc] init];

    [vCard setPhoto:anAvatarImage];

    [[TNStropheIMClient defaultClient] setVCard:vCard object:self selector:@selector(_didSetAvatar:image:) userInfo:anAvatarImage];
}

/*! conpute avatar setting answer
    @param aStanza the response stanza
    @param anImage the actual avatar image that will be displayed on the toolbar
*/
- (void)_didSetAvatar:(TNStropheStanza)aStanza image:(CPImage)anImage
{
    if ([aStanza type] == @"result")
    {
        [_buttonAvatar setImage:anImage];
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Avatar" message:@"Avatar has been changed"];
    }
    else
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Avatar" message:@"Unable to change the avatar" icon:TNGrowlIconError];
    }
}


#pragma mark -
#pragma mark Delegate

/*! CPURLConnection delegate
*/
- (void)connection:(CPURLConnection)connection didReceiveData:(CPString)data
{
    var cpdata = [CPData dataWithRawString:data];

    CPLog.info(@"avatars.plist recovered");

    _pListObject = [cpdata plistObject];
    [self loadAvatars];
}


@end
