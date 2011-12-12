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

@import <AppKit/CPImageView.j>
@import <AppKit/CPSearchField.j>
@import <AppKit/CPTableView.j>
@import <AppKit/CPTabView.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPView.j>

@import <LPKit/LPChartView.j>
@import <TNKit/TNTableViewDataSource.j>

@import "TNCellLogView.j"
@import "TNCellPartitionView.j"
@import "TNDatasourceChartView.j"
@import "TNDatasourcePieChartView.j"
@import "TNLogEntryObject.j"
@import "TNPartitionObject.j"


var TNArchipelTypeHypervisorHealth              = @"archipel:hypervisor:health",
    TNArchipelTypeHypervisorHealthInfo          = @"info",
    TNArchipelTypeHypervisorHealthHistory       = @"history",
    TNArchipelTypeHypervisorHealthLog           = @"logs",
    TNArchipelHealthRefreshBaseKey              = @"TNArchipelHealthRefreshBaseKey_";

/*! @defgroup  hypervisorhealth Module Hypervisor Health
    @desc This module display statistics about the hypervisor health
*/

/*! @ingroup hypervisorhealth
    The main module controller
*/
@implementation TNHypervisorHealthController : TNModule
{
    @outlet CPImageView         imageCPULoading;
    @outlet CPImageView         imageDiskLoading;
    @outlet CPImageView         imageLoadLoading;
    @outlet CPImageView         imageMemoryLoading;
    @outlet CPSearchField       filterLogField;
    @outlet CPTableView         tableLogs;
    @outlet CPTableView         tablePartitions;
    @outlet CPTabView           tabViewInfos;
    @outlet CPTextField         fieldHalfMemory;
    @outlet CPTextField         fieldPreferencesAutoRefresh;
    @outlet CPTextField         fieldPreferencesMaxItems;
    @outlet CPTextField         fieldPreferencesMaxLogEntries;
    @outlet CPTextField         fieldTotalMemory;
    @outlet CPTextField         healthCPUUsage;
    @outlet CPTextField         healthDiskUsage;
    @outlet CPTextField         healthInfo;
    @outlet CPTextField         healthLibvirtDriverVersion;
    @outlet CPTextField         healthLibvirtVersion;
    @outlet CPTextField         healthLoad;
    @outlet CPTextField         healthMemSwapped;
    @outlet CPTextField         healthMemUsage;
    @outlet CPTextField         healthUptime;
    @outlet CPView              viewCharts;
    @outlet CPView              viewGraphCPUContainer;
    @outlet CPView              viewGraphDiskContainer;
    @outlet CPView              viewGraphLoadContainer;
    @outlet CPView              viewGraphMemoryContainer;
    @outlet CPView              viewGraphNetworkContainer;
    @outlet CPView              viewLogs;
    @outlet LPChartView         chartViewCPU;
    @outlet LPChartView         chartViewLoad;
    @outlet LPChartView         chartViewMemory;
    @outlet LPChartView         chartViewNetwork;
    @outlet TNCellLogView       logDataViewPrototype;
    @outlet TNCellPartitionView partitionDataViewPrototype;
    @outlet TNSwitch            switchPreferencesAutoRefresh;

    BOOL                        _needReloadDataForCharts;
    BOOL                        _needReloadDataForLogs;
    CPTimer                     _timerLogs;
    CPTimer                     _timerStats;
    TNDatasourceChartView       _cpuDatasource;
    TNDatasourceChartView       _loadDatasource;
    TNDatasourceChartView       _memoryDatasource;
    TNDatasourceChartView       _networkDatasource;
    TNTableViewDataSource       _datasourceLogs;
    TNTableViewDataSource       _datasourcePartitions;
}


#pragma mark -
#pragma mark Initialization

