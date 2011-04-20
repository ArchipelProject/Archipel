
@interface TNNetworkController : NSObject
{
    IBOutlet NSWindow* mainWindow;
    IBOutlet NSPopUpButton* buttonModel;
    IBOutlet NSPopUpButton* buttonSource;
    IBOutlet NSPopUpButton* buttonType;
    IBOutlet NSTextField* fieldMac;
}
- (IBAction)save:(id)aSender;
- (IBAction)performNicTypeChanged:(id)aSender;
- (IBAction)showWindow:(id)aSender;
- (IBAction)hideWindow:(id)aSender;
@end