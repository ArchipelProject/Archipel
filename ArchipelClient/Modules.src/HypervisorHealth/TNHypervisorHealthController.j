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

@import "TNDatasourceChartView.j";
@import "TNDatasourcePieChartView.j";
@import "TNLogEntryObject.j";

TNArchipelTypeHypervisorHealth              = @"archipel:hypervisor:health";
TNArchipelTypeHypervisorHealthInfo          = @"info";
TNArchipelTypeHypervisorHealthHistory       = @"history";
TNArchipelTypeHypervisorHealthLog           = @"logs";

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
    @outlet CPScrollView        scrollViewLogsTable;
    @outlet CPSearchField       filterLogField;
    @outlet CPTabView           tabViewInfos;
    @outlet CPTextField         fieldHalfMemory;
    @outlet CPTextField         fieldJID;
    @outlet CPTextField         fieldName;
    @outlet CPTextField         fieldPreferencesAutoRefresh;
    @outlet CPTextField         fieldPreferencesMaxItems;
    @outlet CPTextField         fieldPreferencesMaxLogEntries;
    @outlet CPTextField         fieldTotalMemory;
    @outlet CPTextField         healthCPUUsage;
    @outlet CPTextField         healthDiskUsage;
    @outlet CPTextField         healthInfo;
    @outlet CPTextField         healthLoad;
    @outlet CPTextField         healthMemSwapped;
    @outlet CPTextField         healthMemUsage;
    @outlet CPTextField         healthUptime;
    @outlet CPView              viewCharts;
    @outlet CPView              viewGrapDiskContainer;
    @outlet CPView              viewGraphCPU;
    @outlet CPView              viewGraphCPUContainer;
    @outlet CPView              viewGraphDisk;
    @outlet CPView              viewGraphLoad;
    @outlet CPView              viewGraphLoadContainer;
    @outlet CPView              viewGraphMemory;
    @outlet CPView              viewGraphMemoryContainer;
    @outlet CPView              viewLogs;
    @outlet CPView              viewLogsTableContainer;
    @outlet TNSwitch            switchPreferencesShowColunmFile;
    @outlet TNSwitch            switchPreferencesShowColunmMethod;
    @outlet TNSwitch            switchPreferencesAutoRefresh;

    BOOL                        _tableLogDisplayFileColumn;
    BOOL                        _tableLogDisplayMethodColumn;
    CPNumber                    _statsHistoryCollectionSize;
    CPTableView                 _tableLogs;
    CPTimer                     _timerLogs;
    CPTimer                     _timerStats;
    float                       _timerInterval;
    int                         _maxLogEntries;
    LPChartView                 _chartViewCPU;
    LPChartView                 _chartViewLoad;
    LPChartView                 _chartViewMemory;
    LPPieChartView              _chartViewDisk;
    TNDatasourceChartView       _cpuDatasource;
    TNDatasourceChartView       _loadDatasource;
    TNDatasourceChartView       _memoryDatasource;
    TNDatasourcePieChartView    _disksDatasource
    TNTableViewDataSource       _datasourceLogs;
}


//#pragma mark -
//#pragma mark Initialization

