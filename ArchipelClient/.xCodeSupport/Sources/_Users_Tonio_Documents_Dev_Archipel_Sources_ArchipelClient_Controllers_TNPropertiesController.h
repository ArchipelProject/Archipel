
@interface TNPropertiesController : NSObject
{
    IBOutlet NSView* frontView;
    IBOutlet NSView* backView;
    IBOutlet TNEditableLabel* entryName;
    IBOutlet NSButton* entryAvatar;
    IBOutlet NSImageView* entryStatusIcon;
    IBOutlet NSButton* buttonEventSubscription;
    IBOutlet NSButton* buttonFrontViewFlip;
    IBOutlet NSButton* buttonBackViewFlip;
    IBOutlet NSTextField* entryType;
    IBOutlet NSTextField* labelType;
    IBOutlet NSTextField* entryDomain;
    IBOutlet NSTextField* entryResource;
    IBOutlet NSTextField* entryStatus;
    IBOutlet NSTextField* labelDomain;
    IBOutlet NSTextField* labelResource;
    IBOutlet NSTextField* labelStatus;
    IBOutlet NSTextField* newNickName;
    IBOutlet NSTextField* labelVCardFN;
    IBOutlet NSTextField* labelVCardLocality;
    IBOutlet NSTextField* labelVCardCompany;
    IBOutlet NSTextField* labelVCardRole;
    IBOutlet NSTextField* labelVCardEmail;
    IBOutlet NSTextField* labelVCardWebiste;
    IBOutlet NSImageView* imageViewVCardPhoto;
    IBOutlet TNContactsController* contactsController;
}
- (IBAction)openAvatarManager:(id)aSender;
- (IBAction)changeNickName:(id)aSender;
- (IBAction)manageContactSubscription:(id)aSender;
@end