#!/usr/bin/python
import sys,os,xmpp,time,select,uuid,sqlite3,datetime,pexpect,random,shutil
sys.path.append("../ArchipelAgent/archipel-core/archipelcore")
import pubsub
ARCHIPEL_KEEPALIVE_PUBSUB="/archipel/centralagentkeepalive"

class XmppClient:

    def __init__(self,jabber,jid):
        self.jabber = jabber
        self.jid=jid
        self.roster=None

    def xmpp_connect(self):
        con=self.jabber.connect()
        if not con:
            sys.stderr.write('could not connect!\n')
            return False
        sys.stderr.write('connected with %s\n'%con)
        auth=self.jabber.auth(self.jid.getNode(),"professeur",resource="professeur")
        if not auth:
            sys.stderr.write('could not authenticate!\n')
            return False
        sys.stderr.write('authenticated using %s\n'%auth)
        self.jabber.RegisterHandler('presence', self.process_presence)
        self.jabber.sendInitPresence()
        return con

    def process_presence(self, conn, presence):
        """
        Process presence stanzas.
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the message
        @type presence: xmpp.Protocol.Iq
        @param presence: the received IQ
        """
        if presence.getFrom().getStripped() == self.jid.getStripped():
            raise xmpp.protocol.NodeProcessed
        if not presence.getType() in ("subscribe", "unsubscribe"):
            #sys.stdout.write("got presence %s\n"%presence)
            entity=presence.getFrom()
            presence_string=presence.getStatus()
            sys.stdout.write("got presence : %s has status %s\n"%(entity,presence_string))
            raise xmpp.protocol.NodeProcessed
        # update roster is necessary
        if not self.roster:
            self.roster = self.jabber.getRoster()
        typ = presence.getType()
        jid = presence.getFrom()
        if typ == "subscribe":
            self.authorize(jid)
        elif typ == "unsubscribe":
            self.unauthorize(jid)
        raise xmpp.protocol.NodeProcessed

    def authorize(self, jid):
        """
        Authorize the given JID.
        @type jid: xmpp.JID
        @param jid: this jid to remove
        """
        sys.stdout.write("%s is authorizing jid %s\n" % (str(self.jid), str(jid)))
        if not self.roster:
            self.roster = self.jabber.getRoster()
        self.roster.Authorize(jid)

    def unauthorize(self, jid):
        """
        Unauthorize the given JID.
        @type jid: xmpp.JID
        @param jid: this jid to remove
        """
        sys.stdout.write("%s is unauthorizing jid %s\n" % (str(self.jid), str(jid)))
        if not self.roster:
            self.roster = self.jabber.getRoster()
        self.roster.Unauthorize(jid)

