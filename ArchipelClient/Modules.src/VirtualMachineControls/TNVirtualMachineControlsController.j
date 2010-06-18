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


TNArchipelPushNotificationDefinition            = @"archipel:push:virtualmachine:definition";
TNArchipelPushNotificationControl               = @"archipel:push:virtualmachine:control";

TNArchipelControlNotification                   = @"TNArchipelControlNotification";
TNArchipelControlPlay                           = @"TNArchipelControlPlay";
TNArchipelControlSuspend                        = @"TNArchipelControlSuspend";
TNArchipelControlResume                         = @"TNArchipelControlResume";
TNArchipelControlStop                           = @"TNArchipelControlStop";
TNArchipelControlReboot                         = @"TNArchipelControlReboot";

TNArchipelTypeVirtualMachineControl             = @"archipel:vm:control";
TNArchipelTypeVirtualMachineControlInfo         = @"info";
TNArchipelTypeVirtualMachineControlCreate       = @"create";
TNArchipelTypeVirtualMachineControlShutdown     = @"shutdown";
TNArchipelTypeVirtualMachineControlDestroy      = @"destroy";
TNArchipelTypeVirtualMachineControlReboot       = @"reboot";
TNArchipelTypeVirtualMachineControlSuspend      = @"suspend";
TNArchipelTypeVirtualMachineControlResume       = @"resume";

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
TNArchipelTransportBarDestroy   = 3
TNArchipelTransportBarReboot    = 4;

@implementation TNVirtualMachineControlsController : TNModule
{
    @outlet CPImageView             imageState;
    @outlet CPSegmentedControl      buttonBarTransport;
    @outlet CPTextField             fieldInfoConsumedCPU;
    @outlet CPTextField             fieldInfoCPUs;
    @outlet CPTextField             fieldInfoMem;
    @outlet CPTextField             fieldInfoState;
    @outlet CPTextField             fieldJID;
    @outlet CPTextField             fieldName;
    @outlet CPView                  maskingView;

    CPNumber    _VMLibvirtStatus;
}


- (void)awakeFromCib
{
    [fieldJID setSelectable:YES];
    
    var bundle          = [CPBundle bundleForClass:[self class]];
    var imagePlay       = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-play.png"] size:CGSizeMake(20, 20)];
    var imageStop       = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-stop.png"] size:CGSizeMake(20, 20)];
    var imageDestroy    = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-unplug.png"] size:CGSizeMake(20, 20)];
    var imagePause      = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-pause.png"] size:CGSizeMake(20, 20)];
    var imageReboot     = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-restart.png"] size:CGSizeMake(16, 16)];
    
    [maskingView setBackgroundColor:[CPColor whiteColor]];
    [maskingView setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [maskingView setAlphaValue:0.9];

    [fieldJID setSelectable:YES];
    
    [buttonBarTransport setSegmentCount:5];
    [buttonBarTransport setLabel:@"Play" forSegment:TNArchipelTransportBarPlay];
    [buttonBarTransport setLabel:@"Pause" forSegment:TNArchipelTransportBarPause];
    [buttonBarTransport setLabel:@"Stop" forSegment:TNArchipelTransportBarStop];
    [buttonBarTransport setLabel:@"Destroy" forSegment:TNArchipelTransportBarDestroy];
    [buttonBarTransport setLabel:@"Reboot" forSegment:TNArchipelTransportBarReboot];
    
    [buttonBarTransport setWidth:100 forSegment:TNArchipelTransportBarPlay];
    [buttonBarTransport setWidth:100 forSegment:TNArchipelTransportBarPause];
    [buttonBarTransport setWidth:100 forSegment:TNArchipelTransportBarStop];
    [buttonBarTransport setWidth:100 forSegment:TNArchipelTransportBarDestroy];
    [buttonBarTransport setWidth:100 forSegment:TNArchipelTransportBarReboot];
    
    [buttonBarTransport setImage:imagePlay forSegment:TNArchipelTransportBarPlay];
    [buttonBarTransport setImage:imagePause forSegment:TNArchipelTransportBarPause];
    [buttonBarTransport setImage:imageStop forSegment:TNArchipelTransportBarStop];
    [buttonBarTransport setImage:imageDestroy forSegment:TNArchipelTransportBarDestroy];
    [buttonBarTransport setImage:imageReboot forSegment:TNArchipelTransportBarReboot];
    
    [buttonBarTransport setTarget:self];
    [buttonBarTransport setAction:@selector(segmentedControlClicked:)];
}

/* TNModule implementation */
- (void)willLoad
{
    [super willLoad];

    var center = [CPNotificationCenter defaultCenter];

    [center addObserver:self selector:@selector(didNickNameUpdated:) name:TNStropheContactNicknameUpdatedNotification object:_entity];
    //[center addObserver:self selector:@selector(didPresenceUpdated:) name:TNStropheContactPresenceUpdatedNotification object:_entity];
    [center addObserver:self selector:@selector(didReceiveControlNotification:) name:TNArchipelControlNotification object:nil];
    [center postNotificationName:TNArchipelModulesReadyNotification object:self];
    
    [self registerSelector:@selector(didPushReceive:) forPushNotificationType:TNArchipelPushNotificationControl];
    [self registerSelector:@selector(didPushReceive:) forPushNotificationType:TNArchipelPushNotificationDefinition];
    
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarPlay];
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarStop];
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarDestroy];
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarPause];
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarReboot];

    [fieldName setStringValue:[_entity nickname]];
    [fieldJID setStringValue:[_entity JID]];
    [imageState setImage:[_entity statusIcon]];
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
    
    // var center = [CPNotificationCenter defaultCenter];
    // 
    // [center addObserver:self selector:@selector(didReceiveControlNotification:) name:TNArchipelControlNotification object:nil];
    
    [fieldInfoMem setStringValue:@"..."];
    [fieldInfoCPUs setStringValue:@"..."];
    [fieldInfoConsumedCPU setStringValue:@"..."];
    [fieldInfoState setStringValue:@"..."];
    [imageState setImage:nil];
    
    [buttonBarTransport setLabel:@"Pause" forSegment:TNArchipelTransportBarPause];
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarPlay];
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarStop];
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarDestroy];
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarPause];
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarReboot];
}

