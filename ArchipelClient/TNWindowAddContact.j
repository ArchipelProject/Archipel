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

@import "StropheCappuccino/TNStrophe.j";

@implementation TNWindowAddContact: CPWindow 
{
    @outlet CPPopUpButton   newContactGroup     @accessors;
    @outlet CPTextField     newContactJid       @accessors;
    @outlet CPTextField     newContactName      @accessors;
    
    TNStropheRoster roster  @accessors;    
}

- (IBAction) orderFront:(id) sender
{
    var groups = [roster groups];
    var i;
    
    [[self newContactJid] setStringValue:@""];
    [[self newContactName] setStringValue:@""];
    [[self newContactGroup] removeAllItems];
    
    var generalItem = [[CPMenuItem alloc] initWithTitle:@"General" action:nil keyEquivalent:@""]
    [[self newContactGroup] addItem:generalItem];
    
    //@each (var group in groups)
    for(var i = 0; i < [groups count]; i++)
    {
        var group = [groups objectAtIndex:i];
        
        var item = [[CPMenuItem alloc] initWithTitle:[group name] action:nil keyEquivalent:@""]
        [[self newContactGroup] addItem:item];
    }
    
    [[self newContactGroup] selectItemWithTitle:@"General"];
    [super orderFront:sender];
}

- (IBAction)addContact:(id)sender
{
    var group = [[self newContactGroup] title];

    [[self roster] addContact:[newContactJid stringValue] withName:[newContactName stringValue] inGroup:group];
    [[self roster] askAuthorizationTo:[newContactJid stringValue]];
    
    [self orderOut:nil];
    
    var msg     = @"Presence subsciption has been sent to " + [newContactJid stringValue] + ".";
    
    [CPAlert alertWithTitle:@"Subscription request sent" message:@"Subscription request sent"];
    
    [[TNViewLog sharedLogger] log:@"added contact " + [newContactJid stringValue]];
}

@end