/*! triggered at cib awaking
*/
- (void)awakeFromCib
{
    var bundle      = [CPBundle bundleForClass:[self class]],
        spinner     = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"loading.gif"]],
        defaults    = [CPUserDefaults standardUserDefaults];

    // register defaults
    [defaults registerDefaults:[CPDictionary dictionaryWithObjectsAndKeys:
            [bundle objectForInfoDictionaryKey:@"TNArchipelHealthRefreshStatsInterval"], @"TNArchipelHealthRefreshStatsInterval",
            [bundle objectForInfoDictionaryKey:@"TNArchipelHealthStatsHistoryCollectionSize"], @"TNArchipelHealthStatsHistoryCollectionSize",
            [bundle objectForInfoDictionaryKey:@"TNArchipelHealthMaxLogEntry"], @"TNArchipelHealthMaxLogEntry",
            [bundle objectForInfoDictionaryKey:@"TNArchipelHealthAutoRefreshStats"], @"TNArchipelHealthAutoRefreshStats"
    ]];

    [imageCPULoading setImage:spinner];
    [imageMemoryLoading setImage:spinner];
    [imageLoadLoading setImage:spinner];
    [imageDiskLoading setImage:spinner];

    [imageCPULoading setHidden:YES];
    [imageMemoryLoading setHidden:YES];
    [imageLoadLoading setHidden:YES];
    [imageDiskLoading setHidden:YES];

    var colorGraphsContainer = [CPColor whiteColor];
    [viewGraphCPUContainer setBackgroundColor:colorGraphsContainer];
    [viewGraphMemoryContainer setBackgroundColor:colorGraphsContainer];
    [viewGraphLoadContainer setBackgroundColor:colorGraphsContainer];
    [viewGraphDiskContainer setBackgroundColor:colorGraphsContainer];
    [viewGraphNetworkContainer setBackgroundColor:colorGraphsContainer];

    [viewGraphCPUContainer setBorderRadius:4];
    [viewGraphMemoryContainer setBorderRadius:4];
    [viewGraphLoadContainer setBorderRadius:4];
    [viewGraphDiskContainer setBorderRadius:4];
    [viewGraphNetworkContainer setBorderRadius:4];

    [chartViewCPU setDrawViewPadding:1.0];
    [chartViewCPU setLabelViewHeight:0.0];
    [chartViewCPU setDrawView:[[TNChartDrawView alloc] init]];
    [chartViewCPU setFixedMaxValue:100];
    [chartViewCPU setDisplayLabels:NO];
    [[chartViewCPU gridView] setBackgroundColor:[CPColor whiteColor]];

    [chartViewMemory setDrawViewPadding:1.0];
    [chartViewMemory setLabelViewHeight:0.0];
    [chartViewMemory setDrawView:[[TNChartDrawView alloc] init]];
    [chartViewMemory setDisplayLabels:NO];
    [[chartViewMemory gridView] setBackgroundColor:[CPColor whiteColor]];

    [chartViewLoad setAutoresizingMask:CPViewWidthSizable];
    [chartViewLoad setDrawViewPadding:1.0];
    [chartViewLoad setLabelViewHeight:0.0];
    [chartViewLoad setDrawView:[[TNChartDrawView alloc] init]];
    [chartViewLoad setFixedMaxValue:10];
    [chartViewLoad setDisplayLabels:YES];
    [[chartViewLoad gridView] setBackgroundColor:[CPColor whiteColor]];

    [chartViewNetwork setAutoresizingMask:CPViewWidthSizable];
    [chartViewNetwork setDrawViewPadding:1.0];
    [chartViewNetwork setLabelViewHeight:0.0];
    [chartViewNetwork setDrawView:[[TNChartDrawView alloc] init]];
    [chartViewNetwork setDisplayLabels:NO];
    [[chartViewNetwork gridView] setBackgroundColor:[CPColor whiteColor]];

    // tabview
    [tabViewInfos setBorderColor:[CPColor colorWithHexString:@"789EB3"]]
    [tabViewInfos setDelegate:self];

    var tabViewItemCharts = [[CPTabViewItem alloc] initWithIdentifier:@"charts"],
        tabViewItemLogs = [[CPTabViewItem alloc] initWithIdentifier:@"logs"],
        scrollViewChart = [[CPScrollView alloc] initWithFrame:CPRectMake(0, 0, 0, 0)];

    [tabViewItemCharts setLabel:CPBundleLocalizedString(@"Charts", @"Charts")];
    [tabViewItemCharts setView:scrollViewChart];
    [tabViewInfos addTabViewItem:tabViewItemCharts];

    [viewCharts setAutoresizingMask:CPViewWidthSizable];
    var newFrameSize = [viewCharts frameSize];
    newFrameSize.width = [scrollViewChart contentSize].width;
    [viewCharts setFrameSize:newFrameSize];
    [scrollViewChart setAutohidesScrollers:YES];
    [scrollViewChart setDocumentView:viewCharts];

    [tabViewItemLogs setLabel:CPBundleLocalizedString(@"Logs", @"Logs")];
    [tabViewItemLogs setView:viewLogs];
    [tabViewInfos addTabViewItem:tabViewItemLogs];


    // tables partition
    _datasourcePartitions = [[TNTableViewDataSource alloc] init];

    [tablePartitions setDataSource:_datasourcePartitions];
    [_datasourcePartitions setTable:tablePartitions];

    [[tablePartitions tableColumnWithIdentifier:@"self"] setDataView:[partitionDataViewPrototype duplicate]];
    [tablePartitions setSelectionHighlightStyle:CPTableViewSelectionHighlightStyleNone];

    // logs tables
    _datasourceLogs = [[TNTableViewDataSource alloc] init];
    [tableLogs setDelegate:self];
    [tableLogs setDataSource:_datasourceLogs];

    [_datasourceLogs setTable:tableLogs];
    [_datasourceLogs setSearchableKeyPaths:[@"level", @"date", @"message"]];

    [filterLogField setTarget:_datasourceLogs];
    [filterLogField setAction:@selector(filterObjects:)];

    [[tableLogs tableColumnWithIdentifier:@"self"] setDataView:[logDataViewPrototype duplicate]];
    [tableLogs setSelectionHighlightStyle:CPTableViewSelectionHighlightStyleNone];


    [fieldPreferencesAutoRefresh setToolTip:CPBundleLocalizedString(@"Set the delay between asking hypervisor statistics", @"Set the delay between asking hypervisor statistics")];
    [fieldPreferencesMaxItems setToolTip:CPBundleLocalizedString(@"Set the max number of statistic entries to fetch", @"Set the max number of statistic entries to fetch")];
    [fieldPreferencesMaxLogEntries setToolTip:CPBundleLocalizedString(@"Set the max number of log item to fetch", @"Set the max number of log item to fetch")];
    [switchPreferencesAutoRefresh setToolTip:CPBundleLocalizedString(@"Activate the statistics auto fetching", @"Activate the statistics auto fetching")];
}


