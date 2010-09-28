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


@implementation TNAvatarImage: TNBase64Image
{
    CPString _avatarFilename @accessors(property=avatarFilename);
}
@end

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

@implementation TNAvatarManager : CPWindow
{
    @outlet CPCollectionView    collectionViewAvatars;
    @outlet CPImageView         imageSpinner;

    BOOL                        isReady;
    TNStropheContact            _entity @accessors(property=entity);
}

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
}

- (void)getAvailableAvatars
{
    var stanza = [TNStropheStanza iqWithType:@"get"];

    [imageSpinner setHidden:NO];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeAvatar}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeAvatarGetAvatars}];

    [_entity sendStanza:stanza andRegisterSelector:@selector(didReceivedAvailableAvatars:) ofObject:self];
}

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

- (void)didSetAvatar:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        CPLog.info("Avatar changed for entity " + [_entity JID]);
        [self close];
    }
}

- (IBAction)makeKeyAndOrderFront:(id)sender
{
    [self getAvailableAvatars];
    [super makeKeyAndOrderFront:sender];
}

- (void)collectionView:(CPCollectionView)collectionView didDoubleClickOnItemAtIndex:(int)index
{
    [self setAvatar:nil];
}
@end