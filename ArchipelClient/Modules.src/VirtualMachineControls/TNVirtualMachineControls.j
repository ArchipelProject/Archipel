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

VIR_DOMAIN_NOSTATE  = 0;
VIR_DOMAIN_RUNNING  = 1;
VIR_DOMAIN_BLOCKED  = 2;
VIR_DOMAIN_PAUSED   = 3;
VIR_DOMAIN_SHUTDOWN = 4;
VIR_DOMAIN_SHUTOFF  = 5;
VIR_DOMAIN_CRASHED  = 6;

TNArchipelTransportBarPlay      = 0;
TNArchipelTransportBarPause     = 1;
TNArchipelTransportBarStop      = 2;
TNArchipelTransportBarReboot    = 3;

@implementation TNVirtualMachineControls : TNModule
{
    @outlet CPTextField     fieldJID                    @accessors;
    @outlet CPTextField     fieldName                   @accessors;
    @outlet CPTextField     fieldVMName                 @accessors;
    @outlet CPTextField     fieldVMJid                  @accessors;
    @outlet CPTextField     fieldInfoState              @accessors;
    @outlet CPTextField     fieldInfoMem                @accessors;
    @outlet CPTextField     fieldInfoCPUs               @accessors;
    @outlet CPTextField     fieldInfoConsumedCPU        @accessors;
    @outlet CPImageView     imageState                  @accessors;
    @outlet CPView          maskingView                 @accessors;
    
    @outlet CPSegmentedControl     buttonBarTransport          @accessors;

    CPTimer     _timer;
    CPNumber    _VMLibvirtStatus;
}


- (void)awakeFromCib
{
    var bundle = [CPBundle bundleForClass:[self class]];
    
    var imagePlay   = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"vm_play.png"] size:CGSizeMake(20, 20)];
    var imageStop   = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"vm_stop.png"] size:CGSizeMake(20, 20)];
    var imagePause  = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"vm_pause.png"] size:CGSizeMake(20, 20)];
    var imageReboot = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"vm_reboot.png"] size:CGSizeMake(20, 20)];
    
    [maskingView setBackgroundColor:[CPColor whiteColor]];
    [maskingView setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [maskingView setAlphaValue:0.9];

    [fieldVMJid setSelectable:YES];
    
    [buttonBarTransport setSegmentCount:4];
    [buttonBarTransport setLabel:@"Play" forSegment:TNArchipelTransportBarPlay];
    [buttonBarTransport setLabel:@"Pause" forSegment:TNArchipelTransportBarPause];
    [buttonBarTransport setLabel:@"Stop" forSegment:TNArchipelTransportBarStop];
    [buttonBarTransport setLabel:@"Reboot" forSegment:TNArchipelTransportBarReboot];
    
    [buttonBarTransport setWidth:100 forSegment:TNArchipelTransportBarPlay];
    [buttonBarTransport setWidth:100 forSegment:TNArchipelTransportBarPause];
    [buttonBarTransport setWidth:100 forSegment:TNArchipelTransportBarStop];
    [buttonBarTransport setWidth:100 forSegment:TNArchipelTransportBarReboot];
    
    [buttonBarTransport setImage:imagePlay forSegment:TNArchipelTransportBarPlay];
    [buttonBarTransport setImage:imagePause forSegment:TNArchipelTransportBarPause];
    [buttonBarTransport setImage:imageStop forSegment:TNArchipelTransportBarStop];
    [buttonBarTransport setImage:imageReboot forSegment:TNArchipelTransportBarReboot];
    
    [buttonBarTransport setTarget:self];
    [buttonBarTransport setAction:@selector(segmentedControlClicked:)];
}

// TNModule implementation
- (void)willLoad
{
    [super willLoad];

    var center = [CPNotificationCenter defaultCenter];

    [center addObserver:self selector:@selector(didNickNameUpdated:) name:TNStropheContactNicknameUpdatedNotification object:_entity];
    [center addObserver:self selector:@selector(didPresenceUpdated:) name:TNStropheContactPresenceUpdatedNotification object:_entity];
}

