#
# archipelHookableEntity.py
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


class TNHookableEntity (object):
    """
    this class make a TNArchipelEntity hooking capable
    """

    def __init__(self, log):
        """
        initialize the TNHookableEntity
        @type log: TNArchipelLog
        @param log: the logger of the entity
        """
        self.hooks  = {}
        self.log    = log


    ### Hooks management

    def create_hook(self, hookname):
        """
        create a new hook
        @type hookname: string
        @param hookname: the name of the new hook
        """
        self.hooks[hookname] = []
        self.log.info("HOOK: creating hook with name %s" % hookname)
        return True

    def remove_hook(self, hookname):
        """
        remove an existing hook. All registered method in the hook
        will be removed
        @type hookname: string
        @param hookname: the name of the hook to remove
        @rtype: boolean
        @return: True in case of success
        """
        if hookname in self.hooks:
            for hook in self.hooks[hookname]:
                self.hooks[hookname].remove(hook)
            del self.hooks[hookname]
            self.log.info("HOOK: removing hook with name %s" % hookname)
            return True
        return False

    def register_hook(self, hookname, method, user_info=None, oneshot=False):
        """
        register a method that will be triggered by a hook. The methood must use
        the following prototype: method(origin, user_info, arguments)
        @type hookname: string
        @param hookname: the name of the hook
        @type method: function
        @param method: the method to register with the hook.
        @type user_info: object
        @param user_info: user info you want to pass to the method when it'll be peformed
        @type oneshot: boolean
        @param oneshot: if True, the method will be unregistered after first performing
        """
        # if the hook is not existing, we create it
        if not hookname in self.hooks:
            self.create_hook(hookname)
        self.hooks[hookname].append({"method": method, "oneshot": oneshot, "user_info": user_info})
        self.log.info("HOOK: registering hook method %s for hook name %s (oneshot: %s)" % (method.__name__, hookname, str(oneshot)))

    def unregister_hook(self, hookname, m):
        """
        unregister a method from a hook.
        @type hookname: string
        @param hookname: the name of the hook
        @type method: function
        @param method: the method to unregister from the hook
        @rtype: boolean
        @return: True in case of success
        """
        if hookname in self.hooks:
            for hook in self.hooks[hookname]:
                if hook["method"] == m:
                    self.hooks[hookname].remove(hook)
                    break
            self.log.info("HOOK: unregistering hook method %s for hook name %s" % (m.__name__, hookname))
            return True
        return False

    def perform_hooks(self, hookname, arguments=None):
        """
        perform all registered methods for the given hook
        @type hookname: string
        @param hookname: the name of the hook
        @type arguments: object
        @param arguments: random object that will be given to the registered methods as "argument" kargs
        """
        self.log.info("HOOK: going to run methods for hook %s" % hookname)
        for info in self.hooks[hookname]:
            m           = info["method"]
            oneshot     = info["oneshot"]
            user_info   = info["user_info"]
            try:
                self.log.info("HOOK: performing method %s registered in hook with name %s" % (m.__name__, hookname))
                m(self, user_info, arguments)
                if oneshot:
                    self.log.info("HOOK: this hook was oneshot. removing it")
                    self.unregister_hook(hookname, m)
            except Exception as ex:
                self.log.error("HOOK: error during performing method %s for hookname %s: %s" % (m.__name__, hookname, str(ex)))


