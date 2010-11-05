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
@import <AppKit/AppKit.j>


TNArchipelControlNotification                   = @"TNArchipelControlNotification";
TNArchipelControlSuspend                        = @"TNArchipelControlSuspend";

/*! @defgroup  toolbarpausebutton Module Toolbar Button Pause
    @desc This module displays a toolbar item that can send pause action to the current entity
*/


/*! @ingroup toolbarpausebutton
    The module main controller
*/
@implementation TNToolbarPauseButtonController : TNModule


//#pragma mark -
//#pragma mark Actions

/*! send TNArchipelControlNotification containing command TNArchipelControlSuspend
    to a loaded VirtualMachineControl module instance
*/
- (IBAction)toolbarItemClicked:(id)aSender
{
    var center = [CPNotificationCenter defaultCenter];

    CPLog.info(@"Sending TNArchipelControlNotification with command TNArchipelControlSuspend");
    [center postNotificationName:TNArchipelControlNotification object:self userInfo:TNArchipelControlSuspend];
}

@end
