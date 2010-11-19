# 
# archipelPermissionCenter.py
# 
# Copyright (C) 2010 Antoine Mercadal <antoine.mercadal@inframonde.eu>
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

import sqlite3

class TNArchipelPermissionCenter:
    
    def __init__(self, database, permissions):
        """
        Initialize the permission center
        """
        self.permissions = permissions
        #self.database = sqlite3.connect(database, check_same_thread=False)
    
    
    
    ######################################################################################################
    ### Storage management
    ###################################################################################################### 

    def recover_permissions(self):
        """recover permission from database"""
        pass
    
    
    def save_permission(self):
        """save permission into database"""
        pass
    

    
    ######################################################################################################
    ### Permissions management
    ###################################################################################################### 

    def create_permission(self, name, default_permission=False):
        """create a new permission"""
        pass
    
    
    def delete_permission(self, name):
        """delete a permission"""
        pass
    
    
    def check_permission(self, user, permission_name):
        """check if given user has given permission"""
        return True
    
    
    
    ######################################################################################################
    ### User permissions management
    ###################################################################################################### 
    
    def add_permission(self, user, permission):
        """give to user a permission"""
        pass
    
    
    def add_permissions(self, user, permissions):
        """give user some permission"""
        for perm in permissions:
            self.add_permission(user, perm)
    
    
    def remove_permission(self, user, permission):
        """remove the given permission for given user"""
        pass
    
    
    def remove_permissions(self, user, permissions):
        """remove some permissions from user"""
        for perm in permissions:
            self.remove_permission(user, perm)
    
        