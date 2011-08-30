/*
 * TNAvatarManager.j
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

@import <AppKit/CPGeometry.j>
@import <AppKit/CPButton.j>
@import <AppKit/CPCollectionView.j>
@import <AppKit/CPImageView.j>
@import <AppKit/CPView.j>


@import "../Views/TNAvatarImage.j"
@import "../Views/TNAvatarView.j"



var TNArchipelTypeAvatar                = @"archipel:avatar",
    TNArchipelTypeAvatarGetAvatars      = @"getavatars",
    TNArchipelTypeAvatarSetAvatar       = @"setavatar",
    TNArchipelAvatarManagerThumbSize    = nil;


/*! @ingroup archipelcore
    Representation of Archipel entity avatar controler
*/
@implementation TNAvatarController : CPObject
{
    @outlet CPButton            buttonCancel;
    @outlet CPButton            buttonChange;
    @outlet CPCollectionView    collectionViewAvatars;
    @outlet CPImageView         imageSpinner;
    @outlet CPPopover           mainPopover;

    TNStropheContact            _entity                 @accessors(getter=entity);

    BOOL                        _shouldRefresh;
    CPArray                     _currentAvatars;
    CPDictionary                _avatarRegistry;
    CPDictionary                _rawAvatarDataCache;
}


#pragma mark -
#pragma mark Initialization

- (void)awakeFromCib
{
    TNArchipelAvatarManagerThumbSize = CPSizeMake(48, 48);

    var itemPrototype   = [[CPCollectionViewItem alloc] init],
        avatarView      = [[TNAvatarView alloc] initWithFrame:CPRectMakeZero()];

    [imageSpinner setHidden:YES];

    _avatarRegistry = [CPDictionary dictionary];
    _rawAvatarDataCache = [CPDictionary dictionary];
    _shouldRefresh  = YES;
    _currentAvatars = [CPArray array];

    // fix
    collectionViewAvatars._minItemSize = TNArchipelAvatarManagerThumbSize;
    [collectionViewAvatars setMinItemSize:TNArchipelAvatarManagerThumbSize];
    [collectionViewAvatars setMaxItemSize:TNArchipelAvatarManagerThumbSize];
    [collectionViewAvatars setSelectable:YES];
    [collectionViewAvatars setDelegate:self];
    [[[collectionViewAvatars superview] superview] setBorderedWithHexColor:@"#a5a5a5"]; //access the Atlas generated scrollview

    [itemPrototype setView:avatarView];

    [collectionViewAvatars setItemPrototype:itemPrototype];

    [[TNPermissionsCenter defaultCenter] addDelegate:self];
}


#pragma mark -
#pragma mark Getters / Setters

- (void)setEntity:(TNStropheContact)anEntity
{
    _entity = anEntity;

    if (![_avatarRegistry containsKey:_entity])
    {
        [_avatarRegistry setObject:[CPArray array] forKey:_entity];
        _shouldRefresh = YES;
    }
}


#pragma mark -
#pragma mark Utilities

- (void)populateCollectionView
{
    [collectionViewAvatars setContent:[]];
    [collectionViewAvatars reloadContent];

    [collectionViewAvatars setContent:[_avatarRegistry objectForKey:_entity]];
    [collectionViewAvatars reloadContent];
}


#pragma mark -
#pragma mark Actions

/*! Open the main window
    @param aSender the sender of the action
*/
- (IBAction)showWindow:(id)aSender
{
    [[TNPermissionsCenter defaultCenter] setControl:buttonChange segment:nil enabledAccordingToPermissions:[@"setavatars"] forEntity:_entity specialCondition:YES];

    if ([[TNPermissionsCenter defaultCenter] hasPermission:@"getavatars" forEntity:_entity])
    {
        if (_shouldRefresh)
            [self getAvailableAvatars];
        else
            [self populateCollectionView];

        [mainPopover showRelativeToRect:nil ofView:aSender preferredEdge:nil];
        [mainPopover setDefaultButton:buttonChange];
    }
}

/*! Close the window
*/
- (IBAction)closeWindow:(id)aSender
{
    [mainPopover close];

}

#pragma mark -
#pragma mark XMPP System

/*! Ask the entity for availables avatars
*/
- (void)getAvailableAvatars
{
    var stanza = [TNStropheStanza iqWithType:@"get"];

    [imageSpinner setHidden:NO];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeAvatar}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeAvatarGetAvatars}];

    [_entity sendStanza:stanza andRegisterSelector:@selector(didReceivedAvailableAvatars:) ofObject:self];
}

/*! this message is sent on avatars reception
    @param aStanza TNStropheStanza that contains the avatars base64 encoded
*/
- (void)didReceivedAvailableAvatars:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        var avatars = [aStanza childrenWithName:@"avatar"];

        [[_avatarRegistry objectForKey:_entity] removeAllObjects];

        for (var i = 0; i < [avatars count]; i++)
        {
            var avatar      = [avatars objectAtIndex:i],
                file        = [avatar valueForAttribute:@"name"],
                ctype       = [avatar valueForAttribute:@"content-type"],
                cacheKey    = [avatar valueForAttribute:@"hash"] || data, // @TODO: remove the || data later
                data        = [avatar text],
                img         = [[TNAvatarImage alloc] init];

            if ([_rawAvatarDataCache containsKey:cacheKey])
            {
                img = [_rawAvatarDataCache objectForKey:cacheKey];
                CPLog.trace("Image with cache key " + cacheKey + "'s data are already cached. using it");
            }
            else
            {
                [img setBase64EncodedData:data];
                [img setContentType:ctype];
                [img setSize:TNArchipelAvatarManagerThumbSize];
                [img setAvatarFilename:file];
                [img load];
                [_rawAvatarDataCache setObject:img forKey:cacheKey];
            }
            [[_avatarRegistry objectForKey:_entity] addObject:img];
        }
    }
    [imageSpinner setHidden:YES];

    _shouldRefresh = NO;
    [self populateCollectionView];
}

/*! Send to the entity the avatar it should use
    It send the filename of the avatar as parameter.
    @param sender the sender of the action
*/
- (IBAction)setAvatar:(id)sender
{
    var stanza          = [TNStropheStanza iqWithType:@"set"],
        selectedIndex   = [[collectionViewAvatars selectionIndexes] firstIndex],
        selectedAvatar  = [collectionViewAvatars itemAtIndex:selectedIndex],
        filename        = [[selectedAvatar representedObject] avatarFilename];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeAvatar}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeAvatarSetAvatar,
        "avatar": filename}];

    [_entity sendStanza:stanza andRegisterSelector:@selector(didSetAvatar:) ofObject:self];
}

/*! this message is sent when entity confirm avatar changes
    @param aStanza TNStropheStanza that contains the result
*/
- (void)didSetAvatar:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        CPLog.info("Avatar changed for entity " + [_entity JID]);
        [mainPopover close];
    }
}


#pragma mark -
#pragma mark Delegates

- (void)collectionView:(CPCollectionView)collectionView didDoubleClickOnItemAtIndex:(int)index
{
    [self setAvatar:nil];
}

/*! delegate of TNPermissionsCenter
*/
- (void)permissionCenter:(TNPermissionsCenter)aCenter updatePermissionForEntity:(TNStropheContact)anEntity
{
    if (anEntity === _entity)
        [aCenter setControl:buttonChange segment:nil enabledAccordingToPermissions:[@"setavatar"] forEntity:_entity specialCondition:YES];
}

@end