class ArchipelTest:

    def open_hyp_consoles(self):
        for hyp in ["archipel-hyp-1","archipel-hyp-2","archipel-hyp-3"]:
            self.log("Connecting to console %s"%hyp)
            child=pexpect.spawn("virsh console %s"%hyp)
            logfile=open("%s/%s.console.log"%(self.results_dir,hyp),'w')
            child.logfile=logfile
            child.expect("Connected")
            child.sendline("")
            # long timeout so that we wait for hyp to be ready
            i=child.expect(["login:","\[root@"],timeout=300)
            if i==0:
                child.sendline("root")
                child.expect("\[root@")
            # enable logging of expect session
            self.consoles.append(child)
            self.log("Connected")
            #public_key_file=open("/root/.ssh/id_rsa.pub",'r')
            #public_key=public_key_file.readline()
            #public_key_file.close()
            ##allow ssh connections to hyp
            #child.sendline("echo %s > /root/.ssh/authorized_keys"%public_key)
            #child.expect("\[root@")
            #child.sendline("/etc/init.d/iptables stop")
            #child.expect("\[root@")


    def stop_archipel(self):
        self.log("Stopping archipel on hypervisors")
        for console in self.consoles[0:2]:
            console.sendline("/etc/init.d/archipel stop")
            console.expect("\[root@")
            #console.expect(["Archipel is not running","Stopping Archipel"])

    def start_archipel(self):
        self.log("Starting archipel on hypervisors")
        for console in self.consoles[0:2]:
            console.sendline("/etc/init.d/archipel start")
            console.expect("\[root@")
            #console.expect(["Starting Archipel","lready started"])

    def begin_suite(self,standalone_central_agent):
        
        self.xmppdomain="archipel-test.archipel.priv"
        self.own_jid=xmpp.protocol.JID("professeur@%s"%self.xmppdomain)
        #self.cl=xmpp.Client(self.own_jid.getDomain(),debug=['always', 'nodebuilder'])
        self.cl=xmpp.Client(self.own_jid.getDomain(),debug=[])
        self.xmppclient=XmppClient(self.cl,self.own_jid)
        if not self.xmppclient.xmpp_connect():
            sys.stderr.write("Could not connect to server, or password mismatch!\n")
            sys.exit(1)
        self.logfiles=[]
        shutil.rmtree("stateless/config")
        os.mkdir("stateless/config")
        shutil.copy("testfiles/archipel.conf","stateless/config/")
        shutil.rmtree("stateless/logs")
        self.start_archipel()
        self.consoles[2].sendline("/etc/init.d/archipel-central-agent restart")
        self.consoles[2].expect("\[root@")
        for logfile in ['archipel.archipel-hyp-1.archipel.priv.log', 'archipel.archipel-hyp-2.archipel.priv.log','archipel.archipel-hyp-3.archipel.priv.log']:
            logfile_open=False
            while not logfile_open:
                try:
                    self.logfiles.append(open("stateless/logs/%s"%logfile,'r'))
                    logfile_open=True
                except IOError:
                    self.log("Log file not yet created for %s. archipel not started yet ?"%logfile)
                    time.sleep(0.5)
        
    def begin_test(self,description):
        self.tests.append({"description":description,"success":True,"reasons":[]})
        self.log("Start test %s : %s."%(self.test_id+1,description))

    def fail_test(self,reason):
        self.tests[self.test_id]["success"]=False
        self.tests[self.test_id]["reasons"].append(reason)

    def end_test(self):
        for logfile in self.logfiles:
            lines=logfile.readlines()
            #self.log("Now checking logs: reading %s lines"%len(lines))
            error_in_log=False
            for line in lines:
                if "ERROR" in line or "CRITICAL" in line:
                    error_in_log=True
                    self.log("log error in %s:%s"%(logfile,line))
                    self.fail_test("Error in log")
        if self.tests[self.test_id]["success"]:
            result="PASS"
            self.log("Test %s passed."%(self.test_id+1))
        else:
            self.log("Test %s failed, reasons : %s"%((self.test_id+1),self.tests[self.test_id]["reasons"]))
            result="FAIL"
        self.test_id+=1

    def end_suite(self,suite_name):
        self.stop_archipel()
        self.xmppclient.jabber.disconnect()
        for logfile in self.logfiles:
            logfile.close()
        # copy the logs to the results dir
        results_subdir="%s/suite_%s/"%(self.results_dir,suite_name)
        os.mkdir(results_subdir)
        for log in os.listdir("stateless/logs"):
            shutil.copy("stateless/logs/%s"%log,results_subdir)


    def log(self,line):
        self.logfile.write("%s\n"%line)
        sys.stdout.write("%s\n"%line)

    def handle_central_keepalive_event(self,event):
        items = event.getTag("event").getTag("items").getTags("item")
        for item in items:
            central_announcement_event=item.getTag("event")
            event_type=central_announcement_event.getAttr("type")
            if event_type=="keepalive":
                self.central_agent_jid=xmpp.JID(central_announcement_event.getAttr("jid"))
                #self.log("We have a central keepalive event, central agent jid is %s"%self.central_agent_jid)
                self.log("We have a central keepalive event, central agent keepalive is %s" % event)


    def __init__(self):


        if not "results" in os.listdir("."):
            os.mkdir("results")
        self.results_dir="results/%s"%datetime.datetime.now().strftime("%Y-%m-%d-%H:%M:%S")
        os.mkdir(self.results_dir)
        self.logfile=open("%s/tests.log"%self.results_dir,'w')
        self.central_keepalive_received=False
        self.central_agent_jid=None


        self.consoles=[]
        self.tests=[]
        self.test_id=0
        # connect to archipel consoles
        self.open_hyp_consoles()
        use_local_codebase=True
        self.stop_archipel()
        # delete any previously existing vms in hypervisors
        for console in self.consoles:
            console.sendline("virsh list --name --all | xargs -n 1 virsh destroy")
            console.expect("\[root@")
            console.sendline("virsh list --name --all | xargs -n 1 virsh undefine")
            console.expect("\[root@")
        if use_local_codebase:
            for console in self.consoles[0:2]:
                console.sendline("/bin/bash -c 'mount | grep archipel_dev | wc -l'")
                i=console.expect(["0\n","1\n"])
                if i==0:
                    self.log("did not found mount of archipel working directory, mounting now")
                    console.sendline("mkdir /archipel_dev")
                    console.expect("\[root@")
                    console.sendline("mount -t cifs -o password=archipel //192.168.137.1/archipel /archipel_dev")
                    console.expect("\[root@")
                    console.sendline("cd /archipel_dev/ArchipelAgent")
                    console.expect("\[root@")
                    console.sendline("./buildAgent -d") # perform archipel developer installation
                    console.expect("\[root@")
                else:
                    self.log("archipel working directory already mounted on the hypervisor")
        # create central agent
        console=self.consoles[2]
        console.sendline("/bin/bash -c 'mount | grep archipel_dev | wc -l'")
        i=console.expect(["0\n","1\n"])
        if i==0:
            self.log("did not found mount of archipel working directory, mounting now")
            console.sendline("mkdir /archipel_dev")
            console.sendline("mount -t cifs -o password=password //192.168.122.1/archipel /archipel_dev")
            console.expect("\[root@")
        else:
            self.log("archipel working directory already mounted on the hypervisor")
        console.sendline("/etc/init.d/archipel stop")
        console.expect("\[root@")
        console.sendline("cd /archipel_dev/ArchipelAgent")
        console.expect("\[root@")
        self.log("Installing and running central agent")
        console.sendline("./buildCentralAgent -d") # perform archipel developer installation
        console.expect("\[root@")
        console.sendline("rm -f /etc/archipel/archipel-central-agent.conf")
        console.expect("\[root@")
        console.sendline("archipel-central-agent-initinstall -x archipel-test.archipel.priv")
        console.expect("\[root@")
        # configure logging to shared folder
        console.sendline("sed -i 's&logging_file_path.*=.*&logging_file_path=/stateless/logs/archipel.archipel-hyp-3.archipel.priv.log&' /etc/archipel/archipel-central-agent.conf")
        console.expect("\[root@")
        # configure database to be on shared storage
        console.sendline("sed -i 's&database *=.*&database = /vm/central_db.sqlite3&' /etc/archipel/archipel-central-agent.conf")
        console.expect("\[root@")

        self.run_tests(True)

    def wait_xmpp_pingable(self,jid):

        ping_successful= False
        max_nb_of_tries=120
        nb_of_tries=0
        while not ping_successful:
            nb_of_tries+=1
            time.sleep(1)
            iq = xmpp.Iq(typ="get", to=jid)   
            iq.addChild("ping",namespace="urn:xmpp:ping")
            resp=self.send_iq(iq)
            ping_successful = (resp and resp.getType()=="result")
            if ping_successful:
                self.log("XMPP Ping of %s successful"%str(jid))
                return True
            else:
                self.log("XMPP Ping of %s unsuccessful, retrying"%str(jid))
            if nb_of_tries==max_nb_of_tries:
                return False

    def wait_central_db_ok(self,command,expected_result):
        """
        We probe central db with one command until it returns the number of rows
        we are expecting.
        """
        max_nb_of_tries=120
        nb_of_tries=0
        while nb_of_tries<max_nb_of_tries:
            ret=[]
            try:
                rows = self.central_database.execute(command)
            except sqlite3.OperationalError:
                self.log("Database not present yet")
                nb_of_tries+=1
                time.sleep(1)
                continue
            nb_rows=0
            for row in rows:
                ret.append(row[0])
            if len(ret)==expected_result:
                return ret
            self.log("Waiting for central database to return %s rows to the command '%s'"%(expected_result,command))

            nb_of_tries+=1
            time.sleep(2)
        return ret

    def send_iq(self,iq_to_send):
        '''
        send iq. necessary to manually set the id otherwise some stanzas get lost
        for some reason
        '''
        xmpp.dispatcher.ID += 1
        iq_to_send.setID("professeur-%s-%d" % (random.random(), xmpp.dispatcher.ID))
        return self.xmppclient.jabber.SendAndWaitForResponse(iq_to_send)

    def wait_subscription(self,jid):
        i=0
        while i<30:
            roster=self.xmppclient.jabber.getRoster()
            is_subscribed=(roster.getSubscription(str(jid))=="both")
            if is_subscribed:
                break
            self.xmppclient.jabber.Process(1)
            i+=1

        return is_subscribed

    def get_central_pubsub_jid(self):
        self.central_agent_jid=None
        # we figure out who's central agent
        central_keepalive_pubsub = pubsub.TNPubSubNode(self.xmppclient.jabber, "pubsub.archipel-test.archipel.priv", ARCHIPEL_KEEPALIVE_PUBSUB)
        central_keepalive_pubsub.recover()
        central_keepalive_pubsub.subscribe(self.own_jid, self.handle_central_keepalive_event)
        i=0
        while (not self.central_agent_jid) and i<30:
            self.log("Waiting for central agent keepalive")
            self.xmppclient.jabber.Process(1)
            i+=1
        central_keepalive_pubsub.unsubscribe(self.own_jid, self.handle_central_keepalive_event)

        if self.central_agent_jid:
            return self.central_agent_jid
        else:
            return None

    def run_tests(self,standalone_central_agent):

        num_hyp=2
        self.begin_suite(standalone_central_agent)
        self.begin_test("Hypervisors come online")

        hyp_jid=[]
        for i in [0,1]:
            hyp_jid.append(xmpp.JID("archipel-hyp-%s.archipel.priv@%s/archipel-hyp-%s.archipel.priv"%(i+1,self.xmppdomain,i+1)))

        # we wait for ping success
        ping_successful=self.wait_xmpp_pingable(hyp_jid[i])
        if not ping_successful:
            self.fail_test("Hypervisor %s failed to come online"%hyp_jid[i])

        self.end_test()

        self.begin_test("Subscribe to hypervisor")
        roster=self.xmppclient.jabber.getRoster()
        for i in [0,1]:
            hyp_subscription_iq=xmpp.Iq(typ='set', queryNS="archipel:subscription", to=hyp_jid[i])
            hyp_subscription_iq.getTag("query").addChild(name="archipel", attrs={"action": "add","jid":str(self.own_jid)})
            resp=self.send_iq(hyp_subscription_iq)
            success = (resp and resp.getType()=="result")
            if not success:
                self.fail_test("Subscribe stanza returned error")
            if not self.wait_subscription(hyp_jid[i]):
                self.fail_test("We were expecting a subscription request from the hypervisor but it did not arrive")
        self.end_test() 

        self.begin_test("Hypervisors are in central database")
        central_agent=str(self.get_central_pubsub_jid())
        self.log("Central agent detected : %s"%central_agent)
        self.central_database = sqlite3.connect("vm/central_db.sqlite3", check_same_thread=False)
        self.central_database.row_factory = sqlite3.Row
            
        ret=self.wait_central_db_ok("select jid from hypervisors where status='Online'",num_hyp)
        self.log("Hypervisors in central db:  %s"%ret)
        if len(ret)!=num_hyp:
            self.fail_test("Did not find %s hypervisors in central db"%num_hyp)
        self.end_test()

        self.begin_test("Create undefined VMs")
        # we test undefined vms creation. for next test cases, we need 4 of them.
        for i in [0,1]:
            for j in range(4):
                vm_creation_iq=xmpp.Iq(typ='set', queryNS="archipel:hypervisor:control", to=hyp_jid[i])
                vm_creation_iq.getTag("query").addChild(name="archipel", attrs={"action": "alloc", "name":"archipel-vm-%s"%(4*i+j+1),"orgname":"","orgunit":"","locality":"","userid":"","categories":""})
                #vm_creation_iq.getTag("query").addChild(name="archipel", attrs={"action": "alloc", "name":"","orgname":"","orgunit":"","locality":"","userid":"","categories":""})
                resp=self.send_iq(vm_creation_iq)
                success = (resp and resp.getType()=="result")
                if success:
                    self.log("Vm creation %s success"%(4*i+1+j))
                else:
                    self.fail_test("Vm creation stanza returned error : %s"%resp)

        vms=[]
        j=0
        for i in [0,1]:
            ret=self.wait_central_db_ok("select uuid from vms where hypervisor='%s'"%str(hyp_jid[i]),4)
            if len(ret)!=4:
                self.fail_test("Did not find 4 vms with the correct hypervisor value (%s) in central db"%hyp_jid[i])
            else:
                self.log("Found vm %s which has hypervisor %s in central db"%(ret,hyp_jid[i]))
                for vm_uuid in ret:
                    vms.append({"uuid":vm_uuid})
                    vms[j]["jid"]=xmpp.JID("%s@%s"%(vm_uuid,self.xmppdomain))
                    vms[j]["jid"].setResource(hyp_jid[i].getNode())
                    j+=1
        time.sleep(1)
        self.end_test()

        self.begin_test("Delete undefined VM by sending stanza to hypervisor")
        # delete the first of 4 vms
        for i in [0,1]:
            vm_deletion_iq=xmpp.Iq(typ='set', queryNS="archipel:hypervisor:control", to=hyp_jid[i])
            vm_deletion_iq.getTag("query").addChild(name="archipel", attrs={"action": "free", "jid": vms[4*i]["jid"]})
            xmpp.dispatcher.ID += 1
            vm_deletion_iq.setID("archipel-test-%s-%d" % (i, xmpp.dispatcher.ID))
            resp=self.send_iq(vm_deletion_iq)
            success = (resp and resp.getType()=="result")
            if not success:
                self.fail_test("Vm deletion stanza returned error : %s"%resp)

        for i in [0,1]:
            ret=self.wait_central_db_ok("select uuid from vms where uuid='%s'"%vms[4*i]["uuid"],0)
            if len(ret)!=0:
                self.fail_test("Vm did not get unattached from hypervisor (%s) in central db"%hyp_jid[i])
            else:
                self.log("did not find vm in central db, as expected.")
        self.end_test()
        
        self.begin_test("Delete undefined VM by sending stanza to vm")
        # delete the second of 4 vms
        for i in [0,1]:
            vm_deletion_iq=xmpp.Iq(typ='set', queryNS="archipel:vm:control", to=vms[4*i+1]["jid"])
            vm_deletion_iq.getTag("query").addChild(name="archipel", attrs={"action": "free"})
            resp=self.send_iq(vm_deletion_iq)
            success = (resp and resp.getType()=="result")
            if not success:
                self.fail_test("Vm deletion stanza returned error : %s"%resp)

        for i in [0,1]:
            ret=self.wait_central_db_ok("select uuid from vms where uuid='%s'"%(vms[4*i+1]["uuid"]),0)
            if len(ret)!=0:
                self.fail_test("Vm did not get removed from central db")
            else:
                self.log("did not find vm in central db, as expected.")
        self.end_test()
        
        self.begin_test("Define vm")
        # define the 3rd and 4th vms of each hypervisor
        for i in [0,1]:
            for j in [2,3]:
                vm_definition="<domain type='kvm'><name>%s</name><uuid>%s</uuid><memory>125952</memory><currentMemory>125952</currentMemory><vcpu>1</vcpu><os><type machine='rhel6.3.0' arch='x86_64'>hvm</type><boot dev='hd'/></os><clock offset='utc'/><on_poweroff>destroy</on_poweroff><on_reboot>restart</on_reboot><on_crash>restart</on_crash><features><acpi/><apic/></features><memoryBacking/><blkiotune/><devices><graphics type='vnc' keymap='en-us' autoport='yes'/><input type='tablet' bus='usb'/></devices><memtune/></domain>"%("archipel-vm-%s"%(4*i+j+1),vms[4*i+j]["uuid"])
                vm_definition_xml = xmpp.simplexml.NodeBuilder(data=vm_definition).getDom()
                vm_definition_iq=xmpp.Iq(typ='set', queryNS="archipel:vm:definition", to=vms[4*i+j]["jid"])
                vm_definition_iq.getTag("query").addChild(name="archipel", attrs={"action": "define"})
                vm_definition_iq.getTag("query").getTag("archipel").addChild(node=vm_definition_xml)
                self.log("vm definition iq : %s"%vm_definition_iq)
                resp=self.send_iq(vm_definition_iq)
                success = (resp and resp.getType()=="result")
                if not success:
                    self.fail_test("Vm definition stanza returned error : %s"%resp)

        for i in [0,1]:
            for j in [2,3]:
                ret=self.wait_central_db_ok("select domain from vms where uuid='%s'"%(vms[4*i+j]["uuid"]),1)
                if len(ret)!=1:
                    self.fail_test("Vm not found in central db")
                else:
                    if "memory" in ret[0]:
                        self.log("vm definition was updated in central db")
                    else:
                        self.fail_test("Vm definition was not updated in central db")
        self.end_test()
        
        self.begin_test("Delete defined VM by sending stanza to hypervisor")
        # delete the third of 4 vms
        for i in [0,1]:
            vm_deletion_iq=xmpp.Iq(typ='set', queryNS="archipel:hypervisor:control", to=hyp_jid[i])
            vm_deletion_iq.getTag("query").addChild(name="archipel", attrs={"action": "free", "jid": vms[4*i+2]["jid"]})
            xmpp.dispatcher.ID += 1
            vm_deletion_iq.setID("archipel-test-%s-%d" % (i, xmpp.dispatcher.ID))
            resp=self.send_iq(vm_deletion_iq)
            success = (resp and resp.getType()=="result")
            if not success:
                self.fail_test("Vm deletion stanza returned error : %s"%resp)

        for i in [0,1]:
            ret=self.wait_central_db_ok("select uuid from vms where uuid='%s'"%vms[4*i+2]["uuid"],0)
            if len(ret)!=0:
                self.fail_test("Vm did not get unattached from hypervisor (%s) in central db"%hyp_jid[i])
            else:
                self.log("did not find vm in central db, as expected.")
        self.end_test()
        
        self.begin_test("Delete defined VM by sending stanza to vm")
        # delete the 4th of 4 vms
        for i in [0,1]:
            vm_deletion_iq=xmpp.Iq(typ='set', queryNS="archipel:vm:control", to=vms[4*i+3]["jid"])
            vm_deletion_iq.getTag("query").addChild(name="archipel", attrs={"action": "free"})
            resp=self.send_iq(vm_deletion_iq)
            success = (resp and resp.getType()=="result")
            if not success:
                self.fail_test("Vm deletion stanza returned error : %s"%resp)

        for i in [0,1]:
            ret=self.wait_central_db_ok("select uuid from vms where uuid='%s'"%(vms[4*i+3]["uuid"]),0)
            if len(ret)!=0:
                self.fail_test("Vm did not get removed from central db")
            else:
                self.log("did not find vm in central db, as expected.")
        self.end_test()
        
        self.begin_test("Create vms directly in parking") 
        # we could do it all from one hypervisor, but we do it from 2
        # because one will be central agent (commit locally) and the other will not
        # (so it will send the sqlite commands to the central agent for execution)
        vms=[]
        vm_template_file = open('testfiles/vm_template.xml')
        vm_template_content = vm_template_file.read()
        for i in [0,1]:
            create_parking_iq=xmpp.Iq(typ='set', queryNS="archipel:hypervisor:vmparking", to=hyp_jid[i])
            create_parking_iq.getTag("query").addChild(name="archipel", attrs={"action": "create_parked"})
            for j in range(3):
                vm_uuid=str(uuid.uuid4())
                vms.append({"uuid":vm_uuid})
                vm_xml = xmpp.simplexml.NodeBuilder(data=vm_template_content).getDom()
                vm_xml.addChild("name")
                vm_xml.getTag("name").setData("archipel-vm-%s"%(3*i+j+1))
                vm_xml.addChild("uuid")
                vm_xml.getTag("uuid").setData(vm_uuid)
                create_parking_iq.getTag("query").getTag("archipel").addChild("item",attrs={"uuid":vm_uuid}).addChild(node=vm_xml)
            resp=self.send_iq(create_parking_iq)
            success = (resp.getType()=="result")
            if not success:
                self.fail_test("Subscribe stanza returned error")
        # now check that the number of vms in central db is correct
        vm_template_file.close()




        ret=self.wait_central_db_ok("select uuid from vms",6)
        self.log("Vms in central db:  %s"%ret)

        if len(ret)!=6:
            self.fail_test("Did not find 6 vms in central db after 60 probes")
        time.sleep(1)
        self.end_test() 

        self.begin_test("Unpark one vm in each hypervisor")
        hyp_unpark_iqs=[]
        for i in [0,1]:
            hyp_unpark_iqs.append(xmpp.Iq(typ='set', queryNS="archipel:hypervisor:vmparking", to=hyp_jid[i]))
            hyp_unpark_iqs[i].getTag("query").addChild(name="archipel", attrs={"action": "unpark"})
            vm_uuid=vms[i]["uuid"]
            hyp_unpark_iqs[i].getTag("query").getTag("archipel").addChild("item",attrs={"identifier":vm_uuid})
            vms[i]["jid"]=xmpp.JID("%s@%s"%(vm_uuid,self.xmppdomain))
            vms[i]["jid"].setResource(hyp_jid[i].getNode())
            #self.log("Hyp unpark iq : %s"%hyp_unpark_iq)
            resp=self.send_iq(hyp_unpark_iqs[i])
            success = (resp.getType()=="result")
            if not success:
                self.fail_test("Unpark stanza returned error for hyp %s"%hyp_jid[i])

        for vm_props in [vms[0],vms[1]]:
            self.wait_xmpp_pingable(vm_props["jid"])

        for i in [0,1]:
            ret=self.wait_central_db_ok("select uuid from vms where hypervisor='%s'"%str(hyp_jid[i]),1)
            if len(ret)!=1:
                self.fail_test("Vm did not get the correct hypervisor value (%s) in central db"%hyp_jid[i])
            else:
                self.log("Found vm %s which has hypervisor %s in central db"%(ret,hyp_jid[i]))
        self.end_test()

        self.begin_test("Park vms using the hypervisor park command")
        for i in [0,1]:
            hyp_park_iq=xmpp.Iq(typ='set', queryNS="archipel:hypervisor:vmparking", to=hyp_jid[i])
            hyp_park_iq.getTag("query").addChild(name="archipel", attrs={"action": "park"})
            vm_uuid=vms[i]["uuid"]
            hyp_park_iq.getTag("query").getTag("archipel").addChild("item",attrs={"uuid":vm_uuid})
            vms[i]["jid"]=xmpp.JID("%s@%s"%(vm_uuid,self.xmppdomain))
            vms[i]["jid"].setResource(hyp_jid[i].getNode())
            #self.log("Hyp unpark iq : %s"%hyp_park_iq)
            resp=self.send_iq(hyp_park_iq)
            success = (resp and resp.getType()=="result")
            if not success:
                self.fail_test("Park stanza returned error for hyp %s"%hyp_jid[i])

        for i in [0,1]:
            ret=self.wait_central_db_ok("select uuid from vms where hypervisor='None' and uuid='%s'"%vms[i]["uuid"],1)
            if len(ret)!=1:
                self.fail_test("Vm did not get the correct hypervisor value (%s) in central db"%hyp_jid[i])
            else:
                self.log("Found vm %s which has hypervisor None in central db"%ret)
        time.sleep(3)
        #TODO wait for parked vm to be offline
        self.end_test()

        self.begin_test("Park vms using the vm park command")
        # first, unpark normally using iqs created 2 tests ago one more time
        for i in [0,1]:
            resp=self.send_iq(hyp_unpark_iqs[i])
            success = (resp.getType()=="result")
            if not success:
                self.fail_test("Unpark stanza returned error for hyp %s"%hyp_jid[i])
        for i in [0,1]:
            ret=self.wait_central_db_ok("select uuid from vms where hypervisor='%s'"%str(hyp_jid[i]),1)
            if len(ret)!=1:
                self.fail_test("Vm did not get the correct hypervisor value (%s) in central db"%hyp_jid[i])
            else:
                self.log("Found vm %s which has hypervisor %s in central db"%(ret,hyp_jid[i]))
        time.sleep(1)
        # now park
        for i in [0,1]:
            vm_uuid=vms[i]["uuid"]
            vms[i]["jid"]=xmpp.JID("%s@%s"%(vm_uuid,self.xmppdomain))
            vms[i]["jid"].setResource(hyp_jid[i].getNode())
            vm_park_iq=xmpp.Iq(typ='set', queryNS="archipel:vm:vmparking", to=vms[i]["jid"])
            vm_park_iq.getTag("query").addChild(name="archipel", attrs={"action": "park"})
            self.log("Vm park iq : %s"%vm_park_iq)
            resp=self.send_iq(vm_park_iq)
            success = (resp and resp.getType()=="result")
            if not success:
                self.fail_test("Park stanza returned error for hyp %s"%hyp_jid[i])

        for i in [0,1]:
            ret=self.wait_central_db_ok("select uuid from vms where hypervisor='None' and uuid='%s'"%vms[i]["uuid"],1)
            if len(ret)!=1:
                self.fail_test("Vm did not get the correct hypervisor value (%s) in central db"%hyp_jid[i])
            else:
                self.log("Found vm %s which has hypervisor None in central db"%ret)
        time.sleep(3)
        self.end_test()

        self.begin_test("Unpark and start multiple vms in both hypervisors at the same time")
	hyp_unpark_iq=[]
        for i in [0,1]:
            hyp_unpark_iq.append(xmpp.Iq(typ='set', queryNS="archipel:hypervisor:vmparking", to=hyp_jid[i]))
            hyp_unpark_iq[i].getTag("query").addChild(name="archipel", attrs={"action": "unpark"})
            for j in range(3):
                vm_uuid=vms[i*3+j]["uuid"]
                hyp_unpark_iq[i].getTag("query").getTag("archipel").addChild("item",attrs={"identifier":vm_uuid,"start":"True"})
                vms[i*3+j]["jid"]=xmpp.JID("%s@%s"%(vm_uuid,self.xmppdomain))
                vms[i*3+j]["jid"].setResource(hyp_jid[i].getNode())
            self.log("Hyp unpark iq : %s"%hyp_unpark_iq[i])
            resp=self.send_iq(hyp_unpark_iq[i])
            success = (resp and resp.getType()=="result")
            if not success:
                self.fail_test("Unpark stanza returned error for hyp %s"%hyp_jid[i])

        for vm_props in vms:
            self.wait_xmpp_pingable(vm_props["jid"])
        time.sleep(3)
        self.end_test()

        self.begin_test("List parked vms")
	vmparking_list_iq=xmpp.Iq(typ='set', queryNS="archipel:hypervisor:vmparking", to=hyp_jid[0])
        vmparking_list_iq.getTag("query").addChild(name="archipel", attrs={"action": "list"})
        self.log("Vmparking list iq : %s" % vmparking_list_iq)
	self.log("TODO: check that the number of parked vms is correct")
        resp=self.send_iq(vmparking_list_iq)
        success = (resp and resp.getType()=="result")
        if not success:
	    self.log("vmparking list iq returned error"%resp)
            self.fail_test("Vmparking list iq returned error")
	self.end_test()

        self.begin_test("Destroy and park multiple vms in both hypervisors at the same time")
	hyp_park_iq = []
        for i in [0,1]:
            hyp_park_iq.append(xmpp.Iq(typ='set', queryNS="archipel:hypervisor:vmparking", to=hyp_jid[i]))
            hyp_park_iq[i].getTag("query").addChild(name="archipel", attrs={"action": "park"})
            for j in range(3):
                vm_uuid=vms[i*3+j]["uuid"]
                hyp_park_iq[i].getTag("query").getTag("archipel").addChild("item",attrs={"uuid":vm_uuid})
            self.log("Hyp park iq : %s"%hyp_park_iq[i])
            resp=self.send_iq(hyp_park_iq[i])
            success = (resp and resp.getType()=="result")
            if not success:
                self.fail_test("Park stanza returned error for hyp %s"%hyp_jid[i])

        ret=self.wait_central_db_ok("select uuid from vms where hypervisor='None'",6)
        if len(ret)!=6:
            self.fail_test("Did not find 6 vms in parking, as expected.")
        self.end_test()

        for i in [0,1]:
            if i==0:
                self.begin_test("Graceful shutdown of the hypervisor. Checks status is 'off' in centraldb")
            else:
                self.begin_test("Ungraceful shutdown of the hypervisor. Checks status is 'unreachable' in centraldb")

            central_agent=str(self.get_central_pubsub_jid())
    
            self.log("Switching off hypervisor")
            hyp1_console=self.consoles[0]
            if i==0:
                hyp1_console.sendline("/etc/init.d/archipel stop")
                expected_status = "Off"
            else:
                # sending signal 9, does not execute exit proc = equivalent to unplugging
                hyp1_console.sendline("killall -9 runarchipel")
                expected_status = "Unreachable"
            hyp1_console.expect("OK")
            hyp1_console.expect("\[root@")
            ret=self.wait_central_db_ok("select jid from hypervisors where status='%s'" % expected_status,1)
            if len(ret)!=1:
                self.fail_test("Did not find %s hypervisors in central db with correct status"%1)
            ret=self.wait_central_db_ok("select jid from hypervisors where status='Online'",num_hyp-1)
            self.log("Hypervisors in central db with status Online:  %s"%ret)
            if len(ret)!=num_hyp-1:
                self.fail_test("Did not find %s hypervisors in central db with status online when 1 hypervisor is off"%(num_hyp-1))
            self.log("Now switching back on hyp1")
            hyp1_console.sendline("/etc/init.d/archipel restart")
            for i in [0,1]:
                # we wait for ping success
                ping_successful=self.wait_xmpp_pingable(hyp_jid[i])
                if not ping_successful:
                    self.fail_test("Hypervisor %s failed to come online"%hyp_jid[i])
            ret=self.wait_central_db_ok("select jid from hypervisors where status='Online'",num_hyp)
            self.log("Hypervisors in central db:  %s"%ret)
            if len(ret)!=num_hyp:
                self.fail_test("Did not find %s hypervisors in central db at the end"%num_hyp)
            # Check that central agent has not changed
            if central_agent!=self.get_central_pubsub_jid():
                self.fail_test("central agent has changed")
            else:
                self.log("central agent still the same")
            time.sleep(3)
            self.end_test()

	self.log("unparking and starting same 3 vms in hypervisor 1, iq : %s"% hyp_unpark_iq[0])
	resp=self.send_iq(hyp_unpark_iq[0])
	success = (resp and resp.getType()=="result")
	if not success:
	    self.fail_test("Park stanza returned error for hyp %s"%hyp_jid[0])

        for vm_props in [vms[0],vms[1],vms[2]]:
            self.wait_xmpp_pingable(vm_props["jid"])
        self.log("Stopping the 1st vm")
        vm_destroy_iq=xmpp.Iq(typ='set', queryNS="archipel:vm:control", to=vms[0]["jid"])
        vm_destroy_iq.getTag("query").addChild(name="archipel", attrs={"action": "destroy"})
        self.log("Stop vm iq : %s" % vm_destroy_iq)
        resp=self.send_iq(vm_destroy_iq)
        success = (resp and resp.getType()=="result")
        if not success:
	    self.log("destroy stana returned error %s"%resp)
            self.fail_test("Destroy stanza returned error")
    

        for i in [0,1]:
	    if i==0:
                self.begin_test("Restart hypervisor with vms, checks that vm xmpp entities are instanciated")
	    else:
		self.begin_test("When central agent is off, restart hypervisor, check that vms xmpp entities are instanciated")
                self.log("Switching off central agent")
                hyp3_console=self.consoles[2]
                hyp3_console.sendline("/etc/init.d/archipel-central-agent stop")
                hyp3_console.expect("OK")
                hyp3_console.expect("\[root@")
    
            self.log("Switching off hyp 1")	
            hyp1_console=self.consoles[0]
            hyp1_console.sendline("/etc/init.d/archipel stop")
            hyp1_console.expect("OK")
            hyp1_console.expect("\[root@")
    
	    self.log("Now switching back on")
            hyp1_console.sendline("/etc/init.d/archipel start")
            hyp1_console.expect("OK")
            hyp1_console.expect("\[root@")
            ping_successful=self.wait_xmpp_pingable(hyp_jid[0])
            if not ping_successful:
                self.fail_test("Hypervisor %s failed to come online"%hyp_jid[0])

            for vm_props in [vms[0],vms[1],vms[2]]:
	        vm_jid = vm_props["jid"]
                self.wait_xmpp_pingable(vm_jid)
    
            if i==1:
                self.log("Switching on central agent")
                hyp3_console=self.consoles[2]
                hyp3_console.sendline("/etc/init.d/archipel-central-agent start")
                hyp3_console.expect("OK")
                hyp3_console.expect("\[root@")
		self.get_central_pubsub_jid()

            self.end_test()

        self.begin_test("Hypervisor switches off and on and finds out one of its vms has been started somewhere else, deletes them locally")
        time.sleep(4)
        self.xmppclient.jabber.Process(3)
	
        self.log("Switching off hyp 1")	
        hyp1_console=self.consoles[0]
        hyp1_console.sendline("/etc/init.d/archipel stop")
        hyp1_console.expect("OK")
        hyp1_console.expect("\[root@")
        ret=self.wait_central_db_ok("select jid from hypervisors where status='Online'",num_hyp-1)
        self.log("Hypervisors in central db with status Online:  %s"%ret)
        if len(ret)!=num_hyp-1:
            self.fail_test("Did not find %s hypervisors in central db with status online when 1 hypervisor is off"%(num_hyp-1))

	self.log("Now unparking 2 of hyp1's vms on hyp2 while hyp1 is off")
        unpark_orphan_iq=xmpp.Iq(typ='set', queryNS="archipel:hypervisor:vmparking", to=hyp_jid[1])
        unpark_orphan_iq.getTag("query").addChild(name="archipel", attrs={"action": "unpark"})
        vm_uuid=vms[0]["uuid"]
        unpark_orphan_iq.getTag("query").getTag("archipel").addChild("item",attrs={"identifier":vms[0]["uuid"],"start":"True"})
        unpark_orphan_iq.getTag("query").getTag("archipel").addChild("item",attrs={"identifier":vms[1]["uuid"],"start":"True"})
        self.log("Unpark orphan vm iqs : %s" % unpark_orphan_iq)
        resp=self.send_iq(unpark_orphan_iq)
        success = (resp and resp.getType()=="result")
        if not success:
            self.fail_test("Unpark stanza returned error")

        for vm_props in [vms[0],vms[1]]:
	    vm_jid = vm_props["jid"]
            vm_jid.setResource(hyp_jid[1].getNode())
            self.wait_xmpp_pingable(vm_jid)

	self.log("Now switching back on")
        hyp1_console.sendline("/etc/init.d/archipel start")
        hyp1_console.expect("OK")
        hyp1_console.expect("\[root@")
        ping_successful=self.wait_xmpp_pingable(hyp_jid[0])
        if not ping_successful:
            self.fail_test("Hypervisor %s failed to come online"%hyp_jid[0])
        ret=self.wait_central_db_ok("select jid from hypervisors where status='Online'",num_hyp)
        self.log("Hypervisors in central db with status Online:  %s"%ret)
        if len(ret)!=num_hyp:
            self.fail_test("Did not find %s hypervisors in central db with status online when 1 hypervisor is off"%(num_hyp))
	self.log("TODO: check automatically that hyp 1 has Online(1) as status")
        #sleep_time=5
        #self.log("We sleep %s secs otherwise we have strange libvirt errors" % sleep_time)	
	#time.sleep(sleep_time)
        self.wait_xmpp_pingable(vms[2]["jid"])

	self.log("Putting all vms back in parking")
        park_orphan_iqs=xmpp.Iq(typ='set', queryNS="archipel:hypervisor:vmparking", to=hyp_jid[1])
        park_orphan_iqs.getTag("query").addChild(name="archipel", attrs={"action": "park"})
        park_orphan_iqs.getTag("query").getTag("archipel").addChild("item",attrs={"uuid":vms[0]["uuid"],"destroy":"True"})
        park_orphan_iqs.getTag("query").getTag("archipel").addChild("item",attrs={"uuid":vms[1]["uuid"],"destroy":"True"})
        self.log("Park orphan vm iq : %s" % park_orphan_iqs)
        resp=self.send_iq(park_orphan_iqs)
        success = (resp and resp.getType()=="result")
        if not success:
            self.fail_test("Park stanza returned error")
	self.end_test()

        self.begin_test("Live migration of offline hypervisor")
        self.log("Stopping the vm")
        vm_destroy_iq=xmpp.Iq(typ='set', queryNS="archipel:vm:control", to=vms[2]["jid"])
        vm_destroy_iq.getTag("query").addChild(name="archipel", attrs={"action": "destroy"})
        self.log("Stop vm iq : %s" % vm_destroy_iq)
        resp=self.send_iq(vm_destroy_iq)
        success = (resp and resp.getType()=="result")
        if not success:
	    self.log("destroy stana returned error %s"%resp)
            self.fail_test("Destroy stanza returned error")
