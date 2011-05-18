/*
 * TNOutlineTableColumn.j
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

@import <AppKit/CPImage.j>
@import <AppKit/CPImageView.j>
@import <AppKit/CPTextField.j>

@import <StropheCappuccino/TNStropheContact.j>
@import <TNKit/TNAttachedWindow.j>

/*! @ingroup archipelcore
    Subclass of CPView that represent a entry of level two in TNOutlineViewRoster (TNStropheContact, not groups)
*/
@implementation TNRosterDataViewContact : CPView
{
    CPImageView         _avatar         @accessors(property=avatar);
    CPImageView         _statusIcon     @accessors(property=statusIcon);
    CPTextField         _events         @accessors(property=events);
    CPTextField         _name           @accessors(property=name);
    CPTextField         _status         @accessors(property=status);

    CPButton            _buttonAction;
    CPImage             _unknownUserImage;
    CPImage             _normalStateCartoucheColor;
    CPImage             _selectedStateCartoucheColor;
    CPString            _entityType;
    BOOL                _shouldDisplayAvatar;
    TNStropheContact    _contact;
    TNAttachedWindow    _quickActionWindow;
}


#pragma mark -
#pragma mark Initialization

/*! initialize the class
    @return a initialized instance of TNRosterDataViewContact
*/
- (id)initWithFrame:(CPRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        var bundle                  = [CPBundle mainBundle],
            rosterLayout            = [bundle objectForInfoDictionaryKey:@"TNArchipelRosterLayout"],
            contactFontSizeName     = [rosterLayout objectForKey:@"TNRosterDataViewContactFontSizeName"],
            contactFontSizeStatus   = [rosterLayout objectForKey:@"TNRosterDataViewContactFontSizeStatus"],
            contactPlacementOffset  = [rosterLayout objectForKey:@"TNRosterDataViewContactPlacementOffset"],
            contactImageSizeAvatar  = CPSizeMake([[rosterLayout objectForKey:@"TNRosterDataViewContactImageSizeAvatar"] objectForKey:@"width"],
                                                 [[rosterLayout objectForKey:@"TNRosterDataViewContactImageSizeAvatar"] objectForKey:@"height"]),
            contactImageSizeStatus  = CPSizeMake([[rosterLayout objectForKey:@"TNRosterDataViewContactImageSizeStatus"] objectForKey:@"width"],
                                                 [[rosterLayout objectForKey:@"TNRosterDataViewContactImageSizeStatus"] objectForKey:@"height"]);

        _shouldDisplayAvatar            = !![rosterLayout objectForKey:@"TNOutlineViewRosterDisplayAvatar"],
        _statusIcon                     = [[CPImageView alloc] initWithFrame:CGRectMake(33 + contactPlacementOffset, 1, 16, 16)];
        _name                           = [[CPTextField alloc] initWithFrame:CGRectMake(48 + contactPlacementOffset, 3, 170, 100)];
        _status                         = [[CPTextField alloc] initWithFrame:CGRectMake(33 + contactPlacementOffset, 18, 170, 100)];
        _events                         = [[CPTextField alloc] initWithFrame:CGRectMake(CPRectGetMaxX(aFrame) - 25, 10, 23, 14)];
        _unknownUserImage               = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"user-unknown.png"]];
        _normalStateCartoucheColor      = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"cartouche.png"]]];
        _selectedStateCartoucheColor    = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"cartouche-selected.png"]]];

        if (_shouldDisplayAvatar)
            _avatar = [[CPImageView alloc] initWithFrame:CGRectMake(0, 3, 29, 29)];
            [_avatar setFrameSize:contactImageSizeAvatar];

        [_events setBackgroundColor:_normalStateCartoucheColor];
        [_events setAlignment:CPCenterTextAlignment];
        [_events setAutoresizingMask:CPViewMinXMargin];
        [_events setVerticalAlignment:CPCenterVerticalTextAlignment];
        [_events setFont:[CPFont systemFontOfSize:11]];
        [_events setTextColor:[CPColor whiteColor]];
        [_events setValue:[CPColor colorWithHexString:@"5184C9"] forThemeAttribute:@"text-color" inState:CPThemeStateSelectedDataView];
        [_events setValue:_normalStateCartoucheColor forThemeAttribute:@"bezel-color" inState:CPThemeStateNormal];
        [_events setValue:_selectedStateCartoucheColor forThemeAttribute:@"bezel-color" inState:CPThemeStateSelectedDataView];
        [_events setValue:CGInsetMake(0.0, 0.0, 0.0, 0.0) forThemeAttribute:@"content-inset"];
        [_events setValue:CGInsetMake(0.0, 0.0, 0.0, 0.0) forThemeAttribute:@"bezel-inset"];
        [_events setHidden:YES];

        [_name setFont:[CPFont systemFontOfSize:contactFontSizeName]];
        [_name setValue:[CPColor colorWithHexString:@"f2f0e4"] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
        [_name setValue:[CPColor whiteColor] forThemeAttribute:@"text-color" inState:CPThemeStateSelectedDataView];
        [_name setValue:[CPFont boldSystemFontOfSize:contactFontSizeName] forThemeAttribute:@"font" inState:CPThemeStateSelectedDataView ];

        [_status setFont:[CPFont systemFontOfSize:contactFontSizeStatus]];
        [_status setValue:[CPColor colorWithHexString:@"f2f0e4"] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
        [_status setValue:[CPFont systemFontOfSize:9.0] forThemeAttribute:@"font" inState:CPThemeStateNormal];
        [_status setValue:[CPColor colorWithHexString:@"808080"] forThemeAttribute:@"text-color" inState:CPThemeStateNormal];
        [_status setValue:[CPColor whiteColor] forThemeAttribute:@"text-color" inState:CPThemeStateSelectedDataView];

        var actionImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"quickaction.png"] size:CPSizeMake(14.0, 14.0)],
            actionImagePressed = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"quickaction-pressed.png"] size:CPSizeMake(14.0, 14.0)];

        _buttonAction = [[CPButton alloc] initWithFrame:CPRectMake(CPRectGetMaxX(aFrame) - 24, CPRectGetMidY(aFrame) - 18, 16, 16)];
        [_buttonAction setAutoresizingMask:CPViewMinXMargin];
        [_buttonAction setBordered:NO];
        [_buttonAction setImage:actionImage];
        [_buttonAction setValue:actionImage forThemeAttribute:@"image"];
        [_buttonAction setValue:actionImagePressed forThemeAttribute:@"image" inState:CPThemeStateHighlighted];
        [_buttonAction setHidden:YES];
        [_buttonAction setTarget:self];
        [_buttonAction setAction:@selector(openQuickActionWindow:)];

        [self addSubview:_statusIcon];
        [self addSubview:_name];
        [self addSubview:_events];
        [self addSubview:_status];
        [self addSubview:_buttonAction];

        if (_shouldDisplayAvatar)
            [self addSubview:_avatar];
    }
    return self;
}


