
@interface TNVirtualMachineControlsController : TNModule
{
    IBOutlet NSButton* buttonKill;
    IBOutlet CPButtonBar* buttonBarMigration;
    IBOutlet NSImageView* imageState;
    IBOutlet NSSearchField* filterHypervisors;
    IBOutlet NSSegmentedControl* buttonBarTransport;
    IBOutlet NSSlider* sliderMemory;
    IBOutlet NSTextField* fieldInfoConsumedCPU;
    IBOutlet NSTextField* fieldInfoMem;
    IBOutlet NSTextField* fieldInfoState;
    IBOutlet NSTextField* fieldOOMAdjust;
    IBOutlet NSTextField* fieldOOMScore;
    IBOutlet NSTextField* fieldPreferencesMaxCPUs;
    IBOutlet NSView* maskingView;
    IBOutlet NSView* viewTableHypervisorsContainer;
    IBOutlet TNSwitch* switchAutoStart;
    IBOutlet TNSwitch* switchPreventOOMKiller;
    IBOutlet TNTextFieldStepper* stepperCPU;
    IBOutlet TNUIKitScrollView* scrollViewTableHypervisors;
}
- (IBAction)segmentedControlClicked:(id)aSender;
- (IBAction)play:(id)aSender;
- (IBAction)pause:(id)aSender;
- (IBAction)stop:(id)aSender;
- (IBAction)destroy:(id)aSender;
- (IBAction)reboot:(id)aSender;
- (IBAction)setAutostart:(id)aSender;
- (IBAction)setPreventOOMKiller:(id)aSender;
- (IBAction)setMemory:(id)aSender;
- (IBAction)setVCPUs:(id)aSender;
- (IBAction)migrate:(id)aSender;
- (IBAction)free:(id)aSender;
@end