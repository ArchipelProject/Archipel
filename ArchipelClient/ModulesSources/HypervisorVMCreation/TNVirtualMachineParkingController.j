/*
 * TNVirtualMachineParkingController.j
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
@import <AppKit/CPView.j>
@import <AppKit/CPButton.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPTableView.j>
@import <AppKit/CPPopover.j>

@import <LPKit/LPMultiLineTextField.j>
@import <StropheCappuccino/TNXMLNode.j>
@import <StropheCappuccino/TNStropheStanza.j>
@import <TNKit/TNAlert.j>
@import <TNKit/TNTableViewLazyDataSource.j>

@implementation TNTableViewLazyDataSource (paginate)
- (id)tableView:(CPTableView)aTable objectValueForTableColumn:(CPNumber)aCol row:(CPNumber)aRow
{
    var identifier = [aCol identifier];

    if (!_currentlyLoading
        && [_content count] < _totalCount
        && (aRow + _lazyLoadingTrigger >= [_content count])
        && _delegate
        && [_delegate respondsToSelector:@selector(tableViewDataSourceNeedsLoading:)])
    {
        _currentlyLoading = YES;
        [_delegate tableViewDataSourceNeedsLoading:self];
    }

    return [_content[aRow] valueForKeyPath:identifier];
}
@end


@global CPLocalizedString
@global CPLocalizedStringFromTableInBundle
@global TNArchipelModuleStatusWaiting
@global TNArchipelModuleStatusReady


var TNArchipelTypeHypervisorParking             = @"archipel:hypervisor:vmparking",
    TNArchipelTypeHypervisorParkingList         = @"list",
    TNArchipelTypeHypervisorParkingPark         = @"park",
    TNArchipelTypeHypervisorParkingUnpark       = @"unpark",
    TNArchipelTypeHypervisorParkingDelete       = @"delete",
    TNArchipelTypeHypervisorParkingUpdateXML    = @"updatexml";

@implementation TNVirtualMachineParkedObject : CPObject
{
    CPString name       @accessors;
    CPString UUID       @accessors;
    CPString date       @accessors;
    CPString parker     @accessors;
    TNXMLNode domain    @accessors;
}
@end


/*! @ingroup hypervisorvmcreation
    This object allow to clone an existing virtual machine
*/
@implementation TNVirtualMachineParkingController : CPObject
{
    @outlet CPButton                buttonDefine;
    @outlet CPPopover               mainPopover;
    @outlet LPMultiLineTextField    fieldXMLString;

    TNVirtualMachineParkedObject    _currentItem @accessors(property=currentItem);
    id                              _delegate    @accessors(property=delegate);
    TNTableViewLazyDataSource       _datasource  @accessors(getter=dataSource);

    int                             _maxLoadedPage;
    CPString                        _currentFilter;
}


#pragma mark -
#pragma mark Initialization

/*! Called at cib awakening
*/
- (void)awakeFromCib
{
    [fieldXMLString setTextColor:[CPColor blackColor]];
    [fieldXMLString setFont:[CPFont fontWithName:@"Andale Mono, Courier New" size:12]];
    [fieldXMLString setBordered:YES];
    [fieldXMLString setBezeled:YES];
    [fieldXMLString setEnabled:YES];
}

#pragma mark -
#pragma mark Initialization

/*! Instaciate the class
*/
- (id)init
{
    if (self = [super init])
    {
        _maxLoadedPage = 0;
        _currentFilter = @""
    }

    return self;
}

#pragma mark -
#pragma mark Getters / Setters

/*! Set the target datasource, and set self ad datasource delegate
    @pathForResource aDataSource the TNTableViewLazyDataSource to use
*/
- (void)setDataSource:(TNTableViewLazyDataSource)aDataSource
{
    _datasource = aDataSource;
    [_datasource setDelegate:self];
}


/*! Reset informations
*/
- (void)reset
{
    _currentFilter = @"";
    _maxLoadedPage = 0;
    [_datasource setTotalCount:-1];
    [_datasource setCurrentlyLoading:NO];
}


#pragma mark -
#pragma mark Action

/*! open the window
    @param aSender the sender
*/
- (IBAction)openWindow:(id)aSender
{
    [fieldXMLString setStringValue:@""];

    [mainPopover close];

    if (!_currentItem)
        return;

    if ([aSender isKindOfClass:CPTableView])
    {
        var rect = [aSender rectOfRow:[aSender selectedRow]];
        rect.origin.y += rect.size.height / 2;
        rect.origin.x += rect.size.width / 2;
        [mainPopover showRelativeToRect:CGRectMake(rect.origin.x, rect.origin.y, 10, 10) ofView:aSender preferredEdge:nil];
    }
    else
        [mainPopover showRelativeToRect:nil ofView:aSender preferredEdge:nil];
    [mainPopover makeFirstResponder:fieldXMLString];
    [mainPopover setDefaultButton:buttonDefine];

    // if I put this before, the field is empty...
    var XMLString = [[_currentItem domain] description];
    XMLString = XMLString.replace("\n  \n", "\n");
    XMLString = XMLString.replace(" xmlns='http://www.gajim.org/xmlns/undeclared'", "");
    XMLString = XMLString.replace(" xmlns='archipel:hypervisor:vmparking'", "");
    [fieldXMLString setStringValue:XMLString];

    [fieldXMLString setEditable:YES];
}

