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
@import <LPKit/LPKit.j>
 
@import "../../TNModule.j";
@import "TNDatasourceGraphCPU.j"
@import "TNDatasourceGraphMemory.j"

trinityTypeHypervisorControl            = @"trinity:hypervisor:control";
trinityTypeHypervisorControlAlloc       = @"alloc";
trinityTypeHypervisorControlFree        = @"free";
trinityTypeHypervisorControlRosterVM    = @"rostervm";
trinityTypeHypervisorControlHealth      = @"healthinfo";


@implementation TNMainViewController : TNModule 
{
    @outlet CPTextField     fieldJID            @accessors;
    @outlet CPTextField     fieldName           @accessors;
    @outlet CPButton        buttonCreateVM      @accessors;
    @outlet CPPopUpButton   popupDeleteMachine  @accessors;
    @outlet CPButton        buttonDeleteVM      @accessors;
    @outlet CPTextField     healthCPUUsage      @accessors;
    @outlet CPTextField     healthDiskUsage     @accessors;
    @outlet CPTextField     healthMemUsage      @accessors;
    @outlet CPTextField     healthLoad          @accessors;
    @outlet CPTextField     healthUptime        @accessors;
    @outlet CPTextField     healthInfo          @accessors;
    
    @outlet CPView          viewGraphCPU        @accessors;
    @outlet CPView          viewGraphMemory     @accessors;   
    
    LPChartView                 _chartViewCPU;
    LPChartView                 _chartViewMemory;
    TNDatasourceGraphCPU        _cpuDatasource;
    TNDatasourceGraphMemory     _memoryDatasource;
    CPTimer                     _timer;
    CPNumber                    _timerInterval;
    
}

- (void)awakeFromCib
{
    //_cpuDatasource = [[TNDatasourceGraphCPU alloc] init];
    
    _chartViewCPU   = [[LPChartView alloc] initWithFrame:[viewGraphCPU bounds]];
    // [_chartViewCPU setDataSource:_cpuDatasource];
    [_chartViewCPU setDrawView:[[LPChartDrawView alloc] init]];
    
    [_chartViewCPU setDisplayGrid:YES];
    [_chartViewCPU setDisplayLabels:YES];   
    [viewGraphCPU addSubview:_chartViewCPU];
    
    
    
    //_memoryDatasource = [[TNDatasourceGraphMemory alloc] init];
    
    _chartViewMemory   = [[LPChartView alloc] initWithFrame:[viewGraphMemory bounds]];
    // [_chartViewMemory setDataSource:_memoryDatasource];
    [_chartViewMemory setDrawView:[[LPChartDrawView alloc] init]];
    
    [_chartViewMemory setDisplayGrid:YES];
    [_chartViewMemory setDisplayLabels:YES];   
    [viewGraphMemory addSubview:_chartViewMemory];
}
}


- (void)willLoad
{
    _timerInterval = 5;
    var center = [CPNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(didNickNameUpdated:) name:TNStropheContactNicknameUpdatedNotification object:nil];
    
    _memoryDatasource   = [[TNDatasourceGraphMemory alloc] init];
    _cpuDatasource      = [[TNDatasourceGraphCPU alloc] init];
    
    [_chartViewMemory setDataSource:_memoryDatasource];
    [_chartViewCPU setDataSource:_cpuDatasource];
}
    

- (void)willUnload
{
    var center = [CPNotificationCenter defaultCenter];
    [center removeObserver:self];
}

- (void)willShow
{
    
    if (_timer)
        [_timer invalidate];
    
    [[self popupDeleteMachine] removeAllItems];
    [[self fieldName] setStringValue:[[self contact] nickname]];
    
    [[self fieldJID] setStringValue:[[self contact] jid]];
    
    [self getHypervisorRoster];
    [self getHypervisorHealth:nil];
    
    _timer = [CPTimer scheduledTimerWithTimeInterval:_timerInterval target:self selector:@selector(getHypervisorHealth:) userInfo:nil repeats:YES]
}

- (void)willHide
{
    if (_timer)
        [_timer invalidate];
}



- (void)didNickNameUpdated:(CPNotification)aNotification
{
    if ([aNotification object] == [self contact])
    {
       [[self fieldName] setStringValue:[[self contact] nickname]] 
    }
}

