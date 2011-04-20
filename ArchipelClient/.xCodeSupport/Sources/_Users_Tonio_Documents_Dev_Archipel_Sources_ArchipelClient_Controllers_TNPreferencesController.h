
@interface TNPreferencesController : NSObject
{
    IBOutlet NSButton* buttonCancel;
    IBOutlet NSButton* buttonSave;
    IBOutlet CPCheckBox* checkBoxUpdate;
    IBOutlet NSPopUpButton* buttonDebugLevel;
    IBOutlet NSTabView* tabViewMain;
    IBOutlet NSTextField* fieldBOSHResource;
    IBOutlet NSTextField* fieldModuleLoadingDelay;
    IBOutlet NSTextField* fieldWelcomePageUrl;
    IBOutlet NSView* viewPreferencesGeneral;
    IBOutlet NSWindow* mainWindow;
    IBOutlet TNSwitch* switchUseAnimations;
    IBOutlet TNSwitch* switchUseXMPPMonitoring;
}
- (IBAction)showWindow:(id)aSender;
- (IBAction)savePreferences:(id)aSender;
- (IBAction)resetPreferences:(id)aSender;
@end