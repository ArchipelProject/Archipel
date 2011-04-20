
@interface TNHypervisorHealthController : TNModule
{
    IBOutlet NSImageView* imageCPULoading;
    IBOutlet NSImageView* imageDiskLoading;
    IBOutlet NSImageView* imageLoadLoading;
    IBOutlet NSImageView* imageMemoryLoading;
    IBOutlet NSSearchField* filterLogField;
    IBOutlet NSTabView* tabViewInfos;
    IBOutlet NSTextField* fieldHalfMemory;
    IBOutlet NSTextField* fieldPreferencesAutoRefresh;
    IBOutlet NSTextField* fieldPreferencesMaxItems;
    IBOutlet NSTextField* fieldPreferencesMaxLogEntries;
    IBOutlet NSTextField* fieldTotalMemory;
    IBOutlet NSTextField* healthCPUUsage;
    IBOutlet NSTextField* healthDiskUsage;
    IBOutlet NSTextField* healthInfo;
    IBOutlet NSTextField* healthLoad;
    IBOutlet NSTextField* healthMemSwapped;
    IBOutlet NSTextField* healthMemUsage;
    IBOutlet NSTextField* healthUptime;
    IBOutlet NSView* viewCharts;
    IBOutlet NSView* viewGraphCPU;
    IBOutlet NSView* viewGraphCPUContainer;
    IBOutlet NSView* viewGraphDiskContainer;
    IBOutlet NSView* viewGraphLoad;
    IBOutlet NSView* viewGraphLoadContainer;
    IBOutlet NSView* viewGraphMemory;
    IBOutlet NSView* viewGraphMemoryContainer;
    IBOutlet NSView* viewGraphNetwork;
    IBOutlet NSView* viewGraphNetworkContainer;
    IBOutlet NSView* viewLogs;
    IBOutlet TNSwitch* switchPreferencesAutoRefresh;
    IBOutlet TNSwitch* switchPreferencesShowColunmFile;
    IBOutlet TNSwitch* switchPreferencesShowColunmMethod;
    IBOutlet TNUIKitScrollView* scrollViewLogsTable;
    IBOutlet TNUIKitScrollView* scrollViewPartitionTable;
}
- (IBAction)handleAutoRefresh(id)aSender;
@end