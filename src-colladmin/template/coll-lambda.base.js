var lambda_base = "/lambda"
var admintool_home = "{{ADMINTOOL_HOME}}"
var colladmin_home = "{{COLLADMIN_HOME}}"
var colladmin_root = "{{COLLADMIN_ROOT}}"

function buildtag(tr) {
        var t = tr.find("a:contains('build-info')").attr('href');
        setTimeout(
            function(){
                $.ajax({
                        dataType: "text",
                        method: "GET",
                        url: t,
                        success: function(data) {
                                if (data) {
                                        var t = data.split("\n")[0];
                                        tr.find("td.buildtag").text(t);
                                }
                                postLoad();
                        },
                        error: function( xhr, status ) {
                                tr.find("td.buildtag").text("Error");
                                postLoad();
                        }
                });
            }, 
            250
        );
 
}

function srvstart(tr) {
        var t = tr.find("a:contains('state')").attr('href');
        setTimeout(
            function(){
                $.ajax({
                        dataType: "json",
                        method: "GET",
                        url: t,
                        success: function(data) {
                                var t = "No date";
                                if ('repsvc:replicationServiceState' in data) {
                                        if ('repsvc:currentReportDate' in data['repsvc:replicationServiceState']) {
                                                t = data['repsvc:replicationServiceState']['repsvc:currentReportDate'];
                                        }
                                }
                                if ('fix:fixityServiceState' in data) {
                                        if ('fix:currentReportDate' in data['fix:fixityServiceState']) {
                                                t = data['fix:fixityServiceState']['fix:currentReportDate'];
                                        }
                                }
                                if ('invsv:invServiceState' in data) {
                                        if ('invsv:currentReportDate' in data['invsv:invServiceState']) {
                                                t = data['invsv:invServiceState']['invsv:currentReportDate'];
                                        }
                                }
                                tr.find("td.srvstart").text(t);
                                postLoad();
                        },
                        error: function( xhr, status ) {
                                tr.find("td.srvstart").text("Error");
                                postLoad();
                        }
                });
            }, 
            250
        );
}