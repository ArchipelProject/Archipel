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
 
@import "../../TNModule.j";


trinityTypeVirtualMachineControl            = @"trinity:vm:control";
trinityTypeVirtualMachineDefinition         = @"trinity:vm:definition";

trinityTypeVirtualMachineControlInfo        = @"info";
trinityTypeVirtualMachineControlCreate      = @"create";
trinityTypeVirtualMachineControlShutdown    = @"shutdown";
trinityTypeVirtualMachineControlReboot      = @"reboot";
trinityTypeVirtualMachineControlSuspend     = @"suspend";
trinityTypeVirtualMachineControlResume      = @"resume";

VIR_DOMAIN_NOSTATE	                        =	0;
VIR_DOMAIN_RUNNING	                        =	1;
VIR_DOMAIN_BLOCKED	                        =	2;
VIR_DOMAIN_PAUSED	                        =	3;
VIR_DOMAIN_SHUTDOWN	                        =	4;
VIR_DOMAIN_SHUTOFF	                        =	5;
VIR_DOMAIN_CRASHED	                        =	6;


@implementation TNVirtualMachineControls : TNModule 
{
    @outlet CPTextField     fieldVMName                 @accessors;
    @outlet CPTextField     fieldVMJid                  @accessors;
    @outlet CPTextField     fieldInfoState              @accessors;
    @outlet CPTextField     fieldInfoMem                @accessors;
    @outlet CPTextField     fieldInfoCPUs               @accessors;
    @outlet CPTextField     fieldInfoConsumedCPU        @accessors;
    @outlet CPImageView     imageState                  @accessors;
    @outlet CPView          maskingView                 @accessors;
    @outlet CPButton        buttonPlay                  @accessors;
    @outlet CPButton        buttonPause                 @accessors;
    @outlet CPButton        buttonStop                  @accessors;
    @outlet CPButton        buttonReboot                @accessors;

    CPTimer     _timer;
    CPNumber    _VMLibvirtStatus;
}

- (void)awakeFromCib
{
    var bundle = [CPBundle bundleForClass:[self class]];
    
    [[self buttonPlay] setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"vm_play.png"]]];
    [[self buttonStop] setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"vm_stop.png"]]];
    [[self buttonPause] setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"vm_pause.png"]]];
    [[self buttonReboot] setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"vm_reboot.png"]]];

    [[self maskingView] setBackgroundColor:[CPColor whiteColor]];
    [[self maskingView] setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [[self maskingView] setAlphaValue:0.9];
    
    [[self fieldVMJid] setSelectable:YES];
}

// TNModule implementation
- (void)willLoad
{    
    var center = [CPNotificationCenter defaultCenter];
    
    [center addObserver:self selector:@selector(didNickNameUpdated:) name:TNStropheContactNicknameUpdatedNotification object:nil];
    [center addObserver:self selector:@selector(didNickPresenceUpdated:) name:TNStropheContactPresenceUpdatedNotification object:nil];
}

- (void)willUnload
{
    var center = [CPNotificationCenter defaultCenter];
    
    [center removeObserver:self];
}

- (void)willShow
{    
    [[self maskingView] setFrame:[self bounds]];
    
    [[self buttonPlay] setEnabled:NO];
    [[self buttonStop] setEnabled:NO];
    [[self buttonPause] setEnabled:NO];
    
    [[self fieldVMName] setStringValue:[[self contact] nickname]];
    [[self fieldVMJid] setStringValue:[[self contact] jid]];
    
    [self getVirtualMachineInfo:nil];
    
    _timer = [CPTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(getVirtualMachineInfo:) userInfo:nil repeats:YES];
}

- (void)willHide
{
    if (_timer)
        [_timer invalidate];
        
    [[self fieldInfoMem] setStringValue:@"..."];
    [[self fieldInfoCPUs] setStringValue:@"..."];
    [[self fieldInfoConsumedCPU] setStringValue:@"..."];
    [[self fieldInfoState] setStringValue:@"..."];
    [[self imageState] setImage:nil];
    [[self buttonPause] setTitle:@"Pause"];
    [[self buttonPlay] setEnabled:NO];
    [[self buttonStop] setEnabled:NO];
    [[self buttonPause] setEnabled:NO];
    [[self buttonReboot] setEnabled:NO];
    
    [[self maskingView] removeFromSuperview];
}

// Notifications listener
- (void)didNickNameUpdated:(CPNotification)aNotification
{
    if ([aNotification object] == [self contact])
    {
       [[self fieldVMName] setStringValue:[[self contact] nickname]] 
    }
}

