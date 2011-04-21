
@interface TNToolbarLogsController : TNModule
{
    IBOutlet NSPopUpButton* buttonLogLevel;
    IBOutlet NSSearchField* fieldFilter;
    IBOutlet TNUIKitScrollView* mainScrollView;
}
- (IBAction)clearLog:(id)aSender;
- (IBAction)setLogLevel:(id)aSender;
@end