
@interface TNXMPPServerController : TNModule
{
    IBOutlet NSPopUpButton* buttonHypervisors;
    IBOutlet NSTabView* tabViewMain;
    IBOutlet NSView* viewBottom;
    IBOutlet TNXMPPSharedGroupsController* sharedGroupsController;
    IBOutlet TNXMPPUsersController* usersController;
}
- (IBAction)changeCurrentHypervisor:(id)aSender;
@end