#!/usr/bin/python -W ignore::DeprecationWarning

import trinity


hyp = trinity.TrinityHypervisor("localhypervisor@pulsar.local", "password")
hyp.connect()
hyp.loop()


# vm = trinity.TrinityVM("71D48B03-D5B8-47B3-87DC-F7870CDDD311@10.68.142.23", "password")
# vm.connect()
# # vm.add_jid("virt-hypervisor-a@10.68.142.23")
# # vm.remove_jid("virt-hypervisor-a@10.68.142.23")
# vm.loop()