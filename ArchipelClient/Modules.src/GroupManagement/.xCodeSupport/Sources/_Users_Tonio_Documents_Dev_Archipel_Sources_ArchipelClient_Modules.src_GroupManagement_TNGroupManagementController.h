
@interface TNGroupManagementController : TNModule
{
    IBOutlet CPButtonBar* buttonBarControl;
    IBOutlet TNUIKitScrollView* VMScrollView;
    IBOutlet NSSearchField* filterField;
    IBOutlet NSView* viewTableContainer;
    IBOutlet TNGroupedMigrationController* groupedMigrationController;
}
- (IBAction)virtualMachineDoubleClick:(id)aSender;
- (IBAction)create:(id)aSender;
- (IBAction)shutdown:(id)aSender;
- (IBAction)destroy:(id)aSender;
- (IBAction)suspend:(id)aSender;
- (IBAction)resume:(id)aSender;
- (IBAction)reboot:(id)aSender;
- (IBAction)migrate:(id)aSender;
@end