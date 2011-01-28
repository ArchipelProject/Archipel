#!/usr/bin/python
# 
# install.py
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


import os, sys, getopt
import threading, time
import ConfigParser
import uuid




### tests / init / Utils

def ask(message, answers=None, default=None):
    question = " * " + message
    if answers and default:
        question += " ["
        for a in answers:
            a = a
            if default and a in (default): a = "\033[32m" + a + "\033[0m"
            question += a + "/"
        question = question[:-1]
        question += "]"
        
    if not answers and default:
        question += " [\033[32m" + default + "\033[0m]"
        
    question += " : "
    
    resp = raw_input(question)
    
    if default:
        if resp == "": resp = default;
    
    if answers and default:
        if not resp in answers and len(answers) > 0:
            resp = ask("\033[33mYou must select of the following answer\033[0m", answers, default);
    
    return resp


def ask_bool(message, default="y"):
    if ask(message, ["y", "n"], default) == "y":
        return True
    return False




### install server

def install_archipelserver():
    inst_conf               = "/etc/archipel/"
    inst_data               = "/var/lib/archipel/"
    inst_log_folder         = "/var/log/archipel/"
    inst_init               = "/etc/init.d/"
    inst_cert               = True
    vm_working_folders      = { "drives":   "/vm/drives", 
                                "iso":      "/vm/iso", 
                                "repo":     "/vm/repo",
                                "tmp":      "/vm/tmp",
                                "vmcasts":  "/vm/vmcasts"}
    
    shoud_inst_conf     = True
    shoud_inst_data     = True
    shoud_inst_log      = True
    shoud_inst_init     = True
    shoud_inst_cert     = True
    
    xmpp_server = ask("what is the adress of the XMPP server you would like to use ? ");
    
    if os.path.exists(inst_conf):
        shoud_inst_conf = not ask_bool("%s seems to already exists. Should I keep it as it is ? " % inst_conf)
        
    if os.path.exists(inst_data):
        shoud_inst_data = not ask_bool("%s seems to already exists. Should I keep it as it is ? " % inst_data)
    
    if os.path.exists(inst_log_folder):
        shoud_inst_log = not ask_bool("%s seems to already exists. Should I keep it as it is ? " % inst_log_folder)
    
    if os.path.exists("%s/archipel" % inst_init):
        shoud_inst_init = not ask_bool("%s/archipel seems to already exists. Should I keep it as it is ? " % inst_init)
    
    if os.path.exists("%s/vnc.pem" % inst_conf):
       shoud_inst_cert = not ask_bool("%s/vnc.pem seems to already exists. Should I keep it as it is ? " % inst_init)
    
    
    if shoud_inst_conf: inst_cert = ask_bool("Would you like to generate the VNC certificates ?")
    
    
    server_install_working_folders(vm_working_folders)
    if shoud_inst_data : server_install_initscript(inst_init)
    if shoud_inst_log : server_install_data_folder(inst_data)
    if shoud_inst_init : server_install_log_folder(inst_log_folder)
    if shoud_inst_conf : server_configure("./data/conf/archipel.conf", inst_data, inst_conf, vm_working_folders, inst_log_folder, xmpp_server)
    if shoud_inst_cert and inst_conf : server_install_vnc_certificate(inst_conf)
    
    print "\033[32m"
    print " Installation is now complete.\n"
    print "\033[0m"



def server_install_data_folder(inst_data):
    if not os.path.exists(inst_data):
        print " - creating folder %s" %  inst_data
        os.system("mkdir -p '%s'" % inst_data)
    os.system("cp -a ./data/avatars '%s'" % inst_data)
    os.system("cp -a ./data/names.txt '%s'" % inst_data)
       


def server_install_log_folder(folder):
    if not os.path.exists(folder):
        print " - creating log folder  %s" % folder
        os.system("mkdir -p '%s'" % folder)


def server_install_initscript(folder):
    if not os.path.exists(folder):
        print " - creating log folder  %s" % folder
        os.system("mkdir -p '%s'" % folder)
    os.system("cp -a ./data/init.d/archipel '%s'" % folder)


