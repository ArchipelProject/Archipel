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


TNArchipelTypeVirtualMachineControl            = @"archipel:vm:control";

TNArchipelTypeVirtualMachineControlInfo        = @"info";
TNArchipelTypeVirtualMachineControlCreate      = @"create";
TNArchipelTypeVirtualMachineControlShutdown    = @"shutdown";
TNArchipelTypeVirtualMachineControlReboot      = @"reboot";
TNArchipelTypeVirtualMachineControlSuspend     = @"suspend";
TNArchipelTypeVirtualMachineControlResume      = @"resume";

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
    [super willLoad];
    
    var center = [CPNotificationCenter defaultCenter];
    
    [center addObserver:self selector:@selector(didNickNameUpdated:) name:TNStropheContactNicknameUpdatedNotification object:nil];
    [center addObserver:self selector:@selector(didNickPresenceUpdated:) name:TNStropheContactPresenceUpdatedNotification object:nil];
}

- (void)willShow
{
    [super willShow];
    
    [[self maskingView] setFrame:[self bounds]];
    
    [[self buttonPlay] setEnabled:NO];
    [[self buttonStop] setEnabled:NO];
    [[self buttonPause] setEnabled:NO];
    
    [[self fieldVMName] setStringValue:[[self entity] nickname]];
    [[self fieldVMJid] setStringValue:[[self entity] jid]];
    
    [self getVirtualMachineInfo:nil];
    
    _timer = [CPTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(getVirtualMachineInfo:) userInfo:nil repeats:YES];
}

- (void)willHide
{
    [super willHide];
    
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
    if ([aNotification object] == [self entity])
    {
       [[self fieldVMName] setStringValue:[[self entity] nickname]] 
    }
}

- (void)didNickPresenceUpdated:(CPNotification)aNotification
{
    
    if ([aNotification object] == [self entity])
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
    
    var infoStanza  = [TNStropheStanza iqWithAttributes:{"type" : TNArchipelTypeVirtualMachineControl}];
    
    [infoStanza addChildName:@"query" withAttributes:{"type" : TNArchipelTypeVirtualMachineControlInfo}];
    
    [[self entity] sendStanza:infoStanza andRegisterSelector:@selector(didReceiveVirtualMachineInfo:) ofObject:self];
}

- (void)didReceiveVirtualMachineInfo:(id)aStanza 
{
      if ([aStanza getType] == @"success")
      {   
          [[self maskingView] removeFromSuperview];
          
          var infoNode      = [aStanza firstChildWithName:@"info"];
          var libvirtState  = [infoNode valueForAttribute:@"state"];
          var cpuTime       = Math.round(parseInt([infoNode valueForAttribute:@"cpuTime"]) / 6000000000);
          var mem           = parseInt([infoNode valueForAttribute:@"memory"]) / 1024;
          var humanState;
          
          [[self fieldInfoMem] setStringValue:mem + @" Mo"];
          [[self fieldInfoCPUs] setStringValue:[infoNode valueForAttribute:@"nrVirtCpu"]];
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
          [[self maskingView] setFrame:[self bounds]];
          [self addSubview:[self maskingView]];
      }
}


// Actions
- (IBAction)play:(id)sender
{
    var controlStanza = [TNStropheStanza iqWithAttributes:{"type": TNArchipelTypeVirtualMachineControl}];
    
    [controlStanza addChildName:@"query" withAttributes:{"type": TNArchipelTypeVirtualMachineControlCreate}];
    [sender setEnabled:NO];
    
    [[self entity] sendStanza:controlStanza andRegisterSelector:@selector(didPlay:) ofObject:self];
}

- (IBAction)pause:(id)sender
{
    var controlStanza = [TNStropheStanza iqWithAttributes:{"type": TNArchipelTypeVirtualMachineControl}];
    var selector;
    
    if (_VMLibvirtStatus == VIR_DOMAIN_PAUSED)
    {
        selector = @selector(didResume:)
        
        [controlStanza addChildName:@"query" withAttributes:{"type": TNArchipelTypeVirtualMachineControlResume}];
        [sender setTitle:@"Pause"];
    }
    else
    {
        selector = @selector(didPause:)
        
        [controlStanza addChildName:@"query" withAttributes:{"type": TNArchipelTypeVirtualMachineControlSuspend}];
        [sender setTitle:@"Resume"];
    }
    
    [[self entity] sendStanza:controlStanza andRegisterSelector:selector ofObject:self];
}

