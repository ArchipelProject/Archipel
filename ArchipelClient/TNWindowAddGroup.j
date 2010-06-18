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
    @outlet CPTextField newGroupName;

    TNStropheRoster     roster          @accessors;
}

/*! overide of the orderFront
    @param sender the sender
*/
- (void)orderFront:(id)sender
{
    [newGroupName setStringValue:@""];
    [self makeFirstResponder:newGroupName];
    
    [self center];
    [super orderFront:sender];
}

/*! add a group according to the outlets
    @param sender the sender
*/
- (IBAction)addGroup:(id)sender
{
    if ([newGroupName stringValue] == "")
    {
        [CPAlert alertWithTitle:@"Group addition error" message:@"You have to enter a valid group name." style:CPCriticalAlertStyle];
    }
    else
    {
        var groupName = [newGroupName stringValue];
        
        [[self roster] addGroupWithName:groupName];
        [newGroupName setStringValue:@""];
        CPLog.info(@"new group " + groupName + " added.");
        
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Group" message:@"Group " + groupName + @" has been created"];

        [self performClose:nil];
    }
}

-(void)keyDown:(CPEvent)anEvent
{
    if ([anEvent keyCode] == CPEscapeKeyCode)
    {
        [self close];
        return;
    }
    [super keyDown:anEvent];
}

@end