#pragma mark -
#pragma mark TNModule overrides

/*! called when module is loaded
*/
- (BOOL)willLoad
{
    if (![super willLoad])
        return NO;

    var defaults    = [CPUserDefaults standardUserDefaults],
        key         = TNArchipelHealthRefreshBaseKey + [_entity JID],
        shouldBeOn  = ([defaults boolForKey:key] === nil) ? YES : [defaults boolForKey:key];

    [[CPNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_didUpdatePresence:)
                                                 name:TNStropheContactPresenceUpdatedNotification
                                               object:_entity];

    _memoryDatasource   = [[TNDatasourceChartView alloc] initWithNumberOfSets:1];
    _cpuDatasource      = [[TNDatasourceChartView alloc] initWithNumberOfSets:1];
    _loadDatasource     = [[TNDatasourceChartView alloc] initWithNumberOfSets:3];
    _networkDatasource  = nil; // dynamically allocated according to the number of nics

    [chartViewMemory setDataSource:_memoryDatasource];
    [chartViewCPU setDataSource:_cpuDatasource];
    [chartViewLoad setDataSource:_loadDatasource];
    [tablePartitions setDataSource:_datasourcePartitions];
    [tableLogs setDataSource:_datasourceLogs];

    [self getHypervisorLog:nil];
    [self getHypervisorHealthHistory];

    return YES;
}

/*! called when module is unloaded
*/
- (void)willUnload
{
    if (_timerStats)
    {
        [_timerStats invalidate];
        CPLog.debug("timer for stats invalidated");
        _timerStats = nil;
    }

    if (_timerLogs)
    {
        [_timerLogs invalidate];
        CPLog.debug("timer for logs invalidated");
        _timerLogs = nil;
    }

    if (_cpuDatasource)
        [_cpuDatasource removeAllObjects];
    if (_memoryDatasource)
        [_memoryDatasource removeAllObjects];
    if (_loadDatasource)
        [_loadDatasource removeAllObjects];
    if (_networkDatasource)
        [_networkDatasource removeAllObjects];
    if (_datasourcePartitions)
        [_datasourcePartitions removeAllObjects];
    if (_datasourceLogs)
        [_datasourceLogs removeAllObjects];

    [super willUnload];
}

