var lambda_base = "/lambda"
var admintool_home = "{{ADMINTOOL_HOME}}"
var colladmin_home = "{{COLLADMIN_HOME}}"
var colladmin_root = "{{COLLADMIN_ROOT}}"

function buildtag(tr) {
        var url = tr.find("a:contains('build-info')").attr('href');
        if (!url) {
                postLoad();
                return;
        }
        setTimeout(
            function(){
                $.ajax({
                        dataType: "text",
                        method: "GET",
                        url: url,
                        success: function(data) {
                                if (data) {
                                        var t = data.split("\n")[0];
                                        tr.find("td.buildtag").text(t.replace("Building tag ",""));
                                }
                                postLoad();
                        },
                        error: function( xhr, status ) {
                                tr.find("td.buildtag").text("Error");
                                postLoad();
                        }
                });
            }, 
            50
        );
 
}

function stateFetch(obj, key, def) {
        return (key in obj) ? obj[key] : def;
}

function srvstartPing(tr) {
        var url = tr.find("a:contains('ping')").attr('href');
        if (!url) {
               srvstart(tr);
               return;
        }
        setTimeout(
            function(){
                $.ajax({
                        dataType: "json",
                        method: "GET",
                        url: url,
                        success: function(data) {
                                var t = "No date";
                                t = stateFetch(stateFetch(data, 'ping:pingState', {}), 'ping:dateTime', t);
                                tr.find("td.srvstart").text(t);
                                srvstart(tr);
                        },
                        error: function( xhr, status ) {
                                tr.find("td.srvstart").text("Error");
                                srvstart(tr);
                        }
                });
            }, 
            50
        );
}

function srvstart(tr) {
        var url = tr.find("a:contains('state')").attr('href');
        if (!url) {
                postLoad();
                return;
        }
        setTimeout(
            function(){
                $.ajax({
                        dataType: "json",
                        method: "GET",
                        url: url,
                        success: function(data) {
                                var t = "No date";
                                if (tr.find("td.srvstart").text() == "") {
                                        t = stateFetch(stateFetch(data, 'repsvc:replicationServiceState', {}), 'repsvc:serviceStartTime', t);
                                        t = stateFetch(stateFetch(data, 'fix:fixityServiceState', {}), 'fix:serviceStartTime', t);
                                        t = stateFetch(stateFetch(data, 'invsv:invServiceState', {}), 'invsv:serviceStartTime', t);
                                        t = stateFetch(stateFetch(data, 'ing:ingestServiceState', {}), 'ing:serviceStartTime', t);
                                        t = stateFetch(data, 'start_time', t);
                                        tr.find("td.srvstart").text(t);
                                }

                                t = "OK";
                                t = stateFetch(stateFetch(data, 'repsvc:replicationServiceState', {}), 'repsvc:status', t);
                                t = stateFetch(stateFetch(data, 'fix:fixityServiceState', {}), 'fix:status', t);
                                t = stateFetch(stateFetch(data, 'invsv:invServiceState', {}), 'invsv:systemStatus', t);
                                tr.find("td.srvstate").text(t);        

                                t = "";
                                t = stateFetch(data, 'version', t);
                                if (t != '') {
                                        tr.find("td.buildtag").text(t);
                                }

                                postLoad();
                        },
                        error: function( xhr, status ) {
                                tr.find("td.srvstart").text("Error");
                                tr.find("td.srvstate").text("Error");
                                postLoad();
                        }
                });
            }, 
            50
        );
}