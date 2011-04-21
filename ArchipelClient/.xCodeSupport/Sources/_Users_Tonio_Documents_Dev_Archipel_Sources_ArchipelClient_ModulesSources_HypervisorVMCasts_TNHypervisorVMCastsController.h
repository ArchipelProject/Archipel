
@interface TNHypervisorVMCastsController : TNModule
{
    IBOutlet CPButtonBar* buttonBarControl;
    IBOutlet CPCheckBox* checkBoxOnlyInstalled;
    IBOutlet TNUIKitScrollView* mainScrollView;
    IBOutlet NSSearchField* fieldFilter;
    IBOutlet NSTextField* fieldNewURL;
    IBOutlet NSView* viewTableContainer;
    IBOutlet NSWindow* windowDownloadQueue;
    IBOutlet NSWindow* windowNewCastURL;
}
- (IBAction)fieldFilterDidChange:(id)aSender;
- (IBAction)openNewVMCastURLWindow:(id)aSender;
- (IBAction)clickOnFilterCheckBox:(id)aSender;
- (IBAction)addNewVMCast:(id)aSender;
- (IBAction)remove:(id)aSender;
- (IBAction)removeAppliance:(id)aSender;
- (IBAction)removeVMCast:(id)aSender;
- (IBAction)download:(id)aSender;
- (IBAction)showDownloadQueue:(id)aSender;
@end