/*! called when module becomes visible
*/
- (BOOL)willShow
{
    if (![super willShow])
        return NO;

    return YES;
}

/*! called when user saves preferences
*/
- (void)savePreferences
{
    var defaults = [CPUserDefaults standardUserDefaults];

    [defaults setInteger:[fieldPreferencesAutoRefresh intValue] forKey:@"TNArchipelHealthRefreshStatsInterval"];
    [defaults setInteger:[fieldPreferencesMaxItems intValue] forKey:@"TNArchipelHealthStatsHistoryCollectionSize"];
    [defaults setInteger:[fieldPreferencesMaxLogEntries intValue] forKey:@"TNArchipelHealthMaxLogEntry"];
    [defaults setBool:[switchPreferencesAutoRefresh isOn] forKey:@"TNArchipelHealthAutoRefreshStats"];

    [self handleAutoRefresh];
}

/*! called when user gets preferences
*/
- (void)loadPreferences
{
    var defaults = [CPUserDefaults standardUserDefaults];

    [fieldPreferencesAutoRefresh setIntValue:[defaults integerForKey:@"TNArchipelHealthRefreshStatsInterval"]];
    [fieldPreferencesMaxItems setIntValue:[defaults integerForKey:@"TNArchipelHealthStatsHistoryCollectionSize"]];
    [fieldPreferencesMaxLogEntries setIntValue:[defaults integerForKey:@"TNArchipelHealthMaxLogEntry"]];
    [switchPreferencesAutoRefresh setOn:[defaults boolForKey:@"TNArchipelHealthAutoRefreshStats"] animated:YES sendAction:NO];
}


#pragma mark -
#pragma mark Notification handlers

/*! called when presence of user changed and evenutally stops the timers
    @param aNotification the notification
*/
- (void)_didUpdatePresence:(CPNotification)aNotification
{
    if ([_entity XMPPShow] === TNStropheContactStatusOffline)
    {
        if (_timerStats)
        {
            [_timerStats invalidate];
            CPLog.debug("timer for stats invalidated");
            _timerStats = nil;
        }

        if (_timerLogs)
        {
            [_timerLogs invalidate];
            CPLog.debug("timer for logs invalidated");
            _timerLogs = nil;
        }
    }
    else
    {
        [self handleAutoRefresh];
    }
}


#pragma mark -
#pragma mark Utilities

/*! parse diskNode info to get a CPTableView valid object
    @parse diskNode TNStropheStanza containing the disk info
*/
- (CPDictionary)parseDiskNodes:(TNStropheStanza)diskNode
{
    var ret = [CPArray array];

    for (var i = 0; i < [[diskNode childrenWithName:@"partition"] count]; i++)
    {
        var partition   = [[diskNode childrenWithName:@"partition"] objectAtIndex:i],
            part        = [[TNPartitionObject alloc] init];

        [part setCapacity:[partition valueForAttribute:@"capacity"]];
        [part setMount:[partition valueForAttribute:@"mount"]];
        [part setUsed:[partition valueForAttribute:@"used"]];
        [part setAvailable:[partition valueForAttribute:@"available"]];

        [ret addObject:part];
    }

    return ret;
}

/*! populate the network chart dataview
    @param networkNodes CPArray of TNXMLNode containing the network information
*/
- (void)popupateNetworkDatasource:(CPArray)networkNodes
{
    if (!_networkDatasource)
    {
        _networkDatasource = [[TNDatasourceChartView alloc] initWithNumberOfSets:[networkNodes count]];
        [chartViewNetwork setDataSource:_networkDatasource];
    }

    for (var i = 0 ; i < [networkNodes count]; i++)
    {
        var node = [networkNodes objectAtIndex:i],
            value = parseInt([node valueForAttribute:@"delta"]);
        [_networkDatasource pushData:value inSet:i];
    }

}


#pragma mark -
#pragma mark Actions