- (void)willShow
{
    [super willShow];

    [maskingView setFrame:[self bounds]];

    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarPlay];
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarStop];
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarPause];
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarReboot];

    [fieldVMName setStringValue:[_entity nickname]];
    [fieldVMJid setStringValue:[_entity jid]];
    [imageState setImage:[_entity statusIcon]];
    
    [self checkIfRunning];
    
    [self getVirtualMachineInfo:nil];

    _timer = [CPTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(getVirtualMachineInfo:) userInfo:nil repeats:YES];
}

- (void)willHide
{
    [super willHide];

    if (_timer)
        [_timer invalidate];

    [fieldInfoMem setStringValue:@"..."];
    [fieldInfoCPUs setStringValue:@"..."];
    [fieldInfoConsumedCPU setStringValue:@"..."];
    [fieldInfoState setStringValue:@"..."];
    [imageState setImage:nil];
    
    [buttonBarTransport setLabel:@"Pause" forSegment:TNArchipelTransportBarPause];
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarPlay];
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarStop];
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarPause];
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarReboot];
}

// Notifications listener
- (void)didNickNameUpdated:(CPNotification)aNotification
{
    [fieldVMName setStringValue:[_entity nickname]]
}

- (void)didPresenceUpdated:(CPNotification)aNotification
{
    [imageState setImage:[_entity statusIcon]];
    [self checkIfRunning];
}

- (void)checkIfRunning
{
    var status = [_entity status];
    
    if ((status == TNStropheContactStatusDND))
    {
        [maskingView setFrame:[self bounds]];
        [self addSubview:maskingView];
    }
    else
        [maskingView removeFromSuperview];
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

    [_entity sendStanza:infoStanza andRegisterSelector:@selector(didReceiveVirtualMachineInfo:) ofObject:self];
}

- (void)didReceiveVirtualMachineInfo:(id)aStanza
{
      if ([aStanza getType] == @"success")
      {
          var infoNode      = [aStanza firstChildWithName:@"info"];
          var libvirtState  = [infoNode valueForAttribute:@"state"];
          var cpuTime       = Math.round(parseInt([infoNode valueForAttribute:@"cpuTime"]) / 6000000000);
          var mem           = parseInt([infoNode valueForAttribute:@"memory"]) / 1024;
          var humanState;

          [fieldInfoMem setStringValue:mem + @" Mo"];
          [fieldInfoCPUs setStringValue:[infoNode valueForAttribute:@"nrVirtCpu"]];
          [fieldInfoConsumedCPU setStringValue:cpuTime + @" min."];

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
          [fieldInfoState setStringValue:humanState];
      }
}


- (IBAction)segmentedControlClicked:(id)sender
{
    var segment = [sender selectedSegment];
    
    switch(segment)
    {
        case TNArchipelTransportBarPlay:
            [self play];
            break;
        case TNArchipelTransportBarPause:
            [self pause];
            break;
        case TNArchipelTransportBarStop:
            [self stop];
            break;
        case TNArchipelTransportBarReboot:
            [self reboot];
            break;
    }
}

- (void)play
{
    var controlStanza = [TNStropheStanza iqWithAttributes:{"type": TNArchipelTypeVirtualMachineControl}];

    [controlStanza addChildName:@"query" withAttributes:{"type": TNArchipelTypeVirtualMachineControlCreate}];

    [_entity sendStanza:controlStanza andRegisterSelector:@selector(didPlay:) ofObject:self];
}

- (void)pause
{
    var controlStanza = [TNStropheStanza iqWithAttributes:{"type": TNArchipelTypeVirtualMachineControl}];
    var selector;

    if (_VMLibvirtStatus == VIR_DOMAIN_PAUSED)
    {
        selector = @selector(didResume:)

        [controlStanza addChildName:@"query" withAttributes:{"type": TNArchipelTypeVirtualMachineControlResume}];
    }
    else
    {
        selector = @selector(didPause:)

        [controlStanza addChildName:@"query" withAttributes:{"type": TNArchipelTypeVirtualMachineControlSuspend}];
    }

    [_entity sendStanza:controlStanza andRegisterSelector:selector ofObject:self];
}

