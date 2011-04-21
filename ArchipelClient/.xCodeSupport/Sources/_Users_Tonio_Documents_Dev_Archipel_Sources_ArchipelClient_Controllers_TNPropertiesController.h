
@interface TNPropertiesController : NSObject
{
    IBOutlet NSButton* buttonBackViewFlip;
    IBOutlet NSButton* buttonEventSubscription;
    IBOutlet NSButton* buttonFrontViewFlip;
    IBOutlet NSButton* entryAvatar;
    IBOutlet NSImageView* entryStatusIcon;
    IBOutlet NSImageView* imageViewVCardPhoto;
    IBOutlet NSTextField* entryDomain;
    IBOutlet NSTextField* entryResource;
    IBOutlet NSTextField* entryStatus;
    IBOutlet NSTextField* entryType;
    IBOutlet NSTextField* labelDomain;
    IBOutlet NSTextField* labelResource;
    IBOutlet NSTextField* labelStatus;
    IBOutlet NSTextField* labelType;
    IBOutlet NSTextField* labelVCardCompany;
    IBOutlet NSTextField* labelVCardEmail;
    IBOutlet NSTextField* labelVCardFN;
    IBOutlet NSTextField* labelVCardLocality;
    IBOutlet NSTextField* labelVCardRole;
    IBOutlet NSTextField* labelVCardWebiste;
    IBOutlet NSView* backView;
    IBOutlet NSView* frontView;
    IBOutlet TNContactsController* contactsController;
    IBOutlet TNEditableLabel* entryName;
    IBOutlet TNFlipView* mainView;
}
- (IBAction)openAvatarManager:(id)aSender;
- (IBAction)changeNickName:(id)aSender;
- (IBAction)manageContactSubscription:(id)aSender;
@end