/*! Action that make the auto refresh on or off
    @param sender the sender of the action
*/
- (IBAction)handleAutoRefresh
{
    var defaults    = [CPUserDefaults standardUserDefaults];

    if (![defaults boolForKey:@"TNArchipelHealthAutoRefreshStats"])
    {
        if (_timerStats)
        {
            [_timerStats invalidate];
            CPLog.debug("timer for stats invalidated");
            _timerStats = nil;
        }

        if (_timerLogs)
        {
            [_timerLogs invalidate];
            CPLog.debug("timer for logs invalidated");
            _timerLogs = nil;
        }
    }
    else
    {
        var interval = MAX([defaults integerForKey:@"TNArchipelHealthRefreshStatsInterval"], 5.0);

        if (!_timerStats)
        {
            _timerStats = [CPTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(getHypervisorHealth:) userInfo:nil repeats:YES];
            CPLog.debug("timer for stats started from switch action");
        }
        if (!_timerLogs)
        {
            _timerLogs  = [CPTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(getHypervisorLog:) userInfo:nil repeats:YES];
            CPLog.debug("timer for logs started from switch action");
        }
    }
}


#pragma mark -
#pragma mark XMPP Management

/*! get the hypervisor health
    it is launched by a timer every X seconds, as defined in the info.plist
    @param aTimer the timer that sent the message
*/
- (void)getHypervisorHealth:(CPTimer)aTimer
{
    var stanza    = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorHealth}];
    [stanza addChildWithName:@"archipel" andAttributes:{"xmlns": TNArchipelTypeHypervisorHealth, "action": TNArchipelTypeHypervisorHealthInfo}];

    [imageCPULoading setHidden:NO];
    [imageMemoryLoading setHidden:NO];
    [imageLoadLoading setHidden:NO];
    [imageDiskLoading setHidden:NO];

    [self sendStanza:stanza andRegisterSelector:@selector(_didReceiveHypervisorHealth:)];
}

/*! compute the hypervisor health info received
    @param aStanza the stanza containing the answer of the request
*/
- (BOOL)_didReceiveHypervisorHealth:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        try
        {
            var memNode         = [aStanza firstChildWithName:@"memory"],
                freeMem         = Math.round([[memNode valueForAttribute:@"free"] intValue] / 1024),
                swapped         = Math.round([[memNode valueForAttribute:@"swapped"] intValue] / 1024),
                memUsed         = [[memNode valueForAttribute:@"used"] intValue],
                diskNode        = [aStanza firstChildWithName:@"disk"],
                loadNode        = [aStanza firstChildWithName:@"load"],
                loadOne         = [[loadNode valueForAttribute:@"one"] floatValue],
                loadFive        = [[loadNode valueForAttribute:@"five"] floatValue],
                loadFifteen     = [[loadNode valueForAttribute:@"fifteen"] floatValue],
                uptimeNode      = [aStanza firstChildWithName:@"uptime"],
                cpuNode         = [aStanza firstChildWithName:@"cpu"],
                cpuFree         = 100 - [[cpuNode valueForAttribute:@"id"] intValue],
                infoNode        = [aStanza firstChildWithName:@"uname"],
                libvirtNode     = [aStanza firstChildWithName:@"libvirt"],
                driverNode      = [aStanza firstChildWithName:@"driver"],
                networkNodes    = [aStanza childrenWithName:@"network"];

            [healthMemUsage setStringValue:freeMem + CPBundleLocalizedString(@" MB", @" MB")];
            [healthMemSwapped setStringValue:swapped + CPBundleLocalizedString(@" MB", @" MB")];
            [healthDiskUsage setStringValue:[diskNode valueForAttribute:@"capacity"]];
            [healthLoad setStringValue:loadFive];
            [healthUptime setStringValue:[uptimeNode valueForAttribute:@"up"]];
            [healthCPUUsage setStringValue:cpuFree + @"%"];
            [healthInfo setStringValue:[infoNode valueForAttribute:@"os"] + " " + [infoNode valueForAttribute:@"kname"] + " " + [infoNode valueForAttribute:@"machine"]];
            [healthLibvirtVersion setStringValue:[CPString stringWithFormat:@"%s.%s.%s",
                                                        [libvirtNode valueForAttribute:@"major"],
                                                        [libvirtNode valueForAttribute:@"minor"],
                                                        [libvirtNode valueForAttribute:@"release"]]];
            [healthLibvirtDriverVersion setStringValue:[CPString stringWithFormat:@"%s.%s.%s",
                                                        [driverNode valueForAttribute:@"major"],
                                                        [driverNode valueForAttribute:@"minor"],
                                                        [driverNode valueForAttribute:@"release"]]];
            [_cpuDatasource pushData:cpuFree inSet:0];
            [_memoryDatasource pushData:memUsed inSet:0];
            [_loadDatasource pushData:loadOne inSet:0];
            [_loadDatasource pushData:loadFive inSet:1];
            [_loadDatasource pushData:loadFifteen inSet:2];

            [self popupateNetworkDatasource:networkNodes];

            [_datasourcePartitions removeAllObjects];
            [_datasourcePartitions setContent:[self parseDiskNodes:diskNode]];

            /* reload the charts view */
            if ([[tabViewInfos selectedTabViewItem] identifier] == @"charts")
            {
                [chartViewMemory reloadData];
                [chartViewCPU reloadData];
                [chartViewLoad reloadData];
                [chartViewNetwork reloadData];
                [tablePartitions reloadData];
                _needReloadDataForCharts = NO;
            }
            else
                _needReloadDataForCharts = YES;

            CPLog.debug("current stats recovered");
        }
        catch(e)
        {
            CPLog.warn("populating the charts has been interupted");
        }
    }
    else if ([aStanza type] == @"error")
    {
        [self handleIqErrorFromStanza:aStanza];
    }

    [imageCPULoading setHidden:YES];
    [imageMemoryLoading setHidden:YES];
    [imageLoadLoading setHidden:YES];
    [imageDiskLoading setHidden:YES];

    return NO;
}