- (void)stop
{
    var controlStanza = [TNStropheStanza iqWithAttributes:{"type": TNArchipelTypeVirtualMachineControl}];

    [controlStanza addChildName:@"query" withAttributes:{"type": TNArchipelTypeVirtualMachineControlShutdown}];

    [_entity sendStanza:controlStanza andRegisterSelector:@selector(didStop:) ofObject:self];
}

- (void)reboot
{
    var controlStanza = [TNStropheStanza iqWithAttributes:{"type": TNArchipelTypeVirtualMachineControl}];

    [controlStanza addChildName:@"query" withAttributes:{"type": TNArchipelTypeVirtualMachineControlReboot}];

    [_entity sendStanza:controlStanza andRegisterSelector:@selector(didReboot:) ofObject:self];
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
        // [[TNViewLog sharedLogger] log:@"virtual machine " + responseFrom + " started with ID : " + libvirtID];
        
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Virtual Machine" message:@"Virtual machine is running"];
        
        [self getVirtualMachineInfo:nil];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}

- (void)didPause:(id)aStanza
{
    var responseType    = [aStanza getType];
    var responseFrom    = [aStanza getFrom];

    [self getVirtualMachineInfo:nil];

    if (responseType == @"success")
    {
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Virtual Machine" message:@"Virtual machine is paused"];
        
        [self getVirtualMachineInfo:nil];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}

- (void)didResume:(id)aStanza
{
    var responseType    = [aStanza getType];
    var responseFrom    = [aStanza getFrom];

    [self getVirtualMachineInfo:nil];

    if (responseType == @"success")
    {
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Virtual Machine" message:@"Virtual machine is resumed"];
        
        [self getVirtualMachineInfo:nil];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}

- (void)didStop:(id)aStanza
{
    var responseType    = [aStanza getType];
    var responseFrom    = [aStanza getFrom];

    [self getVirtualMachineInfo:nil];

    if (responseType == @"success")
    {
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Virtual Machine" message:@"Virtual machine is stopped"];
        [self getVirtualMachineInfo:nil];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}

- (void)didReboot:(id)aStanza
{
    var responseType    = [aStanza getType];
    var responseFrom    = [aStanza getFrom];

    [self getVirtualMachineInfo:nil];

    if (responseType == @"success")
    {
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Virtual Machine" message:@"Virtual machine is rebooting"];
        [self getVirtualMachineInfo:nil];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}

// button management
- (void)enableButtonsForRunning
{
    [buttonBarTransport setSelectedSegment:TNArchipelTransportBarPlay];
    
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarPlay];
    [buttonBarTransport setEnabled:YES forSegment:TNArchipelTransportBarStop];
    [buttonBarTransport setEnabled:YES forSegment:TNArchipelTransportBarPause];
    [buttonBarTransport setEnabled:YES forSegment:TNArchipelTransportBarReboot];
    [buttonBarTransport setLabel:@"Pause" forSegment:TNArchipelTransportBarPause];
}

- (void)enableButtonsForPaused
{
    [buttonBarTransport setSelectedSegment:TNArchipelTransportBarPause];
    
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarPlay];
    [buttonBarTransport setEnabled:YES forSegment:TNArchipelTransportBarStop];
    [buttonBarTransport setEnabled:YES forSegment:TNArchipelTransportBarPause];
    [buttonBarTransport setEnabled:YES forSegment:TNArchipelTransportBarReboot];
    [buttonBarTransport setLabel:@"Resume" forSegment:TNArchipelTransportBarPause];
    
}

- (void)enableButtonsForShutdowned
{
    [buttonBarTransport setSelectedSegment:TNArchipelTransportBarStop];
    
    [buttonBarTransport setEnabled:YES forSegment:TNArchipelTransportBarPlay];
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarStop];
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarPause];
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarReboot];
    [buttonBarTransport setLabel:@"Pause" forSegment:TNArchipelTransportBarPause];
    
}

@end



