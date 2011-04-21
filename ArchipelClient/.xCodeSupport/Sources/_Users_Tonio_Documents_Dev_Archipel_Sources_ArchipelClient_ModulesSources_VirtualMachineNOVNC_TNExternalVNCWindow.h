
@interface TNExternalVNCWindow : NSWindow
{

}
- (IBAction)sendCtrlAltDel:(id)aSender;
- (IBAction)getPasteboard:(id)aSender;
- (IBAction)sendPasteboard:(id)aSender;
- (IBAction)setFullScreen:(id)aSender;
- (IBAction)changeScale:(id)aSender;
@end