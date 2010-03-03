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

trinityTypeHypervisorControl                = @"trinity:hypervisor:control";
trinityTypeHypervisorControlAlloc           = @"alloc";
trinityTypeHypervisorControlFree            = @"free";
trinityTypeHypervisorControlRosterVM        = @"rostervm";
trinityTypeHypervisorControlHealth          = @"healthinfo";
trinityTypeHypervisorControlHealthHistory   = @"healthinfohistory";


@implementation TNHypervisorHealth : TNModule 
{
    @outlet CPTextField     fieldJID            @accessors;
    @outlet CPTextField     fieldName           @accessors;
    @outlet CPTextField     healthCPUUsage      @accessors;
    @outlet CPTextField     healthDiskUsage     @accessors;
    @outlet CPTextField     healthMemUsage      @accessors;
    @outlet CPTextField     healthMemSwapped    @accessors;
    @outlet CPTextField     healthLoad          @accessors;
    @outlet CPTextField     healthUptime        @accessors;
    @outlet CPTextField     healthInfo          @accessors;
    @outlet CPTextField     fieldTotalMemory    @accessors;
    @outlet CPTextField     fieldHalfMemory    @accessors;

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
    var cpuViewFrame = [viewGraphCPU bounds];

    _chartViewCPU   = [[LPChartView alloc] initWithFrame:cpuViewFrame];
    [_chartViewCPU setDrawView:[[LPChartDrawView alloc] init]];
    [_chartViewCPU setUserDefinedMaxValue:100];
    [_chartViewCPU setDisplayLabels:YES] // in fact this deactivates the labels... yes...
    [viewGraphCPU addSubview:_chartViewCPU];
    
    
    var memoryViewFrame = [viewGraphMemory bounds];

    _chartViewMemory   = [[LPChartView alloc] initWithFrame:memoryViewFrame];
    [_chartViewMemory setDrawView:[[LPChartDrawView alloc] init]];
    [_chartViewMemory setDisplayLabels:YES] // in fact this deactivates the labels... yes...
    [viewGraphMemory addSubview:_chartViewMemory];
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
    [[self fieldName] setStringValue:[[self contact] nickname]];
   
    [[self fieldJID] setStringValue:[[self contact] jid]];
    
    [self getHypervisorHealthHistory];
    
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


- (void)getHypervisorHealth:(CPTimer)aTimer
{
    var uid = [[[self contact] connection] getUniqueId];
    var rosterStanza = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeHypervisorControl, "to": [[self contact] fullJID], "id": uid}];
    var params;
    
    [rosterStanza addChildName:@"query" withAttributes:{"type" : trinityTypeHypervisorControlHealth}];
    
    params= [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];
    [[[self contact] connection] registerSelector:@selector(didReceiveHypervisorHealth:) ofObject:self withDict:params];
    
    [[[self contact] connection] send:rosterStanza];
}

- (void)didReceiveHypervisorHealth:(TNStropheStanza)aStanza 
{   
    if ([aStanza getType] == @"success")
    {       
        var memNode = [aStanza firstChildWithName:@"memory"];
        var freeMem = Math.round(parseInt([memNode valueForAttribute:@"free"]) / 1024)
        [[self healthMemUsage] setStringValue: freeMem + " Mo"];
        [[self healthMemSwapped] setStringValue:[memNode valueForAttribute:@"swapped"] + " Mo"];
        
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
        [[self healthInfo] setStringValue:[infoNode valueForAttribute:@"os"] + " " + [infoNode valueForAttribute:@"kname"] + " " + [infoNode valueForAttribute:@"machine"]];
        
        
        [_cpuDatasource pushData:parseInt(cpuFree)];
        [_memoryDatasource pushData:parseInt([memNode valueForAttribute:@"used"])];
        
        // reload the charts view
        [_chartViewMemory reloadData];
        [_chartViewCPU reloadData];
    }
}


- (void)getHypervisorHealthHistory
{
    var uid = [[[self contact] connection] getUniqueId];
    var rosterStanza = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeHypervisorControl, "to": [[self contact] fullJID], "id": uid}];
    var params;
    
    [rosterStanza addChildName:@"query" withAttributes:{"type" : trinityTypeHypervisorControlHealthHistory, "limit": 50}];
    
    params= [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];
    [[[self contact] connection] registerSelector:@selector(didReceiveHypervisorHealthHistory:) ofObject:self withDict:params];
    
    [[[self contact] connection] send:rosterStanza];
}



- (void)didReceiveHypervisorHealthHistory:(TNStropheStanza)aStanza 
{       
    if ([aStanza getType] == @"success")
    {   
        var stats = [aStanza childrenWithName:@"stat"];
        stats.reverse();
        for (var i = 0; i < [stats count]; i++)
        {
            var currentNode = [stats objectAtIndex:i];
            
            var memNode = [currentNode firstChildWithName:@"memory"];
            [[self healthMemUsage] setStringValue:[memNode valueForAttribute:@"free"] + "Mo / " + [memNode valueForAttribute:@"swapped"] + "Mo"];

            var cpuNode = [currentNode firstChildWithName:@"cpu"];
            var cpuFree = 100 - parseInt([cpuNode valueForAttribute:@"id"]);
            [[self healthCPUUsage] setStringValue:cpuFree + @"%"];

            [_cpuDatasource pushData:parseInt(cpuFree)];
            [_memoryDatasource pushData:parseInt([memNode valueForAttribute:@"used"])];
        }
        
        var maxMem = Math.round(parseInt([memNode valueForAttribute:@"total"]) / 1024 / 1024 )
        
        [[self fieldTotalMemory] setStringValue: maxMem + "G"];
        [[self fieldHalfMemory] setStringValue: Math.round(maxMem / 2) + "G"];
        [_chartViewMemory setUserDefinedMaxValue: parseInt([memNode valueForAttribute:@"total"])];
        
        // reload the charts view
        [_chartViewMemory reloadData];
        [_chartViewCPU reloadData];
    }
}


@end


