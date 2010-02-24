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
    
    @outlet CPButton        buttonPlay  @accessors;
    @outlet CPButton        buttonPause @accessors;
    @outlet CPButton        buttonStop  @accessors;

    CPTimer     _timer;
    CPNumber    _VMLibvirtStatus;
}

- (void)awakeFromCib
{   
    [[self buttonPlay] setImage:[[CPImage alloc] initWithContentsOfFile:[[self moduleBundle] pathForResource:@"vm_play.png"]]];
    [[self buttonStop] setImage:[[CPImage alloc] initWithContentsOfFile:[[self moduleBundle] pathForResource:@"vm_stop.png"]]];
    [[self buttonPause] setImage:[[CPImage alloc] initWithContentsOfFile:[[self moduleBundle] pathForResource:@"vm_pause.png"]]];
}

- (void)willBeDisplayed
{
    //not interessting.
}

- (void)willBeUnDisplayed
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
}


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

- (void)initializeWithContact:(TNStropheContact)aContact andRoster:(TNStropheRoster)aRoster
{
    [super initializeWithContact:aContact andRoster:aRoster]
    
    [[self buttonPlay] setEnabled:NO];
    [[self buttonStop] setEnabled:NO];
    [[self buttonPause] setEnabled:NO];
    
    var center = [CPNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(didNickNameUpdated:) name:TNStropheContactNicknameUpdatedNotification object:nil];
    [center addObserver:self selector:@selector(didNickPresenceUpdated:) name:TNStropheContactPresenceUpdatedNotification object:nil];
    
    [[self fieldVMName] setStringValue:[[self contact] nickname]];
    [[self fieldVMJid] setStringValue:[[self contact] jid]];
    
    [self getVirtualMachineInfo:nil];
    
    _timer = [CPTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(getVirtualMachineInfo:) userInfo:nil repeats:YES];
}


- (void)getVirtualMachineInfo:(CPTimer)aTimer
{
    if (![self superview])
    {
        [_timer invalidate];
        return;
    }
    
    var uid = [[[self contact] connection] getUniqueId];
    var infoStanza = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeVirtualMachineControlInfo, "to": [[self contact] fullJID], "id": uid}];
    var params;
    
    [infoStanza addChildName:@"query" withAttributes:{"xmlns" : trinityTypeVirtualMachineControl}];
    
    params= [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];
    [[[self contact] connection] registerSelector:@selector(didReceiveVirtualMachineInfo:) ofObject:self withDict:params];
    
    [[[self contact] connection] send:[infoStanza stanza]];
}

- (void)didReceiveVirtualMachineInfo:(id)aStanza 
{
    if (aStanza.getAttribute("type") == @"success")
    {       
        var infoNode = aStanza.getElementsByTagName("info")[0];
        var cpuTime = parseInt(infoNode.getAttribute("cpuTime"));
        var mem = parseInt(infoNode.getAttribute("memory"));
        
        cpuTime /= 6000000000;
        cpuTime = Math.round(cpuTime);
        mem = mem / 1024;
        
        [[self fieldInfoMem] setStringValue:mem + @" Mo"];
        [[self fieldInfoCPUs] setStringValue:infoNode.getAttribute("nrVirtCpu")];
        [[self fieldInfoConsumedCPU] setStringValue:cpuTime + @" min."];

        var libvirtSate = infoNode.getAttribute("state");
        var humanState;
        
        _VMLibvirtStatus = libvirtSate;
        
        switch ([libvirtSate intValue])
        {
            case VIR_DOMAIN_NOSTATE:
                humanState = @"No status";
                break;
            case VIR_DOMAIN_RUNNING:
                [[self buttonPause] setTitle:@"Pause"];
                [[self buttonPlay] setEnabled:NO];
                [[self buttonStop] setEnabled:YES];
                [[self buttonPause] setEnabled:YES];
                humanState = @"Running";
                break;
            case VIR_DOMAIN_BLOCKED:
                humanState = @"Blocked";
                break;
            case VIR_DOMAIN_PAUSED:
                [[self buttonPause] setTitle:@"Resume"];
                [[self buttonPlay] setEnabled:NO];
                [[self buttonStop] setEnabled:YES];
                [[self buttonPause] setEnabled:YES];
                humanState = @"Paused";
                break;
            case VIR_DOMAIN_SHUTDOWN:
                [[self buttonPause] setTitle:@"Pause"];
                [[self buttonPlay] setEnabled:YES];
                [[self buttonStop] setEnabled:NO];
                [[self buttonPause] setEnabled:NO];
                humanState = @"Shutdown";
                break;
            case VIR_DOMAIN_SHUTOFF:
                [[self buttonPause] setTitle:@"Pause"];
                [[self buttonPlay] setEnabled:YES];
                [[self buttonStop] setEnabled:NO];
                [[self buttonPause] setEnabled:NO];
                humanState = @"Shutdown";
                break;
            case VIR_DOMAIN_CRASHED:
                humanState = @"Crashed";
                break;
        }
        [[self fieldInfoState] setStringValue:humanState];
    }
}


- (IBAction)play:(id)sender
{
    [sender setEnabled:NO];
    
    var createStanza = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeVirtualMachineControlCreate, "to": [[self contact] fullJID]}];
    var uuid = [CPString UUID];

    [createStanza addChildName:@"query" withAttributes:{"xmlns" : trinityTypeVirtualMachineControl}];
    [createStanza addChildName:@"jid" withAttributes:{}];
    [createStanza addTextNode:uuid];
    
    [[[self contact] connection] send:[createStanza tree]];
}

- (IBAction)pause:(id)sender
{
    var pauseStanza;
    
    if (_VMLibvirtStatus == VIR_DOMAIN_PAUSED)
    {
        pauseStanza = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeVirtualMachineControlResume, "to": [[self contact] fullJID]}];
        [sender setTitle:@"Resume"];
    }
    else
    {
        pauseStanza = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeVirtualMachineControlSuspend, "to": [[self contact] fullJID]}];
        [sender setTitle:@"Pause"];
    }
        
    var uuid = [CPString UUID];

    [pauseStanza addChildName:@"query" withAttributes:{"xmlns" : trinityTypeVirtualMachineControl}];
    [pauseStanza addChildName:@"jid" withAttributes:{}];
    [pauseStanza addTextNode:uuid];
    
    [[[self contact] connection] send:[pauseStanza tree]];
    [self getVirtualMachineInfo:nil];
}

- (IBAction)stop:(id)sender
{
    [sender setEnabled:NO];
    var stopStanza = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeVirtualMachineControlShutdown, "to": [[self contact] fullJID]}];
    var uuid = [CPString UUID];

    [stopStanza addChildName:@"query" withAttributes:{"xmlns" : trinityTypeVirtualMachineControl}];
    [stopStanza addChildName:@"jid" withAttributes:{}];
    [stopStanza addTextNode:uuid];
    
    [[[self contact] connection] send:[stopStanza tree]];
    [self getVirtualMachineInfo:nil];
}
@end



