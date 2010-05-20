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
    TNStropheContact        _virtualMachinesForDeletion;
    CPButton                _plusButton;
    CPButton                _minusButton;
}

- (void)awakeFromCib
{
    [viewTableContainer setBorderedWithHexColor:@"#9e9e9e"];
    
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
    [center postNotificationName:TNArchipelModulesReadyNotification object:self];
    
    [_tableVirtualMachines setDelegate:nil];
    [_tableVirtualMachines setDelegate:self]; // hum....
    
    [self getHypervisorRoster];
}

- (void)willShow
{
    [super willShow];
    
    var center = [CPNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(didNickNameUpdated:) name:TNStropheContactNicknameUpdatedNotification object:_entity];
    [center addObserver:self selector:@selector(didContactAdded:) name:TNStropheRosterAddedContactNotification object:nil];
    
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

- (void)didContactAdded:(CPNotification)aNotification
{
    [self getHypervisorRoster];
}

- (void)didNickNameUpdated:(CPNotification)aNotification
{
    [fieldName setStringValue:[_entity nickname]] 
}

- (void)getHypervisorRoster
{
    var rosterStanza = [TNStropheStanza iqWithAttributes:{"type" : TNArchipelTypeHypervisorControl}];
        
    [rosterStanza addChildName:@"query" withAttributes:{"type" : TNArchipelTypeHypervisorControlRosterVM}];
    [_entity sendStanza:rosterStanza andRegisterSelector:@selector(didReceiveHypervisorRoster:) ofObject:self];
}

- (void)didReceiveHypervisorRoster:(id)aStanza 
{
    if ([aStanza getType] == @"success")
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
    var creationStanza  = [TNStropheStanza iqWithAttributes:{"type": TNArchipelTypeHypervisorControl}];
    var uuid            = [CPString UUID];
    
    [creationStanza addChildName:@"query" withAttributes:{"type": TNArchipelTypeHypervisorControlAlloc}];
    [creationStanza addChildName:@"uuid"];
    [creationStanza addTextNode:uuid];
    
    [self sendStanza:creationStanza andRegisterSelector:@selector(didAllocVirtualMachine:)];
    
    [buttonCreateVM setEnabled:NO];
}

- (void)didAllocVirtualMachine:(id)aStanza
{
    [buttonCreateVM setEnabled:YES];
    
    if ([aStanza getType] == @"success")
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
    
    _virtualMachinesForDeletion     = [_tableVirtualMachines selectedRowIndexes];

    var msg;
    var title;
    
    if ([_virtualMachinesForDeletion count] < 2)
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
    
    [CPAlert alertWithTitle:title
                    message:msg
                      style:CPInformationalAlertStyle 
                   delegate:self 
                    buttons:[@"Yes", @"No"]];
}

- (void)alertDidEnd:(CPAlert)theAlert returnCode:(int)returnCode 
{
    if (returnCode == 0)
    {
        var indexes = _virtualMachinesForDeletion;
        var objects = [_virtualMachinesDatasource objectsAtIndexes:indexes];
        
        [_tableVirtualMachines deselectAll];
        
        for (var i = 0; i < [objects count]; i++)
        {                              
            var vm              = [objects objectAtIndex:i];
            var freeStanza      = [TNStropheStanza iqWithAttributes:{"type" : TNArchipelTypeHypervisorControl}];

            [freeStanza addChildName:@"query" withAttributes:{"type" : TNArchipelTypeHypervisorControlFree}];
            [freeStanza addTextNode:[vm JID]];

            [_roster removeContact:vm];

            [_entity sendStanza:freeStanza andRegisterSelector:@selector(didFreeVirtualMachine:) ofObject:self];          
        }
    }
    else
    {
        _virtualMachinesForDeletion = Nil;
        [buttonDeleteVM setEnabled:YES];
    }
}

- (void)didFreeVirtualMachine:(id)aStanza
{
    [buttonDeleteVM setEnabled:YES];
    _virtualMachinesForDeletion = Nil;  
    
    if ([aStanza getType] == @"success")
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


