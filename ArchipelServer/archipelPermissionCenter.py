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
from utils import *

class TNArchipelPermissionCenter:
    
    class TNArchipelUser (SQLObject):
        
        class sqlmeta:
            table = "TNArchipelUser"
            lazyUpdate = True
            cacheValues = False
        
        name = StringCol(alternateID=True)
        roles = RelatedJoin('TNArchipelRole')
        permissions = RelatedJoin('TNArchipelPermission')
    
    
    class TNArchipelRole (SQLObject):
        
        class sqlmeta:
            table = "TNArchipelRole"
            lazyUpdate = True
            cacheValues = False
        
        name = StringCol(alternateID=True)
        description = StringCol()
        users = RelatedJoin('TNArchipelUser')
        permissions = RelatedJoin('TNArchipelPermission')
        
    
    
    class TNArchipelPermission (SQLObject):
        
        class sqlmeta:
            table = "TNArchipelPermission"
            lazyUpdate = True
            cacheValues = False
        
        name = StringCol(alternateID=True)
        description = StringCol()
        defaultValue = IntCol()
        users = RelatedJoin('TNArchipelUser')
        roles = RelatedJoin('TNArchipelRole')
    
    
    def __init__(self, database_file, root_admin):
        self.root_admin = root_admin
        connection_string = 'sqlite://%s' % database_file
        self.connection = connectionForURI(connection_string)
        
        self.TNArchipelRole.createTable(ifNotExists=True, connection=self.connection)
        self.TNArchipelUser.createTable(ifNotExists=True, connection=self.connection)
        self.TNArchipelPermission.createTable(ifNotExists=True, connection=self.connection)
    
    
    ######################################################################################################
    ### Permission management
    ###################################################################################################### 
    
    def create_permission(self, name, description="", default_permission=False):
        """create a new permission"""
        try:
            self.TNArchipelPermission(name=name, description=description, defaultValue=int(default_permission), connection=self.connection)
            return True
        except dberrors.DuplicateEntryError:
            return False
    
    
    def get_permission(self, name):
        """get the permission by name"""
        try:
            return self.TNArchipelPermission.byName(name, connection=self.connection);
        except main.SQLObjectNotFound:
            return None
    
    
    def delete_permission(self, name):
        """delete the permission by name"""
        perm = self.get_permission(name)
        if perm: 
            perm.destroySelf(connection=self.connection)
            return True
        else:
            return False
    
    
    def get_permissions(self):
        """return all permissions"""
        return self.TNArchipelPermission.select(connection=self.connection);
    
    
    
    ######################################################################################################
    ### Users management
    ###################################################################################################### 
    
    def create_user(self, name):
        """create a new user"""
        try:
            trans = self.connection.transaction()
            self.TNArchipelUser(name=name, connection=self.connection)
            trans.commit()
            return True
        except dberrors.DuplicateEntryError:
            return False
    
    
    def get_user(self, name):
        """get the user by name"""
        try:
            return self.TNArchipelUser.byName(name, connection=self.connection);
        except main.SQLObjectNotFound:
            return None
    
    
    def delete_user(self, name):
        """delete the user by name"""
        user = self.get_user(name)
        if user: 
            trans = self.connection.transaction()
            user.destroySelf()
            trans.commit()
            return True
        else:
            return False
    
    
    
    def grant_permission_to_user(self, permission_name, user_name):
        perm = self.get_permission(permission_name)
        user = self.get_user(user_name)
        
        if not user:
            log.info("user %s doesn't exists. creating" % user_name)
            self.create_user(user_name)
            user = self.get_user(user_name)
            perm = self.get_permission(permission_name)
            self.TNArchipelUser.expired = True
            self.TNArchipelPermission.expired = True
        
        if perm in user.permissions: return True
        
        if perm and user:
            trans = self.connection.transaction()
            log.info("setting permission %s to user %s" % (permission_name, user_name))
            perm.addTNArchipelUser(user)
            trans.commit()
            return True
        else:
            return False
    
    
    def revoke_permission_to_user(self, permission_name, user_name):
        perm = self.get_permission(permission_name)
        user = self.get_user(user_name)
        
        if not user: return True
        if not perm in user.permissions: return True
        
        if user and perm:
            trans = self.connection.transaction()
            user.removeTNArchipelPermission(perm)
            trans.commit()
            self.TNArchipelUser.expired = True
            self.TNArchipelPermission.expired = True
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
        if user: return user.roles
        return None
    
    
    def get_user_permissions(self, user_name):
        user = self.get_user(user_name);
        if user: return user.permissions
        return None

    
    
    ######################################################################################################
    ### Roles management
    ###################################################################################################### 
    
    def create_role(self, name, description=""):
        """create a new role"""
        try:
            trans = self.connection.transaction()
            self.TNArchipelRole(name=name, description=description, connection=self.connection)
            trans.commit()
            return True
        except dberrors.DuplicateEntryError:
            return False
    
    
    def get_role(self, name):
        """get the role by name"""
        try:
            return self.TNArchipelRole.byName(name, connection=self.connection);
        except main.SQLObjectNotFound:
            return None
    
    
    def delete_role(self, name):
        """delete the role by name"""
        role = self.get_role(name)
        if role: 
            trans = self.connection.transaction()
            role.destroySelf()
            trans.commit()
            return True
        else:
            return False
    
    
    
    def give_role_to_user(self, role_name, user_name):
        user = self.get_user(user_name)
        role = self.get_role(role_name)
        if user and role:
            trans = self.connection.transaction()
            role.addTNArchipelUser(user)
            trans.commit()
            return True
        else:
            return False
    
    
    def retract_role_to_user(self, role_name, user_name):
        user = self.get_user(user_name)
        role = self.get_role(role_name)
        if user and role:
            trans = self.connection.transaction()
            role.removeTNArchipelUser(user)
            trans.commit()
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
            trans = self.connection.transaction()
            perm.addTNArchipelRole(role)
            trans.commit()
            return True
        else:
            return False
    
    
    def revoke_permission_to_role(self, permission_name, role_name):
        perm = self.get_permission(permission_name)
        role = self.get_role(role_name)
        if role and perm:
            trans = self.connection.transaction()
            perm.addTNArchipelRole(role)
            trans.commit()
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
    
    def check_permission(self, user_name, permission_name):
        """check if given user has given permission"""
        
        if user_name == self.root_admin: return True
        if self.user_has_permission(user_name, "all"): return True
        if not self.get_user(user_name): return False
        if not self.get_permission(permission_name): return False
        if self.user_has_permission(user_name, permission_name): return True
        
        for role in self.get_user_roles(user_name):
            if self.role_has_permission(role.name, permission_name):
                return True
        return False
    


if __name__ == "__main__":
    import os, sys
    f = sys.argv[1]
    p = TNArchipelPermissionCenter(f, "admin")
    
    print p.create_role("Role1")
    print p.create_role("Role2")
    print p.create_user("User1")
    print p.create_user("User2")
    print p.create_user("User3")
    print p.create_permission("Perm1")
    print p.create_permission("Perm2")
    print p.create_permission("Perm3")
    print p.create_permission("Perm4")
    print 
    print p.give_role_to_user("Role1", "User1")
    print p.give_role_to_user("Role2", "User1")
    print p.give_role_to_user("Role2", "User2")
    print 
    print p.grant_permission_to_user("Perm1", "User3")
    print 
    print p.grant_permission_to_role("Perm3", "Role1")
    print p.grant_permission_to_role("Perm4", "Role1")
    print p.grant_permission_to_role("Perm2", "Role2")    
    print p.revoke_permission_to_user("Perm1", "User3")
