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


/*! @defgroup  sampletoolbarmodule Module SampleToolbarModule
    @desc Development starting point to create a Toolbar module
*/


/*! @ingroup sampletoolbarmodule
    Sample toolbar module implementation

    Please respect the pragma marks as musch as possible.
*/
@implementation TNSampleToolbarModuleController : TNModule
{

}

//#pragma mark -
//#pragma mark Initialization

// put your initializations here


//#pragma mark -
//#pragma mark TNModule overrides

/*! this message is called when module is loaded
*/
- (void)willLoad
{
    [super willLoad];
}

/*! this message is called when module is unloaded
*/
- (void)willUnload
{
    [super willUnload];
   // message sent when view will be removed from superview;
}

/*! this message is called when module becomes visible
*/
- (void)willShow
{
    [super willShow];
    // message sent when the tab is clicked
}

/*! this message is called when module becomes unvisible
*/
- (void)willHide
{
    [super willHide];
    // message sent when the tab is changed
}

//#pragma mark -
//#pragma mark Notification handlers

// put your notification handlers here


//#pragma mark -
//#pragma mark Utilities

// put your utilities here


//#pragma mark -
//#pragma mark Actions

// put your IBAction here


//#pragma mark -
//#pragma mark XMPP Controls

// put your IBActions here


//#pragma mark -
//#pragma mark Delegates

// put your delegates here

@end



