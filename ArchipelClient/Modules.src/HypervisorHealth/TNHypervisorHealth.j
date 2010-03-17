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
 
@import "TNDatasourceGraphCPU.j"
@import "TNDatasourceGraphMemory.j"
@import "TNDatasourceGraphDisks.j"

TNArchipelTypeHypervisorHealth           = @"archipel:hypervisor:health";
TNArchipelTypeHypervisorHealthInfo       = @"info";
TNArchipelTypeHypervisorHealthHistory    = @"history";


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
    @outlet CPTextField     fieldHalfMemory     @accessors;

    @outlet CPImageView     imageMemoryLoading  @accessors;
    @outlet CPImageView     imageCPULoading     @accessors;

    @outlet CPView          viewGraphCPU        @accessors;
    @outlet CPView          viewGraphMemory     @accessors;
    
    
    LPChartView                 _chartViewCPU;
    LPChartView                 _chartViewMemory;
    LPPieChartView              _chartViewDisk;
    
    TNDatasourceGraphCPU        _cpuDatasource;
    TNDatasourceGraphMemory     _memoryDatasource;
    
    CPTimer                     _timer;
    CPNumber                    _timerInterval;
    CPNumber                    _statsHistoryCollectionSize;
}

- (void)awakeFromCib
{
    var mainBundle  = [CPBundle mainBundle];
    var spinner     = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"spinner.gif"]];
    
    [[self imageCPULoading] setImage:spinner];
    [[self imageMemoryLoading] setImage:spinner];
    [[self imageCPULoading] setHidden:YES];
    [[self imageMemoryLoading] setHidden:YES];
    
    
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
    
    var moduleBundle = [CPBundle bundleForClass:[self class]]
    _timerInterval              = [moduleBundle objectForInfoDictionaryKey:@"RefreshStatsInterval"];
    _statsHistoryCollectionSize = [moduleBundle objectForInfoDictionaryKey:@"StatsHistoryCollectionSize"];
}


// Modules implementation
- (void)willLoad
{
    [super willLoad];
    
    var center = [CPNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(didNickNameUpdated:) name:TNStropheContactNicknameUpdatedNotification object:nil];
    
    _memoryDatasource   = [[TNDatasourceGraphMemory alloc] init];
    _cpuDatasource      = [[TNDatasourceGraphCPU alloc] init];
    
    [_chartViewMemory setDataSource:_memoryDatasource];
    [_chartViewCPU setDataSource:_cpuDatasource];
    
    [self getHypervisorHealthHistory];
}

- (void)willUnload
{
    [super willUnload];
    
    if (_timer)
        [_timer invalidate];
    
    [_cpuDatasource removeAllObjects];
    [_memoryDatasource removeAllObjects];
}

- (void)willShow
{
    [super willShow];
    
    [[self fieldName] setStringValue:[[self entity] nickname]];
    [[self fieldJID] setStringValue:[[self entity] jid]];
}


- (void)didNickNameUpdated:(CPNotification)aNotification
{
    if ([aNotification object] == [self entity])
    {
       [[self fieldName] setStringValue:[[self entity] nickname]]
    }
}

- (void)getHypervisorHealth:(CPTimer)aTimer
{
    var rosterStanza    = [TNStropheStanza iqWithAttributes:{"type" : TNArchipelTypeHypervisorHealth}];
    
    [rosterStanza addChildName:@"query" withAttributes:{"type" : TNArchipelTypeHypervisorHealthInfo}];
    
    [self sendStanza:rosterStanza andRegisterSelector:@selector(didReceiveHypervisorHealth:)];
}

- (void)didReceiveHypervisorHealth:(TNStropheStanza)aStanza 
{
    if ([aStanza getType] == @"success")
    {       
        var memNode = [aStanza firstChildWithName:@"memory"];
        var freeMem = Math.round(parseInt([memNode valueForAttribute:@"free"]) / 1024)
        var swapped = Math.round(parseInt([memNode valueForAttribute:@"swapped"]) / 1024);
        [[self healthMemUsage] setStringValue:freeMem + " Mo"];
        [[self healthMemSwapped] setStringValue:swapped + " Mo"];
        
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
        [_memoryDatasource pushDataMemUsed:parseInt([memNode valueForAttribute:@"used"])];
        // [_memoryDatasource pushDataMemSwapped:parseInt([memNode valueForAttribute:@"swapped"]) * 1024];
        
        // reload the charts view
        [_chartViewMemory reloadData];
        [_chartViewCPU reloadData];
    }
}


- (void)getHypervisorHealthHistory
{
    var rosterStanza    = [TNStropheStanza iqWithAttributes:{"type": TNArchipelTypeHypervisorHealth}];
    
    [rosterStanza addChildName:@"query" withAttributes:{"type" : TNArchipelTypeHypervisorHealthHistory, "limit": _statsHistoryCollectionSize}];
    
    [self sendStanza:rosterStanza andRegisterSelector:@selector(didReceiveHypervisorHealthHistory:)];
}

- (BOOL)didReceiveHypervisorHealthHistory:(TNStropheStanza)aStanza 
{
    if ([aStanza getType] == @"success")
    {
        var stats = [aStanza childrenWithName:@"stat"];
        stats.reverse();
        
        for (var i = 0; i < [stats count]; i++)
        {
            var currentNode = [stats objectAtIndex:i];
            
            var memNode = [currentNode firstChildWithName:@"memory"];
            var freeMem = Math.round(parseInt([memNode valueForAttribute:@"free"]) / 1024);
            var swapped = Math.round(parseInt([memNode valueForAttribute:@"swapped"]) / 1024);
            
            [[self healthMemUsage] setStringValue:freeMem + " Mo"];
            [[self healthMemSwapped] setStringValue:swapped + " Mo"];
            
            
            var cpuNode = [currentNode firstChildWithName:@"cpu"];
            var cpuFree = 100 - parseInt([cpuNode valueForAttribute:@"id"]);
            
            [[self healthCPUUsage] setStringValue:cpuFree + @"%"];

            [_cpuDatasource pushData:parseInt(cpuFree)];
            [_memoryDatasource pushDataMemUsed:parseInt([memNode valueForAttribute:@"used"])];
            // [_memoryDatasource pushDataMemSwapped:parseInt([memNode valueForAttribute:@"swapped"]) * 1024];
        }
        
        var maxMem = Math.round(parseInt([memNode valueForAttribute:@"total"]) / 1024 / 1024 )
        
        [[self fieldTotalMemory] setStringValue: maxMem + "G"];
        [[self fieldHalfMemory] setStringValue: Math.round(maxMem / 2) + "G"];
        [_chartViewMemory setUserDefinedMaxValue: parseInt([memNode valueForAttribute:@"total"])];
        
        
        var diskNode = [aStanza firstChildWithName:@"disk"];
        [[self healthDiskUsage] setStringValue:[diskNode valueForAttribute:@"used-percentage"]];
        
        // reload the charts view
        [_chartViewMemory reloadData];
        [_chartViewCPU reloadData];
    }
    
    [[self imageCPULoading] setHidden:YES];
    [[self imageMemoryLoading] setHidden:YES];
    
    
    [self getHypervisorHealth:nil];
    
    // now get health every 5 seconds
    _timer = [CPTimer scheduledTimerWithTimeInterval:_timerInterval target:self selector:@selector(getHypervisorHealth:) userInfo:nil repeats:YES]
    
    return NO;
}


@end


