
@interface TNVirtualMachineSnapshotsController : TNModule
{
    IBOutlet CPButtonBar* buttonBarControl;
    IBOutlet NSSearchField* fieldFilter;
    IBOutlet NSTextField* fieldInfo;
    IBOutlet NSTextField* fieldNewSnapshotName;
    IBOutlet NSView* viewTableContainer;
    IBOutlet NSWindow* windowNewSnapshot;
    IBOutlet LPMultiLineTextField* fieldNewSnapshotDescription;
    IBOutlet TNUIKitScrollView* scrollViewSnapshots;
}
- (IBAction)openWindowNewSnapshot:(id)aSender;
- (IBAction)takeSnapshot:(id)aSender;
- (IBAction)deleteSnapshot:(id)aSender;
- (IBAction)revertSnapshot:(id)aSender;
@end