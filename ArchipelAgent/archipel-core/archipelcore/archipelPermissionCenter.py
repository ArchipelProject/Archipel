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

import sqlobject

from archipelcore.utils import log


class TNArchipelPermissionCenter:

    class TNArchipelUser (sqlobject.SQLObject):

        class sqlmeta:
            table = "TNArchipelUser"
            lazyUpdate = True
            cacheValues = False

        name = sqlobject.StringCol(alternateID=True)
        roles = sqlobject.RelatedJoin('TNArchipelRole')
        permissions = sqlobject.RelatedJoin('TNArchipelPermission')

    class TNArchipelRole (sqlobject.SQLObject):

        class sqlmeta:
            table = "TNArchipelRole"
            lazyUpdate = True
            cacheValues = False

        name = sqlobject.StringCol(alternateID=True)
        description = sqlobject.StringCol()
        users = sqlobject.RelatedJoin('TNArchipelUser')
        permissions = sqlobject.RelatedJoin('TNArchipelPermission')

    class TNArchipelPermission (sqlobject.SQLObject):

        class sqlmeta:
            table = "TNArchipelPermission"
            lazyUpdate = True
            cacheValues = False

        name = sqlobject.StringCol(alternateID=True)
        description = sqlobject.StringCol()
        defaultValue = sqlobject.IntCol()
        users = sqlobject.RelatedJoin('TNArchipelUser')
        roles = sqlobject.RelatedJoin('TNArchipelRole')

    def __init__(self, database_file, root_admin):
        self.root_admin = root_admin
        connection_string = 'sqlite://%s' % database_file
        self.connection = sqlobject.connectionForURI(connection_string)
        self.TNArchipelRole.createTable(ifNotExists=True, connection=self.connection)
        self.TNArchipelUser.createTable(ifNotExists=True, connection=self.connection)
        self.TNArchipelPermission.createTable(ifNotExists=True, connection=self.connection)

    ### Permission management

    def create_permission(self, name, description="", default_permission=False):
        """
        create a new permission
        @type name: string
        @param name: the name of the permission
        @type description: string
        @param description: the description of the permission
        @type default_permission: Boolean
        @param default_permission: the default value of permission if not set
        @rtype: Boolean
        @return: True in case of success
        """
        try:
            self.TNArchipelPermission(name=name, description=description, defaultValue=int(default_permission), connection=self.connection)
            return True
        except sqlobject.dberrors.DuplicateEntryError:
            return False

    def get_permission(self, name):
        """
        get the permission by name
        @type name: string
        @param name: the name of the permission
        @rtype: L{TNArchipelPermission}
        @return: the L{TNArchipelPermission} object or None
        """
        try:
            return self.TNArchipelPermission.byName(name, connection=self.connection)
        except sqlobject.main.SQLObjectNotFound:
            return None

    def delete_permission(self, name):
        """
        delete the permission by name
        @type name: string
        @param name: the name of the permission
        @rtype: Boolean
        @return: True in case of success
        """
        perm = self.get_permission(name)
        if perm:
            perm.destroySelf(connection=self.connection)
            return True
        else:
            return False

    def get_permissions(self):
        """
        return all permissions
        """
        return self.TNArchipelPermission.select(connection=self.connection)


    ### Users management

    def create_user(self, name):
        """
        create a new user
        @type name: string
        @param name: the name of the user
        @rtype: Boolean
        @return: True in case of success
        """
        try:
            trans = self.connection.transaction()
            self.TNArchipelUser(name=name, connection=self.connection)
            trans.commit(close=True)
            return True
        except sqlobject.dberrors.DuplicateEntryError:
            return False

    def get_user(self, name):
        """
        get the user by name
        @type name: string
        @param name: the name of the user
        @rtype: L{TNArchipelUser}
        @return: the L{TNArchipelUser} object or None
        """
        try:
            return self.TNArchipelUser.byName(name, connection=self.connection)
        except sqlobject.main.SQLObjectNotFound:
            return None

    def delete_user(self, name):
        """
        delete the user by name
        @type name: string
        @param name: the name of the user
        @rtype: Boolean
        @return: True in case of success
        """
        user = self.get_user(name)
        if user:
            trans = self.connection.transaction()
            user.destroySelf()
            trans.commit(close=True)
            return True
        else:
            return False

    def grant_permission_to_user(self, permission_name, user_name):
        """
        grant given permission to given user
        @type permission_name: string
        @param permission_name: the name of the permission
        @type user_name: string
        @param user_name: the name of the user
        @rtype: Boolean
        @return: True in case of success
        """
        perm = self.get_permission(permission_name)
        user = self.get_user(user_name)
        if not user:
            log.info("user %s doesn't exists. creating" % user_name)
            self.create_user(user_name)
            user = self.get_user(user_name)
            perm = self.get_permission(permission_name)
            self.TNArchipelUser.expired = True
            self.TNArchipelPermission.expired = True
        if perm in user.permissions:
            return True
        if perm and user:
            trans = self.connection.transaction()
            log.info("setting permission %s to user %s" % (permission_name, user_name))
            perm.addTNArchipelUser(user)
            trans.commit(close=True)
            return True
        else:
            return False

    def revoke_permission_to_user(self, permission_name, user_name):
        """
        revoke given permission to given user
        @type permission_name: string
        @param permission_name: the name of the permission
        @type user_name: string
        @param user_name: the name of the user
        @rtype: Boolean
        @return: True in case of success
        """
        perm = self.get_permission(permission_name)
        user = self.get_user(user_name)
        if not user:
            return True
        if not perm in user.permissions:
            return True
        if user and perm:
            trans = self.connection.transaction()
            user.removeTNArchipelPermission(perm)
            trans.commit(close=True)
            self.TNArchipelUser.expired = True
            self.TNArchipelPermission.expired = True
            return True
        else:
            return False

    def user_has_permission(self, user_name, permission_name):
        """
        check if user has permission
        @type user_name: string
        @param user_name: the name of the user
        @type permission_name: string
        @param permission_name: the name of the permission
        @rtype: Boolean
        @return: True in case of success
        """
        user = self.get_user(user_name)
        perm = self.get_permission(permission_name)
        if user and perm:
            return (user in perm.users)
        else:
            return False

    def user_has_role(self, user_name, role_name):
        """
        check if user has role
        @type user_name: string
        @param user_name: the name of the user
        @type role_name: string
        @param role_name: the name of the role
        @rtype: Boolean
        @return: True in case of success
        """
        role = self.get_role(role_name)
        user = self.get_user(user_name)
        if user and role:
            return (role in user.roles)
        else:
            return False

    def get_user_roles(self, user_name):
        """
        get roles of user
        @type user_name: string
        @param user_name: the name of the user
        @rtype: list of L{TNArchipelRole}
        @return: the list L{TNArchipelRole} of user or None
        """
        user = self.get_user(user_name)
        if user:
            return user.roles
        return None

    def get_user_permissions(self, user_name):
        """
        get permissions of user
        @type user_name: string
        @param user_name: the name of the user
        @rtype: list of L{TNArchipelPermission}
        @return: the list L{TNArchipelPermission} of user or None
        """
        user = self.get_user(user_name)
        if user:
            return user.permissions
        return None


    ### Roles management

    def create_role(self, name, description=""):
        """
        create a new role
        @type name: string
        @param name: the name of the role
        @type description: string
        @param description: the description of the role
        @rtype: Boolean
        @return: True in case of success
        """
        try:
            trans = self.connection.transaction()
            self.TNArchipelRole(name=name, description=description, connection=self.connection)
            trans.commit(close=True)
            return True
        except sqlobject.dberrors.DuplicateEntryError:
            return False

    def get_role(self, name):
        """
        get the role by name
        @type name: string
        @param name: the name of the role
        @rtype: L{TNArchipelRole}
        @return: the L{TNArchipelRole} or None
        """
        try:
            return self.TNArchipelRole.byName(name, connection=self.connection)
        except sqlobject.main.SQLObjectNotFound:
            return None

    def delete_role(self, name):
        """
        delete the role by name
        @type name: string
        @param name: the name of the role
        @rtype: Boolean
        @return: True in case of success
        """
        role = self.get_role(name)
        if role:
            trans = self.connection.transaction()
            role.destroySelf()
            trans.commit(close=True)
            return True
        else:
            return False

    def give_role_to_user(self, role_name, user_name):
        """
        give given role to given user
        @type role_name: string
        @param role_name: the name of the role
        @type user_name: string
        @param user_name: the name of the user
        @rtype: Boolean
        @return: True in case of success
        """
        user = self.get_user(user_name)
        role = self.get_role(role_name)
        if user and role:
            trans = self.connection.transaction()
            role.addTNArchipelUser(user)
            trans.commit(close=True)
            return True
        else:
            return False

    def retract_role_to_user(self, role_name, user_name):
        """
        retract given role from given user
        @type role_name: string
        @param role_name: the name of the role
        @type user_name: string
        @param user_name: the name of the user
        @rtype: Boolean
        @return: True in case of success
        """
        user = self.get_user(user_name)
        role = self.get_role(role_name)
        if user and role:
            trans = self.connection.transaction()
            role.removeTNArchipelUser(user)
            trans.commit(close=True)
            return True
        else:
            return False

    def role_has_user(self, role_name, user_name):
        """
        check if given role is given to given user
        @type role_name: string
        @param role_name: the name of the role
        @type user_name: string
        @param user_name: the name of the user
        @rtype: Boolean
        @return: True in case of success
        """
        role = self.get_role(role_name)
        user = self.get_user(user_name)
        if user and role:
            return (user in role.users)
        else:
            return False

    def get_role_users(self, role_name):
        """
        return all roles of given user
        @type role_name: string
        @param role_name: the name of the role
        @rtype: list of L{TNArchipelRole}
        @return: the list of L{TNArchipelRole}
        """
        role = self.get_role(role_name)
        return role.users

    def grant_permission_to_role(self, permission_name, role_name):
        """
        grant permission of given role
        @type permission_name: string
        @param permission_name: the name of the permission
        @type role_name: string
        @param role_name: the name of the role
        @rtype: Boolean
        @return: True in case of success
        """
        perm = self.get_permission(permission_name)
        role = self.get_role(role_name)
        if role and perm:
            trans = self.connection.transaction()
            perm.addTNArchipelRole(role)
            trans.commit(close=True)
            return True
        else:
            return False

    def revoke_permission_to_role(self, permission_name, role_name):
        """
        revoke permission from given role
        @type permission_name: string
        @param permission_name: the name of the permission
        @type role_name: string
        @param role_name: the name of the role
        @rtype: Boolean
        @return: True in case of success
        """
        perm = self.get_permission(permission_name)
        role = self.get_role(role_name)
        if role and perm:
            trans = self.connection.transaction()
            perm.addTNArchipelRole(role)
            trans.commit(close=True)
            return True
        else:
            return False

    def role_has_permission(self, role_name, permission_name):
        """
        check if role has permission
        @type role_name: string
        @param role_name: the name of the role
        @type permission_name: string
        @param permission_name: the name of the permission
        @rtype: Boolean
        @return: True in case of success
        """
        role = self.get_role(role_name)
        perm = self.get_permission(permission_name)
        if role and perm:
            return (role in perm.roles)
        else:
            return False


    ### User permissions verification

    def check_permission(self, user_name, permission_name):
        """
        check if given user has given permission
        @type user_name: string
        @param user_name: the name of the user
        @type permission_name: string
        @param permission_name: the name of the permission
        @rtype: Boolean
        @return: True in case of success
        """
        permObject = self.get_permission(permission_name)
        if user_name == self.root_admin:
            return True
        if self.user_has_permission(user_name, "all"):
            return True
        if not self.get_user(user_name):
            if permObject and permObject.defaultValue == 1:
                return True
            else:
                return False
        if not permObject:
            return False
        if self.user_has_permission(user_name, permission_name):
            return True
        for role in self.get_user_roles(user_name):
            if self.role_has_permission(role.name, permission_name):
                return True
        return False

    def check_permissions(self, user_name, permissions):
        """
        check if all permissions on array are granted
        @type user_name: string
        @param user_name: the name of the user
        @type permission_name: array of string
        @param permission_name: list permissions names
        @rtype: Boolean
        @return: True in case of success
        """
        for perm in permissions:
            if not self.check_permission(user_name, perm):
                return False
        return True

    def close_database(self):
        """
        close the db connection
        """
        self.
        self.connection.close()