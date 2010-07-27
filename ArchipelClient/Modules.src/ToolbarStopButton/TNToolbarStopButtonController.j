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
TNArchipelControlPlay                           = @"TNArchipelControlPlay";
TNArchipelControlSuspend                        = @"TNArchipelControlSuspend";
TNArchipelControlResume                         = @"TNArchipelControlResume";
TNArchipelControlStop                           = @"TNArchipelControlStop";
TNArchipelControlReboot                         = @"TNArchipelControlReboot";

/*! @defgroup  sampletoolbarmodule Module SampleToolbarModule
    
    @desc Development starting point to create a Toolbar module
*/


/*! @ingroup sampletoolbarmodule
    Sample toolbar module implementation
*/
@implementation TNToolbarStopButtonController : TNModule
{

}

- (void)willLoad
{
    [super willLoad];
    // message sent when view will be added from superview;
}

- (void)willUnload
{
    [super willUnload];
   // message sent when view will be removed from superview;
}

- (void)willShow
{
    [super willShow];
    // message sent when the tab is clicked
}

- (void)willHide
{
    [super willHide];
    // message sent when the tab is changed
}

- (IBAction)toolbarItemClicked:(id)sender
{
    var center = [CPNotificationCenter defaultCenter];
    
    CPLog.info(@"Sending TNArchipelControlNotification with command TNArchipelControlStop");
    [center postNotificationName:TNArchipelControlNotification object:self userInfo:TNArchipelControlStop];
}

@end



