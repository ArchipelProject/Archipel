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


trinityTypeVirtualMachineControl            = @"trinity:vm:control";

trinityTypeVirtualMachineControlVNCDisplay  = @"vncdisplay";
trinityTypeVirtualMachineControlInfo        = @"info";

VIR_DOMAIN_RUNNING	                        =	1;

@implementation TNVirtualMachineVNC : TNModule 
{
    @outlet     CPWebView   vncWebView      @accessors;
    @outlet     CPView      maskingView     @accessors;
    
    CPString    _VMHost;
    CPString    _vncDisplay;
    CPString    _webServerPort;
}


- (void)awakeFromCib
{
    [[self maskingView] setBackgroundColor:[CPColor whiteColor]];
    [[self maskingView] setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [[self maskingView] setAlphaValue:0.9];
    
    _webServerPort   = [[CPBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"ArchipelServerSideWebServerPort"];
}


- (void)willShow
{
    [[self maskingView] setFrame:[self bounds]];

    [self getVirtualMachineInfo];
}

- (void)willHide
{
    var bundle = [CPBundle bundleForClass:[self class]];
    
    [[self vncWebView] setMainFrameURL:[bundle pathForResource:@"empty.html"]];
    [[self maskingView] removeFromSuperview];
}

- (void)willUnload
{
    [[self maskingView] removeFromSuperview];
}

- (void)getVirtualMachineInfo
{    
    var uid = [[[self contact] connection] getUniqueId];
    var infoStanza = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeVirtualMachineControl, "to": [[self contact] fullJID], "id": uid}];
    var params = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];;
    
    [infoStanza addChildName:@"query" withAttributes:{"type" : trinityTypeVirtualMachineControlInfo}];
    
    [[[self contact] connection] registerSelector:@selector(didReceiveVirtualMachineInfo:) ofObject:self withDict:params];
    [[[self contact] connection] send:infoStanza];
}

- (void)didReceiveVirtualMachineInfo:(id)aStanza 
{
    if ([aStanza getType] == @"success")
    {
        var infoNode = [aStanza firstChildWithName:@"info"];
        var libvirtSate = [infoNode valueForAttribute:@"state"];
        if (libvirtSate != VIR_DOMAIN_RUNNING)
            [self addSubview:[self maskingView]];
        else
        {
            [[self maskingView] removeFromSuperview];
            [self getVirtualMachineVNCDisplay:nil];
        }
            
    }   
}

- (void)getVirtualMachineVNCDisplay:(CPTimer)aTimer
{
    var uid         = [[[self contact] connection] getUniqueId];
    var vncStanza   = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeVirtualMachineControl, "to": [[self contact] fullJID], "id": uid}];
    var params      = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];
    
    [vncStanza addChildName:@"query" withAttributes:{"type" : trinityTypeVirtualMachineControlVNCDisplay}];
    
    [[[self contact] connection] registerSelector:@selector(didReceiveVNCDisplay:) ofObject:self withDict:params];
    [[[self contact] connection] send:vncStanza];
}

- (void)didReceiveVNCDisplay:(id)aStanza 
{
    if ([aStanza getType] == @"success")
    {   
        var displayNode = [aStanza firstChildWithName:@"vncdisplay"];
        _vncDisplay     = [displayNode valueForAttribute:@"port"];
        _VMHost         = [displayNode valueForAttribute:@"host"];
        
        var url     = @"http://" + _VMHost + @":" + _webServerPort + @"?port=" + _vncDisplay;
        
        [[self vncWebView] setMainFrameURL:url];
    }
}
    
@end



