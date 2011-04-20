
@interface TNNewDriveController : NSObject
{
    IBOutlet CPCheckBox* checkBoxUseQCOW2Preallocation;
    IBOutlet NSPopUpButton* buttonNewDiskFormat;
    IBOutlet NSPopUpButton* buttonNewDiskSizeUnit;
    IBOutlet NSTextField* fieldNewDiskName;
    IBOutlet NSTextField* fieldNewDiskSize;
    IBOutlet NSWindow* mainWindow;
}
- (IBAction)diskCreationFormatChanged:(id)aSender;
- (IBAction)createDisk:(id)aSender;
@end