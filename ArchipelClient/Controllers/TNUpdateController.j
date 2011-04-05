/*
 * TNUpdateController.j
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

@import <AppKit/CPTextField.j>
@import <AppKit/CPWindow.j>

@import <LPKit/LPMultiLineTextField.j>
@import <TNKit/TNAlert.j>

@import "../Model/TNVersion.j"


/*! @ingroup archipelcore
    this class allow to check for new version of the application
*/
@implementation TNUpdateController : CPObject
{
    @outlet     CPTextField             fieldCurrentVersion;
    @outlet     CPTextField             fieldDate;
    @outlet     CPTextField             fieldServerVersion;
    @outlet     CPTextField             labelCurrentVersion;
    @outlet     CPTextField             labelDate;
    @outlet     CPTextField             labelServerVersion;
    @outlet     CPWindow                mainWindow;
    @outlet     LPMultiLineTextField    fieldChanges;

    CPURL       _URL                    @accessors(property=URL);
    TNVersion   _currentVersion         @accessors(property=currentVersion);

    BOOL        _forceCheck;
    CPString    _changes;
    CPString    _date;
    CPURL       _URLDownload;
    id          _plist;
    TNVersion   _version;
}


#pragma mark -
#pragma mark Initialization

/*! called at cib awakeingin
*/
- (void)awakeFromCib
{
    [labelCurrentVersion setFont:[CPFont boldSystemFontOfSize:12]];
    [labelServerVersion setFont:[CPFont boldSystemFontOfSize:12]];
    [labelDate setFont:[CPFont boldSystemFontOfSize:12]];

    [fieldChanges setEditable:NO];
    [fieldChanges setEnabled:NO];
    [fieldChanges setTextColor:[CPColor blackColor]];

    _forceCheck = NO;
}


#pragma mark -
#pragma mark Controls

/*! fetch the version information
*/
- (void)check
{
    if (!_forceCheck && ![[CPUserDefaults standardUserDefaults] boolForKey:@"TNArchipelAutoCheckUpdate"])
        return;

    var request     = [CPURLRequest requestWithURL:_URL],
        connection  = [CPURLConnection connectionWithRequest:request delegate:self];

    [connection cancel];
    [connection start];
}

/*! dislay the new version dialog
*/
- (void)showMainWindow
{
    [fieldCurrentVersion setStringValue:[_currentVersion description]];
    [fieldServerVersion setStringValue:[_version description]];
    [fieldDate setStringValue:_date];
    [fieldChanges setStringValue:_changes];

    [mainWindow center];
    [mainWindow makeKeyAndOrderFront:nil];
}


#pragma mark -
#pragma mark Actions

/*! force manual update check
    @param aSender the sender of the action
*/
- (IBAction)manualCheck:(id)aSender
{
    _forceCheck = YES;
    [self check];
}

/*! download the update
    @param aSender the sender of the action
*/
- (IBAction)update:(id)aSender
{
    window.open(_URLDownload, "__new");
    [mainWindow close];
}

/*! cancel the update
    @param aSender the sender of the action
*/
- (IBAction)cancel:(id)aSender
{
    [mainWindow close];
}

/*! ignore definilty this update
    @param aSender the sender of the action
*/
- (IBAction)ignore:(id)aSender
{
    var ignoredVersions = [[CPUserDefaults standardUserDefaults] objectForKey:@"TNArchipelIgnoredVersions"];

    if (!ignoredVersions)
        ignoredVersions = [CPArray array];

    if (![ignoredVersions containsObject:_version])
    {
        [ignoredVersions addObject:_version];
        [[CPUserDefaults standardUserDefaults] setObject:ignoredVersions forKey:@"TNArchipelIgnoredVersions"];
        [[CPNotificationCenter defaultCenter] postNotificationName:TNPreferencesControllerSavePreferencesRequestNotification object:self];
    }

    [mainWindow close];
}


#pragma mark -
#pragma mark Delegate

/*! CPURLConnection delegate
*/
- (void)connection:(CPURLConnection)connection didReceiveData:(CPString)data
{
    var cpdata = [CPData dataWithRawString:data];

    _plist = [cpdata plistObject];

    var major           = [[_plist objectForKey:@"version"] objectForKey:@"major"],
        minor           = [[_plist objectForKey:@"version"] objectForKey:@"minor"],
        revision        = [[_plist objectForKey:@"version"] objectForKey:@"revision"],
        ignoredVersions  = [[CPUserDefaults standardUserDefaults] objectForKey:@"TNArchipelIgnoredVersions"];

    _version     = [TNVersion versionWithMajor:major minor:minor revision:revision];
    _date        = [_plist objectForKey:@"date"];
    _changes     = [_plist objectForKey:@"changes"];
    _URLDownload = [CPURL URLWithString:[_plist objectForKey:@"url"]];

    if ([_version greaterThan:_currentVersion])
    {
        if (_forceCheck == NO)
            for (var i = 0; i < [ignoredVersions count]; i++)
                if ([_version equals:[ignoredVersions objectAtIndex:i]])
                    return;
        else
            _forceCheck = NO;

        [self showMainWindow];
    }
    else if (_forceCheck)
    {
        [TNAlert showAlertWithMessage:@"Already up to date" informative:@"Your version of Archipel ("+_currentVersion+") is already the latest version"];
    }
}

@end