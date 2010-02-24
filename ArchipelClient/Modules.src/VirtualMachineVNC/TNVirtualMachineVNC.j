/*  
 * TNViewHypervisorControl.j
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
@import <AppKit/CPWebView.j>
 
@import "../../TNModule.j";

trinityTypeVirtualMachineControl            = @"trinity:vm:control";

trinityTypeVirtualMachineControlVNCDisplay  = @"vncdisplay";

@implementation TNVirtualMachineVNC : TNModule 
{
    @outlet     CPWebView   vncWebView @accessors;
    
    CPString    _VMHost;
    CPString    _vncDisplay;
}

- (void)willBeDisplayed
{
    // message sent when view will be added from superview;
    // MUST be declared
    
}

- (void)willBeUnDisplayed
{
   // message sent when view will be removed from superview;
   // MUST be declared
   //console.log([[self moduleBundle] description]);
   
   //var vncViewerURL = [[self moduleBundle] pathForResource:@"tightvnc/index.html"]
   //[[self vncWebView] setMainFrameURL:vncViewerURL];
}

- (void)initializeWithContact:(TNStropheContact)aContact andRoster:(TNStropheRoster)aRoster
{
    [super initializeWithContact:aContact andRoster:aRoster]
    
    [self getVirtualMachineVNCDisplay:nil];
}


- (void)getVirtualMachineVNCDisplay:(CPTimer)aTimer
{
    if (![self superview])
    {
        [_timer invalidate];
        return;
    }
    
    var uid = [[[self contact] connection] getUniqueId];
    var vncStanza = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeVirtualMachineControlVNCDisplay, "to": [[self contact] fullJID], "id": uid}];
    var params;
    
    [vncStanza addChildName:@"query" withAttributes:{"xmlns" : trinityTypeVirtualMachineControl}];
    
    params= [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];
    [[[self contact] connection] registerSelector:@selector(didReceiveVirtualMachineInfo:) ofObject:self withDict:params];
    
    [[[self contact] connection] send:[vncStanza stanza]];
}

- (void)didReceiveVirtualMachineInfo:(id)aStanza 
{
    if (aStanza.getAttribute("type") == @"success")
    {       
        _vncDisplay = aStanza.getElementsByTagName("vncdisplay")[0].getAttribute("port");
        _VMHost = aStanza.getElementsByTagName("vncdisplay")[0].getAttribute("host");
        
        [[self vncWebView] setBackgroundColor:[CPColor blackColor]];
        [[self vncWebView] setMainFrameURL:"http://"+_VMHost+"/index.html?port="+_vncDisplay];
    }
}
    
@end



