
@interface TNContactsController : NSObject
{
    IBOutlet NSButton* buttonAdd;
    IBOutlet NSButton* buttonCancel;
    IBOutlet NSTextField* newContactJID;
    IBOutlet NSTextField* newContactName;
    IBOutlet NSWindow* mainWindow;
}
- (IBAction)showWindow:(id)aSender;
- (IBAction)addContact:(id)aSender;
- (IBAction)showHelpForSubscription:(id)aSender;
- (IBAction)showHelpForDelete:(id)aSender;
@end