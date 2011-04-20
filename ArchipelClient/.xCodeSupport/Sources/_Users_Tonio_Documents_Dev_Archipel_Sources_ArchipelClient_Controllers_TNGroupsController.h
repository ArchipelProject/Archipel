
@interface TNGroupsController : NSObject
{
    IBOutlet NSButton* buttonAdd;
    IBOutlet NSButton* buttonCancel;
    IBOutlet NSTextField* newGroupName;
    IBOutlet NSWindow* mainWindow;
}
- (IBAction)showWindow:(id)aSender;
- (IBAction)addGroup:(id)aSender;
@end