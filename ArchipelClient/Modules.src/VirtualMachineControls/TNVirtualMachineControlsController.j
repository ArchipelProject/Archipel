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

TNArchipelPushNotificationControl               = @"archipel:push:virtualmachine:control";
TNArchipelControlNotification                   = @"TNArchipelControlNotification";
TNArchipelControlPlay                           = @"TNArchipelControlPlay";
TNArchipelControlSuspend                        = @"TNArchipelControlSuspend";
TNArchipelControlResume                         = @"TNArchipelControlResume";
TNArchipelControlStop                           = @"TNArchipelControlStop";
TNArchipelControlReboot                         = @"TNArchipelControlReboot";

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

@implementation TNVirtualMachineControlsController : TNModule
{
    @outlet CPTextField             fieldJID;
    @outlet CPTextField             fieldName;
    @outlet CPTextField             fieldInfoState;
    @outlet CPTextField             fieldInfoMem;
    @outlet CPTextField             fieldInfoCPUs;
    @outlet CPTextField             fieldInfoConsumedCPU;
    @outlet CPImageView             imageState;
    @outlet CPView                  maskingView;
    @outlet CPSegmentedControl      buttonBarTransport;

    CPNumber    _VMLibvirtStatus;
}


- (void)awakeFromCib
{
    var bundle = [CPBundle bundleForClass:[self class]];
    
    var imagePlay   = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-play.png"] size:CGSizeMake(20, 20)];
    var imageStop   = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-stop.png"] size:CGSizeMake(20, 20)];
    var imagePause  = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-pause.png"] size:CGSizeMake(20, 20)];
    var imageReboot = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-restart.png"] size:CGSizeMake(16, 16)];
    
    [maskingView setBackgroundColor:[CPColor whiteColor]];
    [maskingView setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [maskingView setAlphaValue:0.9];

    [fieldJID setSelectable:YES];
    
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
    
    var center = [CPNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(didReceiveControllNotification:) name:TNArchipelControlNotification object:nil];
}

/* TNModule implementation */
- (void)willLoad
{
    [super willLoad];

    var center = [CPNotificationCenter defaultCenter];

    [center addObserver:self selector:@selector(didNickNameUpdated:) name:TNStropheContactNicknameUpdatedNotification object:_entity];
    [center addObserver:self selector:@selector(didPresenceUpdated:) name:TNStropheContactPresenceUpdatedNotification object:_entity];
    [center postNotificationName:TNArchipelModulesReadyNotification object:self];
    
    [self registerSelector:@selector(didPushReceived:) forPushNotificationType:TNArchipelPushNotificationControl];
    
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarPlay];
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarStop];
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarPause];
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarReboot];

    [fieldName setStringValue:[_entity nickname]];
    [fieldJID setStringValue:[_entity JID]];
    [imageState setImage:[_entity statusIcon]];
    
    
    [self getVirtualMachineInfo];
}

- (void)willShow
{
    [super willShow];

    [maskingView setFrame:[[self view] bounds]];
    
    [self checkIfRunning];
}

- (void)willHide
{
    [super willHide];
}

- (void)willUnload
{
    [super willUnload];
    
    var center = [CPNotificationCenter defaultCenter];

    [center addObserver:self selector:@selector(didReceiveControllNotification:) name:TNArchipelControlNotification object:nil];
    
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

- (BOOL)didPushReceived:(TNStropheStanza)aStanza
{
    CPLog.info("Push notification received with with ");
    [self getVirtualMachineInfo];
    return YES;
}

- (void)didReceiveControllNotification:(CPNotification)aNotification
{
    var params                  = [aNotification userInfo];
    var currentEntityHandler    = _entity;
    var commandTargetEntity     = [params objectForKey:@"entity"];
    var command                 = [params objectForKey:@"command"];
    
    _entity = commandTargetEntity; 
    
    switch(command)
    {
        case TNArchipelControlPlay:
            [self play];
            break;
        
        case (TNArchipelControlSuspend || TNArchipelControlResume):
            [self pause];
            break;
        
        case TNArchipelControlReboot:
            [self reboot];
            break;
    }
    
    _entity = currentEntityHandler;
}

/* Notifications listener */
- (void)didNickNameUpdated:(CPNotification)aNotification
{
    [fieldName setStringValue:[_entity nickname]]
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
        [maskingView setFrame:[[self view] bounds]];
        [[self view] addSubview:maskingView];
    }
    else
        [maskingView removeFromSuperview];
}