- (BOOL)didPushReceive:(TNStropheStanza)aStanza
{
    var sender  = [aStanza getFromNode];
    var type    = [[aStanza firstChildWithName:@"x"] valueForAttribute:@"xmlns"];
    var change  = [[aStanza firstChildWithName:@"x"] valueForAttribute:@"change"];
    
    CPLog.info("PUSH NOTIFICATION: from: " + sender + ", type: " + type + ", change: " + change);
    
    [self checkIfRunning];
    return YES;
}

- (void)didReceiveControlNotification:(CPNotification)aNotification
{
    var command                  = [aNotification userInfo];
    
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
        case TNArchipelControlStop:
            [self stop];
            break;
    }
}

/* Notifications listener */
- (void)didNickNameUpdated:(CPNotification)aNotification
{
    [fieldName setStringValue:[_entity nickname]]
}

- (void)didPresenceUpdated:(CPNotification)aNotification
{
    // [imageState setImage:[_entity statusIcon]];
    // 
    // [self checkIfRunning];
}

- (void)checkIfRunning
{
    var XMPPShow = [_entity XMPPShow];
    
    [self getVirtualMachineInfo];
    
    if ((XMPPShow == TNStropheContactStatusDND))
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
    var stanza  = [TNStropheStanza iqWithType:@"get"];
            
    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeVirtualMachineControl}];
    [stanza addChildName:@"archipel" withAttributes:{
        "action": TNArchipelTypeVirtualMachineControlInfo}];
    
    [_entity sendStanza:stanza andRegisterSelector:@selector(didReceiveVirtualMachineInfo:) ofObject:self];
}

- (BOOL)didReceiveVirtualMachineInfo:(id)aStanza
{
      if ([aStanza getType] == @"result")
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
          
          [self layoutButtons:libvirtState]
      }
      
      return NO;
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
            [self pause];
            break;
        case TNArchipelTransportBarStop:
            [self stop];
            break;
        case TNArchipelTransportBarDestroy:
            [self destroy];
            break;
        case TNArchipelTransportBarReboot:
            [self reboot];
            break;
    }
}

/* vm controls */
- (void)play
{
    var stanza  = [TNStropheStanza iqWithType:@"set"];

    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeVirtualMachineControl}];
    [stanza addChildName:@"archipel" withAttributes:{
        "action": TNArchipelTypeVirtualMachineControlCreate}];
    [_entity sendStanza:stanza andRegisterSelector:@selector(didPlay:) ofObject:self];
}

- (BOOL)didPlay:(id)aStanza
{
    var responseType    = [aStanza getType];
    var responseFrom    = [aStanza getFrom];

    if (responseType == @"result")
    {
        var libvirtID = [[aStanza firstChildWithName:@"domain"] valueForAttribute:@"id"];
        
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Virtual Machine" message:@"Virtual machine is running"];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
    
    return NO;
}


- (void)pause
{
    var stanza  = [TNStropheStanza iqWithType:@"set"];
    var selector;

    if (_VMLibvirtStatus == VIR_DOMAIN_PAUSED)
    {
        selector = @selector(didResume:)
        
        [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeVirtualMachineControl}];
        [stanza addChildName:@"archipel" withAttributes:{
            "xmlns": TNArchipelTypeVirtualMachineControl, 
            "action": TNArchipelTypeVirtualMachineControlResume}];
    }
    else
    {
        selector = @selector(didPause:)
        
        [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeVirtualMachineControl}];
        [stanza addChildName:@"archipel" withAttributes:{
            "xmlns": TNArchipelTypeVirtualMachineControl, 
            "action": TNArchipelTypeVirtualMachineControlSuspend}];
    }

    [_entity sendStanza:stanza andRegisterSelector:selector ofObject:self];
}

