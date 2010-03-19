/*  
 * TNWindowConnection.j
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

@import "TNViewLog.j"

TNStropheConnectionSuccessNotification  = @"TNStropheConnectionSuccessNotification";
TNStropheDisconnectionNotification      = @"TNStropheDisconnectionNotification";
TNStropheConnectionFailNotification     = @"TNStropheConnectionFailNotification";

@implementation TNWindowConnection: CPWindow 
{
    @outlet CPImageView spinning            @accessors;
    @outlet CPTextField jid                 @accessors;
    @outlet CPTextField message             @accessors;
    @outlet CPTextField password            @accessors;
    @outlet CPTextField boshService         @accessors;
    @outlet CPCheckBox  credentialRemember  @accessors;
    
    TNStropheConnection     strophe         @accessors;
    CPCookie                cookieLogin     @accessors;
    CPCookie                cookiePassword  @accessors;
}

// initialization
- (void) awakeFromCib 
{
    [[self password] setSecure:YES];
      
    var lastBoshService  = JSON.parse(localStorage.getItem("lastboshservice"));
    var lastJID          = JSON.parse(localStorage.getItem("lastjid"));
    var lastPassword     = JSON.parse(localStorage.getItem("lastpassword"));
   
    if (lastBoshService)
        [[self boshService] setStringValue:lastBoshService];
   
    [[self jid] setStringValue:lastJID]; 
    [[self password] setStringValue:lastPassword];
   
    if (lastJID && lastPassword) 
        [self connect:nil];
    else
        [[self credentialRemember] setState:CPOffState];
    
    [self setShowsResizeIndicator:NO];
}


// actions
- (IBAction)connect:(id)sender
{
    localStorage.setItem("lastboshservice", JSON.stringify([[self boshService] stringValue]));
    if ([[self credentialRemember] state] == CPOnState) 
    {
        localStorage.setItem("lastjid", JSON.stringify([jid stringValue]));
        localStorage.setItem("lastpassword", JSON.stringify([password stringValue]));
    }

    [self setStrophe:[TNStropheConnection connectionWithService:[boshService stringValue] jid:[jid stringValue] password:[password stringValue]]];
    [[self strophe] setDelegate:self];                                      
    [[self strophe] connect];   
}

//TNStrophe delegate
- (void)onStropheConnecting:(TNStrophe)strophe 
{
    [[self spinning] setHidden:NO];
}

- (void)onStropheConnected:(TNStrophe)strophe
{
    var center = [CPNotificationCenter defaultCenter];    
    [center postNotificationName:TNStropheConnectionSuccessNotification object:self userInfo:[self strophe]];
    [[self spinning] setHidden:YES];
    
    [[TNViewLog sharedLogger] log:@"Strophe is now connected using JID " + [[self jid] stringValue]];
}

- (void)onStropheConnectFail:(TNStrophe)strophe
{
    var center = [CPNotificationCenter defaultCenter];
    [center postNotificationName:TNStropheConnectionFailNotification object:self userInfo:[self strophe]];
    [[self spinning] setHidden:YES];
    [[self message] setStringValue:@"strophe connection failed"];
    
    [[TNViewLog sharedLogger] log:@"Strophe connection failed"];
}

- (void)onStropheDisconnected:(TNStrophe)strophe
{
    var center = [CPNotificationCenter defaultCenter];   
    [center postNotificationName:TNStropheDisconnectionNotification object:self userInfo:[self strophe]];
    
    [[self jid] setStringValue:""]; 
    [[self password] setStringValue:""];
       
    localStorage.setItem("lastjid", JSON.stringify(""));
    localStorage.setItem("lastpassword", JSON.stringify(""));
    
    [[TNViewLog sharedLogger] log:@"Strophe is disconnected"];
}
@end