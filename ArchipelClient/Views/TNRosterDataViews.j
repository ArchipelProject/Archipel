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
@import <AppKit/AppKit.j>


/*! @ingroup archipelcore
    Subclass of CPView that represent a entry of level two in TNOutlineViewRoster (TNStropheContact, not groups)
*/
@implementation TNRosterDataViewContact : CPView
{
    CPImageView _avatar      @accessors(property=avatar);
    CPImageView _statusIcon  @accessors(property=statusIcon);
    CPTextField _events      @accessors(property=events);
    CPTextField _name        @accessors(property=name);
    CPTextField _status      @accessors(property=status);

    CPImage     _unknownUserImage;
    CPImage     _playImage;
    CPImage     _pauseImage;
    CPImage     _normalStateCartoucheColor;
    CPImage     _selectedStateCartoucheColor;
    CPButton    _playButton;
    CPButton    _pauseButton;
    CPString    _entityType;

    TNStropheContact    _contact;
}


//#pragma mark -
//#pragma mark Initialization

/*! initialize the class
    @return a initialized instance of TNRosterDataViewContact
*/
- (id)init
{
    if (self = [super init])
    {
        var bundle = [CPBundle mainBundle];

        _statusIcon                     = [[CPImageView alloc] initWithFrame:CGRectMake(33, 1, 16, 16)];
        _name                           = [[CPTextField alloc] initWithFrame:CGRectMake(48, 2, 170, 100)];
        _status                         = [[CPTextField alloc] initWithFrame:CGRectMake(33, 18, 170, 100)];
        _events                         = [[CPTextField alloc] initWithFrame:CGRectMake(170, 10, 23, 14)];
        _avatar                         = [[CPImageView alloc] initWithFrame:CGRectMake(0, 3, 29, 29)];
        _playButton                     = [[CPButton alloc] initWithFrame:CGRectMake(150, 8, 16, 16)];
        _pauseButton                    = [[CPButton alloc] initWithFrame:CGRectMake(130, 8, 16, 16)];
        _unknownUserImage               = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"user-unknown.png"]];
        _normalStateCartoucheColor      = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"cartouche.png"]]];
        _selectedStateCartoucheColor    = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"cartouche-selected.png"]]];
        _pauseImage                     = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"vm_pause.png"] size:CGSizeMake(16, 16)];
        _playImage                      = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"vm_play.png"] size:CGSizeMake(16, 16)];

        [_pauseButton setImage:_pauseImage];
        [_pauseButton setBordered:NO];
        [_pauseButton setTarget:self];
        [_pauseButton setAction:@selector(sendPauseCommand:)];
        [_pauseButton setHidden:YES];

        [_playButton setImage:_playImage];
        [_playButton setBordered:NO];
        [_playButton setTarget:self];
        [_playButton setAction:@selector(sendPlayCommand:)];
        [_playButton setHidden:YES];

        [_events setBackgroundColor:_normalStateCartoucheColor];
        [_events setAlignment:CPCenterTextAlignment];
        [_events setVerticalAlignment:CPCenterVerticalTextAlignment];
        [_events setFont:[CPFont boldSystemFontOfSize:11]];
        [_events setTextColor:[CPColor whiteColor]];
        [_events setValue:[CPColor colorWithHexString:@"5184C9"] forThemeAttribute:@"text-color" inState:CPThemeStateSelectedDataView];
        [_events setValue:_normalStateCartoucheColor forThemeAttribute:@"bezel-color" inState:CPThemeStateNormal];
        [_events setValue:_selectedStateCartoucheColor forThemeAttribute:@"bezel-color" inState:CPThemeStateSelectedDataView];
        [_events setValue:CGInsetMake(0.0, 0.0, 0.0, 0.0) forThemeAttribute:@"content-inset"];
        [_events setValue:CGInsetMake(0.0, 0.0, 0.0, 0.0) forThemeAttribute:@"bezel-inset"];
        [_events setHidden:YES];

        [_name setValue:[CPColor colorWithHexString:@"f2f0e4"] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
        [_name setValue:[CPColor whiteColor] forThemeAttribute:@"text-color" inState:CPThemeStateSelectedDataView];
        [_name setValue:[CPFont boldSystemFontOfSize:12] forThemeAttribute:@"font" inState:CPThemeStateSelectedDataView ];

        [_status setValue:[CPColor colorWithHexString:@"f2f0e4"] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
        [_status setValue:[CPFont systemFontOfSize:9.0] forThemeAttribute:@"font" inState:CPThemeStateNormal];
        [_status setValue:[CPColor colorWithHexString:@"808080"] forThemeAttribute:@"text-color" inState:CPThemeStateNormal];
        [_status setValue:[CPColor whiteColor] forThemeAttribute:@"text-color" inState:CPThemeStateSelectedDataView];

        [self addSubview:_statusIcon];
        [self addSubview:_name];
        [self addSubview:_events];
        [self addSubview:_status];
        [self addSubview:_avatar];
        [self addSubview:_playButton];
        [self addSubview:_pauseButton];
    }
    return self;
}


