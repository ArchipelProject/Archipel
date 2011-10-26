# -*- coding: utf-8 -*-
#
# archipelPermissionCenter.py
#
# Copyright (C) 2010 Antoine Mercadal <antoine.mercadal@inframonde.eu>
# Copyright, 2011 - Franck Villaume <franck.villaume@trivialdev.com>
# This file is part of ArchipelProject
# http://archipelproject.org
#
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

from sqlalchemy import Table, Column, Integer, String, ForeignKey, create_engine
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship, backref
from sqlalchemy.orm.exc import NoResultFound

Base = declarative_base()


users_have_permissions = Table('users_have_permissions', Base.metadata,
    Column('user', String, ForeignKey('users.name')),
    Column('permission', String, ForeignKey('permissions.name'))
)


class TNArchipelUser (Base):
    __tablename__ = 'users'

    name = Column(String, primary_key=True)
    permissions = relationship('TNArchipelPermission', secondary=users_have_permissions, backref=backref('users', lazy='dynamic'))

    def __init__(self, name):
        self.name = name

    def __repr__(self):
        return "<TNArchipelUser('%s')>" % (self.name)

class TNArchipelPermission (Base):
    __tablename__ = 'permissions'

    name = Column(String, primary_key=True)
    description = Column(String)
    defaultValue = Column(Integer)

    def __init__(self, name, description, default_value):
        self.name = name
        self.description = description
        self.defaultValue = default_value

    def __repr__(self):
        return "<TNArchipelPermission('%s', '%s', '%s')>" % (self.name, self.description, self.defaultValue)