#pragma mark -
#pragma mark Overrides

/*! Message used by CPOutlineView to set the value of the object
    @param aContact TNStropheContact to represent
*/
- (void)setObjectValue:(id)aContact
{
    if (!aContact)
        return;

    _contact = aContact;

    [_name setStringValue:[aContact nickname]];
    [_name sizeToFit];
    [_status setStringValue:[aContact XMPPStatus]];
    [_status sizeToFit];

    var boundsName = [_name frame];
    boundsName.size.width += 10;
    [_name setFrame:boundsName];

    var boundsShow = [_status frame];
    boundsShow.size.width += 10;
    [_status setFrame:boundsShow];

    [_statusIcon setImage:[aContact statusIcon]];

    if (_shouldDisplayAvatar)
    {
        if ([aContact avatar])
            [_avatar setImage:[aContact avatar]];
        else
            [_avatar setImage:_unknownUserImage];
    }

    if ([aContact numberOfEvents] > 0)
    {
        [_events setHidden:NO];
        [_events setStringValue:[aContact numberOfEvents]];
    }
    else
    {
        [_events setHidden:YES];
    }
}


#pragma mark -
#pragma mark Theming

/*! implement theming in order to allow change color of selected item
*/
- (void)setThemeState:(id)aState
{
    [super setThemeState:aState];

    [_name setThemeState:aState];
    [_status setThemeState:aState];
    [_events setThemeState:aState];

    if ((aState == CPThemeStateSelectedDataView) && [[[TNStropheIMClient defaultClient] roster] analyseVCard:[_contact vCard]] != TNArchipelEntityTypeUser)
        [_buttonAction setHidden:NO];
}

/*! implement theming in order to allow change color of selected item
*/
- (void)unsetThemeState:(id)aState
{
    [super unsetThemeState:aState];

    [_name unsetThemeState:aState];
    [_status unsetThemeState:aState];
    [_events unsetThemeState:aState];

    if (aState == CPThemeStateSelectedDataView)
    {
        [_buttonAction setHidden:YES];
        [_quickActionWindow close:nil];
    }
}


