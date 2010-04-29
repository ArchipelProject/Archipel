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
 
@import "TNDatasourceVMs.j"

TNArchipelTypeHypervisorControl             = @"archipel:hypervisor:control";
TNArchipelTypeHypervisorControlAlloc        = @"alloc";
TNArchipelTypeHypervisorControlFree         = @"free";
TNArchipelTypeHypervisorControlRosterVM     = @"rostervm";

TNArchipelPushNotificationVirtualMachine    = @"archipel:push:subcription";
TNArchipelPushNotificationSubscriptionAdded = @"added";

@implementation TNHypervisorVMCreation : TNModule 
{
    @outlet CPTextField     fieldJID                    @accessors;
    @outlet CPTextField     fieldName                   @accessors;
    @outlet CPButton        buttonCreateVM              @accessors;
    @outlet CPPopUpButton   popupDeleteMachine          @accessors;
    @outlet CPButton        buttonDeleteVM              @accessors;
    @outlet CPScrollView    scrollViewListVM            @accessors;
    
    CPTableView             tableVirtualMachines        @accessors;
    TNDatasourceVMs         virtualMachinesDatasource   @accessors;
    
    TNStropheContact        _virtualMachineRegistredForDeletion;
}

- (void)awakeFromCib
{
    // VM table view
    virtualMachinesDatasource   = [[TNDatasourceVMs alloc] init];
    tableVirtualMachines        = [[CPTableView alloc] initWithFrame:[[self scrollViewListVM] bounds]];

    [[self scrollViewListVM] setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [[self scrollViewListVM] setAutohidesScrollers:YES];
    [[self scrollViewListVM] setDocumentView:[self tableVirtualMachines]];
    [[self scrollViewListVM] setBorderedWithHexColor:@"#9e9e9e"];

    [[self tableVirtualMachines] setUsesAlternatingRowBackgroundColors:YES];
    [[self tableVirtualMachines] setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [[self tableVirtualMachines] setAllowsColumnReordering:YES];
    [[self tableVirtualMachines] setAllowsColumnResizing:YES];
    [[self tableVirtualMachines] setAllowsEmptySelection:YES];

    var vmColumNickname = [[CPTableColumn alloc] initWithIdentifier:@"nickname"];
    [vmColumNickname setWidth:250];
    [[vmColumNickname headerView] setStringValue:@"Name"];

    var vmColumJID = [[CPTableColumn alloc] initWithIdentifier:@"jid"];
    [vmColumJID setWidth:450];
    [[vmColumJID headerView] setStringValue:@"Jabber ID"];

    var vmColumStatusIcon   = [[CPTableColumn alloc] initWithIdentifier:@"statusIcon"];
    var imgView             = [[CPImageView alloc] initWithFrame:CGRectMake(0,0,16,16)];
    [imgView setImageScaling:CPScaleNone];
    [vmColumStatusIcon setDataView:imgView];
    [vmColumStatusIcon setResizingMask:CPTableColumnAutoresizingMask ];
    [vmColumStatusIcon setWidth:16];
    [[vmColumStatusIcon headerView] setStringValue:@""];

    [[self tableVirtualMachines] addTableColumn:vmColumStatusIcon];
    [[self tableVirtualMachines] addTableColumn:vmColumNickname];
    [[self tableVirtualMachines] addTableColumn:vmColumJID];

    [[self tableVirtualMachines] setDataSource:[self virtualMachinesDatasource]];
}

- (void)willLoad
{
    [super willLoad];
    
    [self registerSelector:@selector(didSubscriptionPushReceived:) forPushNotificationType:TNArchipelPushNotificationVirtualMachine];
}

- (void)willShow
{
    [super willShow];
    
    var center = [CPNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(didNickNameUpdated:) name:TNStropheContactNicknameUpdatedNotification object:[self entity]];
    [center addObserver:self selector:@selector(didContactAdded:) name:TNStropheRosterAddedContactNotification object:nil];
    
    [[self fieldName] setStringValue:[[self entity] nickname]];
    [[self fieldJID] setStringValue:[[self entity] jid]];
        
    [self getHypervisorRoster];
}

- (void)willUnload
{
    [super willUnload];
    
    [buttonCreateVM setEnabled:YES];
}

- (BOOL)didSubscriptionPushReceived:(TNStropheStanza)aStanza
{
    CPLog.info("Receiving push notification of type TNArchipelPushNotificationVirtualMachine");
    [self getHypervisorRoster];
    
    return YES;
}

- (void)didContactAdded:(CPNotification)aNotification
{
    [self getHypervisorRoster];
}

- (void)didNickNameUpdated:(CPNotification)aNotification
{
    [[self fieldName] setStringValue:[[self entity] nickname]] 
}

- (void)getHypervisorRoster
{
    var rosterStanza = [TNStropheStanza iqWithAttributes:{"type" : TNArchipelTypeHypervisorControl}];
        
    [rosterStanza addChildName:@"query" withAttributes:{"type" : TNArchipelTypeHypervisorControlRosterVM}];
    [[self entity] sendStanza:rosterStanza andRegisterSelector:@selector(didReceiveHypervisorRoster:) ofObject:self];
}

- (void)didReceiveHypervisorRoster:(id)aStanza 
{
    if ([aStanza getType] == @"success")
    {
        var queryItems  = [aStanza childrenWithName:@"item"];
        var center      = [CPNotificationCenter defaultCenter];
    
        [[[self virtualMachinesDatasource] VMs] removeAllObjects];
    
        for (var i = 0; i < [queryItems count]; i++)
        {
            var jid     = [[queryItems objectAtIndex:i] text];
            var entry   = [[self roster] getContactFromJID:jid];
        
            if (entry) 
            {
               if ([[[entry vCard] firstChildWithName:@"TYPE"] text] == "virtualmachine")
               {
                    [[self virtualMachinesDatasource] addVM:entry];
                    [center addObserver:self selector:@selector(didVirtualMachineChangesStatus:) name:TNStropheContactPresenceUpdatedNotification object:entry];   
               }
            }
        }
    
        [[self tableVirtualMachines] reloadData];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}

- (void)didVirtualMachineChangesStatus:(CPNotification)aNotif
{
    [[self tableVirtualMachines] reloadData];
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
        var vmJid   = [[[aStanza firstChildWithName:@"query"] firstChildWithName:@"virtualmachine"] valueForAttribute:@"jid"];
        CPLog.info(@"sucessfully create a virtual machine");
        
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Virtual Machine" message:@"Virtual machine " + vmJid + @" has been created"];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}

- (IBAction)deleteVirtualMachine:(id)sender
{
    if (([[self tableVirtualMachines] numberOfRows] == 0) || ([[self tableVirtualMachines] numberOfSelectedRows] <= 0))
    {
         [CPAlert alertWithTitle:@"Error" message:@"You must select a virtual machine"];
         return;
    }
    
    var selectedIndex                       = [[[self tableVirtualMachines] selectedRowIndexes] firstIndex];
    
    _virtualMachineRegistredForDeletion     = [[[self virtualMachinesDatasource] VMs] objectAtIndex:selectedIndex];
    
    [buttonDeleteVM setEnabled:NO];
    
    [CPAlert alertWithTitle:@"Destroying a Virtual Machine" 
                    message:@"Are you sure you want to completely remove this virtual machine ?"
                      style:CPInformationalAlertStyle 
                   delegate:self 
                    buttons:[@"Yes", @"No"]];
}

- (void)alertDidEnd:(CPAlert)theAlert returnCode:(int)returnCode 
{
    if (returnCode == 0)
    {
        var vm              = _virtualMachineRegistredForDeletion;
        var freeStanza      = [TNStropheStanza iqWithAttributes:{"type" : TNArchipelTypeHypervisorControl}];
        
        [freeStanza addChildName:@"query" withAttributes:{"type" : TNArchipelTypeHypervisorControlFree}];
        [freeStanza addTextNode:[vm jid]];
        
        [[self roster] removeContact:[vm jid]];
        
        [[self entity] sendStanza:freeStanza andRegisterSelector:@selector(didFreeVirtualMachine:) ofObject:self];
    }
    else
    {
        _virtualMachineRegistredForDeletion = Nil;
        [buttonDeleteVM setEnabled:YES];
    }
}

- (void)didFreeVirtualMachine:(id)aStanza
{
    [buttonDeleteVM setEnabled:YES];
    _virtualMachineRegistredForDeletion = Nil;
    if ([aStanza getType] == @"success")
    {
        [self getHypervisorRoster];
        CPLog.info(@"sucessfully deallocating a virtual machine");
        
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Virtual Machine" message:@"Virtual machine has been removed"];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}

@end