class TNArchipelPermissionCenter:

    def __init__(self, database_file=None, root_admins={}):
        """
        Initialize the permission center.
        @type database_file: string
        @param database_file: the path to the db file
        @type root_admins: array
        @param root_admins: the root users JID
        """
        self.root_admins = root_admins
        self.database_file = database_file
        self.engine = None
        self.metadata = None
        self.session = None

    def start(self, database_file=None, root_admins={}):
        """
        Start the connection and be ready to use permissions
        """
        if database_file:
            self.database_file = database_file
        if len(root_admins) > 0:
            self.root_admins = root_admins

        connection_string = 'sqlite:///%s' % self.database_file
        self.engine = create_engine(connection_string)
        self.metadata = Base.metadata
        self.metadata.create_all(self.engine)
        self.session = sessionmaker(bind=self.engine)

    def create_session(self):
        """
        Create a new SQL session
        @rtype: Session
        @return: the new session
        """
        return self.session()

    def add_admin(self, key, new_account):
        """
        Add a new admin account in the list
        @type key: string
        @param key: unique id
        @type new_account: String
        @param new_account: the JID of the new admin account
        """
        if not new_account in self.root_admins.values():
            self.root_admins[key] = new_account

    def del_admin(self, key):
        """
        Remove the admin account associated to the key
        @type ket: string
        @param ket: the key
        """
        if key in self.root_admins:
            del self.root_admins[key]

    def admins(self):
        """
        Returns the list of admins accounts
        @rtype: List
        @return: list of admin accounts
        """
        return self.root_admins

    ### Permission management

    def create_permission(self, name, description="", default_permission=False, currentsession=None):
        """
        Create a new permission.
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
            if currentsession: session = currentsession
            else: session = self.create_session()
            p = TNArchipelPermission(name, description, default_permission)
            session.add(p)
            session.commit()
            if not currentsession: session.close()
            return True
        except IntegrityError:
            return False

    def get_permission(self, name, currentsession=None):
        """
        Get the permission by name.
        @type name: string
        @param name: the name of the permission
        @rtype: L{TNArchipelPermission}
        @return: the L{TNArchipelPermission} object or None
        """
        try:
            if currentsession: session = currentsession
            else: session = self.create_session()
            p = session.query(TNArchipelPermission).filter(TNArchipelPermission.name == name).one()
            if not currentsession: session.close()
            return p
        except NoResultFound:
            return None

    def delete_permission(self, name, currentsession=None):
        """
        Delete the permission by name.
        @type name: string
        @param name: the name of the permission
        @rtype: Boolean
        @return: True in case of success
        """
        try:
            if currentsession: session = currentsession
            else: session = self.create_session()
            p = self.get_permission(name, currentsession=session)
            session.delete(p)
            session.commit()
            if not currentsession: session.close()
            return True
        except NoResultFound:
            return False


    def get_permissions(self, currentsession=None):
        """
        Return all permissions.
        """
        if currentsession: session = currentsession
        else: session = self.create_session()
        permissions = session.query(TNArchipelPermission).all()
        if not currentsession: session.close()
        return permissions


    ### Users management

    def create_user(self, name, currentsession=None):
        """
        Create a new user.
        @type name: string
        @param name: the name of the user
        @rtype: Boolean
        @return: True in case of success
        """
        try:
            if currentsession: session = currentsession
            else: session = self.create_session()
            u = TNArchipelUser(name)
            session.add(u)
            session.commit()
            if not currentsession: session.close()
            return u
        except IntegrityError:
            return None

    def get_user(self, name, currentsession=None):
        """
        Get the user by name.
        @type name: string
        @param name: the name of the user
        @rtype: L{TNArchipelUser}
        @return: the L{TNArchipelUser} object or None
        """
        try:
            if currentsession: session = currentsession
            else: session = self.create_session()
            u = session.query(TNArchipelUser).filter(TNArchipelUser.name == name).one()
            if not currentsession: session.close()
            return u
        except NoResultFound:
            return None

    def delete_user(self, name, currentsession=None):
        """
        Delete the user by name.
        @type name: string
        @param name: the name of the user
        @rtype: Boolean
        @return: True in case of success
        """
        try:
            if currentsession: session = currentsession
            else: session = self.create_session()
            u = session.query(TNArchipelUser).filter(TNArchipelUser.name == name).one()
            session.delete(u)
            session.commit()
            if not currentsession: session.close()
            return True
        except NoResultFound:
            return False

    def grant_permission_to_user(self, permission_name, user_name, currentsession=None):
        """
        Grant given permission to given user.
        @type permission_name: string
        @param permission_name: the name of the permission
        @type user_name: string
        @param user_name: the name of the user
        @rtype: Boolean
        @return: True in case of success
        """
        if currentsession: session = currentsession
        else: session = self.create_session()
        p = self.get_permission(permission_name, currentsession=session)
        u = self.get_user(user_name, currentsession=session)
        if not u:
            u = self.create_user(user_name, currentsession=session)
        if not (p in u.permissions):
            u.permissions.append(p)
            session.commit()
        if not currentsession: session.close()
        return True

    def revoke_permission_to_user(self, permission_name, user_name, currentsession=None):
        """
        Revoke given permission to given user.
        @type permission_name: string
        @param permission_name: the name of the permission
        @type user_name: string
        @param user_name: the name of the user
        @rtype: Boolean
        @return: True in case of success
        """
        if currentsession: session = currentsession
        else: session = self.create_session()
        p = self.get_permission(permission_name, currentsession=session)
        u = self.get_user(user_name, currentsession=session)
        if not p or not u:
            return True
        if not p in (u.permissions):
            return True
        u.permissions.remove(p)
        session.commit()
        if not currentsession: session.close()
        return True

    def user_has_permission(self, user_name, permission_name, currentsession=None):
        """
        Check if user has permission.
        @type user_name: string
        @param user_name: the name of the user
        @type permission_name: string
        @param permission_name: the name of the permission
        @rtype: Boolean
        @return: True in case of success
        """
        if currentsession: session = currentsession
        else: session = self.create_session()
        p = self.get_permission(permission_name, currentsession=session)
        u = self.get_user(user_name, currentsession=session)
        if not p or not u:
            if not currentsession: session.close()
            return False
        ret = (p in u.permissions)
        if not currentsession: session.close()
        return ret

    def get_user_permissions(self, user_name, currentsession=None):
        """
        Get permissions of user.
        @type user_name: string
        @param user_name: the name of the user
        @rtype: list of L{TNArchipelPermission}
        @return: the list L{TNArchipelPermission} of user or None
        """
        if currentsession: session = currentsession
        else: session = self.create_session()
        u = self.get_user(user_name, currentsession=session)
        if not u:
            if not currentsession: session.close()
            return []
        ret = u.permissions
        if not currentsession: session.close()
        return ret


    ### User permissions verification

    def check_permission(self, user_name, permission_name):
        """
        Check if given user has given permission.
        @type user_name: string
        @param user_name: the name of the user
        @type permission_name: string
        @param permission_name: the name of the permission
        @rtype: Boolean
        @return: True in case of success
        """
        permObject = self.get_permission(permission_name)
        if user_name in self.root_admins.values():
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
        return False

    def check_permissions(self, user_name, permissions):
        """
        Check if all permissions on array are granted.
        @type user_name: string
        @param user_name: the name of the user
        @type permissions: array of string
        @param permissions: list permissions names
        @rtype: Boolean
        @return: True in case of success
        """
        for perm in permissions:
            if not self.check_permission(user_name, perm):
                return False
        return True

    def close_database(self):
        """
        Close the db connection.
        """
        self.session.close_all()
        self.engine.dispose()
        del self.session
        del self.engine