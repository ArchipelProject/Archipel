
@interface TNUpdateController : NSObject
{
    IBOutlet NSTextField* fieldCurrentVersion;
    IBOutlet NSTextField* fieldDate;
    IBOutlet NSTextField* fieldServerVersion;
    IBOutlet NSTextField* labelCurrentVersion;
    IBOutlet NSTextField* labelDate;
    IBOutlet NSTextField* labelServerVersion;
    IBOutlet NSWindow* mainWindow;
    IBOutlet LPMultiLineTextField* fieldChanges;
}
- (IBAction)manualCheck:(id)aSender;
- (IBAction)update:(id)aSender;
- (IBAction)cancel:(id)aSender;
- (IBAction)ignore:(id)aSender;
@end