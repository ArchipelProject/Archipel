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

@implementation TNViewProperties: CPView 
{
    @outlet CPPopUpButton   groupSelector   @accessors;
    @outlet CPImageView     entryStatusIcon @accessors;
    @outlet CPTextField     entryDomain     @accessors;
    @outlet CPTextField     entryName       @accessors;
    @outlet CPTextField     entryRessource  @accessors;
    @outlet CPTextField     entryStatus     @accessors;
    @outlet CPTextField     newNickName     @accessors;
    
    TNStropheRoster         roster          @accessors;
    TNStropheContact        entry           @accessors;

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
    [[self entryName]  setFont:[CPFont boldSystemFontOfSize:13]];
    [[self entryName]  setTextColor:[CPColor colorWithHexString:@"8D929D"]];
    
    [self setHidden:YES];
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
    if ((![self entry]) || ([[self entry] type] == "group"))
    {
        [self hide];
        return;
    }
    [self show];
    
    [[self entryName] setStringValue:[entry nickname]];
    [[self entryDomain] setStringValue:[entry domain]];
    [[self entryRessource] setStringValue:[entry resource]];
    [[self entryStatusIcon] setImage:[entry statusIcon]];
    [[self entryStatus] setStringValue:[entry status]];
    
    [[self groupSelector] removeAllItems];
    
    var groups = [roster groups];
    @each (group in groups)
    {
        var item = [[CPMenuItem alloc] initWithTitle:[group name] action:@selector(changeGroup:) keyEquivalent:@""]
        [item setTarget:self];
        [[self groupSelector] addItem:item];
    }
    
    [[self groupSelector] selectItemWithTitle:[entry group]];
}



// Actions
- (IBAction)changeGroup:(id)sender
{
    var theGroup = [sender title]
    var theJid = [entry jid];
    [[self roster] changeGroup:theGroup forJID:theJid];
    [[self groupSelector] selectItemWithTitle:theGroup];
}

- (IBAction)changeNickName:(id)sender
{
    var theJid = [entry jid];
    var theName = [sender stringValue];
    [sender setStringValue:@""];
    [[self roster] changeNickname:theName forJID:theJid];
    [[self entryName] setStringValue:theName];
}
@end