/*
 * TNXMPPAccountController.j
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


@import <AppKit/CPButton.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPWindow.j>

@import <GrowlCappuccino/GrowlCappuccino.j>
@import <StropheCappuccino/TNStropheIMClient.j>


/*! @ingroup archipelcore
    This class represent the current XMPP account properties controller
*/
@implementation TNXMPPAccountController : CPObject
{
    @outlet CPButton        defaultButton;
    @outlet CPTextField     fieldNewPassword;
    @outlet CPTextField     fieldNewPasswordConfirm;
    @outlet CPWindow        mainWindow;
}


#pragma mark -
#pragma mark Initialization

/*! called at cib awakening
*/
- (void)awakeFromCib
{
    [mainWindow setDefaultButton:defaultButton];

    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(passwordDidChange:) name:TNStropheClientPasswordChangedNotification object:nil];
    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(passwordChangeError:) name:TNStropheClientPasswordChangeErrorNotification object:nil];

    [fieldNewPassword setSecure:YES];
    [fieldNewPassword setNeedsLayout];
    [fieldNewPasswordConfirm setSecure:YES];
    [fieldNewPasswordConfirm setNeedsLayout];
}


#pragma mark -
#pragma mark Notification handlers

/*! called when TNStropheClientPasswordChangedNotification is received
    @param aNotification the notificaion
*/
- (void)passwordDidChange:(CPNotification)aNotification
{
    [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:CPLocalizedString(@"Error", @"Error")
                                                     message:CPLocalizedString(@"Your password has been successfully updated", @"Your password has been successfully updated")];
}

/*! called when TNStropheClientPasswordChangeErrorNotification is received
    @param aNotification the notificaion
*/
- (void)passwordChangeError:(CPNotification)aNotification
{
    [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:CPLocalizedString(@"Error", @"Error")
                                                     message:CPLocalizedString(@"Unable to update your password", @"Unable to update your password")
                                                        icon:TNGrowlIconError];
}


#pragma mark -
#pragma mark Actions

/*! Open the main window
    @param sender the sender of the action
*/
- (IBAction)showWindow:(id)aSender
{
    [fieldNewPassword setStringValue:@""];
    [fieldNewPasswordConfirm setStringValue:@""];
    [mainWindow center];
    [mainWindow makeKeyAndOrderFront:aSender];
}

/*! save the changes
    @param aSender the sender of the action
*/
- (IBAction)saveChange:(id)aSender
{
    var password = [fieldNewPassword stringValue],
        passwordConfirm = [fieldNewPasswordConfirm stringValue];

    if (password && password != @"")
    {
        if (password != passwordConfirm)
        {
            [TNAlert showAlertWithMessage:CPLocalizedString(@"Password error", @"Password error")
                              informative:CPLocalizedString(@"The passwords you entered don't match.", @"The passwords you entered don't match.")
                                    style:CPCriticalAlertStyle];
            return;
        }
        [[TNStropheIMClient defaultClient] changePassword:password];
        [mainWindow close];
    }
}

@end