/*! get the hypervisor health history
*/
- (void)getHypervisorHealthHistory
{
    var stanza    = [TNStropheStanza iqWithType:@"get"],
        defaults  = [CPUserDefaults standardUserDefaults];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorHealth}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorHealthHistory,
        "limit": [defaults integerForKey:@"TNArchipelHealthStatsHistoryCollectionSize"]}];

    [imageCPULoading setHidden:NO];
    [imageMemoryLoading setHidden:NO];
    [imageLoadLoading setHidden:NO];
    [imageDiskLoading setHidden:NO];

    [self setModuleStatus:TNArchipelModuleStatusWaiting];
    [self sendStanza:stanza andRegisterSelector:@selector(_didReceiveHypervisorHealthHistory:)];
}

/*! compute the hypervisor health history info received
    @param aStanza the stanza containing the answer of the request
*/
- (BOOL)_didReceiveHypervisorHealthHistory:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        try
        {
            var stats = [aStanza childrenWithName:@"stat"];

            stats.reverse();

            for (var i = 0; i < [stats count]; i++)
            {
                var currentNode     = [stats objectAtIndex:i],
                    memNode         = [currentNode firstChildWithName:@"memory"],
                    freeMem         = Math.round([[memNode valueForAttribute:@"free"] intValue] / 1024),
                    memUsed         = [[memNode valueForAttribute:@"used"] intValue],
                    swapped         = Math.round([[memNode valueForAttribute:@"swapped"] intValue] / 1024),
                    cpuNode         = [currentNode firstChildWithName:@"cpu"],
                    cpuFree         = 100 - [[cpuNode valueForAttribute:@"id"] intValue],
                    loadNode        = [currentNode firstChildWithName:@"load"],
                    loadOne         = [[loadNode valueForAttribute:@"one"] floatValue],
                    loadFive        = [[loadNode valueForAttribute:@"five"] floatValue],
                    loadFifteen     = [[loadNode valueForAttribute:@"fifteen"] floatValue],
                    networkNodes    = [currentNode childrenWithName:@"network"];

                [healthMemUsage setStringValue:freeMem + CPBundleLocalizedString(" MB", " MB")];
                [healthMemSwapped setStringValue:swapped + CPBundleLocalizedString(" MB", " MB")];

                [healthCPUUsage setStringValue:cpuFree + @"%"];

                [_cpuDatasource pushData:cpuFree inSet:0];
                [_memoryDatasource pushData:memUsed inSet:0];
                [_loadDatasource pushData:loadOne inSet:0];
                [_loadDatasource pushData:loadFive inSet:1];
                [_loadDatasource pushData:loadFifteen inSet:2];

                [self popupateNetworkDatasource:networkNodes];
            }

            var maxMem      = Math.round([[memNode valueForAttribute:@"total"] floatValue] / 1024 / 1024),
                diskNode    = [aStanza firstChildWithName:@"disk"];

            [fieldTotalMemory setStringValue:maxMem + CPBundleLocalizedString("GB", "GB")];
            [fieldHalfMemory setStringValue:Math.round((maxMem / 2) * 10) / 10 + CPBundleLocalizedString("GB", "GB")];
            [chartViewMemory setFixedMaxValue:[memNode valueForAttribute:@"total"]];

            [_datasourcePartitions removeAllObjects];
            [_datasourcePartitions setContent:[self parseDiskNodes:diskNode]];

            [healthDiskUsage setStringValue:[diskNode valueForAttribute:@"capacity"]];

            /* reload the charts view */
            if ([[tabViewInfos selectedTabViewItem] identifier] == @"charts")
            {
                [chartViewMemory reloadData];
                [chartViewCPU reloadData];
                [chartViewLoad reloadData];
                [chartViewNetwork reloadData];
                [tablePartitions reloadData];
                _needReloadDataForCharts = NO;
            }
            else
                _needReloadDataForCharts = YES;

            CPLog.debug("Stats history recovered");
        }
        catch(e)
        {
            CPLog.warn("populating the charts has been interupted");
        }
        [self setModuleStatus:TNArchipelModuleStatusReady];
    }
    else if ([aStanza type] == @"error")
    {
        [self setModuleStatus:TNArchipelModuleStatusError];
        [self handleIqErrorFromStanza:aStanza];
    }

    [imageCPULoading setHidden:YES];
    [imageMemoryLoading setHidden:YES];
    [imageLoadLoading setHidden:YES];
    [imageDiskLoading setHidden:YES];

    [self getHypervisorHealth:nil];
    [self handleAutoRefresh];

    return NO;
}

