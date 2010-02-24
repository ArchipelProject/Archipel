#!/usr/bin/python
import xmpp
import sys
from trinitybasic import *

class XMPPVirtualMachineController(TrinityBase):
                
    def send_iq(self, iq):
        if sys.argv[2] == "trinity:vm:definition":
            f = open(sys.argv[4])
            data = f.read()
            f.close()
            iq.setQueryPayload(data)
        
        if  (sys.argv[2] == "trinity:hypervisor:control" and (sys.argv[3] == "alloc" or sys.argv[3] == "free")):
            iq.setQueryPayload([sys.argv[4]])
        
        print "sending iq : " + str(iq)    
        self.xmppclient.send(iq)


    def register_handler(self):
        self.xmppclient.RegisterHandler('iq', self.__process_iq)
    
    def __process_iq(self, conn, iq):
        print str(iq)
        

vm = XMPPVirtualMachineController("localcontroller@pulsar.local", "password")
#vm = XMPPVirtualMachineController("f07c652e-0a6c-11df-bf22-0016d4e7e91g", "10.68.142.23", "/virt-hyperviseur", "password")
vm.connect()
#vm.add_jid("f07c652e-0a6c-11df-bf22-0016d4e7e91f@10.68.142.23")
vm.send_iq(xmpp.Iq(typ=sys.argv[3],queryNS=sys.argv[2], to=sys.argv[1]))
vm.loop()