/*! close the window
    @param aSender the sender
*/
- (IBAction)closeWindow:(id)aSender
{
    [mainPopover close];
}

/*! clone a virtual machine
    @param sender the sender of the action
*/
- (IBAction)updateXML:(id)aSender
{
    var desc;
    try
    {
        desc = (new DOMParser()).parseFromString(unescape(""+[fieldXMLString stringValue]+""), "text/xml").getElementsByTagName("domain")[0];
        if (!desc || typeof(desc) == "undefined")
            [CPException raise:CPInternalInconsistencyException reason:@"Not valid XML"];
    }
    catch (e)
    {
        [TNAlert showAlertWithMessage:CPLocalizedString(@"Error", @"Error")
                          informative:CPLocalizedString(@"Unable to parse the given XML", @"Unable to parse the given XML")
                          style:CPCriticalAlertStyle];
        [mainPopover close];
        return;
    }

    [self updateCurrentItemXML:[TNXMLNode nodeWithXMLNode:desc]];
    [mainPopover close];
}


#pragma mark -
#pragma mark Utilities

/*! unpark given virtual machines but not start them
    @param someVirtualMachines CPArray of virtual machine to park
*/
- (void)unparkVirtualMachines:(CPArray)someVirtualMachines
{
    [self unparkVirtualMachines:someVirtualMachines start:NO];
}

/*! unpark given virtual machines and start them
    @param someVirtualMachines CPArray of virtual machine to park
*/
- (void)unparkAndStartVirtualMachines:(CPArray)someVirtualMachines
{
    [self unparkVirtualMachines:someVirtualMachines start:YES];
}


#pragma mark -
#pragma mark XMPP Controls

/*! Get list of parked virtual machines
*/
- (void)listParkedVirtualMachines
{
    [self listParkedVirtualMachines:_currentFilter];
}

/*! Get list of parked virtual machines with  filter
*/
- (void)listParkedVirtualMachines:(CPString)aFilter
{
    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorParking}];
    if (aFilter != @""){
        [stanza addChildWithName:@"archipel" andAttributes:{
            "action": TNArchipelTypeHypervisorParkingList,
            "page": _maxLoadedPage,
            "filter": aFilter}];
    }
    else {
        [stanza addChildWithName:@"archipel" andAttributes:{
            "action": TNArchipelTypeHypervisorParkingList,
            "page": _maxLoadedPage}];
    }

    [_delegate setModuleStatus:TNArchipelModuleStatusWaiting];
    [_datasource setCurrentlyLoading:YES];
    [_delegate sendStanza:stanza andRegisterSelector:@selector(_didReceiveList:) ofObject:self];
}

/*! compute the answer of the hypervisor about its parking VMs list
    @param aStanza TNStropheStanza containing hypervisor answer
*/
- (BOOL)_didReceiveList:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        var table = [_delegate tableVirtualMachinesParked],
            datasource = [table dataSource],
            virtualmachines = [aStanza childrenWithName:@"virtualmachine"];

        if (_maxLoadedPage == 0) {
            [datasource removeAllObjects];
        }

        for (var i = 0; i < [virtualmachines count]; i++)
        {
            var vm = [virtualmachines objectAtIndex:i],
                data = [TNVirtualMachineParkedObject new];

            [data setName:[[vm firstChildWithName:@"name"] text]];
            [data setUUID:[[vm firstChildWithName:@"uuid"] text]];
            [data setDate:[vm valueForAttribute:@"date"]];
            [data setParker:[vm valueForAttribute:@"parker"]];
            [data setDomain:[vm firstChildWithName:@"domain"]];

            [datasource addObject:data];
        }
        [table reloadData];
        if ([virtualmachines count] < 30)
            [datasource setTotalCount:[datasource count]]
        else
            [datasource setTotalCount:[datasource count] + 10]
    }
    else
    {
        [_delegate handleIqErrorFromStanza:aStanza];
    }
    [_datasource setCurrentlyLoading:NO];

    return NO;
}

/*! Destroy if needed and park some virtual machines
    @param someVirtualMachines CPArray of virtual machine to park
*/
- (void)parkVirtualMachines:(CPArray)someVirtualMachines
{
    var stanza = [TNStropheStanza iqWithType:@"set"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorParking}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorParkingPark}];

    for (var i = 0; i < [someVirtualMachines count]; i++)
    {
        var vm = [someVirtualMachines objectAtIndex:i];
        [stanza addChildWithName:@"item" andAttributes:{"uuid": [[vm JID] node]}];
        [stanza up];
    }

    [_delegate setModuleStatus:TNArchipelModuleStatusWaiting];
    [_delegate sendStanza:stanza andRegisterSelector:@selector(_didParkVirtualMachine:) ofObject:self];
}