/*! get the hypervisor logs
*/
- (void)getHypervisorLog:(CPTimer)aTimer
{
    var stanza      = [TNStropheStanza iqWithType:@"get"],
        defaults    = [CPUserDefaults standardUserDefaults];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorHealth}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "xmlns": TNArchipelTypeHypervisorHealth,
        "action": TNArchipelTypeHypervisorHealthLog,
        "limit": MAX([defaults integerForKey:@"TNArchipelHealthMaxLogEntry"], 10)}];

    [self sendStanza:stanza andRegisterSelector:@selector(_didReceiveHypervisorLog:)];
}

/*! compute the hypervisor logs info received
    @param aStanza the stanza containing the answer of the request
*/
- (BOOL)_didReceiveHypervisorLog:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        var logNodes = [aStanza childrenWithName:@"log"];

        logNodes.reverse();

        [_datasourceLogs removeAllObjects];

        for (var i = 0; i < [logNodes count]; i++)
        {
            var currentLog  = [logNodes objectAtIndex:i],
                lvl         = [currentLog valueForAttribute:@"level"],
                date        = [currentLog valueForAttribute:@"date"],
                file        = [currentLog valueForAttribute:@"file"],
                method      = [currentLog valueForAttribute:@"method"],
                message     = [currentLog text],
                logEntry    = [TNLogEntry logEntryWithLevel:lvl date:date file:file method:method message:message];

            [_datasourceLogs addObject:logEntry];
        }
        if ([[tabViewInfos selectedTabViewItem] identifier] == @"logs")
        {
            [tableLogs reloadData];
            _needReloadDataForLogs = NO;
        }
        else
            _needReloadDataForLogs = YES;

        CPLog.debug("logs recovered");

    }
    else if ([aStanza type] == @"error")
    {
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}


#pragma mark -
#pragma mark Delegate

/*! CPTableViewDelegate
*/
- (float)tableView:(CPTableView)tableView heightOfRow:(int)row
{
    var logEntry = [_datasourceLogs objectAtIndex:row],
        theWidth = [tableView frameSize].width - 34;

    return [[logEntry message] sizeWithFont:[CPFont systemFontFace] inWidth:theWidth].height + 37;
}

/*! CPTabViewDelegate
*/
- (void)tabView:(CPTabView)aTabView didSelectTabViewItem:(CPTabViewItem)anItem
{
    if ([anItem identifier] == @"logs" && _needReloadDataForLogs)
    {
        [tableLogs reloadData];
        _needReloadDataForLogs = NO;
    }

    if ([anItem identifier] == @"charts" && _needReloadDataForCharts)
    {
        [chartViewMemory reloadData];
        [chartViewCPU reloadData];
        [chartViewLoad reloadData];
        [chartViewNetwork reloadData];
        [tablePartitions reloadData];
        _needReloadDataForCharts = NO;
    }
}

@end


// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNHypervisorHealthController], comment);
}
