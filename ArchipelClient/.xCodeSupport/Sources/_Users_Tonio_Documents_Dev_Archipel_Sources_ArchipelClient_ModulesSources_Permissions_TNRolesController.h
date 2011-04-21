
@interface TNRolesController : NSObject
{
    IBOutlet CPButtonBar* buttonBar;
    IBOutlet TNUIKitScrollView* scrollViewTableRoles;
    IBOutlet NSSearchField* filterField;
    IBOutlet NSTextField* fieldNewTemplateDescription;
    IBOutlet NSTextField* fieldNewTemplateName;
    IBOutlet NSView* viewTableContainer;
    IBOutlet NSWindow* mainWindow;
    IBOutlet NSWindow* windowNewTemplate;
}
- (IBAction)showWindow:(id)aSender;
- (IBAction)hideWindow:(id)aSender;
- (IBAction)applyRoles:(id)aSender;
- (IBAction)addRoles:(id)aSender;
- (IBAction)retractRoles:(id)aSender;
- (IBAction)openNewTemplateWindow:(id)aSender;
- (IBAction)saveRole:(id)aSender;
- (IBAction)deleteSelectedRole:(id)aSender;
@end