
@interface TNWindowNetworkController : NSObject
{
    IBOutlet CPButtonBar* buttonBarControlDHCPHosts;
    IBOutlet CPButtonBar* buttonBarControlDHCPRanges;
    IBOutlet CPCheckBox* checkBoxDHCPEnabled;
    IBOutlet CPCheckBox* checkBoxSTPEnabled;
    IBOutlet NSPopUpButton* buttonForwardDevice;
    IBOutlet NSPopUpButton* buttonForwardMode;
    IBOutlet NSTabView* tabViewDHCP;
    IBOutlet NSTextField* fieldBridgeDelay;
    IBOutlet NSTextField* fieldBridgeIP;
    IBOutlet NSTextField* fieldBridgeName;
    IBOutlet NSTextField* fieldBridgeNetmask;
    IBOutlet NSTextField* fieldNetworkName;
    IBOutlet NSView* viewHostsConf;
    IBOutlet NSView* viewRangesConf;
    IBOutlet NSView* viewTableHostsContainer;
    IBOutlet NSView* viewTableRangesContainer;
    IBOutlet NSWindow* mainWindow;
    IBOutlet TNUIKitScrollView* scrollViewDHCPHosts;
    IBOutlet TNUIKitScrollView* scrollViewDHCPRanges;
}
- (IBAction)save:(id)aSender;
- (IBAction)addDHCPRange:(id)aSender;
- (IBAction)removeDHCPRange:(id)aSender;
- (IBAction)addDHCPHost:(id)aSender;
- (IBAction)removeDHCPHost:(id)aSender;
- (IBAction)showWindow:(id)aSender;
- (IBAction)hideWindow:(id)aSender;
- (IBAction)forwardModeChanged:(id)aSender;
@end