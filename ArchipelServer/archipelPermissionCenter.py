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

from sqlobject import *

class TNArchipelUser (SQLObject):
    
    class sqlmeta:
        table = "TNArchipelUser"
    
    name = StringCol(alternateID=True)
    roles = RelatedJoin('TNArchipelRole')

    
class TNArchipelRole (SQLObject):
    
    class sqlmeta:
        table = "TNArchipelRole"
    
    name = StringCol(alternateID=True)
    
    users = RelatedJoin('TNArchipelUser')


class TNArchipelPermission (SQLObject):

    class sqlmeta:
        table = "TNArchipelPermission"

    name = StringCol(alternateID=True)
    defaultValue = IntCol()

    users = RelatedJoin('TNArchipelUser')
    roles = RelatedJoin('TNArchipelRole')



class TNArchipelPermissionCenter:
    
    
    def __init__(self, database_file):
        connection_string = 'sqlite:/%s' % database_file
        self.connection = connectionForURI(connection_string)
        sqlhub.processConnection = self.connection
        TNArchipelRole.createTable(ifNotExists=True)
        TNArchipelUser.createTable(ifNotExists=True)
        TNArchipelPermission.createTable(ifNotExists=True)
    
    
    ######################################################################################################
    ### Permission management
    ###################################################################################################### 
    
    def create_permission(self, name, default_permission=False):
        """create a new permission"""
        try:
            TNArchipelPermission(name=name, defaultValue=int(default_permission))
            return True
        except dberrors.DuplicateEntryError:
            return False
    
    
    def get_permission(self, name):
        """get the permission by name"""
        try:
            return TNArchipelPermission.byName(name);
        except main.SQLObjectNotFound:
            return None
    
    
    def delete_permission(self, name):
        """delete the permission by name"""
        perm = self.get_permission(name)
        if perm: 
            perm.destroySelf()
            return True
        else:
            return False
    
    
    
    ######################################################################################################
    ### Users management
    ###################################################################################################### 
    
    def create_user(self, name):
        """create a new user"""
        try:
            TNArchipelUser(name=name)
            return True
        except dberrors.DuplicateEntryError:
            return False
    
    
    def get_user(self, name):
        """get the user by name"""
        try:
            return TNArchipelUser.byName(name);
        except main.SQLObjectNotFound:
            return None
    
    
    def delete_user(self, name):
        """delete the user by name"""
        user = self.get_user(name)
        if user: 
            user.destroySelf()
            return True
        else:
            return False
    
    
    
    def grant_permission_to_user(self, permission_name, user_name):
        perm = self.get_permission(permission_name)
        user = self.get_user(user_name)
        if user and perm:
            perm.addTNArchipelUser(user)
            return True
        else:
            return False
    
    
    def retract_permission_to_user(self, permission_name, user_name):
        perm = self.get_permission(permission_name)
        user = self.get_user(user_name)
        if user and perm:
            perm.removeTNArchipelUser(user)
            return True
        else:
            return False
    
    
    def user_has_permission(self, user_name, permission_name):
        user = self.get_user(user_name)
        perm = self.get_permission(permission_name)
        if user and perm:
            return (user in perm.users)
        else:
            return False
    
    
    
    def user_has_role(self, user_name, role_name):
        role = self.get_role(role_name)
        user = self.get_user(user_name)
        if user and role:
            return (role in user.roles)
        else:
            return False
    
    
    def get_user_roles(self, user_name):
        user = self.get_user(user_name);
        return user.roles
    
    
    ######################################################################################################
    ### Roles management
    ###################################################################################################### 
    
    def create_role(self, name):
        """create a new role"""
        try:
            TNArchipelRole(name=name)
            return True
        except dberrors.DuplicateEntryError:
            return False
    
    
    def get_role(self, name):
        """get the role by name"""
        try:
            return TNArchipelRole.byName(name);
        except main.SQLObjectNotFound:
            return None
    
    
    def delete_role(self, name):
        """delete the role by name"""
        role = self.get_role(name)
        if role: 
            role.destroySelf()
            return True
        else:
            return False
    
    
    
    def give_role_to_user(self, role_name, user_name):
        user = self.get_user(user_name)
        role = self.get_role(role_name)
        if user and role:
            role.addTNArchipelUser(user)
            return True
        else:
            return False
    
    
    def retract_role_to_user(self, role_name, user_name):
        user = self.get_user(user_name)
        role = self.get_role(role_name)
        if user and role:
            role.removeTNArchipelUser(user)
            return True
        else:
            return False
    
    
    def role_has_user(self, role_name, user_name):
        role = self.get_role(role_name)
        user = self.get_user(user_name)
        if user and role:
            return (user in role.users)
        else:
            return False
    
    
    def get_role_users(self, role_name):
        role = self.get_role(role_name)
        return role.users
    
    
    def grant_permission_to_role(self, permission_name, role_name):
        perm = self.get_permission(permission_name)
        role = self.get_role(role_name)
        if role and perm:
            perm.addTNArchipelRole(role)
            return True
        else:
            return False
    
    
    def retract_permission_to_role(self, permission_name, role_name):
        perm = self.get_permission(permission_name)
        role = self.get_role(role_name)
        if role and perm:
            perm.addTNArchipelRole(role)
            return True
        else:
            return False


    
    
    def role_has_permission(self, role_name, permission_name):
        role = self.get_role(role_name)
        perm = self.get_permission(permission_name)
        if role and perm:
            return (role in perm.roles)
        else:
            return False
    
    
    
    # ######################################################################################################
    # ### User permissions verification
    # ###################################################################################################### 
    # 
    def check_permission(self, user_name, permission_name):
        """check if given user has given permission"""
        #TODO: be kind, be OK 
        return True;
        
        if self.user_has_permission(user_name, permission_name):
            return True
        
        for role in self.get_user_roles(user_name):
            if self.role_has_permission(role.name, permission_name):
                return True
        return False
    


if __name__ == "__main__":
    import os, sys
    f = sys.argv[1]
    p = TNArchipelPermissionCenter(f)
    
    p.create_role("Role1")
    p.create_role("Role2")
    p.create_user("User1")
    p.create_user("User2")
    p.create_user("User3")
    p.create_permission("Perm1")
    p.create_permission("Perm2")
    p.create_permission("Perm3")
    p.create_permission("Perm4")
    
    p.give_role_to_user("Role1", "User1")
    p.give_role_to_user("Role2", "User1")
    p.give_role_to_user("Role2", "User2")
    
    p.grant_permission_to_user("Perm1", "User3")
    
    p.grant_permission_to_role("Perm3", "Role1")
    p.grant_permission_to_role("Perm4", "Role1")
    p.grant_permission_to_role("Perm2", "Role2")