- (void)getHypervisorRoster
{
    var uid             = [[[self contact] connection] getUniqueId];
    var rosterStanza    = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeHypervisorControl, "to": [[self contact] fullJID], "id": uid}];
    var params          = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];
        
    [rosterStanza addChildName:@"query" withAttributes:{"type" : trinityTypeHypervisorControlRosterVM}];
    
    [[[self contact] connection] registerSelector:@selector(didReceiveHypervisorRoster:) ofObject:self withDict:params];
    [[[self contact] connection] send:rosterStanza];
}

- (void)didReceiveHypervisorRoster:(id)aStanza 
{
    var queryItems  = [aStanza childrenWithName:@"item"];
    
    [[self popupDeleteMachine] removeAllItems];
    
    for (var i = 0; i < [queryItems count]; i++)
    {
        var jid     = [[queryItems objectAtIndex:i] text];
        var entry   = [[self roster] getContactFromJID:jid];
        
        if (entry) 
        {
            if ([[[entry vCard] firstChildWithName:@"TYPE"] text] == "virtualmachine")
            {
                var name = [entry nickname] + " (" + jid +")";
                var item = [[TNMenuItem alloc] initWithTitle:name action:nil keyEquivalent:nil];
                
                [item setImage:[entry statusIcon]];
                [item setStringValue:jid];
                [[self popupDeleteMachine] addItem:item];
            }
        }
    }
}

- (void)getHypervisorHealth:(CPTimer)aTimer
{
    if (![self superview])
    {
        [_timer invalidate];
        return;
    }
    var uid = [[[self contact] connection] getUniqueId];
    var rosterStanza = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeHypervisorControl, "to": [[self contact] fullJID], "id": uid}];
    var params;
    
    [rosterStanza addChildName:@"query" withAttributes:{"type" : trinityTypeHypervisorControlHealth}];
    
    params= [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];
    [[[self contact] connection] registerSelector:@selector(didReceiveHypervisorHealth:) ofObject:self withDict:params];
    
    [[[self contact] connection] send:rosterStanza];
}

- (void)didReceiveHypervisorHealth:(id)aStanza 
{   
    if ([aStanza getType] == @"success")
    {       
        var memNode = [aStanza firstChildWithName:@"memory"];
        [[self healthMemUsage] setStringValue:[memNode valueForAttribute:@"free"] + "Mo / " + [memNode valueForAttribute:@"swapped"] + "Mo"];

        var diskNode = [aStanza firstChildWithName:@"disk"];
        [[self healthDiskUsage] setStringValue:[diskNode valueForAttribute:@"used-percentage"]];

        var loadNode = [aStanza firstChildWithName:@"load"];
        [[self healthLoad] setStringValue:[loadNode valueForAttribute:@"five"]];

        var uptimeNode = [aStanza firstChildWithName:@"uptime"];
        [[self healthUptime] setStringValue:[uptimeNode valueForAttribute:@"up"]];

        var cpuNode = [aStanza firstChildWithName:@"cpu"];
        var cpuFree = 100 - parseInt([cpuNode valueForAttribute:@"id"]);
        [[self healthCPUUsage] setStringValue:cpuFree + @"%"];

        var infoNode = [aStanza firstChildWithName:@"uname"];
        [[self healthInfo] setStringValue:[infoNode valueForAttribute:@"os"] + " " + [infoNode valueForAttribute:@"kname"]];
        
        [_cpuDatasource pushData:parseInt(cpuFree)];
        [_memoryDatasource pushData:parseInt([memNode valueForAttribute:@"free"])];
        
        
        [_chartViewMemory reloadData];
        [_chartViewCPU reloadData];

        // var frame = [viewGraphCPU bounds];
        // 
        // [_chartViewCPU removeFromSuperview];
        // _chartViewCPU   = [[LPChartView alloc] initWithFrame:frame];
        // [_chartViewCPU setDataSource:_cpuDatasource];
        // [_chartViewCPU setDrawView:[[LPChartDrawView alloc] init]];
        // [_chartViewCPU setDisplayGrid:YES];
        // [_chartViewCPU setDisplayLabels:YES];
        // [viewGraphCPU addSubview:_chartViewCPU];
        // 
        //     
        // [_chartViewMemory removeFromSuperview];
        // _chartViewMemory   = [[LPChartView alloc] initWithFrame:frame];
        // [_chartViewMemory setDataSource:_memoryDatasource];
        // [_chartViewMemory setDrawView:[[LPChartDrawView alloc] init]];
        // [_chartViewMemory setDisplayGrid:YES];
        // [_chartViewMemory setDisplayLabels:YES];
        // [viewGraphMemory addSubview:_chartViewMemory];

    }
}


