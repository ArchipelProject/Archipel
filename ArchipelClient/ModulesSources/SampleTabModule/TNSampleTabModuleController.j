/*
 * TNSampleTabModule.j
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

// import only AppKit part you need here.
@import <AppKit/CPTextField.j>

@import "../../Model/TNModule.j"

// if you don't need this variables outside of this file,
// *always* use the 'var' keyword to make them filescoped
// otherwise, it will be application scoped
var TNArchipelTypeDummyNamespace = @"archipel:dummy",
    TNArchipelTypeDummyNamespaceSayHello = @"sayhello";

/*! @defgroup  sampletabmodule Module SampleTabModule
    @desc Development starting point to create a Tab module
*/

/*! @ingroup sampletabmodule
    Sample tabbed module implementation
    Please respect the pragma marks as much as possible.
*/
@implementation TNSampleTabModuleController : TNModule
{
    @outlet CPTextField     fieldJID;
    @outlet CPTextField     fieldName;
}


#pragma mark -
#pragma mark Initialization

/*! called at cib awaking
*/
- (void)awakeFromCib
{
    [fieldJID setSelectable:YES];
}

#pragma mark -
#pragma mark TNModule overrides

/*! called when module is loaded
*/
- (BOOL)willLoad
{
    if (![super willLoad])
        return NO;

    var center = [CPNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(_didUpdateNickName:) name:TNStropheContactNicknameUpdatedNotification object:_entity];

    return YES;
}

/*! called when module is unloaded
*/
- (void)willUnload
{
    [super willUnload];
}

/*! called when module becomes visible
*/
- (BOOL)willShow
{
    if (![super willShow])
        return NO;

    [fieldName setStringValue:[_entity nickname]];
    [fieldJID setStringValue:[_entity JID]];

    return YES;
}

/*! called when module becomes unvisible
*/
- (void)willHide
{
    // you should close all your opened windows and popover now.

    [super willHide];
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

/*! this message is used to flush the UI
*/
- (void)flushUI
{
    // flush all your Datasource here
    // and reload everything
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


#pragma mark -
#pragma mark Utilities

// put your utilities here


#pragma mark -
#pragma mark Actions

/*! send hello to entity
    @param aSender the sender of the action
*/
- (IBAction)sendHello:(id)aSender
{
    // try to always proxy your IBAction like this.
    [self sayHello];
}


#pragma mark -
#pragma mark XMPP Controls

/*! Send the dummy hello stanza to the current entity
*/
- (void)sayHello
{
    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeDummyNamespace}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeDummyNamespaceSayHello}];

    [_entity sendStanza:stanza andRegisterSelector:@selector(_didSayHello:) ofObject:self];
}

/*! compute the answer about the hello command
    @param aStanza TNStropheStanza that contains the hypervisor answer
*/
- (BOOL)_didSayHello:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"success")
    {
        // You can use Growl if you want to notify the user about something.
        // Do not forget to localize your strings using CPLocalizedString (defined at the end of this file)
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[_entity nickname]
                                                         message:CPBundleLocalizedString(@"Hello sent!", @"Hello sent!")];
    }
    else
    {
        // Then we got an error. You can manage it as you want,
        // but in any way it is strongly suggested to use the
        // standard handling of the TNModule
        // This will display a growl notification and will log relevant
        // info into the JS console.
        [self handleIqErrorFromStanza:aStanza];
    }

    // return NO to not be notified next time
    // Most of the time you want to return NO.
    return NO;
}


#pragma mark -
#pragma mark Delegates

// put your delegates here

@end


// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    // DO NOT FORGET TO CHANGE THE CLASS NAME HERE
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNSampleTabModuleController], comment);
}