/*! compute the answer of the hypervisor about its parking VMs
    @param aStanza TNStropheStanza containing hypervisor answer
*/
- (BOOL)_didParkVirtualMachine:(TNStropheStanza)aStanza
{
    if ([aStanza type] != @"result")
        [_delegate handleIqErrorFromStanza:aStanza];

    [_delegate setModuleStatus:TNArchipelModuleStatusReady];
    return NO;
}

/*! unpark some virtual machines
    @param someVirtualMachines CPArray of virtual machine to unpark
*/
- (void)unparkVirtualMachines:(CPArray)someVirtualMachines start:(BOOL)shouldStart
{
    var stanza = [TNStropheStanza iqWithType:@"set"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorParking}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorParkingUnpark}];

    for (var i = 0; i < [someVirtualMachines count]; i++)
    {
        var vm = [someVirtualMachines objectAtIndex:i];
        [stanza addChildWithName:@"item" andAttributes:{"identifier": [vm UUID], "start": shouldStart ? @"yes" : @"no"}];
        [stanza up];
    }

    [_delegate setModuleStatus:TNArchipelModuleStatusWaiting];
    [_delegate sendStanza:stanza andRegisterSelector:@selector(_didUnparkVirtualMachine:) ofObject:self];
}

/*! compute the answer of the hypervisor about uparking virtual machines
    @param aStanza TNStropheStanza containing hypervisor answer
*/
- (BOOL)_didUnparkVirtualMachine:(TNStropheStanza)aStanza
{
    if ([aStanza type] != @"result")
        [_delegate handleIqErrorFromStanza:aStanza];

    [[_delegate tableVirtualMachinesParked] deselectAll];
    [_delegate setModuleStatus:TNArchipelModuleStatusReady];

    return NO;
}

/*! Update the current parked vm item XML definition
    @param aNewDefinition TNXMLNode representing the new definition
*/
- (void)updateCurrentItemXML:(TNXMLNode)aNewDefinition
{
    var stanza = [TNStropheStanza iqWithType:@"set"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorParking}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorParkingUpdateXML,
        "identifier": [_currentItem UUID]}];

    [stanza addNode:aNewDefinition];
    _currentItem = nil;

    [_delegate setModuleStatus:TNArchipelModuleStatusWaiting];
    [_delegate sendStanza:stanza andRegisterSelector:@selector(_didUpdateCurrentItemXML:) ofObject:self];
}

/*! compute the answer of the hypervisor about updating xml description
    @param aStanza TNStropheStanza containing hypervisor answer
*/
- (BOOL)_didUpdateCurrentItemXML:(TNStropheStanza)aStanza
{
    if ([aStanza type] != @"result")
        [_delegate handleIqErrorFromStanza:aStanza];

    [_delegate setModuleStatus:TNArchipelModuleStatusReady];

    return NO;
}

/*! Delete some parked VMs
    @param someVirtualMachines CPArray containing parked virtual machines to delete
*/
- (void)deleteParkedVirtualMachines:(CPArray)someVirtualMachines
{
    var stanza = [TNStropheStanza iqWithType:@"set"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorParking}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorParkingDelete}];

    for (var i = 0; i < [someVirtualMachines count]; i++)
    {
        var vm = [someVirtualMachines objectAtIndex:i];
        [stanza addChildWithName:@"item" andAttributes:{"identifier": [vm UUID]}];
        [stanza up];
    }

    [_delegate setModuleStatus:TNArchipelModuleStatusWaiting];
    [_delegate sendStanza:stanza andRegisterSelector:@selector(_didDeleteParkedVirtualMachines:) ofObject:self];

}

/*! compute the answer of the hypervisor about deleting parked virtual machines
    @param aStanza TNStropheStanza containing hypervisor answer
*/
- (BOOL)_didDeleteParkedVirtualMachines:(TNStropheStanza)aStanza
{
    if ([aStanza type] != @"result")
        [_delegate handleIqErrorFromStanza:aStanza];

    [[_delegate tableVirtualMachinesParked] deselectAll];
    [_delegate setModuleStatus:TNArchipelModuleStatusReady];

    return NO;
}

/*! TNTableViewLazyDataSource delegate
*/
- (void)tableViewDataSourceNeedsLoading:(TNTableViewLazyDataSource)aDataSource
{
    console.error(_maxLoadedPage)
    console.error([_datasource count])
    console.error([_datasource totalCount])
    _maxLoadedPage++;
    [self listParkedVirtualMachines];
}

/*! TNTableViewLazyDataSource delegate
*/
- (void)tableViewDataSource:(TNTableViewLazyDataSource)aDataSource applyFilter:(CPString)aFilter
{
    [self reset];
    if ([aFilter length] >= 3)
        _currentFilter = aFilter;
        [self listParkedVirtualMachines:aFilter];
}

/*! TNTableViewLazyDataSource delegate
*/
- (void)tableViewDataSource:(TNTableViewLazyDataSource)aDataSource removeFilter:(CPString)aFilter
{
    [self reset];
    _currentFilter = @""
    [self listParkedVirtualMachines];
}


@end

// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNVirtualMachineParkingController], comment);
}
