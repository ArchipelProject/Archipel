
@interface TNMUCChatController : TNModule
{
    IBOutlet TNUIKitScrollView* scrollViewMessageContainer;
    IBOutlet TNUIKitScrollView* scrollViewPeople;
    IBOutlet NSTextField* fieldPreferencesDefaultRoom;
    IBOutlet NSTextField* fieldPreferencesDefaultService;
    IBOutlet NSTextField* textFieldMessage;
}
- (IBAction)sendMessageToMuc:(id)aSender;
- (IBAction)didDoubleClick:(id)aSender;
@end