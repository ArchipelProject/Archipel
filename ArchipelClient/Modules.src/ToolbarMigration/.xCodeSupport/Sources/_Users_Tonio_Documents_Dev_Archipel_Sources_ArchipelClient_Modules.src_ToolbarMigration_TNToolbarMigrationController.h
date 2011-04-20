
@interface TNToolbarMigrationController : TNModule
{
    IBOutlet NSButton* buttonMigrate;
    IBOutlet NSSearchField* searchHypervisorDestination;
    IBOutlet NSSearchField* searchHypervisorOrigin;
    IBOutlet NSSearchField* searchVirtualMachine;
    IBOutlet TNUIKitScrollView* scrollViewTableHypervisorDestination;
    IBOutlet TNUIKitScrollView* scrollViewTableHypervisorOrigin;
    IBOutlet TNUIKitScrollView* scrollViewTableVirtualMachines;
}
- (IBAction)migrate:(id)aSender;
@end