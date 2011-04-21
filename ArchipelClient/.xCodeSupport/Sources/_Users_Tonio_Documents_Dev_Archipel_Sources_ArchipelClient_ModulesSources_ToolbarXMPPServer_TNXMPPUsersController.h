
@interface TNXMPPUsersController : NSObject
{
    IBOutlet CPButtonBar* buttonBarControl;
    IBOutlet TNUIKitScrollView* scrollViewUsers;
    IBOutlet NSSearchField* filterField;
    IBOutlet NSTextField* fieldNewUserPassword;
    IBOutlet NSTextField* fieldNewUserPasswordConfirm;
    IBOutlet NSTextField* fieldNewUserUsername;
    IBOutlet NSView* mainView;
    IBOutlet NSView* viewTableContainer;
    IBOutlet NSWindow* windowNewUser;
}
- (IBAction)openRegisterUserWindow:(id)aSender;
- (IBAction)registerUser:(id)aSender;
- (IBAction)unregisterUser:(id)aSender;
@end