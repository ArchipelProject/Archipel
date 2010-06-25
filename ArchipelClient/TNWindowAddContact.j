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
    @outlet CPPopUpButton   newContactGroup;
    @outlet CPTextField     newContactJID;
    @outlet CPTextField     newContactName;

    TNStropheRoster         _roster         @accessors(property=roster);
}

/*! overide of the orderFront
    @param sender the sender
*/
- (IBAction)orderFront:(id)sender
{
    var groups = [_roster groups];
    var i;

    [newContactJID setStringValue:@""];
    [newContactName setStringValue:@""];
    [newContactGroup removeAllItems];
    //[self makeFirstResponder:newContactJID];

    if (![_roster containsGroup:@"General"])
    {
        [newContactGroup addItemWithTitle:@"General"];
    }

    //@each (var group in groups)
    for(var i = 0; i < [groups count]; i++)
    {
        var group   = [groups objectAtIndex:i];        
        [newContactGroup addItemWithTitle:[group name]];
    }

    [newContactGroup selectItemWithTitle:@"General"];

    [self center];

    [super orderFront:sender];
}

/*! add a contact according to the values of the outlets
    @param sender the sender
*/
- (IBAction)addContact:(id)sender
{
    var group   = [newContactGroup title];
    var JID     = [[newContactJID stringValue] lowercaseString];
    var name    = [newContactName stringValue];
    var growl   = [TNGrowlCenter defaultCenter];
    
    if (name == "")
        name = [[JID componentsSeparatedByString:@"@"] objectAtIndex:0];
    
    [_roster addContact:JID withName:name inGroupWithName:group];
    [_roster askAuthorizationTo:JID];
    [_roster authorizeJID:JID];

    [self performClose:nil];

    var msg     = @"Presence subsciption has been sent to " + JID + ".";
    
    CPLog.info(@"added contact " + JID);
    
    
    [growl pushNotificationWithTitle:@"Contact" message:@"Contact " + JID + @" has been added"];
}

@end