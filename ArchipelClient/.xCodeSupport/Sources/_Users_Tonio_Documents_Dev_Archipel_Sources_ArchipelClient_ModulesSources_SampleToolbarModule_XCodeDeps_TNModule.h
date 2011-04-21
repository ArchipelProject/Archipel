
@interface TNModule : NSViewController
{
    IBOutlet NSImageView* imageViewModuleReady;
    IBOutlet NSView* viewPreferences;
}
- (IBAction)toolbarItemClicked:(id)aSender;
@end