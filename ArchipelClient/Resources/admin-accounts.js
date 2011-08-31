/*
 * admin-accounts.js
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

// this file contains a list of user that must be considered as admin by the GUI
// This *DOES NOT MEAN* that the user will actually be admins
// It will just activate admin parts of the interface, but in the end
// if the user is not an actual admin account, all his requests will be
// rejected by the archipel entities.
//
// add your the accounts you want to make GUI admins.
//  * if ArchipelCheckNodeAdminAccount is set to 1 (by default) just add the node (ie myuser)
//  * if ArchipelCheckNodeAdminAccount is set to 0 just add the full JID (ie myuser@myfqdn)
//
// for example
// ARCHIPEL_ADMIN_ACCOUNTS_ARRAY = [
//      "userA", "userB", "userC"
// ];

ARCHIPEL_ADMIN_ACCOUNTS_ARRAY = [
    // add users here
];