- (void)didNickPresenceUpdated:(CPNotification)aNotification
{
    
    if ([aNotification object] == [self contact])
    {
        [[self imageState] setImage:[[aNotification object] statusIcon]];
        [[self imageState] setNeedsDisplay:YES];
    }
}


// population messages
- (void)getVirtualMachineInfo:(CPTimer)aTimer
{
    if (![self superview])
    {
        [_timer invalidate];
        return;
    }
    
    var uid         = [[[self contact] connection] getUniqueId];
    var infoStanza  = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeVirtualMachineControlInfo, "to": [[self contact] fullJID], "id": uid}];
    var params      = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];;
    
    [infoStanza addChildName:@"query" withAttributes:{"xmlns" : trinityTypeVirtualMachineControl}];
    
    [[[self contact] connection] registerSelector:@selector(didReceiveVirtualMachineInfo:) ofObject:self withDict:params];
    
    [[[self contact] connection] send:infoStanza];
}

- (void)didReceiveVirtualMachineInfo:(id)aStanza 
{
    var stanza = [TNStropheStanza stanzaWithStanza:aStanza];
      
      if ([stanza getType] == @"success")
      {   
          [[self maskingView] removeFromSuperview];
          
          var infoNode      = [stanza getFirstChildWithName:@"info"];
          var libvirtState  = [infoNode getValueForAttribute:@"state"];
          var cpuTime       = Math.round(parseInt([infoNode getValueForAttribute:@"cpuTime"]) / 6000000000);
          var mem           = parseInt([infoNode getValueForAttribute:@"memory"]) / 1024;
          var humanState;
          
          [[self fieldInfoMem] setStringValue:mem + @" Mo"];
          [[self fieldInfoCPUs] setStringValue:[infoNode getValueForAttribute:@"nrVirtCpu"]];
          [[self fieldInfoConsumedCPU] setStringValue:cpuTime + @" min."];
          
          _VMLibvirtStatus = libvirtState;
          
          switch ([libvirtState intValue])
          {
              case VIR_DOMAIN_NOSTATE:
                    humanState = @"No status";
                    break;
              case VIR_DOMAIN_RUNNING:
                    [self enableButtonsForRunning];
                    humanState = @"Running";
                    break;
              case VIR_DOMAIN_BLOCKED:
                    humanState = @"Blocked";
                    break;
              case VIR_DOMAIN_PAUSED:
                    [self enableButtonsForPaused]
                    humanState = @"Paused";
                    break;
              case VIR_DOMAIN_SHUTDOWN:
                    [self enableButtonsForShutdowned]
                    humanState = @"Shutdown";
                    break;
              case VIR_DOMAIN_SHUTOFF:
                    [self enableButtonsForShutdowned]
                    humanState = @"Shutdown";
                    break;
              case VIR_DOMAIN_CRASHED:
                    humanState = @"Crashed";
                    break;
          }
          [[self fieldInfoState] setStringValue:humanState];
      }
      else
      {
          [self addSubview:[self maskingView]];
      }
}


// Actions
- (IBAction)play:(id)sender
{
    [sender setEnabled:NO];
    [self sendVirtualMachineControl:trinityTypeVirtualMachineControlCreate withSelector:@selector(didPlay:)];
}

- (IBAction)pause:(id)sender
{
    if (_VMLibvirtStatus == VIR_DOMAIN_PAUSED)
    {
        [self sendVirtualMachineControl:trinityTypeVirtualMachineControlResume withSelector:@selector(didResume:)];
        [sender setTitle:@"Pause"];
    }
    else
    {
        [self sendVirtualMachineControl:trinityTypeVirtualMachineControlSuspend withSelector:@selector(didPause:)];
        [sender setTitle:@"Resume"];
    }
}

- (IBAction)stop:(id)sender
{
    [sender setEnabled:NO];
    [self sendVirtualMachineControl:trinityTypeVirtualMachineControlShutdown withSelector:@selector(didStop:)];
}

- (IBAction)reboot:(id)sender
{
    [sender setEnabled:NO];
    [self sendVirtualMachineControl:trinityTypeVirtualMachineControlReboot withSelector:@selector(didReboot:)];
}

// did Actions done selectors
- (void)didPlay:(id)aStanza
{
    var stanza          = [TNStropheStanza stanzaWithStanza:aStanza];
    var responseType    = [stanza getType];
    var responseFrom    = [stanza getFrom];
    
    [self getVirtualMachineInfo:nil];
    
    if (responseType == @"success")
    {
        var libvirtID = [[stanza getFirstChildWithName:@"domain"] getValueForAttribute:@"id"];
        [[TNViewLog sharedLogger] log:@"virtual machine " + responseFrom + " started with ID : " + libvirtID];
    }
    else
    {
       [self onLibvirtError:stanza from:responseFrom];
    }
}

