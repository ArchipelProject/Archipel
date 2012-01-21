importScripts("xparse.js");

self.onmessage = function(e) {
    var raw = e.data,
        memoryFree = [],
        memoryUsed = [],
        memorySwapped = 0,
        memoryTotal = 0,
        cpuFree = [],
        load1 = [],
        load5 = [],
        load15 = [],
        networks = {};

    node = Xparse(raw)
    stats = node.contents[0].contents;

    for (var i = 0; i < stats.length; i++)
    {
        var elems = stats[i].contents;
        for (var j = 0; j < elems.length; j++)
        {
            var elem = elems[j]
            switch (elem.name)
            {
                case "memory":
                    memoryFree.push(parseFloat(elem.attributes.free));
                    memoryUsed.push(parseFloat(elem.attributes.used));
                    memorySwapped = parseFloat(elem.attributes.swapped);
                    memoryTotal = parseFloat(elem.attributes.total);
                    break;
                case "cpu":
                    cpuFree.push(parseFloat(100 - elem.attributes.id))
                    break;

                case "load":
                    load1.push(elem.attributes.one)
                    load5.push(elem.attributes.five)
                    load15.push(elem.attributes.fifteen)
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
    }

    memoryFree.reverse();
    memoryUsed.reverse();
    cpuFree.reverse();
    load1.reverse();
    load5.reverse();
    load15.reverse();
    for (nic in networks)
        networks[nic].reverse()

    self.postMessage({  "memoryFree": memoryFree,
                        "memoryUsed": memoryUsed,
                        "memoryTotal": memoryTotal,
                        "memorySwapped": memorySwapped,
                        "cpuFree": cpuFree,
                        "loadOne": load1,
                        "loadFive": load5,
                        "loadFifteen": load15,
                        "networks": networks});
}