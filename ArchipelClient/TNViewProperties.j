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

@implementation TNViewProperties: CPView 
{
    @outlet CPImageView     entryStatusIcon @accessors;
    @outlet CPPopUpButton   groupSelector   @accessors;
    @outlet CPTextField     entryDomain     @accessors;
    @outlet CPTextField     entryName       @accessors;
    @outlet CPTextField     entryRessource  @accessors;
    @outlet CPTextField     entryStatus     @accessors;
    @outlet CPTextField     newNickName     @accessors;
    
    TNStropheRoster         roster          @accessors;
    TNStropheContact        entry           @accessors;
    CPSplitView             parentSplitView @accessors;

}

- (id)initWithFrame:(CPRect)aRect 
{
    aRect.size.height = 200;
    self = [super initWithFrame:aRect];
    
    return self;
}

- (void)awakeFromCib
{
    [self setAutoresizingMask: CPViewNotSizable];
    [self format];
    [self hide];
    //[self setBoundsOrigin:CGPointMake(0, [self frame].size.height)];
}

- (void)hide 
{
    [self setHidden:YES];
    // [self removeFromSuperview];
    //     [[self parentSplitView] setNeedsDisplay:YES];
    //     [[self parentSplitView] setNeedsLayout:YES];
    //     [[[[self parentSplitView] subviews] objectAtIndex:0] setNeedsDisplay:YES];
    //     [[[[self parentSplitView] subviews] objectAtIndex:0] setNeedsLayout:YES];
}

- (void)show 
{
    // var frame = [self frame];
    //     frame.size.height = 300;
    //     resize = [CPDictionary dictionaryWithObjectsAndKeys:self, CPViewAnimationTargetKey,frame, CPViewAnimationEndFrameKey];
    //     animation = [[CPViewAnimation alloc] initWithViewAnimations:[resize]];
    //     [animation startAnimation];
    // 
    //     [[self superview] setNeedsDisplay:YES];
    // var bounds = [[self parentSplitView] bounds];
    //     [[[[self parentSplitView] subviews] objectAtIndex:0] setBounds:bounds];
    
    [self setHidden:NO];
    //[[self parentSplitView] addSubview:self];
    //[[self parentSplitView] setNeedsDisplay:YES];
}

- (void)format
{
    [self setBackgroundColor:[CPColor colorWithHexString:@"D8DFE8"]];
    [[self entryName]  setFont:[CPFont boldSystemFontOfSize:13]];
    [[self entryName]  setTextColor:[CPColor colorWithHexString:@"8D929D"]];
    //[[self entryDomain] setTextColor:[CPColor colorWithHexString:@"8D929D"]];
    //[[self entryStatus] setTextColor:[CPColor colorWithHexString:@"8D929D"]];
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
    // anim = [CPViewAnimation initWithViewAnimations:[self]];
    // [anim startAnimation];
}


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