- (void)didPause:(id)aStanza
{
    var stanza          = [TNStropheStanza stanzaWithStanza:aStanza];
    var responseType    = [stanza getType];
    var responseFrom    = [stanza getFrom];
    
    [self getVirtualMachineInfo:nil];
        
    if (responseType == @"success")
    {
        [[TNViewLog sharedLogger] log:@"virtual machine " + responseFrom + " has been paused"];
    }
    else
    {
        [self onLibvirtError:stanza from:responseFrom];
    }
}

- (void)didResume:(id)aStanza
{
    var stanza          = [TNStropheStanza stanzaWithStanza:aStanza];
    var responseType    = [stanza getType];
    var responseFrom    = [stanza getFrom];
    
    [self getVirtualMachineInfo:nil];
    
    if (responseType == @"success")
    {
        [[TNViewLog sharedLogger] log:@"virtual machine " + responseFrom + " has been resumed"];
    }
    else
    {
        [self onLibvirtError:stanza from:responseFrom];
    }
}

- (void)didStop:(id)aStanza
{
    var stanza          = [TNStropheStanza stanzaWithStanza:aStanza];
    var responseType    = [stanza getType];
    var responseFrom    = [stanza getFrom];
    
    [self getVirtualMachineInfo:nil];
    
    if (responseType == @"success")
    {
        [[TNViewLog sharedLogger] log:@"virtual machine " + responseFrom + " has been stopped"];
    }
    else
    {
        [self onLibvirtError:stanza from:responseFrom];
    }
}

- (void)didReboot:(id)aStanza
{
    var stanza          = [TNStropheStanza stanzaWithStanza:aStanza]
    var responseType    = [stanza getType];
    var responseFrom    = [stanza getFrom];
    
    [self getVirtualMachineInfo:nil];
    
    if (responseType == @"success")
    {
        [[TNViewLog sharedLogger] log:@"virtual machine " + responseFrom + " has been rebooted"];
    }
    else
    {
        [self onLibvirtError:stanza from:responseFrom];
    }
}


// Send control command
- (void)sendVirtualMachineControl:(CPString)aControl withSelector:(SEL)aSelector
{
    var uid             = [[[self contact] connection] getUniqueId];
    var rebootStanza    = [TNStropheStanza iqWithAttributes:{"type" : aControl, "to": [[self contact] fullJID], "id": uid}];
    var params          = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];

    [[[self contact] connection] registerSelector:aSelector ofObject:self withDict:params];
    [rebootStanza addChildName:@"query" withAttributes:{"xmlns" : trinityTypeVirtualMachineControl}];
    [rebootStanza addChildName:@"jid" withAttributes:{}];

    [[[self contact] connection] send:rebootStanza];
    [self getVirtualMachineInfo:nil];
}

- (void)onLibvirtError:(TNStropheStanza)errorStanza from:(CPString)responseFrom
{
    var errorNode               = [errorStanza getFirstChildWithName:@"error"];
    var libvirtErrorCode        = [errorNode getValueForAttribute:@"code"];
    var libvirtErrorMessage     = [errorNode text];   
    var title                   = @"Unable to create virtual machine. Error " + libvirtErrorCode;
    
    [CPAlert alertWithTitle:title message:libvirtErrorMessage style:CPCriticalAlertStyle]
    
    [[TNViewLog sharedLogger] log:@"Error: " + responseFrom + ". error code :" + libvirtErrorCode + ". " + libvirtErrorMessage];
}

// button management
- (void)enableButtonsForRunning
{
    [[self buttonPause] setTitle:@"Pause"];
    [[self buttonPlay] setEnabled:NO];
    [[self buttonStop] setEnabled:YES];
    [[self buttonPause] setEnabled:YES];
    [[self buttonReboot] setEnabled:YES];
}

- (void)enableButtonsForPaused
{
    [[self buttonPause] setTitle:@"Resume"];
    [[self buttonPlay] setEnabled:NO];
    [[self buttonStop] setEnabled:YES];
    [[self buttonPause] setEnabled:YES];
    [[self buttonReboot] setEnabled:YES];
}

- (void)enableButtonsForShutdowned
{
    [[self buttonPause] setTitle:@"Pause"];
    [[self buttonPlay] setEnabled:YES];
    [[self buttonStop] setEnabled:NO];
    [[self buttonPause] setEnabled:NO];
    [[self buttonReboot] setEnabled:NO];
}

@end