- (IBAction)stop:(id)sender
{
    var controlStanza = [TNStropheStanza iqWithAttributes:{"type": TNArchipelTypeVirtualMachineControl}];
    
    [controlStanza addChildName:@"query" withAttributes:{"type": TNArchipelTypeVirtualMachineControlShutdown}];
    [sender setEnabled:NO];
    
    [[self entity] sendStanza:controlStanza andRegisterSelector:@selector(didStop:) ofObject:self];
}

- (IBAction)reboot:(id)sender
{
    var controlStanza = [TNStropheStanza iqWithAttributes:{"type": TNArchipelTypeVirtualMachineControl}];
    
    [controlStanza addChildName:@"query" withAttributes:{"type": TNArchipelTypeVirtualMachineControlReboot}];
    [sender setEnabled:NO];
    
    [[self entity] sendStanza:controlStanza andRegisterSelector:@selector(didReboot:) ofObject:self];
}

// did Actions done selectors
- (void)didPlay:(id)aStanza
{
    var responseType    = [aStanza getType];
    var responseFrom    = [aStanza getFrom];
    
    [self getVirtualMachineInfo:nil];
    
    if (responseType == @"success")
    {
        var libvirtID = [[aStanza firstChildWithName:@"domain"] valueForAttribute:@"id"];
        [[TNViewLog sharedLogger] log:@"virtual machine " + responseFrom + " started with ID : " + libvirtID];
        
        [self getVirtualMachineInfo:nil];
    }
    else
    {
       [self onLibvirtError:aStanza from:responseFrom];
    }
}

- (void)didPause:(id)aStanza
{
    var responseType    = [aStanza getType];
    var responseFrom    = [aStanza getFrom];
    
    [self getVirtualMachineInfo:nil];
        
    if (responseType == @"success")
    {
        [[TNViewLog sharedLogger] log:@"virtual machine " + responseFrom + " has been paused"];
        
        [self getVirtualMachineInfo:nil];
    }
    else
    {
        [self onLibvirtError:aStanza from:responseFrom];
    }
}

- (void)didResume:(id)aStanza
{
    var responseType    = [aStanza getType];
    var responseFrom    = [aStanza getFrom];
    
    [self getVirtualMachineInfo:nil];
    
    if (responseType == @"success")
    {
        [[TNViewLog sharedLogger] log:@"virtual machine " + responseFrom + " has been resumed"];
        
        [self getVirtualMachineInfo:nil];
    }
    else
    {
        [self onLibvirtError:aStanza from:responseFrom];
    }
}

- (void)didStop:(id)aStanza
{
    var responseType    = [aStanza getType];
    var responseFrom    = [aStanza getFrom];
    
    [self getVirtualMachineInfo:nil];
    
    if (responseType == @"success")
    {
        [[TNViewLog sharedLogger] log:@"virtual machine " + responseFrom + " has been stopped"];
        
        [self getVirtualMachineInfo:nil];
    }
    else
    {
        [self onLibvirtError:aStanza from:responseFrom];
    }
}

- (void)didReboot:(id)aStanza
{
    var responseType    = [aStanza getType];
    var responseFrom    = [aStanza getFrom];
    
    [self getVirtualMachineInfo:nil];
    
    if (responseType == @"success")
    {
        [[TNViewLog sharedLogger] log:@"virtual machine " + responseFrom + " has been rebooted"];
        [self getVirtualMachineInfo:nil];
    }
    else
    {
        [self onLibvirtError:aStanza from:responseFrom];
    }
}


// error displaying
- (void)onLibvirtError:(TNStropheStanza)errorStanza from:(CPString)responseFrom
{
    var errorNode               = [errorStanza firstChildWithName:@"error"];
    var libvirtErrorCode        = [errorNode valueForAttribute:@"code"];
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