/*! triggered at cib awaking
*/
- (void)awakeFromCib
{
    [fieldJID setSelectable:YES];

    var bundle      = [CPBundle bundleForClass:[self class]],
        spinner     = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"loading.gif"]],
        defaults    = [CPUserDefaults standardUserDefaults];

    // register defaults defaults
    [defaults registerDefaults:[CPDictionary dictionaryWithObjectsAndKeys:
            [bundle objectForInfoDictionaryKey:@"TNArchipelHealthRefreshStatsInterval"], @"TNArchipelHealthRefreshStatsInterval",
            [bundle objectForInfoDictionaryKey:@"TNArchipelHealthStatsHistoryCollectionSize"], @"TNArchipelHealthStatsHistoryCollectionSize",
            [bundle objectForInfoDictionaryKey:@"TNArchipelHealthMaxLogEntry"], @"TNArchipelHealthMaxLogEntry",
            [bundle objectForInfoDictionaryKey:@"TNArchipelHealthTableLogDisplayMethodColumn"], @"TNArchipelHealthTableLogDisplayMethodColumn",
            [bundle objectForInfoDictionaryKey:@"TNArchipelHealthTableLogDisplayFileColumn"], @"TNArchipelHealthTableLogDisplayFileColumn",
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

    [viewGraphCPUContainer setBackgroundColor:[CPColor colorWithHexString:@"F5F6F7"]];
    [viewGraphMemoryContainer setBackgroundColor:[CPColor colorWithHexString:@"F5F6F7"]];
    [viewGraphLoadContainer setBackgroundColor:[CPColor colorWithHexString:@"F5F6F7"]];
    [viewGrapDiskContainer setBackgroundColor:[CPColor colorWithHexString:@"F5F6F7"]];

    [viewGraphCPUContainer setBorderRadius:4];
    [viewGraphMemoryContainer setBorderRadius:4];
    [viewGraphLoadContainer setBorderRadius:4];
    [viewGrapDiskContainer setBorderRadius:4];

    var cpuViewFrame    = [viewGraphCPU bounds],
        memoryViewFrame = [viewGraphMemory bounds],
        loadViewFrame   = [viewGraphLoad bounds],
        diskViewFrame   = [viewGraphDisk bounds];

    _chartViewCPU   = [[LPChartView alloc] initWithFrame:cpuViewFrame];
    [_chartViewCPU setDrawViewPadding:1.0];
    [_chartViewCPU setLabelViewHeight:0.0];
    [_chartViewCPU setDrawView:[[TNChartDrawView alloc] init]];
    [_chartViewCPU setFixedMaxValue:100];
    [_chartViewCPU setDisplayLabels:NO];
    [[_chartViewCPU gridView] setBackgroundColor:[CPColor whiteColor]];
    [viewGraphCPU addSubview:_chartViewCPU];

    _chartViewMemory   = [[LPChartView alloc] initWithFrame:memoryViewFrame];
    [_chartViewMemory setDrawViewPadding:1.0];
    [_chartViewMemory setLabelViewHeight:0.0];
    [_chartViewMemory setDrawView:[[TNChartDrawView alloc] init]];
    [_chartViewMemory setDisplayLabels:NO];
    [[_chartViewMemory gridView] setBackgroundColor:[CPColor whiteColor]];
    [viewGraphMemory addSubview:_chartViewMemory];

    _chartViewLoad   = [[LPChartView alloc] initWithFrame:loadViewFrame];
    [_chartViewLoad setDrawViewPadding:1.0];
    [_chartViewLoad setLabelViewHeight:0.0];
    [_chartViewLoad setDrawView:[[TNChartDrawView alloc] init]];
    [_chartViewLoad setFixedMaxValue:10];
    [_chartViewLoad setDisplayLabels:YES];
    [[_chartViewLoad gridView] setBackgroundColor:[CPColor whiteColor]];
    [viewGraphLoad addSubview:_chartViewLoad];

    _chartViewDisk   = [[LPPieChartView alloc] initWithFrame:diskViewFrame];
    [_chartViewDisk setDrawView:[[TNPieChartDrawView alloc] init]];
    [viewGraphDisk addSubview:_chartViewDisk];
    [_chartViewDisk setDelegate:self];


    _timerInterval                  = [defaults floatForKey:@"TNArchipelHealthRefreshStatsInterval"];
    _statsHistoryCollectionSize     = [defaults integerForKey:@"TNArchipelHealthStatsHistoryCollectionSize"];
    _maxLogEntries                  = [defaults integerForKey:@"TNArchipelHealthMaxLogEntry"];
    _tableLogDisplayFileColumn      = [defaults boolForKey:@"TNArchipelHealthTableLogDisplayFileColumn"];
    _tableLogDisplayMethodColumn    = [defaults boolForKey:@"TNArchipelHealthTableLogDisplayMethodColumn"];


    // tabview
    [tabViewInfos setBorderColor:[CPColor colorWithHexString:@"789EB3"]]

    var tabViewItemCharts = [[CPTabViewItem alloc] initWithIdentifier:@"id1"],
        tabViewItemLogs = [[CPTabViewItem alloc] initWithIdentifier:@"id2"];

    [tabViewItemCharts setLabel:@"Charts"];
    [tabViewItemCharts setView:viewCharts];
    [tabViewInfos addTabViewItem:tabViewItemCharts];

    [tabViewItemLogs setLabel:@"Logs"];
    [tabViewItemLogs setView:viewLogs];
    [tabViewInfos addTabViewItem:tabViewItemLogs];

    // logs tables
    _datasourceLogs = [[TNTableViewDataSource alloc] init];
    _tableLogs      = [[CPTableView alloc] initWithFrame:[scrollViewLogsTable bounds]];

    [viewLogsTableContainer setBorderedWithHexColor:@"#C0C7D2"];
    [scrollViewLogsTable setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [scrollViewLogsTable setAutohidesScrollers:NO];
    [scrollViewLogsTable setDocumentView:_tableLogs];

    [_tableLogs setUsesAlternatingRowBackgroundColors:YES];
    [_tableLogs setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [_tableLogs setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [_tableLogs setAllowsColumnReordering:NO];
    [_tableLogs setAllowsColumnResizing:YES];
    [_tableLogs setAllowsEmptySelection:YES];
    [_tableLogs setAllowsMultipleSelection:NO];

    var columnLogLevel      = [[CPTableColumn alloc] initWithIdentifier:@"level"],
        columnLogDate       = [[CPTableColumn alloc] initWithIdentifier:@"date"],
        columnLogFile       = [[CPTableColumn alloc] initWithIdentifier:@"file"],
        columnLogMethod     = [[CPTableColumn alloc] initWithIdentifier:@"method"],
        columnLogMessage    = [[CPTableColumn alloc] initWithIdentifier:@"message"];

    [columnLogLevel setWidth:50];
    [columnLogLevel setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"level" ascending:YES]];
    [[columnLogLevel headerView] setStringValue:@"Level"];

    [columnLogDate setWidth:125];
    [columnLogDate setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]];
    [[columnLogDate headerView] setStringValue:@"Date"];

    [columnLogFile setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"file" ascending:YES]];
    [[columnLogFile headerView] setStringValue:@"file"];

    [columnLogMethod setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"method" ascending:YES]];
    [[columnLogMethod headerView] setStringValue:@"method"];

    [columnLogMessage setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"message" ascending:YES]];
    [[columnLogMessage headerView] setStringValue:@"message"];

    [_tableLogs addTableColumn:columnLogLevel];
    [_tableLogs addTableColumn:columnLogDate];

    if (_tableLogDisplayFileColumn)
        [_tableLogs addTableColumn:columnLogFile];

    if (_tableLogDisplayMethodColumn)
        [_tableLogs addTableColumn:columnLogMethod];

    [_tableLogs addTableColumn:columnLogMessage];

    [_datasourceLogs setTable:_tableLogs];
    [_datasourceLogs setSearchableKeyPaths:[@"level", @"date", @"message"]];

    [filterLogField setTarget:_datasourceLogs];
    [filterLogField setAction:@selector(filterObjects:)];
}


