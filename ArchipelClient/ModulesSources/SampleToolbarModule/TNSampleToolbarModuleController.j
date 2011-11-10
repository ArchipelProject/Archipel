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


/*! @defgroup  sampletoolbarmodule Module SampleToolbarModule
    @desc Development starting point to create a Toolbar module
*/


/*! @ingroup sampletoolbarmodule
    Sample toolbar module implementation

    Please respect the pragma marks as musch as possible.
*/
@implementation TNSampleToolbarModuleController : TNModule
{
    @outlet CPTextField fieldName;
    @outlet CPTextField fieldJID;
}

#pragma mark -
#pragma mark Initialization

// put your initializations here


#pragma mark -
#pragma mark TNModule overrides

/*! this message is called when module is loaded
*/
- (void)willLoad
{
    [super willLoad];

    var center = [CPNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(_didUpdateNickName:) name:TNStropheContactNicknameUpdatedNotification object:_entity];
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
- (BOOL)willShow
{
    if (![super willShow])
        return NO;

    [fieldName setStringValue:[_entity nickname]];
    [fieldJID setStringValue:[_entity JID]];

    return YES;
}

/*! this message is called when module becomes unvisible
*/
- (void)willHide
{
    [super willHide];
    // message sent when the tab is changed
}

/*! called when user permissions changed
*/
- (void)permissionsChanged
{
    [super permissionsChanged];
    // call here the reloading process
}

/*! called when the UI needs to be updated according to the permissions
*/
- (void)setUIAccordingToPermissions
{
    // You may need to update your GUI to disable some
    // controls if permissions changed
}


#pragma mark -
#pragma mark Notification handlers

/*! called when entity' nickname changed
    @param aNotification the notification
*/
- (void)_didUpdateNickName:(CPNotification)aNotification
{
    [fieldName setStringValue:[_entity nickname]];
}

/*! this message is used to flush the UI
*/
- (void)flushUI
{
    // flush all your Datasource here
    // and reload everything
}


#pragma mark -
#pragma mark Utilities

// put your utilities here


#pragma mark -
#pragma mark Actions

/*! send hello to entity
    @param aSender the sender of the action
*/
- (IBAction)showGrowl:(id)aSender
{
    // You can use Growl if you want to notify the user about something.
    // Do not forget to localize your strings using CPLocalizedString (defined at the end of this file)
    [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[_entity nickname]
                                                     message:CPBundleLocalizedString(@"Hello world!", @"Hello world!")];
}


#pragma mark -
#pragma mark XMPP Controls

// Your XMPP controls here


#pragma mark -
#pragma mark Delegates

// put your delegates here

@end


// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    // DO NOT FORGET TO CHANGE THE CLASS NAME HERE
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNSampleToolbarModuleController], comment);
}
