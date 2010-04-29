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
@import <StropheCappuccino/StropheCappuccino.j>

/*! @ingroup archipelcore
    subclass of CPWindow that allows to add a TNStropheContact
*/
@implementation TNWindowAddContact: CPWindow
{
    @outlet CPPopUpButton   newContactGroup     @accessors;
    @outlet CPTextField     newContactJid       @accessors;
    @outlet CPTextField     newContactName      @accessors;

    TNStropheRoster         roster              @accessors;
}

/*! overide of the orderFront
    @param sender the sender
*/
- (IBAction) orderFront:(id)sender
{
    var groups = [roster groups];
    var i;

    [[self newContactJid] setStringValue:@""];
    [[self newContactName] setStringValue:@""];
    [[self newContactGroup] removeAllItems];
    [self makeFirstResponder:[self newContactJid]];

    if (![[self roster] doesRosterContainsGroup:@"General"])
    {
        var generalItem = [[CPMenuItem alloc] initWithTitle:@"General" action:nil keyEquivalent:@""];
        [[self newContactGroup] addItem:generalItem];
    }

    //@each (var group in groups)
    for(var i = 0; i < [groups count]; i++)
    {
        var group = [groups objectAtIndex:i];

        var item = [[CPMenuItem alloc] initWithTitle:[group name] action:nil keyEquivalent:@""]
        [[self newContactGroup] addItem:item];
    }

    [[self newContactGroup] selectItemWithTitle:@"General"];

    [self center];

    [super orderFront:sender];
}

/*! add a contact according to the values of the outlets
    @param sender the sender
*/
- (IBAction)addContact:(id)sender
{
    var group   = [[self newContactGroup] title];
    var jid     = [[newContactJid stringValue] lowercaseString];
    var name    = [newContactName stringValue];

    [[self roster] addContact:jid withName:name inGroup:group];
    [[self roster] askAuthorizationTo:jid];
    [[self roster] authorizeJID:jid];

    [self performClose:nil];

    var msg     = @"Presence subsciption has been sent to " + jid + ".";
    
    CPLog.info(@"added contact " + jid);
    
    var growl = [TNGrowlCenter defaultCenter];
    [growl pushNotificationWithTitle:@"Contact" message:@"Contact " + jid + @" has been added"];
}

@end