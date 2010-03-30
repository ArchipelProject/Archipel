/*  
 * TNWindowAddGroup.j
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
    subclass of CPWindow that allows to add grou in roster
*/
@implementation TNWindowAddGroup: CPWindow 
{
    @outlet CPTextField newGroupName    @accessors;
    
    TNStropheRoster     roster          @accessors;
}

/*! overide of the orderFront
    @param sender the sender
*/
- (void)orderFront:(id)sender
{
    [[self newGroupName] setStringValue:@""];
    [self center];
    [self makeFirstResponder:[self newGroupName]];
    [super orderFront:sender];
}

/*! add a group according to the outlets
    @param sender the sender
*/
- (IBAction)addGroup:(id)sender
{   
    if ([[self newGroupName] stringValue] == "") 
    {
        [CPAlert alertWithTitle:@"Group addition error" message:@"You have to enter a valid group name." style:CPCriticalAlertStyle]; 
    }
    else 
    {
        [[self roster] addGroup:[[self newGroupName] stringValue]];
        [[self newGroupName] setStringValue:@""];
        [[TNViewLog sharedLogger] log:@"new group " + [[self newGroupName] stringValue] + " added."]
        
        [self performClose:nil];
    }
}
@end