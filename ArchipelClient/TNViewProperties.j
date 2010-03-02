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
@import <AppKit/CPViewAnimation.j>

@import "StropheCappuccino/TNStrophe.j";


@implementation TNEditableLabel: CPTextField
{
    CPColor _oldColor;
}
- (void)mouseDown:(CPEvent)anEvent
{
    [self setEditable:YES];
    [self selectAll:nil];

    [super mouseDown:anEvent];
}

- (void)textDidBlur:(CPNotification)aNotification
{
    [self setEditable:NO];
    
    [super textDidBlur:aNotification];
}
@end

@implementation TNViewProperties: CPView 
{
    @outlet TNEditableLabel entryName       @accessors;
    @outlet CPPopUpButton   groupSelector   @accessors;
    @outlet CPImageView     entryStatusIcon @accessors;
    @outlet CPTextField     entryDomain     @accessors;
    @outlet CPTextField     entryResource   @accessors;
    @outlet CPTextField     newNickName     @accessors;
    
    TNStropheRoster         roster          @accessors;
    TNStropheContact        contact         @accessors;

    CPNumber                _height;
}

- (id)initWithFrame:(CPRect)aRect 
{
    _height = 180;
    
    aRect.size.height = _height;
    self = [super initWithFrame:aRect];
    
    return self;
}

- (void)awakeFromCib
{
    [self setAutoresizingMask: CPViewNotSizable];
    
    [self setBackgroundColor:[CPColor colorWithHexString:@"D8DFE8"]];
    [[self entryName] setFont:[CPFont boldSystemFontOfSize:13]];
    [[self entryName] setTextColor:[CPColor colorWithHexString:@"8D929D"]];
    
    var center = [CPNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(didGroupAdded:) name:TNStropheRosterAddedGroupNotification object:nil];
    
    [self setHidden:YES];
    
    [[self entryName] setTarget:self];
    [[self entryName] setAction:@selector(changeNickName:)];
    
    [center addObserver:self selector:@selector(didLabelEntryNameBlur:) name:CPTextFieldDidBlurNotification object:[self entryName]];
}

- (void)didGroupAdded:(CPNotification)aNotification
{
    if (![self isHidden])
        [self reload];
}

- (void)hide 
{
    var splitView = [self superview];

    [self setHidden:YES];
    [splitView setPosition:[splitView bounds].size.height ofDividerAtIndex:0];
}

- (void)show 
{
    var splitView = [self superview];
    
    [self setHidden:NO];
    [splitView setPosition:([splitView bounds].size.height - _height) ofDividerAtIndex:0];
}

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
    
    [[self groupSelector] removeAllItems];
    
    var groups = [roster groups];
    
    //@each (group in groups)
    for(var i = 0; i < [groups count]; i++)
    {
        var group = [groups objectAtIndex:i];

        var item = [[CPMenuItem alloc] initWithTitle:[group name] action:@selector(changeGroup:) keyEquivalent:@""]
        [item setTarget:self];
        [[self groupSelector] addItem:item];
    }
    
    [[self groupSelector] selectItemWithTitle:[contact group]];
}

// Actions
- (IBAction)changeGroup:(id)sender
{
    var theGroup = [sender title]
    var theJid = [contact jid];
    [[self roster] changeGroup:theGroup forJID:theJid];
    [[self groupSelector] selectItemWithTitle:theGroup];
    
    [[TNViewLog sharedLogger] log:@"new group for contact " + theJid + " : " + theGroup];
}


- (void)didLabelEntryNameBlur:(CPNotification)aNotification
{
    [self doChangeNickName];
}

- (IBAction)changeNickName:(id)sender
{
    [sender _inputElement].blur();
}

- (void)doChangeNickName
{
    var theJid = [contact jid];
    var theName = [[self entryName] stringValue];
    
    [[self roster] changeNickname:theName forJID:theJid];
    [[self entryName] setStringValue:theName];
    
    [[TNViewLog sharedLogger] log:@"new nickname for contact " + theJid + " : " + theName];
}

@end