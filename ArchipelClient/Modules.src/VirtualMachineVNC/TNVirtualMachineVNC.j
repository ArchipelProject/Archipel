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


TNArchipelTypeVirtualMachineControl            = @"archipel:vm:control";

TNArchipelTypeVirtualMachineControlVNCDisplay  = @"vncdisplay";
TNArchipelTypeVirtualMachineControlInfo        = @"info";

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
    [super willShow];
    
    [[self maskingView] setFrame:[self bounds]];

    [self getVirtualMachineInfo];
}

- (void)willHide
{
    [super willHide];
    
    var bundle = [CPBundle bundleForClass:[self class]];
    
    [[self vncWebView] setMainFrameURL:[bundle pathForResource:@"empty.html"]];
    [[self maskingView] removeFromSuperview];
}

- (void)willUnload
{
    [super willUnload];
    
    [[self maskingView] removeFromSuperview];
}

- (void)getVirtualMachineInfo
{    
    var infoStanza = [TNStropheStanza iqWithAttributes:{"type" : TNArchipelTypeVirtualMachineControl}];
    
    [infoStanza addChildName:@"query" withAttributes:{"type" : TNArchipelTypeVirtualMachineControlInfo}];
    
    [[self entity] sendStanza:infoStanza andRegisterSelector:@selector(didReceiveVirtualMachineInfo:) ofObject:self];
}

- (void)didReceiveVirtualMachineInfo:(id)aStanza 
{
    if ([aStanza getType] == @"success")
    {
        var infoNode = [aStanza firstChildWithName:@"info"];
        var libvirtSate = [infoNode valueForAttribute:@"state"];
        if (libvirtSate != VIR_DOMAIN_RUNNING)
        {
            [[self maskingView] setFrame:[self bounds]];
            [self addSubview:[self maskingView]];
        }
        else
        {
            [[self maskingView] removeFromSuperview];
            [self getVirtualMachineVNCDisplay:nil];
        }
            
    }   
}

- (void)getVirtualMachineVNCDisplay:(CPTimer)aTimer
{
    var vncStanza   = [TNStropheStanza iqWithAttributes:{"type" : TNArchipelTypeVirtualMachineControl}];
    
    [vncStanza addChildName:@"query" withAttributes:{"type" : TNArchipelTypeVirtualMachineControlVNCDisplay}];
    
    [[self entity] sendStanza:vncStanza andRegisterSelector:@selector(didReceiveVNCDisplay:) ofObject:self];
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



