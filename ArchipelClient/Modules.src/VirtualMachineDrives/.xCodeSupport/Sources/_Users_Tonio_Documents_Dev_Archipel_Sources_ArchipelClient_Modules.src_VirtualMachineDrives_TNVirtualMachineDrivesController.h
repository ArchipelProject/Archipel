
@interface TNVirtualMachineDrivesController : TNModule
{
    IBOutlet CPButtonBar* buttonBarControl;
    IBOutlet NSSearchField* fieldFilter;
    IBOutlet NSView* maskingView;
    IBOutlet NSView* viewTableContainer;
    IBOutlet TNEditDriveController* editDriveController;
    IBOutlet TNNewDriveController* newDriveController;
    IBOutlet TNUIKitScrollView* scrollViewDisks;
}
- (IBAction)openNewDiskWindow:(id)aSender;
- (IBAction)openEditWindow:(id)aSender;
- (IBAction)removeDisk:(id)aSender;
@end