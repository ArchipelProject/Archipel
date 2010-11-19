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
    
    
    def __init__(self, database):
        """
        Initialize the permission center
        """
        self.permissions = []
        self.users = []
        self.users_have_permissions = []
        
        self.database = sqlite3.connect(database, check_same_thread=False)
        self.database.execute("""
            CREATE TABLE IF NOT EXISTS "permissions" (
                "id" integer NOT NULL,
                "name" text NOT NULL,
                "default" integer NOT NULL,
                CONSTRAINT "u_name" UNIQUE (NAME)
                PRIMARY KEY("id")
            );""")
        
        self.database.execute("""
            CREATE TABLE IF NOT EXISTS"users" (
                "id" integer NOT NULL,
                "JID" text NOT NULL,
                PRIMARY KEY("id"),
                CONSTRAINT "u_jid" UNIQUE (JID)
            );""")
        
        self.database.execute("""
            CREATE TABLE IF NOT EXISTS "users_have_permissions" (
                "user_id" integer NOT NULL,
                "permission_id" integer NOT NULL,
                CONSTRAINT "fk_user_id" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
                CONSTRAINT "fk_permission_id" FOREIGN KEY ("permission_id") REFERENCES "permissions" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
                CONSTRAINT "unique" UNIQUE (user_id, permission_id)
            );""")
        
        self.database.commit()
        self.database.row_factory = sqlite3.Row
        self.cursor = self.database.cursor()
    
    
    ######################################################################################################
    ### Storage management
    ###################################################################################################### 
    
    def recover_permissions(self):
        """recover permission from database"""
        self.cursor.execute("SELECT * FROM users")
        self.users = self.cursor.fetchall()
        self.cursor.execute("SELECT * FROM permissions")
        self.permissions = self.cursor.fetchall()
        self.cursor.execute("SELECT * FROM users_have_permissions")
        self.users_have_permissions = self.cursor.fetchall()
    
    
    def save_permission(self):
        """save permission into database"""
        pass
    
    
    
    ######################################################################################################
    ### Database management
    ###################################################################################################### 

    def create_permission(self, name, default_permission=False, should_commit=True):
        """create a new permission"""
        try:
            self.cursor.execute("INSERT INTO permissions ('name', 'default') VALUES (?, ?);", (name, int(default_permission)))
            if should_commit: self.database.commit();
            self.cursor.execute("SELECT * FROM permissions WHERE id=last_insert_rowid()")
            row = self.cursor.fetchone()
            self.permissions.append(row)
            return True
        except sqlite3.IntegrityError:
            return False
    
    
    def delete_permission(self, name, should_commit=True):
        """delete a permission"""
        self.cursor.execute("SELECT * FROM permissions WHERE name=?;", (name,))
        row = self.cursor.fetchone()
        if row in self.permissions:
            self.cursor.execute("DELETE FROM permissions WHERE name=?;", (name,))
            if should_commit: self.database.commit();
            self.permissions.remove(row);
            return True
        return False
    
    
    def default_permission_from_name(self, name):
        """return the default value of permission"""
        for perm in self.permissions:
            if perm[1] == name: return bool(perm[2])
    
    
    def permission_id_from_name(self, name):
        """return the ID of the permission with given name"""
        for perm in self.permissions:
            if perm[1] == name: return perm[0]
    
    
    def contains_permission(self, name):
        """return True is permissions contains permission with given name"""
        if self.permission_id_from_name(name): return True
        else: return False
    
    
    def create_user(self, jid, should_commit=True):
        """create a new user"""
        try:
            self.cursor.execute("INSERT INTO users ('JID') VALUES (?);", (str(jid),))
            if should_commit: self.database.commit();
            self.cursor.execute("SELECT * FROM users WHERE id=last_insert_rowid()")
            row = self.cursor.fetchone()
            self.users.append(row)
            return True
        except sqlite3.IntegrityError:
            return False
    
    
    def delete_user(self, jid, should_commit=True):
        """delete a permission"""
        self.cursor.execute("SELECT * FROM users WHERE JID=?;", (str(jid),))
        row = self.cursor.fetchone()
        if row in self.users:
            self.cursor.execute("DELETE FROM users WHERE JID=?;", (str(jid),))
            if should_commit: self.database.commit();
            self.users.remove(row);
            return True
        return False
    
    
    def user_id_from_jid(self, jid):
        """return the ID of the permission with given name"""
        for user in self.users:
            if user[1] == str(jid): return user[0]
    
    
    def contains_user(self, jid):
        """return True is users contains user with given jid"""
        if self.user_id_from_jid(jid): return True
        else: return False
    
    
    def create_relation(self, user_id, permission_id, should_commit=True):
        """create a new relation"""
        try:
            self.cursor.execute("INSERT INTO users_have_permissions VALUES (?,?);", (user_id, permission_id))
            if should_commit: self.database.commit();
            self.cursor.execute("SELECT * FROM users_have_permissions WHERE user_id=? AND permission_id=?", (user_id, permission_id))
            row = self.cursor.fetchone()
            self.users_have_permissions.append(row)
            return True
        except sqlite3.IntegrityError:
            return False
    
    
    def delete_relation(self, user_id, permission_id, should_commit=True):
        """delete a relation"""
        self.cursor.execute("SELECT * FROM users_have_permissions WHERE user_id=? AND permission_id=?", (user_id, permission_id))
        row = self.cursor.fetchone()
        if row in self.users_have_permissions:
            self.cursor.execute("DELETE FROM users_have_permissions WHERE user_id=? AND permission_id=?", (user_id, permission_id))
            if should_commit: self.database.commit();
            self.users_have_permissions.remove(row);
            return True
        return False
    
    
    def contains_relation(self, user_id, permission_id):
        """return True is users contains user with given jid"""
        for rel in self.users_have_permissions:
            if rel[0] == user_id and rel[1] == permission_id: return True
        return False
    
    
    
    ######################################################################################################
    ### User permissions verification
    ###################################################################################################### 
    
    def check_permission(self, user, permission_name):
        """check if given user has given permission"""
        # TODO: be kind, be OK 
        return True;
        
        user_id = self.user_id_from_jid(user)
        perm_id = self.permission_id_from_name(permission_name)
        
        if self.contains_relation(user_id, perm_id):
            return True
        elif self.contains_permission(permission_name):
            return self.default_permission_from_name(permission_name)
        else:
            return False
    
    
    
    ######################################################################################################
    ### Permission management
    ###################################################################################################### 
    
    def add_permission(self, user, permission):
        """give to user a permission"""
        if not self.contains_user(user):
            self.create_user(user)
        if not self.contains_permission(permission):
            self.create_permission(permission, False)
        user_id = self.user_id_from_jid(user)
        perm_id = self.permission_id_from_name(permission)
        self.create_relation(user_id, perm_id)
    
    
    def add_permissions(self, user, permissions):
        """give user some permission"""
        for perm in permissions:
            self.add_permission(user, perm, should_commit=False)
        self.database.commit()
    
    
    def remove_permission(self, user, permission):
        """remove the given permission for given user"""
        if not self.contains_user(user) or not self.contains_permission(permission):
            return False
        user_id = self.user_id_from_jid(user)
        perm_id = self.permission_id_from_name(permission)
        return self.delete_relation(user_id, perm_id)
    
    
    def remove_permissions(self, user, permissions):
        """remove some permissions from user"""
        for perm in permissions:
            self.remove_permission(user, perm, should_commit=False)
        self.database.commit()
    


# if __name__ == "__main__":
#     import os, sys
#     f = sys.argv[1]
#     p1 = sys.argv[2]
#     p = TNArchipelPermissionCenter(f);
#     p.recover_permissions();
#     # print p.create_permission(p1, False)    
#     print p.users;
#     print p.permissions;
#     print p.users_have_permissions;
#     print p.remove_permission("titi@ducon", p1)
#     print p.check_permission("titi@ducon", p1)
    
    