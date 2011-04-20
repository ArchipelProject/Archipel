
@interface TNConnectionController : NSObject
{
    IBOutlet NSButton* connectButton;
    IBOutlet NSImageView* spinning;
    IBOutlet NSTextField* boshService;
    IBOutlet NSTextField* JID;
    IBOutlet NSTextField* labelBoshService;
    IBOutlet NSTextField* labelJID;
    IBOutlet NSTextField* labelPassword;
    IBOutlet NSTextField* labelRemember;
    IBOutlet NSTextField* labelTitle;
    IBOutlet NSTextField* message;
    IBOutlet NSTextField* password;
    IBOutlet TNModalWindow* mainWindow;
    IBOutlet TNSwitch* credentialRemember;
}
- (IBAction)connect:(id)aSender;
- (IBAction)rememberCredentials:(id)aSender;
@end