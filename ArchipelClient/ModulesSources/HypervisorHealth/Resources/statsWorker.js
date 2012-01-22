importScripts("xparse.js");

self.onmessage = function(e) {
    var raw = e.data,
        memory = {},
        cpu = {},
        disks = [],
        load = {},
        uptime = {},
        libvirt = {},
        driver = {},
        uname = {},
        networks = {};

    node = Xparse(raw)
    elems = node.contents[0].contents;

    for (var j = 0; j < elems.length; j++)
    {
        var elem = elems[j]
        switch (elem.name)
        {
            case "uname":
                uname["machine"] = elem.attributes.machine;
                uname["kname"] = elem.attributes.kname;
                uname["os"] = elem.attributes.os;
                uname["krelease"] = elem.attributes.krelease;
                break;
            case "libvirt":
                libvirt["major"] = elem.attributes.major;
                libvirt["minor"] = elem.attributes.minor;
                libvirt["release"] = elem.attributes.release;
                break;
            case "driver":
                driver["major"] = elem.attributes.major;
                driver["minor"] = elem.attributes.minor;
                driver["release"] = elem.attributes.release;
                break;
            case "uptime":
                uptime["up"] = elem.attributes.up;
                break;
            case "memory":
                memory["total"] = elem.attributes.total
                memory["free"] = elem.attributes.free
                memory["used"] = elem.attributes.used
                memory["swapped"] = elem.attributes.swapped
                break;
            case "cpu":
                cpu["idle"] = 100 - parseFloat(elem.attributes.id);
                break;
            case "load":
                load["one"] = elem.attributes.one;
                load["five"] = elem.attributes.five;
                load["fifteen"] = elem.attributes.fifteen;
                break;
            case "disk":
                diskInfo = {"available": elem.attributes.available,
                            "used": elem.attributes.used,
                            "capacity": elem.attributes.capacity,
                            "partitions": []}
                for (var k = 0; k < elem.contents.length; k++)
                {
                    var partition = elem.contents[k];
                    diskInfo.partitions.push({    "capacity": partition.attributes.capacity,
                                    "mount": partition.attributes.mount,
                                    "used": partition.attributes.used,
                                    "available": partition.attributes.available});
                }
                disks.push(diskInfo);
                break;
            case "networks":
                for (var k = 0; k < elem.contents.length; k++)
                {
                    var net = elem.contents[k];
                    if (!networks[net.attributes.name])
                        networks[net.attributes.name] = [];
                    networks[net.attributes.name].push(parseFloat(net.attributes.delta))
                }
                break;
        }
    }

    self.postMessage({  "memory": memory,
                        "cpu": cpu,
                        "disks": disks,
                        "load": load,
                        "uptime": uptime,
                        "libvirt": libvirt,
                        "driver": driver,
                        "uname": uname,
                        "networks": networks,
                        "raw": raw});
}