#
	#time.sleep(1)
	#
	self.log("Migrating powered off vm")
        vm_migrate_iq=xmpp.Iq(typ='set', queryNS="archipel:vm:control", to=vms[2]["jid"])
	vm_migrate_iq.getTag("query").addChild(name="archipel", attrs={"action": "migrate", "hypervisorjid": hyp_jid[1]})
        self.log("Migrate vm iq : %s" % vm_migrate_iq)
        resp=self.send_iq(vm_migrate_iq)
        success = (resp and resp.getType()=="result")
        if not success:
	    self.log("Migrate stana returned error %s"%resp)
            self.fail_test("Migrate stanza returned error")
	time.sleep(1)

        ret=self.wait_central_db_ok("select uuid from vms where uuid='%s' and hypervisor='%s'" % (vms[2]["uuid"], hyp_jid[1]), 1)
        if len(ret)!=1:
            self.fail_test("Did not find correct hypervisor value in central db")


	self.end_test()

	self.begin_test("Test score computing iq")

	score_iq = xmpp.Iq(typ='get', queryNS="archipel:centralagent:platform", to=self.central_agent_jid)
	score_iq.getTag("query").addChild(name="archipel", attrs={"action": "request", "limit": "10"})
        self.log("Platform request iq : %s" % score_iq)
        resp=self.send_iq(score_iq)
        success = (resp and resp.getType()=="result")
        if not success:
            self.fail_test("Park stanza returned error")
	
	self.log("platform request reply: %s"%resp)
	self.end_test()
        
	self.begin_test("Xml update in parking, should pass")
	self.log("Now parking last remaining vm")
	park_other_iq = xmpp.Iq(typ='set', queryNS="archipel:hypervisor:vmparking", to=hyp_jid[1])
	park_other_iq.getTag("query").addChild(name="archipel", attrs={"action": "park"})
	park_other_iq.getTag("query").getTag("archipel").addChild("item",attrs={"uuid":vms[2]["uuid"]})
	self.log("Park other vm iq : %s" % park_other_iq)
	resp=self.send_iq(park_other_iq)

	vm_xml = self.wait_central_db_ok("select domain from vms where uuid='%s'" % vms[2]["uuid"], 1)
        vm_definition = xmpp.simplexml.NodeBuilder(data=vm_xml[0]).getDom()
	self.log("Old domain xml : %s" % vm_definition)
	self.log("Adding a nic")
	nic_xml = "<interface type='network'><mac address='AB:CD:00:00:01:01'/><source network='default'/><target dev='vnet0'/><model type='virtio'/></interface>"
        nic_definition = xmpp.simplexml.NodeBuilder(data=nic_xml).getDom()
	vm_definition.getTag("devices").addChild(node=nic_definition)
	self.log("New domain xml : %s" % vm_definition)
	update_xml_iq = xmpp.Iq(typ='set', queryNS="archipel:hypervisor:vmparking", to=hyp_jid[1])
	update_xml_iq.getTag("query").addChild(name="archipel", attrs={"action": "updatexml", "identifier":vms[2]["uuid"]})
	update_xml_iq.getTag("query").getTag("archipel").addChild(node=vm_definition)

	self.log("Update xml iq : %s" % update_xml_iq)
	resp=self.send_iq(update_xml_iq)
	time.sleep(5)
	vm_xml = self.wait_central_db_ok("select domain from vms where uuid='%s'" % vms[2]["uuid"], 1)
	self.log("New domain as retrieved from central db : %s" % vm_xml)
	if "AB:CD:00:00:01:01" in vm_xml[0]:
	    self.log("New nic found in new domain")
	else:
	    self.fail_test("New nic not found in new domain")


	self.end_test()

	self.begin_test("Faulty xml update in parking, should fail")
	# we remove the name xml tag, which should trigger an error
	vm_definition.delChild("name")
	self.log("New domain xml : %s" % vm_definition)
	update_xml_iq = xmpp.Iq(typ='set', queryNS="archipel:hypervisor:vmparking", to=hyp_jid[1])
	update_xml_iq.getTag("query").addChild(name="archipel", attrs={"action": "updatexml", "identifier":vms[2]["uuid"]})
	update_xml_iq.getTag("query").getTag("archipel").addChild(node=vm_definition)
	self.log("Update xml iq : %s" % update_xml_iq)
	resp=self.send_iq(update_xml_iq)
	self.end_test()

        self.begin_test("Delete all vms from parking")
        # we could do it all from one hypervisor, but we do it from 2
        # because one will be central agent (commit locally) and the other will not
        # (so it will send the sqlite commands to the central agent for execution)
        # FIXME: it works when sending all commands from one agent but not from 2 : we get xmpp in-band unregistration errors
        for i in [0]:
        #for i in [0,1]:
            delete_from_parking_iq=xmpp.Iq(typ='set', queryNS="archipel:hypervisor:vmparking", to=hyp_jid[i])
            delete_from_parking_iq.getTag("query").addChild(name="archipel", attrs={"action": "delete"})
            for j in range(6):
            #for j in range(3):
                vm_uuid=vms[3*i+j]["uuid"]
                delete_from_parking_iq.getTag("query").getTag("archipel").addChild("item",attrs={"identifier":vm_uuid})
            resp=self.send_iq(delete_from_parking_iq)
            success = (resp.getType()=="result")
            if not success:
                self.fail_test("Delete from parking stanza returned error")
        ret=self.wait_central_db_ok("select uuid from vms",0)
        self.log("Vms in central db:  %s"%ret)

        if len(ret)!=0:
            self.fail_test("Found vms in central db, expected none.")
        self.end_test()

        if standalone_central_agent:
            self.end_suite("standalone")
        else:
            self.end_suite("distributed")

        roster=self.xmppclient.jabber.getRoster()
        for rosteritem in roster.getItems():
            status= roster.getStatus(rosteritem)
            show= roster.getShow(rosteritem)
            resources= roster.getResources(rosteritem)
            self.log("Roster item : %s, status : %s, show : %s, resources : %s"%(rosteritem,status,show,resources))
        
        self.cl.disconnect()
        exit

if __name__ == '__main__':
    archipelTest=ArchipelTest()
