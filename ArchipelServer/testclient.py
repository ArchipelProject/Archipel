#!/usr/bin/python
import xmpp
import sys
from archipelEntity import *

class XMPPVirtualMachineController(TNArchipelEntity):
                
    def send_iq(self, iq):
        if sys.argv[2] == "archipel:vm:definition":
            f = open(sys.argv[4])
            data = f.read()
            f.close()
            iq.setQueryPayload(data)
        
        if  (sys.argv[2] == "archipel:hypervisor:control" and (sys.argv[3] == "alloc" or sys.argv[3] == "free")):
            iq.setQueryPayload([sys.argv[4]])
        
        if  (sys.argv[2] == "archipel:hypervisor:network" and (sys.argv[3] == "define")):
            f = open(sys.argv[4])
            data = f.read()
            f.close()
            iq.setQueryPayload(data)
        
        if  (sys.argv[2] == "archipel:hypervisor:network" and (sys.argv[3] == "undefine" or sys.argv[3] == "create" or sys.argv[3] == "destroy")):
            iq.setQueryPayload([sys.argv[4]])
        
        self.xmppclient.send(iq)


    def register_handler(self):
        self.xmppclient.RegisterHandler('iq', self.__process_iq)
    
    def __process_iq(self, conn, iq):
        print str(iq)
        

iq = xmpp.Iq(typ=sys.argv[2], to=sys.argv[1])
iq.addChild(name="query", attrs={"type": sys.argv[3]})
iq.getTag("query").addChild(name="target", payload="vnet1")
# iq.getTag("query").addChild(name="target", payload="vnet0")

vm = XMPPVirtualMachineController("controller@virt-hyperviseur", "password", None)
vm.register_actions_to_perform_on_auth("send_iq", iq)
vm.connect()
