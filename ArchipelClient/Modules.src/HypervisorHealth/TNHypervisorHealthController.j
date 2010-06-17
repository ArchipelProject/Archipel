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

@import "LPChartView.j"
@import "TNDatasourceGraphCPU.j"
@import "TNDatasourceGraphMemory.j"
@import "TNDatasourceGraphDisks.j"

TNArchipelTypeHypervisorHealth           = @"archipel:hypervisor:health";
TNArchipelTypeHypervisorHealthInfo       = @"info";
TNArchipelTypeHypervisorHealthHistory    = @"history";


@implementation TNHypervisorHealthController : TNModule
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
    float                       _timerInterval;
    CPNumber                    _statsHistoryCollectionSize;
}

- (void)awakeFromCib
{
    [fieldJID setSelectable:YES];
    
    var bundle  = [CPBundle bundleForClass:[self class]];
    var spinner = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"loading.gif"]];

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
    _timerInterval              = [moduleBundle objectForInfoDictionaryKey:@"TNArchipelHealthRefreshStatsInterval"];
    _statsHistoryCollectionSize = [moduleBundle objectForInfoDictionaryKey:@"TNArchipelHealthStatsHistoryCollectionSize"];
}


// Modules implementation
- (void)willLoad
{
    [super willLoad];
    
    var center = [CPNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(didNickNameUpdated:) name:TNStropheContactNicknameUpdatedNotification object:_entity];
    
    _memoryDatasource   = [[TNDatasourceGraphMemory alloc] init];
    _cpuDatasource      = [[TNDatasourceGraphCPU alloc] init];

    [_chartViewMemory setDataSource:_memoryDatasource];
    [_chartViewCPU setDataSource:_cpuDatasource];

    [self getHypervisorHealthHistory];
    
    [center postNotificationName:TNArchipelModulesReadyNotification object:self];
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

    [fieldName setStringValue:[_entity nickname]];
    [fieldJID setStringValue:[_entity JID]];
}


- (void)didNickNameUpdated:(CPNotification)aNotification
{
    if ([aNotification object] == _entity)
    {
       [fieldName setStringValue:[_entity nickname]]
    }
}

- (void)getHypervisorHealth:(CPTimer)aTimer
{
    var stanza    = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeHypervisorHealth}];
    [stanza addChildName:@"archipel" withAttributes:{"xmlns": TNArchipelTypeHypervisorHealth, "action": TNArchipelTypeHypervisorHealthInfo}];
    
    [self sendStanza:stanza andRegisterSelector:@selector(didReceiveHypervisorHealth:)];
}

- (void)didReceiveHypervisorHealth:(TNStropheStanza)aStanza
{
    if ([aStanza getType] == @"result")
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

        /* reload the charts view */
        [_chartViewMemory reloadData];
        [_chartViewCPU reloadData];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}


- (void)getHypervisorHealthHistory
{
    var stanza    = [TNStropheStanza iqWithType:@"get"];
    
    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeHypervisorHealth}];
    [stanza addChildName:@"archipel" withAttributes:{
        "xmlns": TNArchipelTypeHypervisorHealth, 
        "action": TNArchipelTypeHypervisorHealthHistory,
        "limit": _statsHistoryCollectionSize}];
    

    [[self imageCPULoading] setHidden:NO];
    [[self imageMemoryLoading] setHidden:NO];

    [self sendStanza:stanza andRegisterSelector:@selector(didReceiveHypervisorHealthHistory:)];
}

- (BOOL)didReceiveHypervisorHealthHistory:(TNStropheStanza)aStanza
{
    if ([aStanza getType] == @"result")
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
        }

        var maxMem = Math.round(parseInt([memNode valueForAttribute:@"total"]) / 1024 / 1024 )

        [[self fieldTotalMemory] setStringValue: maxMem + "G"];
        [[self fieldHalfMemory] setStringValue: Math.round(maxMem / 2) + "G"];
        [_chartViewMemory setUserDefinedMaxValue: parseInt([memNode valueForAttribute:@"total"])];

        var diskNode = [aStanza firstChildWithName:@"disk"];
        [[self healthDiskUsage] setStringValue:[diskNode valueForAttribute:@"used-percentage"]];

        /* reload the charts view */
        [_chartViewMemory reloadData];
        [_chartViewCPU reloadData];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }

    [[self imageCPULoading] setHidden:YES];
    [[self imageMemoryLoading] setHidden:YES];

    [self getHypervisorHealth:nil];

    /* now get health every 5 seconds */
    _timer = [CPTimer scheduledTimerWithTimeInterval:_timerInterval target:self selector:@selector(getHypervisorHealth:) userInfo:nil repeats:YES]

    return NO;
}


@end