//#pragma mark -
//#pragma mark Overrides

/*! Message used by CPOutlineView to set the value of the object
    @param aContact TNStropheContact to represent
*/
- (void)setObjectValue:(id)aContact
{
    _contact = aContact;

    var mainBounds          = [self bounds],
        boundsEvents        = [_events frame],
        boundsPlay          = [_playButton frame],
        boundsPause         = [_pauseButton frame];

    boundsEvents.origin.x   = mainBounds.size.width - 25;
    [_events setFrame:boundsEvents];
    [_events setAutoresizingMask:CPViewMinXMargin];

    boundsPlay.origin.x     = mainBounds.size.width - 20;
    [_playButton setFrame:boundsPlay];
    [_playButton setAutoresizingMask:CPViewMinXMargin];

    boundsPause.origin.x    = mainBounds.size.width - 36;
    [_pauseButton setFrame:boundsPause];
    [_pauseButton setAutoresizingMask:CPViewMinXMargin];

    if ([aContact XMPPShow] == TNStropheContactStatusOffline)
    {
        [_playButton setHidden:YES];
        [_pauseButton setHidden:YES];
    }

    [_name setStringValue:[aContact nickname]];
    [_name sizeToFit];

    [_status setStringValue:[aContact XMPPStatus]];
    [_status sizeToFit];

    [_statusIcon setImage:[aContact statusIcon]];

    if ([aContact avatar])
        [_avatar setImage:[aContact avatar]];
    else
        [_avatar setImage:_unknownUserImage];

    var boundsName = [_name frame];
    boundsName.size.width += 10;
    [_name setFrame:boundsName];

    var boundsShow = [_status frame];
    boundsShow.size.width += 10;
    [_status setFrame:boundsShow];

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


//#pragma mark -
//#pragma mark Theming

/*! implement theming in order to allow change color of selected item
*/
- (void)setThemeState:(id)aState
{
    [super setThemeState:aState];

    [_name setThemeState:aState];
    [_status setThemeState:aState];
    [_events setThemeState:aState];
}

/*! implement theming in order to allow change color of selected item
*/
- (void)unsetThemeState:(id)aState
{
    [super unsetThemeState:aState];

    [_name unsetThemeState:aState];
    [_status unsetThemeState:aState];
    [_events unsetThemeState:aState];
}


//#pragma mark -
//#pragma mark CPCoding compliance

/*! CPCoder compliance
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        _normalStateCartoucheColor = [aCoder decodeObjectForKey:@"_normalStateCartoucheColor"];
        _selectedStateCartoucheColor = [aCoder decodeObjectForKey:@"_selectedStateCartoucheColor"];

        _contact            = [aCoder decodeObjectForKey:@"_contact"];
        _unknownUserImage   = [aCoder decodeObjectForKey:@"_unknownUserImage"];
        _pauseButton        = [aCoder decodeObjectForKey:@"_pauseButton"];
        _playButton         = [aCoder decodeObjectForKey:@"_playButton"];
        _playImage          = [aCoder decodeObjectForKey:@"_playImage"];
        _pauseImage         = [aCoder decodeObjectForKey:@"_pauseImage"];
        _name               = [aCoder decodeObjectForKey:@"_name"];
        _status               = [aCoder decodeObjectForKey:@"_status"];
        _statusIcon         = [aCoder decodeObjectForKey:@"_statusIcon"];
        _events             = [aCoder decodeObjectForKey:@"_events"];
        _avatar             = [aCoder decodeObjectForKey:@"_avatar"];
    }

    return self;
}

/*! CPCoder compliance
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:_contact forKey:@"_contact"];
    [aCoder encodeObject:_pauseButton forKey:@"_pauseButton"];
    [aCoder encodeObject:_playButton forKey:@"_playButton"];
    [aCoder encodeObject:_pauseImage forKey:@"_pauseImage"];
    [aCoder encodeObject:_playImage forKey:@"_playImage"];
    [aCoder encodeObject:_unknownUserImage forKey:@"_unknownUserImage"];
    [aCoder encodeObject:_name forKey:@"_name"];
    [aCoder encodeObject:_status forKey:@"_status"];
    [aCoder encodeObject:_statusIcon forKey:@"_statusIcon"];
    [aCoder encodeObject:_events forKey:@"_events"];
    [aCoder encodeObject:_avatar forKey:@"_avatar"];
    [aCoder encodeObject:_normalStateCartoucheColor forKey:@"_normalStateCartoucheColor"];
    [aCoder encodeObject:_selectedStateCartoucheColor forKey:@"_selectedStateCartoucheColor"];
}

@end

/*! this is a simple subclass of CPTextField that configure itself to
    be sexy for CPOutlineView groups
*/
@implementation TNRosterDataViewGroup : CPTextField

//#pragma mark -
//#pragma mark Initialization

/*! initialize the class
    @return a initialized instance of TNRosterDataViewGroup
*/
- (id)init
{
    if (self = [super init])
    {
        [self setFont:[CPFont boldSystemFontOfSize:12]];
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