- (BOOL)didPause:(id)aStanza
{
    var responseType    = [aStanza getType];
    var responseFrom    = [aStanza getFrom];

    [self layoutButtons:_VMLibvirtStatus];
    
    if (responseType == @"result") 
    {
        [self enableButtonsForPaused];
        [growl pushNotificationWithTitle:@"Virtual Machine" message:@"Virtual machine is paused"];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
    
    return NO;
}

- (BOOL)didResume:(id)aStanza
{
    var responseType    = [aStanza getType];
    var responseFrom    = [aStanza getFrom];

    [self layoutButtons:_VMLibvirtStatus];
    
    if (responseType == @"result")
    {
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Virtual Machine" message:@"Virtual machine is resumed"];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
    
    return NO;
}


- (void)stop
{
    var stanza  = [TNStropheStanza iqWithType:@"set"];

    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeVirtualMachineControl}];
    [stanza addChildName:@"archipel" withAttributes:{
        "action": TNArchipelTypeVirtualMachineControlShutdown}];

    [_entity sendStanza:stanza andRegisterSelector:@selector(didStop:) ofObject:self];
}

- (BOOL)didStop:(id)aStanza
{
    var responseType    = [aStanza getType];
    var responseFrom    = [aStanza getFrom];

    if (responseType == @"result")
    {
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Virtual Machine" message:@"Virtual machine is stopped"];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
    
    return NO;
}


- (void)destroy
{
    var alert = [TNAlert alertWithTitle:@"Unplug Virtual Machine"
                                message:@"Destroying virtual machine is dangerous. It is equivalent to remove power plug of a real computer"
                                delegate:self
                                 actions:[["Unplug", @selector(performDestroy:)], ["Cancel", @selector(doNotPerformDestroy:)]]];

    [alert runModal];
}

- (void)performDestroy:(id)someUserInfo
{
    var stanza  = [TNStropheStanza iqWithType:@"set"];

    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeVirtualMachineControl}];
    [stanza addChildName:@"archipel" withAttributes:{
        "action": TNArchipelTypeVirtualMachineControlDestroy}];

    [_entity sendStanza:stanza andRegisterSelector:@selector(didDestroy:) ofObject:self];
}

- (void)doNotPerformDestroy:(id)someUserInfo
{
    [self layoutButtons:_VMLibvirtStatus];
}

- (BOOL)didDestroy:(id)aStanza
{
    var responseType    = [aStanza getType];
    var responseFrom    = [aStanza getFrom];

    if (responseType == @"result")
    {
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Virtual Machine" message:@"Virtual machine is destroyed"];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
    
    return NO;
}


- (void)reboot
{
    var stanza  = [TNStropheStanza iqWithType:@"set"];

    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeVirtualMachineControl}];
    [stanza addChildName:@"archipel" withAttributes:{
        "action": TNArchipelTypeVirtualMachineControlReboot}];

    [_entity sendStanza:stanza andRegisterSelector:@selector(didReboot:) ofObject:self];
}

- (BOOL)didReboot:(id)aStanza
{
    var responseType    = [aStanza getType];
    var responseFrom    = [aStanza getFrom];

    if (responseType == @"result")
    {
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Virtual Machine" message:@"Virtual machine is rebooting"];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
    
    return NO;
}


/* button management */

- (void)layoutButtons:(id)libvirtState
{
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
  [imageState setImage:[_entity statusIcon]];
}

- (void)enableButtonsForRunning
{
    [buttonBarTransport setSelectedSegment:TNArchipelTransportBarPlay];
    
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarPlay];
    [buttonBarTransport setEnabled:YES forSegment:TNArchipelTransportBarStop];
    [buttonBarTransport setEnabled:YES forSegment:TNArchipelTransportBarDestroy];
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
    [buttonBarTransport setEnabled:YES forSegment:TNArchipelTransportBarDestroy];
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
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarDestroy];
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
    [buttonBarTransport setSelected:NO forSegment:TNArchipelTransportBarDestroy];
    [buttonBarTransport setSelected:NO forSegment:TNArchipelTransportBarPause];
    [buttonBarTransport setSelected:NO forSegment:TNArchipelTransportBarReboot];
    
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarPlay];
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarStop];
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarDestroy];
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarPause];
    [buttonBarTransport setEnabled:NO forSegment:TNArchipelTransportBarReboot];
    [buttonBarTransport setLabel:@"Pause" forSegment:TNArchipelTransportBarPause];
    var imagePause  = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-pause.png"] size:CGSizeMake(20, 20)];
    [buttonBarTransport setImage:imagePause forSegment:TNArchipelTransportBarPause];
}

@end



