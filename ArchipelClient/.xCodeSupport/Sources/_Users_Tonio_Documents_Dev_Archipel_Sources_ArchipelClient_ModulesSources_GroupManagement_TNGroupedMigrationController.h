
@interface TNGroupedMigrationController : NSObject
{
    IBOutlet TNUIKitScrollView* scrollViewTableHypervisors;
    IBOutlet NSSearchField* searchFieldHypervisors;
    IBOutlet NSWindow* mainWindow;
}
- (IBAction)showMainWindow:(id)aSender;
- (IBAction)closeMainWindow:(id)aSender;
- (IBAction)sendMigration:(id)aSender;
@end