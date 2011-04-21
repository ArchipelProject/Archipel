
@interface TNHypervisorVMCreationController : TNModule
{
    IBOutlet NSButton* buttonAlloc;
    IBOutlet CPButtonBar* buttonBarControl;
    IBOutlet NSPopUpButton* popupDeleteMachine;
    IBOutlet TNUIKitScrollView* scrollViewListVM;
    IBOutlet NSSearchField* fieldFilterVM;
    IBOutlet NSTextField* fieldNewSubscriptionTarget;
    IBOutlet NSTextField* fieldNewVMRequestedName;
    IBOutlet NSTextField* fieldRemoveSubscriptionTarget;
    IBOutlet NSView* viewTableContainer;
    IBOutlet NSWindow* windowNewSubscription;
    IBOutlet NSWindow* windowNewVirtualMachine;
    IBOutlet NSWindow* windowRemoveSubscription;
}
- (IBAction)didDoubleClick:(id)aSender;
- (IBAction)addVirtualMachine:(id)aSender;
- (IBAction)alloc:(id)aSender;
- (IBAction)deleteVirtualMachine:(id)aSender;
- (IBAction)cloneVirtualMachine:(id)aSender;
- (IBAction)openAddSubscriptionWindow:(id)aSender;
- (IBAction)addSubscription:(id)aSender;
- (IBAction)openRemoveSubscriptionWindow:(id)aSender;
- (IBAction)removeSubscription:(id)aSender;
@end