/* population messages */
- (void)getVirtualMachineInfo
{
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

          [self disableAllButtons];
          
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

/* IBAction */
- (IBAction)segmentedControlClicked:(id)sender
{
    var segment = [sender selectedSegment];
    
    switch(segment)
    {
        case TNArchipelTransportBarPlay:
            [self play];
            break;
        case TNArchipelTransportBarPause:
            [self pause:sender];
            break;
        case TNArchipelTransportBarStop:
            [self stop];
            break;
        case TNArchipelTransportBarReboot:
            [self reboot];
            break;
    }
}

/* vm controls */
- (void)play
{
    var controlStanza = [TNStropheStanza iqWithAttributes:{"type": TNArchipelTypeVirtualMachineControl}];

    [controlStanza addChildName:@"query" withAttributes:{"type": TNArchipelTypeVirtualMachineControlCreate}];

    [_entity sendStanza:controlStanza andRegisterSelector:@selector(didPlay:) ofObject:self];
}

- (void)pause:(id)sender
{
    var controlStanza = [TNStropheStanza iqWithAttributes:{"type": TNArchipelTypeVirtualMachineControl}];
    var selector;

    if (_VMLibvirtStatus == VIR_DOMAIN_PAUSED)
    {
        selector = @selector(didResume:)
        
        [self enableButtonsForRunning];
        [controlStanza addChildName:@"query" withAttributes:{"type": TNArchipelTypeVirtualMachineControlResume}];
    }
    else
    {
        selector = @selector(didPause:)
        
        [self enableButtonsForPaused];
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

/* did Actions done selectors */
- (void)didPlay:(id)aStanza
{
    var responseType    = [aStanza getType];
    var responseFrom    = [aStanza getFrom];

    if (responseType == @"success")
    {
        var libvirtID = [[aStanza firstChildWithName:@"domain"] valueForAttribute:@"id"];
        
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Virtual Machine" message:@"Virtual machine is running"];
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

    if (responseType == @"success")
    {
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Virtual Machine" message:@"Virtual machine is paused"];
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

    if (responseType == @"success")
    {
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Virtual Machine" message:@"Virtual machine is resumed"];
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

    if (responseType == @"success")
    {
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Virtual Machine" message:@"Virtual machine is stopped"];
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

    if (responseType == @"success")
    {
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Virtual Machine" message:@"Virtual machine is rebooting"];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}

/* button management */
- (void)enableButtonsForRunning
{
    [buttonBarTransport setSelectedSegment:TNArchipelTransportBarPlay];
    
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarPlay];
    [buttonBarTransport setEnabled:YES forSegment:TNArchipelTransportBarStop];
    [buttonBarTransport setEnabled:YES forSegment:TNArchipelTransportBarPause];
    [buttonBarTransport setEnabled:YES forSegment:TNArchipelTransportBarReboot];
    [buttonBarTransport setLabel:@"Pause" forSegment:TNArchipelTransportBarPause];
    
    var imagePause  = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-pause.png"] size:CGSizeMake(20, 20)];
    [buttonBarTransport setImage:imagePause forSegment:TNArchipelTransportBarPause];
}

- (void)enableButtonsForPaused
{
    [buttonBarTransport setSelectedSegment:TNArchipelTransportBarPause];
    
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarPlay];
    [buttonBarTransport setEnabled:YES forSegment:TNArchipelTransportBarStop];
    [buttonBarTransport setEnabled:YES forSegment:TNArchipelTransportBarPause];
    [buttonBarTransport setEnabled:YES forSegment:TNArchipelTransportBarReboot];
    [buttonBarTransport setLabel:@"Resume" forSegment:TNArchipelTransportBarPause];
    
    var imagePause  = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-resume.png"] size:CGSizeMake(20, 20)];
    [buttonBarTransport setImage:imagePause forSegment:TNArchipelTransportBarPause];
}

- (void)enableButtonsForShutdowned
{
    [buttonBarTransport setSelectedSegment:TNArchipelTransportBarStop];
    
    [buttonBarTransport setEnabled:YES forSegment:TNArchipelTransportBarPlay];
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarStop];
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarPause];
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarReboot];
    [buttonBarTransport setLabel:@"Pause" forSegment:TNArchipelTransportBarPause];
    
    var imagePause  = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-pause.png"] size:CGSizeMake(20, 20)];
    [buttonBarTransport setImage:imagePause forSegment:TNArchipelTransportBarPause];
}

- (void)disableAllButtons
{
    [buttonBarTransport setSelected:NO forSegment:TNArchipelTransportBarPlay];
    [buttonBarTransport setSelected:NO forSegment:TNArchipelTransportBarStop];
    [buttonBarTransport setSelected:NO forSegment:TNArchipelTransportBarPause];
    [buttonBarTransport setSelected:NO forSegment:TNArchipelTransportBarReboot];
    
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarPlay];
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarStop];
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarPause];
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarReboot];
    [buttonBarTransport setLabel:@"Pause" forSegment:TNArchipelTransportBarPause];
    var imagePause  = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-pause.png"] size:CGSizeMake(20, 20)];
    [buttonBarTransport setImage:imagePause forSegment:TNArchipelTransportBarPause];
}

@end



