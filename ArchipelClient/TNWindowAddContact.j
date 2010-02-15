/*  
 * TNWindowAddContact.j
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

@implementation TNWindowAddContact: CPWindow 
{
    @outlet CPPopUpButton   newContactGroup;
    @outlet CPTextField     newContactJid;
    @outlet CPTextField     newContactName;
    @outlet CPTextField     newContactNewGroup;
    
    CPString        group   @accessors;
    TNStropheRoster roster  @accessors;    
}

- (void)awakeFromCib
{
   group = [[CPString alloc] init];
}

- (IBAction)selectGroup:(id)sender
{
    //console.log("group set to " + [sender title]);
    [self setGroup:[sender title]];
}

- (IBAction) orderFront:(id) sender
{
    var groups = [roster groups];
    var i;
    
    [self setGroup:@"General"];
    [[self newContactGroup] removeAllItems];
   
    for (i = 0; i < [groups count]; i++)
    {
       var item = [[CPMenuItem alloc] initWithTitle:[[groups objectAtIndex:i] name] action:@selector(selectGroup:) keyEquivalent:@""]
       [item setTarget:self];
       [[self newContactGroup] addItem:item];
    }
    [[self newContactGroup] selectItemWithTitle:group];

    [super orderFront:sender];
}

- (IBAction)addContact:(id)sender
{
    [[self roster] addContact:[newContactJid stringValue] withName:[newContactName stringValue] inGroup:[self group]];
    [[self roster] askAuthorizationTo:[newContactJid stringValue]];
    
    [self orderOut:nil];
    
    var msg     = @"Presence subsciption has been sent to " + [newContactJid stringValue] + ".";
    var alert   = [[CPAlert alloc] init];
    
    [alert setDelegate:self];
    [alert setTitle:@"Subscription request sent"];
    [alert setMessageText:msg];
    [alert setWindowStyle:CPHUDBackgroundWindowMask];
    [alert addButtonWithTitle:@"Ok"];
    [alert runModal];
}

@end