def server_install_working_folders(folders):
    for name, folder in folders.items():
        print " - creating working %s folder at %s" %  (name, folder)
        os.system("mkdir -p '%s'" % folder)

    

    


def server_install_vnc_certificate(inst_conf):
    print " - generating the certificates for VNC"
    print "\n\033[35m*******************************************************************************"
    os.system("openssl req -new -x509 -days 365 -nodes -out '%s/vnc.pem' -keyout '%s/vnc.pem'" % (inst_conf, inst_conf))
    print "*******************************************************************************\033[0m"


def server_configure(confpath, general_var_dir, general_etc_dir, vm_working_folders, log_folder, xmpp_server):
    os.system("cp %s %s.working" %  (confpath, confpath))
    conf = ConfigParser.ConfigParser()
    conf.readfp(open("%s.working" % confpath))
    configuration = [
                {"domain": "GLOBAL",                "key": "machine_ip",                                "name": "Hypervisor IP",                        "type": "text", "default": "auto"},
                {"domain": "GLOBAL",                "key": "libvirt_uri",                               "name": "Libvirt URI",                          "type": "text", "default": "qemu:///system"},
                {"domain": "GLOBAL",                "key": "xmpp_pubsub_server",                        "name": "PubSub Server",                        "type": "text", "default": "pubsub.%s" % xmpp_server},
                {"domain": "GLOBAL",                "key": "archipel_root_admin",                       "name": "Archipel admin account",               "type": "text", "default": "admin@%s" % xmpp_server},
                {"domain": "GLOBAL",                "key": "machine_avatar_directory",                  "name": "Avatar folder",                        "type": "text", "default": "%s/avatars" % general_var_dir},
                {"domain": "MODULES",               "key": "hypervisor_health",                         "name": "Use module hypervisor health",         "type": "bool", "default": "True"},
                {"domain": "MODULES",               "key": "hypervisor_network",                        "name": "Use module hypervisor network",        "type": "bool", "default": "True"},
                {"domain": "MODULES",               "key": "vm_media_management",                       "name": "Use module media management",          "type": "bool", "default": "True"},
                {"domain": "MODULES",               "key": "geolocalization",                           "name": "Use module geolocalization",           "type": "bool", "default": "True"},
                {"domain": "MODULES",               "key": "vmcasting",                                 "name": "Use module VMCasting",                 "type": "bool", "default": "True"},
                {"domain": "MODULES",               "key": "snapshoting",                               "name": "Use module snapshoting",               "type": "bool", "default": "True"},
                {"domain": "MODULES",               "key": "oom_killer",                                "name": "Use module OOM",                       "type": "bool", "default": "True"},
                {"domain": "MODULES",               "key": "actions_scheduler",                         "name": "Use module scheduler",                 "type": "bool", "default": "True"},
                {"domain": "MODULES",               "key": "xmppserver",                                "name": "Use module XMPPServer",                "type": "bool", "default": "True"},
                {"domain": "MODULES",               "key": "iphone_appnotification",                    "name": "Use module iPhone Notification",       "type": "bool", "default": "False"},
                {"domain": "HYPERVISOR",            "key": "hypervisor_xmpp_jid",                       "name": "Hypervisor XMPP JID",                  "type": "text", "default": "hypervisor@%s" % xmpp_server},
                {"domain": "HYPERVISOR",            "key": "hypervisor_xmpp_password",                  "name": "Hypervisor XMPP password",             "type": "text", "default": "password"},
                {"domain": "HYPERVISOR",            "key": "hypervisor_name",                           "name": "Hypervisor name",                      "type": "text", "default": "auto"},
                {"domain": "HYPERVISOR",            "key": "hypervisor_database_path",                  "name": "Hypervisor database path",             "type": "text", "default": "%s/hypervisor.sqlite3" % general_var_dir},
                {"domain": "HYPERVISOR",            "key": "hypervisor_permissions_database_path",      "name": "Hypervisor permissions database path", "type": "text", "default": "%s/hypervisor-permissions.sqlite3" % general_var_dir},
                {"domain": "HYPERVISOR",            "key": "name_generation_file",                      "name": "path for virtual machine names list",  "type": "text", "default": "%s/names.txt" % general_var_dir},
                {"domain": "VIRTUALMACHINE",        "key": "vm_base_path",                              "name": "Virtual machines base path",           "type": "text", "default": vm_working_folders["drives"]},
                {"domain": "VIRTUALMACHINE",        "key": "xmpp_password_size",                        "name": "Virtual machines XMPP password size",  "type": "text", "default": "32"},
                {"domain": "VIRTUALMACHINE",        "key": "vnc_certificate_file",                      "name": "Virtual machines VNC certificate",     "type": "text", "default": "%s/vnc.pem" % general_etc_dir},
                {"domain": "VIRTUALMACHINE",        "key": "vnc_only_ssl",                              "name": "Use only SSL connection for VNC",      "type": "bool", "default": "False"},
                {"domain": "LOGGING",               "key": "logging_level",                             "name": "Logging level",                        "type": "text", "default": "info"},
                {"domain": "LOGGING",               "key": "logging_file_path",                         "name": "Log file",                             "type": "text", "default": "%s/archipel.log" % log_folder},
                {"domain": "HEALTH",                "key": "health_database_path",                      "name": "Health database path",                 "type": "text", "default": "%s/health.sqlite3" % general_var_dir,                   "dep_module_key": "hypervisor_health"},
                {"domain": "HEALTH",                "key": "health_collection_interval",                "name": "Collection interval",                  "type": "text", "default": "5",                                                     "dep_module_key": "hypervisor_health"},
                {"domain": "HEALTH",                "key": "max_rows_before_purge",                     "name": "Max rows before purge",                "type": "text", "default": "50000",                                                 "dep_module_key": "hypervisor_health"},
                {"domain": "HEALTH",                "key": "max_cached_rows",                           "name": "Max cached rows",                      "type": "text", "default": "200",                                                   "dep_module_key": "hypervisor_health"},
                {"domain": "MEDIAS",                "key": "iso_base_path",                             "name": "Path of common ISO",                  "type": "text", "default": vm_working_folders["iso"],                                "dep_module_key": "vm_media_management"},
                {"domain": "GEOLOCALIZATION",       "key": "localization_mode",                         "name": "Geolocalization mode (manual/auto)",   "type": "text", "default": "auto",                                                  "dep_module_key": "geolocalization"},
                {"domain": "GEOLOCALIZATION",       "key": "localization_latitude",                     "name": "Latitude (manual mode)",               "type": "text", "default": "0.0",                                                   "dep_module_key": "geolocalization"},
                {"domain": "GEOLOCALIZATION",       "key": "localization_longitude",                    "name": "Longitude (manual mode)",              "type": "text", "default": "0.0",                                                   "dep_module_key": "geolocalization"},
                {"domain": "GEOLOCALIZATION",       "key": "localization_service_url",                  "name": "Service URL (auto mode)",              "type": "text", "default": "ipinfodb.com",                                          "dep_module_key": "geolocalization"},
                {"domain": "GEOLOCALIZATION",       "key": "localization_service_request",              "name": "Service request (auto mode)",          "type": "text", "default": "/ip_query.php",                                         "dep_module_key": "geolocalization"},
                {"domain": "GEOLOCALIZATION",       "key": "localization_service_method",               "name": "Service request method (auto mode)",   "type": "text", "default": "GET",                                                   "dep_module_key": "geolocalization"},
                {"domain": "GEOLOCALIZATION",       "key": "localization_service_response_root_node",   "name": "XML root node (auto mode)",            "type": "text", "default": "Response",                                              "dep_module_key": "geolocalization"},
                {"domain": "VMCASTING",             "key": "repository_path",                           "name": "Repo path",                            "type": "text", "default": vm_working_folders["repo"],                              "dep_module_key": "vmcasting"},
                {"domain": "VMCASTING",             "key": "temp_path",                                 "name": "Temp path",                            "type": "text", "default": vm_working_folders["tmp"],                               "dep_module_key": "vmcasting"},
                {"domain": "VMCASTING",             "key": "own_vmcast_name",                           "name": "Name",                                 "type": "text", "default": "Local VM Cast of $HOSTNAME",                            "dep_module_key": "vmcasting"},
                {"domain": "VMCASTING",             "key": "own_vmcast_description",                    "name": "Description",                          "type": "text", "default": "This is the vmcast feed of the hypervisor $HOSTNAME",   "dep_module_key": "vmcasting"},
                {"domain": "VMCASTING",             "key": "own_vmcast_uuid",                           "name": "UUID",                                 "type": "text", "default":  str(uuid.uuid1()),                                      "dep_module_key": "vmcasting"},
                {"domain": "VMCASTING",             "key": "own_vmcast_url",                            "name": "Public URL",                           "type": "text", "default":  "http://127.0.0.1/vmcasts/",                            "dep_module_key": "vmcasting"},
                {"domain": "VMCASTING",             "key": "own_vmcast_file_name",                      "name": "Index file",                           "type": "text", "default": "rss.xml",                                               "dep_module_key": "vmcasting"},
                {"domain": "VMCASTING",             "key": "own_vmcast_lang",                           "name": "Language",                             "type": "text", "default": "en-us",                                                 "dep_module_key": "vmcasting"},
                {"domain": "VMCASTING",             "key": "own_vmcast_path",                           "name": "Physical path",                        "type": "text", "default": vm_working_folders["vmcasts"],                           "dep_module_key": "vmcasting"},
                {"domain": "VMCASTING",             "key": "own_vmcast_refresh_interval",               "name": "Refresh interval",                     "type": "text", "default": "60",                                                    "dep_module_key": "vmcasting"},
                {"domain": "VMCASTING",             "key": "disks_extensions",                          "name": "Supported disks extensions",           "type": "text", "default": ".qcow2;.qcow;.img;.iso",                                "dep_module_key": "vmcasting"},
                {"domain": "VMCASTING",             "key": "vmcasting_database_path",                   "name": "Vmcasting database path",              "type": "text", "default": "%s/vmcasting.sqlite3" % general_var_dir,                "dep_module_key": "vmcasting"},
                {"domain": "IPHONENOTIFICATION",    "key": "credentials_key",                           "name": "PushApp Credentials",                  "type": "text", "default": "",                                                      "dep_module_key": "iphone_appnotification"},
                {"domain": "OOMKILLER",             "key": "database",                                  "name": "OOM database path",                    "type": "text", "default": "%s/oom.sqlite3" % general_var_dir,                      "dep_module_key": "oom_killer"},
                {"domain": "SCHEDULER",             "key": "database",                                  "name": "Scheduler database path",              "type": "text", "default": "%s/scheduler.sqlite3" % general_var_dir,                "dep_module_key": "actions_scheduler"},
                {"domain": "XMPPSERVER",            "key": "exec_path",                                 "name": "XMPP server control tool path",        "type": "text", "default": "/sbin/ejabberdctl",                                     "dep_module_key": "xmppserver"},
                {"domain": "XMPPSERVER",            "key": "exec_user",                                 "name": "XMPP server running user",             "type": "text", "default": "ejabberd",                                              "dep_module_key": "xmppserver"}]
    
    
    for token in configuration: conf.set(token["domain"], token["key"], token["default"])
    
    os.system("mkdir -p '%s'" % general_etc_dir)    
    configfile = open("%s/archipel.conf" % general_etc_dir, "wb")
    conf.write(configfile)
    configfile.close()
    os.system("chmod -R 700 '%s'" % general_etc_dir)
    os.system("chown root:root '%s'" % general_etc_dir)
    
    os.system("rm %s.working" % confpath)




### Main

def main():
    install_archipelserver()




if __name__ == "__main__":
    main()