//actions
- (IBAction) addVirtualMachine:(id)sender
{
    var uid             = [[[self contact] connection] getUniqueId];
    var creationStanza  = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeHypervisorControl, "to": [[self contact] fullJID], "id": uid}];
    var uuid            = [CPString UUID];
    var params          = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];
    
    [creationStanza addChildName:@"query" withAttributes:{"type" : trinityTypeHypervisorControlAlloc}];
    [creationStanza addChildName:@"jid" withAttributes:{}];
    [creationStanza addTextNode:uuid];
    
    [[[self contact] connection] registerSelector:@selector(didAllocVirtualMachine:) ofObject:self withDict:params];
    [[[self contact] connection] send:creationStanza];
    [buttonCreateVM setEnabled:NO];
}

- (void)didAllocVirtualMachine:(id)aStanza
{
    [buttonCreateVM setEnabled:YES];
    
    if ([aStanza getType] == @"success")
    {
        var item    = [[self popupDeleteMachine] selectedItem];
        var vmJid   = [[[aStanza firstChildWithName:@"query"] firstChildWithName:@"virtualmachine"] valueForAttribute:@"jid"];

        [[TNViewLog sharedLogger] log:@"sucessfully create a virtual machine"];
        [[self roster] addContact:vmJid withName:@"New Virtual Machine" inGroup:@"Virtual Machines"];        
        
        [self getHypervisorRoster];
    }
    else
    {
        [CPAlert alertWithTitle:@"Error" message:@"Unable to create virtual machine" style:CPCriticalAlertStyle];
        [[TNViewLog sharedLogger] log:@"error during creation a virtual machine"];
    }
}

- (IBAction) deleteVirtualMachine:(id)sender
{
    var alert = [[CPAlert alloc] init];
    
    [buttonDeleteVM setEnabled:NO];
    
    // TODO avoid people to delete running machine.
    
    [alert setDelegate:self];
    [alert setTitle:@"Destroying a Virtual Machine"];
    [alert setMessageText:@"Are you sure you want to completely remove this virtual machine ?"];
    [alert setWindowStyle:CPHUDBackgroundWindowMask];
    [alert addButtonWithTitle:@"Yes"];
    [alert addButtonWithTitle:@"No"];
    [alert runModal];
}

- (void)alertDidEnd:(CPAlert)theAlert returnCode:(int)returnCode 
{
    if (returnCode == 0)
    {
        var item        = [[self popupDeleteMachine] selectedItem];
        var uid         = [[[self contact] connection] getUniqueId];
        var freeStanza  = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeHypervisorControl, "to": [[self contact] fullJID], "id": uid}];
        var params      = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];
        
        [freeStanza addChildName:@"query" withAttributes:{"type" : trinityTypeHypervisorControlFree}];
        [freeStanza addTextNode:[item stringValue]];
        
        [[[self contact] connection] registerSelector:@selector(didFreeVirtualMachine:) ofObject:self withDict:params];
        [[[self contact] connection] send:freeStanza];
    }
    else
    {
        [buttonDeleteVM setEnabled:YES];
    }
}

- (void)didFreeVirtualMachine:(id)aStanza
{
    [buttonDeleteVM setEnabled:YES];
    
    if ([aStanza getType] == @"success")
    {
        var item = [[self popupDeleteMachine] selectedItem];
        
        [[TNViewLog sharedLogger] log:@"sucessfully deallocating a virtual machine"];
        [[self roster] removeContact:[item stringValue]];
        [self getHypervisorRoster];
    }
    else
    {
        [CPAlert alertWithTitle:@"Error" message:@"Unable to free virtual machine" style:CPCriticalAlertStyle];
        [[TNViewLog sharedLogger] log:@"error during free a virtual machine"];
    }
}

@end

@implementation CPString (CPStringWithUUIDSeparated)
{
}
+ (CPString)UUID
{
    var g = @"";
    
    for(var i = 0; i < 32; i++)
    {
        if ((i == 8) || (i == 12) || (i == 16) || (i == 20))
            g += '-';
        g += FLOOR(RAND() * 0xF).toString(0xF);
    }
    
    return g;
}
@end


