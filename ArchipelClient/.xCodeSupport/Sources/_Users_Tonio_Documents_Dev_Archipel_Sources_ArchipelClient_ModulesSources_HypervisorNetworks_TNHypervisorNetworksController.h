
@interface TNHypervisorNetworksController : TNModule
{
    IBOutlet CPButtonBar* buttonBarControl;
    IBOutlet NSSearchField* fieldFilterNetworks;
    IBOutlet NSView* viewTableContainer;
    IBOutlet TNUIKitScrollView* scrollViewNetworks;
    IBOutlet TNWindowNetworkController* networkController;
}
- (IBAction)addNetwork:(id)aSender;
- (IBAction)delNetwork:(id)aSender;
- (IBAction)editNetwork:(id)aSender;
- (IBAction)defineNetworkXML:(id)aSender;
- (IBAction)activateNetwork:(id)aSender;
- (IBAction)deactivateNetwork:(id)aSender;
@end