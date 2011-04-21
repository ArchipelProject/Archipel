
@interface TNVirtualMachineScheduler : TNModule
{
    IBOutlet CPButtonBar* buttonBarJobs;
    IBOutlet CPCheckBox* checkBoxEveryDay;
    IBOutlet CPCheckBox* checkBoxEveryHour;
    IBOutlet CPCheckBox* checkBoxEveryMinute;
    IBOutlet CPCheckBox* checkBoxEveryMonth;
    IBOutlet CPCheckBox* checkBoxEverySecond;
    IBOutlet CPCheckBox* checkBoxEveryYear;
    IBOutlet NSPopUpButton* buttonNewJobAction;
    IBOutlet NSSearchField* filterFieldJobs;
    IBOutlet NSTabView* tabViewJobSchedule;
    IBOutlet NSTextField* fieldNewJobComment;
    IBOutlet NSView* viewNewJobOneShot;
    IBOutlet NSView* viewNewJobRecurent;
    IBOutlet NSView* viewTableContainer;
    IBOutlet NSWindow* windowNewJob;
    IBOutlet TNCalendarView* calendarViewNewJob;
    IBOutlet TNTextFieldStepper* stepperHour;
    IBOutlet TNTextFieldStepper* stepperMinute;
    IBOutlet TNTextFieldStepper* stepperNewRecurrentJobDay;
    IBOutlet TNTextFieldStepper* stepperNewRecurrentJobHour;
    IBOutlet TNTextFieldStepper* stepperNewRecurrentJobMinute;
    IBOutlet TNTextFieldStepper* stepperNewRecurrentJobMonth;
    IBOutlet TNTextFieldStepper* stepperNewRecurrentJobSecond;
    IBOutlet TNTextFieldStepper* stepperNewRecurrentJobYear;
    IBOutlet TNTextFieldStepper* stepperSecond;
    IBOutlet TNUIKitScrollView* scrollViewTableJobs;
}
- (IBAction)openNewJobWindow:(id)aSender;
- (IBAction)schedule:(id)aSender;
- (IBAction)unschedule:(id)aSender;
- (IBAction)checkboxClicked:(id)aSender;
@end