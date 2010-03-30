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
    @outlet CPTextField     entryDomain     @accessors;
    @outlet CPTextField     entryResource   @accessors;
    @outlet CPTextField     newNickName     @accessors;
    
    TNStropheRoster         roster          @accessors;
    TNStropheContact        contact         @accessors;

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
    [[self entryName] setFont:[CPFont boldSystemFontOfSize:13]];
    [[self entryName] setTextColor:[CPColor colorWithHexString:@"8D929D"]];
    
    [self setHidden:YES];
    
    [[self entryName] setTarget:self];
    [[self entryName] setAction:@selector(changeNickName:)];
    
    var center = [CPNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(_didLabelEntryNameBlur:) name:CPTextFieldDidBlurNotification object:[self entryName]];
    [center addObserver:self selector:@selector(_didContactUpdatePresence:) name:TNStropheContactPresenceUpdatedNotification object:nil];
}

/*! hide the panel
*/
- (void)hide 
{
    var splitView = [self superview];

    [self setHidden:YES];
    [splitView setPosition:[splitView bounds].size.height ofDividerAtIndex:0];
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
    if ((![self contact]) || ([[self contact] type] == "group"))
    {
        [self hide];
        return;
    }
    [self show];
    
    [[self entryName] setStringValue:[contact nickname]];
    [[self entryDomain] setStringValue:[contact domain]];
    [[self entryResource] setStringValue:[contact resource]];
    [[self entryStatusIcon] setImage:[contact statusIcon]];
}

/*! message performed when contact update its presence in order to update information
*/
- (void)_didContactUpdatePresence:(CPNotification)aNotification
{
    [[self entryStatusIcon] setImage:[contact statusIcon]];
    [[self entryResource] setStringValue:[contact resource]];
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
    var theJid = [contact jid];
    var theName = [[self entryName] stringValue];
    
    [[self roster] changeNickname:theName forJID:theJid];
    [[self entryName] setStringValue:theName];
    
    [[TNViewLog sharedLogger] log:@"new nickname for contact " + theJid + " : " + theName];
}

@end