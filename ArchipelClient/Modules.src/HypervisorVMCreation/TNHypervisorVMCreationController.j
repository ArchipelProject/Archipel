/*  
 * TNViewHypervisorControl.j
 *    
 * Copyright (C) 2010 Antoine Mercadal <antoine.mercadal@inframonde.eu>
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 * 
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

TNArchipelTypeHypervisorControl             = @"archipel:hypervisor:control";
TNArchipelTypeHypervisorControlAlloc        = @"alloc";
TNArchipelTypeHypervisorControlFree         = @"free";
TNArchipelTypeHypervisorControlRosterVM     = @"rostervm";

TNArchipelPushNotificationHypervisor        = @"archipel:push:hypervisor";

@implementation TNHypervisorVMCreationController : TNModule 
{
    @outlet CPTextField     fieldJID                    @accessors;
    @outlet CPTextField     fieldName                   @accessors;
    @outlet CPButton        buttonCreateVM              @accessors;
    @outlet CPPopUpButton   popupDeleteMachine          @accessors;
    @outlet CPButton        buttonDeleteVM              @accessors;
    @outlet CPScrollView    scrollViewListVM            @accessors;
    @outlet CPSearchField   fieldFilterVM;
    @outlet CPButtonBar     buttonBarControl;
    @outlet CPView          viewTableContainer;
    
    CPTableView             _tableVirtualMachines;
    TNTableViewDataSource   _virtualMachinesDatasource;
    CPButton                _plusButton;
    CPButton                _minusButton;
}

- (void)awakeFromCib
{
    [viewTableContainer setBorderedWithHexColor:@"#C0C7D2"];
    
    // VM table view
    _virtualMachinesDatasource   = [[TNTableViewDataSource alloc] init];
    _tableVirtualMachines        = [[CPTableView alloc] initWithFrame:[scrollViewListVM bounds]];
    
    [scrollViewListVM setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [scrollViewListVM setAutohidesScrollers:YES];
    [scrollViewListVM setDocumentView:_tableVirtualMachines];
    
    [_tableVirtualMachines setUsesAlternatingRowBackgroundColors:YES];
    [_tableVirtualMachines setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [_tableVirtualMachines setAllowsColumnResizing:YES];
    [_tableVirtualMachines setAllowsEmptySelection:YES];
    [_tableVirtualMachines setAllowsMultipleSelection:YES];
    [_tableVirtualMachines setDelegate:self];
    [_tableVirtualMachines setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    
    var vmColumNickname = [[CPTableColumn alloc] initWithIdentifier:@"nickname"];
    [vmColumNickname setWidth:250];
    [[vmColumNickname headerView] setStringValue:@"Name"];
    [vmColumNickname setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"nickname" ascending:YES]];
    
    var vmColumJID = [[CPTableColumn alloc] initWithIdentifier:@"JID"];
    [vmColumJID setWidth:320];
    [[vmColumJID headerView] setStringValue:@"Jabber ID"];
    [vmColumJID setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"JID" ascending:YES]];

    var vmColumStatusIcon   = [[CPTableColumn alloc] initWithIdentifier:@"statusIcon"];
    var imgView             = [[CPImageView alloc] initWithFrame:CGRectMake(0,0,16,16)];
    [imgView setImageScaling:CPScaleNone];
    [vmColumStatusIcon setDataView:imgView];
    [vmColumStatusIcon setResizingMask:CPTableColumnAutoresizingMask ];
    [vmColumStatusIcon setWidth:16];
    [[vmColumStatusIcon headerView] setStringValue:@""];

    [_tableVirtualMachines addTableColumn:vmColumStatusIcon];
    [_tableVirtualMachines addTableColumn:vmColumNickname];
    [_tableVirtualMachines addTableColumn:vmColumJID];

    [_virtualMachinesDatasource setTable:_tableVirtualMachines];
    [_virtualMachinesDatasource setSearchableKeyPaths:[@"nickname", @"JID"]];
    
    [fieldFilterVM setTarget:_virtualMachinesDatasource];
    [fieldFilterVM setAction:@selector(filterObjects:)];
    
    [_tableVirtualMachines setDataSource:_virtualMachinesDatasource];
    
    var menu = [[CPMenu alloc] init];
    [menu addItemWithTitle:@"Create new virtual machine" action:@selector(addVirtualMachine:) keyEquivalent:@""];
    [menu addItemWithTitle:@"Delete" action:@selector(deleteVirtualMachine:) keyEquivalent:@""];
    [_tableVirtualMachines setMenu:menu];
    
    _plusButton = [CPButtonBar plusButton];
    [_plusButton setTarget:self];
    [_plusButton setAction:@selector(addVirtualMachine:)];
    
    _minusButton = [CPButtonBar minusButton];
    [_minusButton setTarget:self];
    [_minusButton setAction:@selector(deleteVirtualMachine:)];
    
    [_minusButton setEnabled:NO];
    
    [buttonBarControl setButtons:[_plusButton, _minusButton]];
}

- (void)willLoad
{
    [super willLoad];
    
    [self registerSelector:@selector(didPushReceived:) forPushNotificationType:TNArchipelPushNotificationHypervisor];
    
    var center = [CPNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(didNickNameUpdated:) name:TNStropheContactNicknameUpdatedNotification object:_entity];
    [center addObserver:self selector:@selector(reload:) name:TNStropheRosterAddedContactNotification object:nil];
    [center addObserver:self selector:@selector(reload:) name:TNStropheContactPresenceUpdatedNotification object:nil];
    [center postNotificationName:TNArchipelModulesReadyNotification object:self];
    
    [_tableVirtualMachines setDelegate:nil];
    [_tableVirtualMachines setDelegate:self]; // hum....
    
    [self getHypervisorRoster];
}

- (void)willShow
{
    [super willShow];
        
    [fieldName setStringValue:[_entity nickname]];
    [fieldJID setStringValue:[_entity JID]];
}

- (void)willUnload
{
    [super willUnload];
    
    [buttonCreateVM setEnabled:YES];
}

- (BOOL)didPushReceived:(TNStropheStanza)aStanza
{
    CPLog.info("Receiving push notification of type TNArchipelPushNotificationHypervisor");
    [self getHypervisorRoster];
    return YES;
}

- (void)reload:(CPNotification)aNotification
{
    [self getHypervisorRoster];
}

- (void)didNickNameUpdated:(CPNotification)aNotification
{
    [fieldName setStringValue:[_entity nickname]] 
}

- (void)getHypervisorRoster
{
    var stanza = [TNStropheStanza iqWithType:@"get"];
    
    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeHypervisorControl}];
    [stanza addChildName:@"archipel" withAttributes:{
        "xmlns": TNArchipelTypeHypervisorControl, 
        "action": TNArchipelTypeHypervisorControlRosterVM}];
        
    [_entity sendStanza:stanza andRegisterSelector:@selector(didReceiveHypervisorRoster:) ofObject:self];
}

- (void)didReceiveHypervisorRoster:(id)aStanza 
{
    if ([aStanza getType] == @"result")
    {
        var queryItems  = [aStanza childrenWithName:@"item"];
        var center      = [CPNotificationCenter defaultCenter];
    
        [_virtualMachinesDatasource removeAllObjects];
    
        for (var i = 0; i < [queryItems count]; i++)
        {
            var JID     = [[queryItems objectAtIndex:i] text];
            var entry   = [_roster contactWithJID:JID];
        
            if (entry) 
            {
               if ([[[entry vCard] firstChildWithName:@"TYPE"] text] == "virtualmachine")
               {
                   [_virtualMachinesDatasource addObject:entry];
                   [center addObserver:self selector:@selector(didVirtualMachineChangesStatus:) name:TNStropheContactPresenceUpdatedNotification object:entry];   
               }
            }
        }
    
        [_tableVirtualMachines reloadData];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}

- (void)didVirtualMachineChangesStatus:(CPNotification)aNotif
{
    [_tableVirtualMachines reloadData];
}


//actions
- (IBAction)addVirtualMachine:(id)sender
{
    var stanza  = [TNStropheStanza iqWithType:@"set"];
    var uuid            = [CPString UUID];
    
    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeHypervisorControl}];
    [stanza addChildName:@"archipel" withAttributes:{
        "xmlns": TNArchipelTypeHypervisorControl, 
        "action": TNArchipelTypeHypervisorControlAlloc,
        "uuid": uuid}];
    
    [self sendStanza:stanza andRegisterSelector:@selector(didAllocVirtualMachine:)];
    
    [buttonCreateVM setEnabled:NO];
}

- (void)didAllocVirtualMachine:(id)aStanza
{
    [buttonCreateVM setEnabled:YES];
    
    if ([aStanza getType] == @"result")
    {
        var vmJID   = [[[aStanza firstChildWithName:@"query"] firstChildWithName:@"virtualmachine"] valueForAttribute:@"jid"];
        CPLog.info(@"sucessfully create a virtual machine");
        
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Virtual Machine" message:@"Virtual machine " + vmJID + @" has been created"];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}

- (IBAction)deleteVirtualMachine:(id)sender
{
    if (([_tableVirtualMachines numberOfRows] == 0) || ([_tableVirtualMachines numberOfSelectedRows] <= 0))
    {
         [CPAlert alertWithTitle:@"Error" message:@"You must select a virtual machine"];
         return;
    }

    var msg;
    var title;
    
    if ([[_tableVirtualMachines selectedRowIndexes] count] < 2)
    {   
        msg     = @"Are you sure you want to completely remove this virtual machine ?";
        title   = @"Destroying a Virtual Machine"; 
    }
    else
    {                                  
        title   = @"Destroying some Virtual Machines"; 
        msg     = @"Are you sure you want to completely remove theses virtual machines ?";
    }
        
    
    [buttonDeleteVM setEnabled:NO];

    var alert = [TNAlert alertWithTitle:title
                                message:msg
                                delegate:self
                                 actions:[["Delete", @selector(performDeleteVirtualMachine:)], ["Cancel", nil]]];

    [alert setUserInfo:[_tableVirtualMachines selectedRowIndexes]];

    [alert runModal];
}

- (void)performDeleteVirtualMachine:(id)someUserInfo
{
    var indexes = someUserInfo
    var objects = [_virtualMachinesDatasource objectsAtIndexes:indexes];
    
    [_tableVirtualMachines deselectAll];
    
    for (var i = 0; i < [objects count]; i++)
    {                              
        var vm              = [objects objectAtIndex:i];
        var stanza          = [TNStropheStanza iqWithType:@"set"];
        
        [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeHypervisorControl}];
        [stanza addChildName:@"archipel" withAttributes:{
            "xmlns": TNArchipelTypeHypervisorControl, 
            "action": TNArchipelTypeHypervisorControlFree,
            "jid": [vm JID]}];

        [_roster removeContact:vm];

        [_entity sendStanza:stanza andRegisterSelector:@selector(didFreeVirtualMachine:) ofObject:self];          
        
        [buttonDeleteVM setEnabled:YES];
    }
}

- (void)didFreeVirtualMachine:(id)aStanza
{
    [buttonDeleteVM setEnabled:YES];
    
    if ([aStanza getType] == @"result")
    {
        CPLog.info(@"sucessfully deallocating a virtual machine");
        
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Virtual Machine" message:@"Virtual machine has been removed"];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}

- (void)tableViewSelectionDidChange:(CPNotification)aNotification
{
    [_minusButton setEnabled:NO];
    
    if ([[aNotification object] numberOfSelectedRows] > 0)
    {
        [_minusButton setEnabled:YES];
    }
}

@end


