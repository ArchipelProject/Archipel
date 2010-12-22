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
@import <AppKit/AppKit.j>

TNArchipelTypeAvatar             = @"archipel:avatar";
TNArchipelTypeAvatarGetAvatars   = @"getavatars";
TNArchipelTypeAvatarSetAvatar    = @"setavatar";

TNArchipelAvatarManagerThumbSize                = CGSizeMake(48, 48);

/*! @ingroup archipelcore
    Simple TNBase64Image subclass that add a string to get the avatar filename
*/
@implementation TNAvatarImage: TNBase64Image
{
    CPString _avatarFilename @accessors(property=avatarFilename);
}
@end


/*! @ingroup archipelcore
    Prototype of the CPCollectionView that represent an Avatar
*/
@implementation TNAvatarView : CPView
{
    CPImageView         _imageView;
    id                  _representedObject @accessors(getter=representedObject);
}

- (void)setRepresentedObject:(id)anObject
{
    if (!_imageView)
    {
        var frame = CGRectInset([self bounds], 5.0, 5.0);

        _imageView = [[CPImageView alloc] initWithFrame:frame];

        [_imageView setImageScaling:CPScaleProportionally];
        [_imageView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

        [self addSubview:_imageView];
    }
    _representedObject = anObject;
    [_imageView setImage:anObject];
}

- (void)setSelected:(BOOL)isSelected
{
    [self setBackgroundColor:isSelected ? [CPColor colorWithHexString:@"5595D1"] : nil];
}

@end


/*! @ingroup archipelcore
    Representation of Archipel entity avatar controler
*/
@implementation TNAvatarController : CPObject
{
    @outlet CPWindow            mainWindow              @accessors(readonly);
    @outlet CPCollectionView    collectionViewAvatars;
    @outlet CPImageView         imageSpinner;
    @outlet CPButton            buttonChange;

    TNStropheContact            _entity                 @accessors(property=entity);

    BOOL                        isReady;

}


#pragma mark -
#pragma mark Initialization

- (void)awakeFromCib
{
    var itemPrototype   = [[CPCollectionViewItem alloc] init],
        avatarView      = [[TNAvatarView alloc] initWithFrame:CGRectMakeZero()];

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
        var avatars = [aStanza childrenWithName:@"avatar"],
            images  = [CPArray array];

        [collectionViewAvatars setContent:[]];
        [collectionViewAvatars reloadContent];

        for (var i = 0; i < [avatars count]; i++)
        {
            var avatar  = [avatars objectAtIndex:i],
                file    = [avatar valueForAttribute:@"name"],
                ctype   = [avatar valueForAttribute:@"content-type"],
                data    = [avatar text],
                img     = [[TNAvatarImage alloc] init];

            [img setBase64EncodedData:data];
            [img setContentType:ctype];
            [img setSize:TNArchipelAvatarManagerThumbSize];
            [img setAvatarFilename:file];
            [img load];
            [images addObject:img];
        }
        [collectionViewAvatars setContent:images];
        [collectionViewAvatars reloadContent];
    }
    [imageSpinner setHidden:YES];
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
        [mainWindow close];
    }
}


#pragma mark -
#pragma mark Actions

/*! overide the super makeKeyAndOrderFront in order to getAvailableAvatars on display
    @param sender the sender of the action
*/
- (IBAction)showWindow:(id)sender
{
    [[TNPermissionsCenter defaultCenter] setControl:buttonChange segment:nil enabledAccordingToPermissions:[@"setavatars"] forEntity:_entity specialCondition:YES];

    if ([[TNPermissionsCenter defaultCenter] hasPermission:@"getavatars" forEntity:_entity])
    {
        [self getAvailableAvatars];
        [mainWindow center];
        [mainWindow makeKeyAndOrderFront:sender];
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