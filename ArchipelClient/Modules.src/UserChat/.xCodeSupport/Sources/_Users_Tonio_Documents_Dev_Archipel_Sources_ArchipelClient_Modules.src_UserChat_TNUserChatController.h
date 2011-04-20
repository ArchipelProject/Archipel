
@interface TNUserChatController : TNModule
{
    IBOutlet NSButton* buttonClear;
    IBOutlet NSButton* buttonDetach;
    IBOutlet NSImageView* imageSpinnerWriting;
    IBOutlet NSTextField* fieldMessage;
    IBOutlet NSTextField* fieldPreferencesMaxChatMessage;
    IBOutlet NSView* viewControls;
    IBOutlet TNUIKitScrollView* messagesScrollView;
}
- (IBAction)sendMessage:(id)aSender;
- (IBAction)clearHistory:(id)aSender;
- (IBAction)detachChat:(id)aSender;
@end