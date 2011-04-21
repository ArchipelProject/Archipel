
@interface TNMapViewController : TNModule
{
    IBOutlet NSSearchField* filterFieldDestination;
    IBOutlet NSSearchField* filterFieldOrigin;
    IBOutlet NSSplitView* splitViewHorizontal;
    IBOutlet NSSplitView* splitViewVertical;
    IBOutlet NSTextField* textFieldDestinationName;
    IBOutlet NSTextField* textFieldDestinationNameLabel;
    IBOutlet NSTextField* textFieldOriginName;
    IBOutlet NSTextField* textFieldOriginNameLabel;
    IBOutlet NSView* mapViewContainer;
    IBOutlet NSView* viewDestination;
    IBOutlet NSView* viewOrigin;
    IBOutlet TNUIKitScrollView* scrollViewDestination;
    IBOutlet TNUIKitScrollView* scrollViewOrigin;
}

@end