//#pragma mark -
//#pragma mark TNModule overrides

/*! called when module is loaded
*/
- (void)willLoad
{
    [super willLoad];

    var center      = [CPNotificationCenter defaultCenter],
        defaults    = [CPUserDefaults standardUserDefaults],
        key         = TNArchipelHealthRefreshBaseKey + [_entity JID],
        shouldBeOn  = ([defaults boolForKey:key] === nil) ? YES : [defaults boolForKey:key];

    [center addObserver:self selector:@selector(_didUpdateNickName:) name:TNStropheContactNicknameUpdatedNotification object:_entity];

    _memoryDatasource   = [[TNDatasourceChartView alloc] initWithNumberOfSets:1];
    _cpuDatasource      = [[TNDatasourceChartView alloc] initWithNumberOfSets:1];
    _loadDatasource     = [[TNDatasourceChartView alloc] initWithNumberOfSets:3];
    _disksDatasource    = [[TNDatasourcePieChartView alloc] init];

    [_chartViewMemory setDataSource:_memoryDatasource];
    [_chartViewCPU setDataSource:_cpuDatasource];
    [_chartViewLoad setDataSource:_loadDatasource];
    [_chartViewDisk setDataSource:_disksDatasource];
    [_tableLogs setDataSource:_datasourceLogs];

    [self getHypervisorLog:nil];
    [self getHypervisorHealthHistory];

    [center postNotificationName:TNArchipelModulesReadyNotification object:self];
}