#pragma mark -
#pragma mark Actions

/*! open the quick action view
    @param aSender the sender of the actiob
*/
- (void)openQuickActionWindow:(id)aSender
{
    if (!_quickActionWindow)
    {
        _quickActionWindow  = [[TNAttachedWindow alloc] initWithContentRect:CPRectMake(0.0, 0.0, 250, 150) styleMask:TNAttachedBlackWindowMask | CPClosableWindowMask];
        var label = [CPTextField labelWithTitle:@"I'm sure you wanna know\nwhat's this, right?"];

        [label setFont:[CPFont boldSystemFontOfSize:11.0]];
        [label sizeToFit];
        [label setFrameOrigin:CPPointMake(60, 60)];
        [label setTextColor:[CPColor whiteColor]];
        [[_quickActionWindow contentView] addSubview:label];
        [_quickActionWindow setAlphaValue:0.95];
    }

    [_quickActionWindow positionRelativeToView:self gravity:TNAttachedWindowGravityRight];
}


#pragma mark -
#pragma mark CPCoding compliance

/*! CPCoder compliance
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        _normalStateCartoucheColor = [aCoder decodeObjectForKey:@"_normalStateCartoucheColor"];
        _selectedStateCartoucheColor = [aCoder decodeObjectForKey:@"_selectedStateCartoucheColor"];

        _shouldDisplayAvatar    = [aCoder decodeObjectForKey:@"_shouldDisplayAvatar"];
        _contact                = [aCoder decodeObjectForKey:@"_contact"];
        _unknownUserImage       = [aCoder decodeObjectForKey:@"_unknownUserImage"];
        _name                   = [aCoder decodeObjectForKey:@"_name"];
        _status                 = [aCoder decodeObjectForKey:@"_status"];
        _statusIcon             = [aCoder decodeObjectForKey:@"_statusIcon"];
        _events                 = [aCoder decodeObjectForKey:@"_events"];
        _avatar                 = [aCoder decodeObjectForKey:@"_avatar"];
        _buttonAction           = [aCoder decodeObjectForKey:@"_buttonAction"];
    }

    return self;
}

/*! CPCoder compliance
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:_shouldDisplayAvatar forKey:@"_shouldDisplayAvatar"];
    [aCoder encodeObject:_contact forKey:@"_contact"];
    [aCoder encodeObject:_unknownUserImage forKey:@"_unknownUserImage"];
    [aCoder encodeObject:_name forKey:@"_name"];
    [aCoder encodeObject:_status forKey:@"_status"];
    [aCoder encodeObject:_statusIcon forKey:@"_statusIcon"];
    [aCoder encodeObject:_events forKey:@"_events"];
    [aCoder encodeObject:_avatar forKey:@"_avatar"];
    [aCoder encodeObject:_normalStateCartoucheColor forKey:@"_normalStateCartoucheColor"];
    [aCoder encodeObject:_selectedStateCartoucheColor forKey:@"_selectedStateCartoucheColor"];
    [aCoder encodeObject:_buttonAction forKey:@"_buttonAction"];
}

@end

/*! this is a simple subclass of CPTextField that configure itself to
    be sexy for CPOutlineView groups
*/
@implementation TNRosterDataViewGroup : CPTextField

#pragma mark -
#pragma mark Initialization

/*! initialize the class
    @return a initialized instance of TNRosterDataViewGroup
*/
- (id)init
{
    if (self = [super init])
    {
        var rosterLayout            = [[CPBundle mainBundle] objectForInfoDictionaryKey:@"TNArchipelRosterLayout"],
            contactFontSizeGroup    = [rosterLayout objectForKey:@"TNRosterDataViewContactFontSizeGroup"];

        [self setFont:[CPFont boldSystemFontOfSize:contactFontSizeGroup]];
        [self setTextColor:[CPColor colorWithHexString:@"5F676F"]];
        [self setValue:[CPColor whiteColor] forThemeAttribute:@"text-color" inState:CPThemeStateSelectedDataView];
        [self setValue:[CPFont boldSystemFontOfSize:12] forThemeAttribute:@"font" inState:CPThemeStateSelectedDataView];
        [self setAutoresizingMask: CPViewWidthSizable];
        [self setTextShadowOffset:CGSizeMake(0.0, 1.0)];
        [self setValue:[CPColor colorWithHexString:@"f4f4f4"] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
        [self setValue:[CPColor colorWithHexString:@"7485a0"] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateSelectedDataView];
        [self setVerticalAlignment:CPCenterVerticalTextAlignment];
    }

    return self;
}

@end
