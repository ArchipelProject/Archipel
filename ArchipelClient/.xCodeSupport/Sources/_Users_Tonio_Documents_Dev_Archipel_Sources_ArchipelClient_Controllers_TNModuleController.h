
@interface TNModuleTabViewItem : TNiTunesTabViewItem
{

}

@end
@interface TNModuleController : NSObject
{
    IBOutlet NSView* viewPermissionDenied;
}
- (IBAction)didToolbarModuleClicked:(id)aSender;
@end