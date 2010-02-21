/*  
 * TNAlertRemoveContact.j
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


@implementation TNAlertRemoveContact: CPAlert 
{
    CPString        jid     @accessors;
    TNStropheRoster roster  @accessors;
}

- (id)initWithJid:(id)aJid roster:(TNStropheRoster)aRoster 
{
    if (self = [super init])
    {
        if (aJid == nil)
            return nil;

        [self setJid:aJid];
        [self setRoster:aRoster];
        [self setDelegate:self];

        var msg = "Are you sure you want to remove " + aJid + " ?";
        [self setTitle:@"Remove entity"];
        [self setMessageText:msg];
        [self setWindowStyle:CPHUDBackgroundWindowMask];
        [self setAlertStyle:CPInformationalAlertStyle];
        [self addButtonWithTitle:@"Yes"];
        [self addButtonWithTitle:@"No"];
    }
    
    return self;
}

- (void)alertDidEnd:(CPAlert)theAlert returnCode:(int)returnCode 
{
    if (returnCode == 0)
    {
        [[self roster] removeContact:[self jid]];
    }
}

@end