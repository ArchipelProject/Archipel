
@interface TNDriveController : NSObject
{
    IBOutlet NSWindow* mainWindow;
    IBOutlet NSPopUpButton* buttonBus;
    IBOutlet NSPopUpButton* buttonSource;
    IBOutlet NSPopUpButton* buttonTarget;
    IBOutlet NSPopUpButton* buttonType;
    IBOutlet NSPopUpButton* buttonCache;
    IBOutlet NSPopUpButton* buttonDeviceType;
    IBOutlet NSTextField* fieldDevicePath;
}
- (IBAction)save:(id)aSender;
- (IBAction)populateTargetButton:(id)aSender;
- (IBAction)performDeviceTypeChanged:(id)aSender;
- (IBAction)driveTypeDidChange:(id)aSender;
- (IBAction)showWindow:(id)aSender;
- (IBAction)hideWindow:(id)aSender;
@end