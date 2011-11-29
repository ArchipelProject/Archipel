/*
 * TNSampleToolbarModule.j
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

@import <TNKit/TNToolbar.j>

var TNArchipelControlNotification   = @"TNArchipelControlNotification",
    TNArchipelControlDestroy        = @"TNArchipelControlDestroy";

/*! @defgroup  toolbardestroybutton Module Toolbar Button Destroy
    @desc This module displays a toolbar item that can send destroy action to the current entity
*/


/*! @ingroup toolbardestroybutton
    The module main controller
*/
@implementation TNToolbarDestroyButtonController : TNModule

#pragma mark -
#pragma mark Intialization

- (BOOL)willLoad
{
    if (![super willLoad])
        return NO;

    [[self UIItem] setEnabled:NO];

    return YES;
}


#pragma mark -
#pragma mark Notification handlers

- (void)setGUIAccordingToStatus:(CPNotification)aNotification
{
    switch ([_entity XMPPShow])
    {
        case TNStropheContactStatusOnline:
            [[self UIItem] setEnabled:YES];
            break;
        case TNStropheContactStatusAway:
            [[self UIItem] setEnabled:YES];
            break;
        default:
            [[self UIItem] setEnabled:NO];
   }
}


#pragma mark -
#pragma mark Overrides

- (void)setEntity:(TNStropheContact)anEntity
{
    [super setEntity:anEntity];

    [[CPNotificationCenter defaultCenter] removeObserver:self];
    if ([[[TNStropheIMClient defaultClient] roster] analyseVCard:[anEntity vCard]] !== TNArchipelEntityTypeVirtualMachine)
    {
        [[self UIItem] setEnabled:NO];
        return;
    }
    [self setGUIAccordingToStatus:nil];

    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(setGUIAccordingToStatus:) name:TNStropheContactPresenceUpdatedNotification object:_entity];
}


#pragma mark -
#pragma mark Actions

/*! send TNArchipelControlNotification containing command TNArchipelControlDestroy
    to a loaded VirtualMachineControl module instance
*/
- (IBAction)toolbarItemClicked:(id)aSender
{
    var center = [CPNotificationCenter defaultCenter];

    CPLog.info(@"Sending TNArchipelControlNotification with command TNArchipelControlDestroy");
    [center postNotificationName:TNArchipelControlNotification object:self userInfo:TNArchipelControlDestroy];
}

@end



