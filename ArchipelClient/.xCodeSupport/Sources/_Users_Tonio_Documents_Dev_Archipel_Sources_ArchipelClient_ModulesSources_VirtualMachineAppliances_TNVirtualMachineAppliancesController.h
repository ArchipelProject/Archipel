
@interface TNVirtualMachineAppliancesController : TNModule
{
    IBOutlet CPButtonBar* buttonBarControl;
    IBOutlet NSSearchField* fieldFilterAppliance;
    IBOutlet NSTextField* fieldNewApplianceName;
    IBOutlet NSView* maskingView;
    IBOutlet NSView* viewTableContainer;
    IBOutlet NSWindow* windowNewAppliance;
    IBOutlet TNUIKitScrollView* mainScrollView;
}
- (IBAction)openNewApplianceWindow:(id)aSender;
- (IBAction)tableDoubleClicked:(id)aSender;
- (IBAction)attach:(id)aSender;
- (IBAction)detach:(id)aSender;
- (IBAction)package:(id)aSender;
@end