
@interface TNXMPPSharedGroupsController : NSObject
{
    IBOutlet CPButtonBar* buttonBarGroups;
    IBOutlet CPButtonBar* buttonBarUsersInGroups;
    IBOutlet TNUIKitScrollView* scrollViewGroups;
    IBOutlet TNUIKitScrollView* scrollViewUsers;
    IBOutlet TNUIKitScrollView* scrollViewUsersInGroup;
    IBOutlet NSSearchField* filterFieldGroups;
    IBOutlet NSSearchField* filterFieldUsers;
    IBOutlet NSSearchField* filterFieldUsersInGroup;
    IBOutlet NSSplitView* splitViewVertical;
    IBOutlet NSTextField* fieldNewGroupDescription;
    IBOutlet NSTextField* fieldNewGroupName;
    IBOutlet NSView* mainView;
    IBOutlet NSView* viewTableGroupsContainer;
    IBOutlet NSView* viewTableUsersInGroupContainer;
    IBOutlet NSWindow* windowAddUserInGroup;
    IBOutlet NSWindow* windowNewGroup;
}
- (IBAction)openNewGroupWindow:(id)aSender;
- (IBAction)openAddUserInGroupWindow:(id)aSender;
- (IBAction)createGroup:(id)aSender;
- (IBAction)deleteGroup:(id)aSender;
- (IBAction)addUsersInGroup:(id)aSender;
- (IBAction)removeUsersFromGroup:(id)aSender;
@end