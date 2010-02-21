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

@import "StropheCappuccino/TNStrophe.j";

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
    CPCookie                cookieService   @accessors;
}

// initialization
- (void) awakeFromCib 
{
   [[self password] setSecure:YES];
       
       cookieLogin     = [[CPCookie alloc] initWithName:@"login"];
       cookiePassword  = [[CPCookie alloc] initWithName:@"password"];
       cookieService   = [[CPCookie alloc] initWithName:@"service"];
       
       if (([[self cookieLogin] value]) && ([[self cookiePassword] value]) && ([[self cookieLogin] value] != "")  && ([[self cookiePassword] value] != "")) 
       {
           [[self jid] setStringValue:[cookieLogin value]]; 
           [[self password] setStringValue:[cookiePassword value]];
           [[self boshService] setStringValue:[cookieService value]];
           [self connect:nil];
       }
       else
           [[self credentialRemember] setState:CPOffState];
}


// actions
- (IBAction)connect:(id)sender
{
    if ([[self credentialRemember] state] == CPOnState) 
    {
        [cookieLogin setValue:[jid stringValue]  expires:[CPDate distantFuture] domain:""];
        [cookiePassword setValue:[password stringValue]  expires:[CPDate distantFuture] domain:""];
        [cookieService setValue:[boshService stringValue]  expires:[CPDate distantFuture] domain:""];
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
}

- (void)onStropheConnectFail:(TNStrophe)strophe
{
    var center = [CPNotificationCenter defaultCenter];
    [center postNotificationName:TNStropheConnectionFailNotification object:self userInfo:[self strophe]];
    [[self spinning] setHidden:YES];
    [[self message] setStringValue:@"strophe connection failed"];
    [logger log:"TNStropheConnectionFailNotification has been sent."];
}

- (void)onStropheDisconnected:(TNStrophe)strophe
{
    var center = [CPNotificationCenter defaultCenter];   
    [center postNotificationName:TNStropheDisconnectionNotification object:self userInfo:[self strophe]];
    
    [[self jid] setStringValue:""]; 
    [[self password] setStringValue:""];
       
    [cookieLogin setValue:"" expires:[CPDate distantFuture] domain:""];
    [cookiePassword setValue:""  expires:[CPDate distantFuture] domain:""];
    [cookieService setValue:""  expires:[CPDate distantFuture] domain:""];
}





@end