
@interface TNVirtualMachineNOVNCController : TNModule
{
    IBOutlet NSButton* buttonExternalWindow;
    IBOutlet NSButton* buttonGetPasteBoard;
    IBOutlet NSButton* buttonSendCtrlAtlDel;
    IBOutlet NSButton* buttonSendPasteBoard;
    IBOutlet NSButton* buttonZoomFitToWindow;
    IBOutlet NSButton* buttonZoomReset;
    IBOutlet CPCheckBox* checkboxPasswordRemember;
    IBOutlet NSImageView* imageViewSecureConnection;
    IBOutlet NSSlider* sliderScaling;
    IBOutlet NSTextField* fieldPassword;
    IBOutlet NSTextField* fieldPreferencesCheckRate;
    IBOutlet NSTextField* fieldPreferencesFBURefreshRate;
    IBOutlet NSView* maskingView;
    IBOutlet NSView* viewControls;
    IBOutlet NSWindow* windowPassword;
    IBOutlet NSWindow* windowPasteBoard;
    IBOutlet LPMultiLineTextField* fieldPasteBoard;
    IBOutlet TNSwitch* switchPreferencesPreferSSL;
    IBOutlet TNUIKitScrollView* mainScrollView;
}
- (IBAction)openExternalWindow:(id)aSender;
- (IBAction)changeScale:(id)aSender;
- (IBAction)fitToScreen:(id)aSender;
- (IBAction)resetZoom:(id)aSender;
- (IBAction)sendCtrlAltDel:(id)aSender;
- (IBAction)sendPasteBoard:(id)aSender;
- (IBAction)rememberPassword:(id)aSender;
- (IBAction)changePassword:(id)aSender;
@end