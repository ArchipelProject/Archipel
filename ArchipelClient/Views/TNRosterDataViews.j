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


var TNRosterDataViewContactImageUnknownUser,
    TNRosterDataViewContactImageSelectedCartoucheColor,
    TNRosterDataViewContactImageNormalCartoucheColor;


@implementation TNNoAvatarValueTransformer: CPValueTransformer

+ (void)initialize
{
    var bundle  = [CPBundle mainBundle];

    TNRosterDataViewContactImageUnknownUser = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"user-unknown.png"]];
}

+ (Class)transformedValueClass
{
    return [CPImage class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value
{
    return !value ? TNRosterDataViewContactImageUnknownUser : value;
}
@end


/*! @ingroup archipelcore
    Subclass of CPView that represent a entry of level two in TNOutlineViewRoster (TNStropheContact, not groups)
*/
@implementation TNRosterDataViewContact : CPView
{
    @outlet     CPImageView         avatar         @accessors;
    @outlet     CPImageView         statusIcon     @accessors;
    @outlet     CPTextField         events         @accessors;
    @outlet     CPTextField         name           @accessors;
    @outlet     CPTextField         status         @accessors;

    TNStropheContact                _contact;
}


#pragma mark -
#pragma mark Initialization

+ (void)initialize
{
    var bundle  = [CPBundle mainBundle];

    TNRosterDataViewContactImageNormalCartoucheColor = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"cartouche.png"]]];
    TNRosterDataViewContactImageSelectedCartoucheColor = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"cartouche-selected.png"]]];

    [CPValueTransformer setValueTransformer:[[TNNoAvatarValueTransformer alloc] init] forName:@"TNNoAvatarValueTransformer"];
}

/*! initialize the custom theme
*/
- (void)_initTheme
{
    [events setBackgroundColor:TNRosterDataViewContactImageNormalCartoucheColor];
    [events setVerticalAlignment:CPCenterVerticalTextAlignment];
    [events setValue:[CPColor colorWithHexString:@"5184C9"] forThemeAttribute:@"text-color" inState:CPThemeStateSelectedDataView];
    [events setValue:TNRosterDataViewContactImageNormalCartoucheColor forThemeAttribute:@"bezel-color" inState:CPThemeStateNormal];
    [events setValue:TNRosterDataViewContactImageSelectedCartoucheColor forThemeAttribute:@"bezel-color" inState:CPThemeStateSelectedDataView];
    [events setValue:CGInsetMake(0.0, 0.0, 0.0, 0.0) forThemeAttribute:@"content-inset"];
    [events setValue:CGInsetMake(0.0, 0.0, 0.0, 0.0) forThemeAttribute:@"bezel-inset"];
    [events setHidden:YES];

    [name setValue:[CPColor colorWithHexString:@"f4f4f4"] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
    [name setValue:CGSizeMake(0.0, 1.0) forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateNormal];
    [name setValue:[CPColor whiteColor] forThemeAttribute:@"text-color" inState:CPThemeStateSelectedDataView];
    [name setValue:CGSizeMake(0.0, .0) forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateSelectedDataView];

    [status setValue:[CPColor colorWithHexString:@"f4f4f4"] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
    [status setValue:CGSizeMake(0.0, 1.0) forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateNormal];
    [status setValue:[CPColor colorWithHexString:@"808080"] forThemeAttribute:@"text-color" inState:CPThemeStateNormal];
    [status setValue:[CPColor whiteColor] forThemeAttribute:@"text-color" inState:CPThemeStateSelectedDataView];
    [status setValue:CGSizeMake(0.0, 0.0) forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateSelectedDataView];
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

    var opts = [CPDictionary dictionaryWithObjectsAndKeys:@"TNNoAvatarValueTransformer", CPValueTransformerNameBindingOption];

    [name bind:@"objectValue" toObject:aContact withKeyPath:@"nickname" options:nil];
    [status bind:@"objectValue" toObject:aContact withKeyPath:@"XMPPStatus" options:nil];
    [statusIcon bind:@"objectValue" toObject:aContact withKeyPath:@"statusIcon" options:nil];
    [avatar bind:@"objectValue" toObject:aContact withKeyPath:@"avatar" options:opts];

    if ([aContact numberOfEvents] > 0)
    {
        [events setHidden:NO];
        [events setStringValue:[aContact numberOfEvents]];
    }
    else
    {
        [events setHidden:YES];
    }
}


#pragma mark -
#pragma mark Theming

/*! implement theming in order to allow change color of selected item
*/
- (void)setThemeState:(id)aState
{
    [super setThemeState:aState];

    [name setThemeState:aState];
    [status setThemeState:aState];
    [events setThemeState:aState];
}

/*! implement theming in order to allow change color of selected item
*/
- (void)unsetThemeState:(id)aState
{
    [super unsetThemeState:aState];

    [name unsetThemeState:aState];
    [status unsetThemeState:aState];
    [events unsetThemeState:aState];
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
        _contact    = [aCoder decodeObjectForKey:@"_contact"];
        name        = [aCoder decodeObjectForKey:@"name"];
        status      = [aCoder decodeObjectForKey:@"status"];
        statusIcon  = [aCoder decodeObjectForKey:@"statusIcon"];
        events      = [aCoder decodeObjectForKey:@"events"];
        avatar      = [aCoder decodeObjectForKey:@"avatar"];

        [self _initTheme];
    }

    return self;
}

/*! CPCoder compliance
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:_contact forKey:@"_contact"];
    [aCoder encodeObject:name forKey:@"name"];
    [aCoder encodeObject:status forKey:@"status"];
    [aCoder encodeObject:statusIcon forKey:@"statusIcon"];
    [aCoder encodeObject:events forKey:@"events"];
    [aCoder encodeObject:avatar forKey:@"avatar"];
}

@end




/*! this is a simple subclass of CPTextField that configure itself to
    be sexy for CPOutlineView groups
*/
@implementation TNRosterDataViewGroup : CPView
{
    @outlet name @accessors;
}


#pragma mark -
#pragma mark Initialization

/*! initialize the class
    @return a initialized instance of TNRosterDataViewGroup
*/
- (id)_initTheme
{
        [name setTextColor:[CPColor colorWithHexString:@"5F676F"]];
        [name setValue:[CPColor whiteColor] forThemeAttribute:@"text-color" inState:CPThemeStateSelectedDataView];
        [name setTextShadowOffset:CGSizeMake(0.0, 1.0)];
        [name setValue:[CPColor colorWithHexString:@"f4f4f4"] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
        [name setValue:[CPColor colorWithHexString:@"7485a0"] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateSelectedDataView];
        [name setVerticalAlignment:CPCenterVerticalTextAlignment];
    }

    return self;
}


#pragma mark -
#pragma mark Data View compliance

- (void)setObjectValue:(TNStropheGroup)aGroup
{
    [name bind:@"objectValue" toObject:aGroup withKeyPath:@"name" options:nil];
}


#pragma mark -
#pragma mark Theming

/*! implement theming in order to allow change color of selected item
*/
- (void)setThemeState:(id)aState
{
    [super setThemeState:aState];

    [name setThemeState:aState];
}

/*! implement theming in order to allow change color of selected item
*/
- (void)unsetThemeState:(id)aState
{
    [super unsetThemeState:aState];

    [name unsetThemeState:aState];
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
        name = [aCoder decodeObjectForKey:@"name"];
        [self _initTheme];
    }

    return self;
}

/*! CPCoder compliance
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:name forKey:@"name"];
}

@end