/*! called when module is unloaded
*/
- (void)willUnload
{
    [super willUnload];

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

    [_cpuDatasource removeAllObjects];
    [_memoryDatasource removeAllObjects];
    [_loadDatasource removeAllObjects];
    [_disksDatasource removeAllObjects];
    [_datasourceLogs removeAllObjects];
}

/*! called when module becomes visible
*/
- (void)willShow
{
    [super willShow];

    [fieldName setStringValue:[_entity nickname]];
    [fieldJID setStringValue:[_entity JID]];
}

/*! called when user saves preferences
*/
- (void)savePreferences
{
    var defaults = [CPUserDefaults standardUserDefaults];

    [defaults setInteger:[fieldPreferencesAutoRefresh intValue] forKey:@"TNArchipelHealthRefreshStatsInterval"];
    [defaults setInteger:[fieldPreferencesMaxItems intValue] forKey:@"TNArchipelHealthStatsHistoryCollectionSize"];
    [defaults setInteger:[fieldPreferencesMaxLogEntries intValue] forKey:@"TNArchipelHealthMaxLogEntry"];
    [defaults setBool:[switchPreferencesShowColunmMethod isOn] forKey:@"TNArchipelHealthTableLogDisplayMethodColumn"];
    [defaults setBool:[switchPreferencesShowColunmFile isOn] forKey:@"TNArchipelHealthTableLogDisplayFileColumn"];
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
    [switchPreferencesShowColunmMethod setOn:[defaults boolForKey:@"TNArchipelHealthTableLogDisplayMethodColumn"] animated:YES sendAction:NO];
    [switchPreferencesShowColunmFile setOn:[defaults boolForKey:@"TNArchipelHealthTableLogDisplayFileColumn"] animated:YES sendAction:NO];
    [switchPreferencesAutoRefresh setOn:[defaults boolForKey:@"TNArchipelHealthAutoRefreshStats"] animated:YES sendAction:NO];
}


//#pragma mark -
//#pragma mark Notification handlers

/*! called when contact nickname has been updated
    @param aNotification the notification
*/
- (void)_didUpdateNickName:(CPNotification)aNotification
{
    if ([aNotification object] == _entity)
    {
       [fieldName setStringValue:[_entity nickname]]
    }
}


//#pragma mark -
//#pragma mark Actions

