
@interface TNEditDriveController : NSObject
{
    IBOutlet NSButton* buttonConvert;
    IBOutlet NSPopUpButton* buttonEditDiskFormat;
    IBOutlet NSTextField* fieldEditDiskName;
    IBOutlet NSWindow* mainWindow;
}
- (IBAction)convert:(id)aSender;
- (IBAction)rename:(id)aSender;
@end