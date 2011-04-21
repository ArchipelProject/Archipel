
@interface TNPermissionsController : TNModule
{
    IBOutlet CPButtonBar* buttonBarControl;
    IBOutlet NSSearchField* filterField;
    IBOutlet NSSplitView* splitView;
    IBOutlet NSTextField* labelNoUserSelected;
    IBOutlet NSView* viewTableContainer;
    IBOutlet NSView* viewUsersLeft;
    IBOutlet TNRolesController* rolesController;
    IBOutlet TNUIKitScrollView* scrollViewPermissions;
    IBOutlet TNUIKitScrollView* scrollViewUsers;
}
- (IBAction)changePermissionsState:(id)aSender;
- (IBAction)changeCurrentUser:(id)aSender;
- (IBAction)openRolesWindow:(id)aSender;
@end