/*! Action that make the auto-refresh on or off
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
        if (!_timerStats)
        {
            _timerStats = [CPTimer scheduledTimerWithTimeInterval:_timerInterval target:self selector:@selector(getHypervisorHealth:) userInfo:nil repeats:YES];
            CPLog.debug("timer for stats started from switch action");
        }
        if (!_timerLogs)
        {
            _timerLogs  = [CPTimer scheduledTimerWithTimeInterval:_timerInterval target:self selector:@selector(getHypervisorLog:) userInfo:nil repeats:YES];
            CPLog.debug("timer for logs started from switch action");
        }
    }
}


//#pragma mark -
//#pragma mark XMPP Management

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
            var memNode     = [aStanza firstChildWithName:@"memory"],
                freeMem     = Math.round([[memNode valueForAttribute:@"free"] intValue] / 1024),
                swapped     = Math.round([[memNode valueForAttribute:@"swapped"] intValue] / 1024),
                memUsed     = [[memNode valueForAttribute:@"used"] intValue],
                diskNode    = [aStanza firstChildWithName:@"disk"],
                diskPerc    = [[diskNode valueForAttribute:@"used-percentage"] intValue],
                loadNode    = [aStanza firstChildWithName:@"load"],
                loadOne     = [[loadNode valueForAttribute:@"one"] floatValue],
                loadFive    = [[loadNode valueForAttribute:@"five"] floatValue],
                loadFifteen = [[loadNode valueForAttribute:@"fifteen"] floatValue],
                uptimeNode  = [aStanza firstChildWithName:@"uptime"],
                cpuNode     = [aStanza firstChildWithName:@"cpu"],
                cpuFree     = 100 - [[cpuNode valueForAttribute:@"id"] intValue],
                infoNode    = [aStanza firstChildWithName:@"uname"];

            [healthMemUsage setStringValue:freeMem + " Mo"];
            [healthMemSwapped setStringValue:swapped + " Mo"];

            [healthDiskUsage setStringValue:diskPerc];

            [healthLoad setStringValue:loadFive];

            [healthUptime setStringValue:[uptimeNode valueForAttribute:@"up"]];

            [healthCPUUsage setStringValue:cpuFree + @"%"];

            [healthInfo setStringValue:[infoNode valueForAttribute:@"os"] + " " + [infoNode valueForAttribute:@"kname"] + " " + [infoNode valueForAttribute:@"machine"]];

            [_cpuDatasource pushData:cpuFree inSet:0];
            [_memoryDatasource pushData:memUsed inSet:0];
            [_loadDatasource pushData:loadOne inSet:0];
            [_loadDatasource pushData:loadFive inSet:1];
            [_loadDatasource pushData:loadFifteen inSet:2];

            [_disksDatasource removeAllObjects];
            [_disksDatasource pushData:diskPerc];
            [_disksDatasource pushData:(100 - diskPerc)];

            /* reload the charts view */
            [_chartViewMemory reloadData];
            [_chartViewCPU reloadData];
            [_chartViewLoad reloadData];
            [_chartViewDisk reloadData];
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
    var stanza    = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorHealth}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorHealthHistory,
        "limit": _statsHistoryCollectionSize}];

    [imageCPULoading setHidden:NO];
    [imageMemoryLoading setHidden:NO];
    [imageLoadLoading setHidden:NO];
    [imageDiskLoading setHidden:NO];

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
                var currentNode = [stats objectAtIndex:i],
                    memNode     = [currentNode firstChildWithName:@"memory"],
                    freeMem     = Math.round([[memNode valueForAttribute:@"free"] intValue] / 1024),
                    memUsed     = [[memNode valueForAttribute:@"used"] intValue],
                    swapped     = Math.round([[memNode valueForAttribute:@"swapped"] intValue] / 1024),
                    cpuNode     = [currentNode firstChildWithName:@"cpu"],
                    cpuFree     = 100 - [[cpuNode valueForAttribute:@"id"] intValue],
                    loadNode    = [currentNode firstChildWithName:@"load"],
                    loadOne     = [[loadNode valueForAttribute:@"one"] floatValue],
                    loadFive    = [[loadNode valueForAttribute:@"five"] floatValue],
                    loadFifteen = [[loadNode valueForAttribute:@"fifteen"] floatValue];

                [healthMemUsage setStringValue:freeMem + " Mo"];
                [healthMemSwapped setStringValue:swapped + " Mo"];

                [healthCPUUsage setStringValue:cpuFree + @"%"];

                [_cpuDatasource pushData:cpuFree inSet:0];
                [_memoryDatasource pushData:memUsed inSet:0];
                [_loadDatasource pushData:loadOne inSet:0];
                [_loadDatasource pushData:loadFive inSet:1];
                [_loadDatasource pushData:loadFifteen inSet:2];
            }

            var maxMem      = Math.round([[memNode valueForAttribute:@"total"] floatValue] / 1024 / 1024),
                diskNode    = [aStanza firstChildWithName:@"disk"];

            [fieldTotalMemory setStringValue:maxMem + "G"];
            [fieldHalfMemory setStringValue:Math.round(maxMem / 2) + "G"];
            [_chartViewMemory setFixedMaxValue:[memNode valueForAttribute:@"total"]];

            [healthDiskUsage setStringValue:[diskNode valueForAttribute:@"used-percentage"]];

            /* reload the charts view */
            [_chartViewMemory reloadData];
            [_chartViewCPU reloadData];
            [_chartViewLoad reloadData];
            [_chartViewDisk reloadData];

            CPLog.debug("Stats history recovered");
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

    [self getHypervisorHealth:nil];
    [self handleAutoRefresh];

    return NO;
}

/*! get the hypervisor logs
*/
- (void)getHypervisorLog:(CPTimer)aTimer
{
    var stanza    = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorHealth}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "xmlns": TNArchipelTypeHypervisorHealth,
        "action": TNArchipelTypeHypervisorHealthLog,
        "limit": _maxLogEntries}];

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
        [_tableLogs reloadData];
        CPLog.debug("logs recovered");

    }
    else if ([aStanza type] == @"error")
    {
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}

@end
