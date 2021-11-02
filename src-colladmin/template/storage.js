$(document).ready(function(){
  init();
});

function init() {
  $("p.buttons").show();
  $("button.storage-del-object-from-node").on("click", function(){
    var ark = $(this).attr("data-ark");
    var nodenum = $(this).attr("data-node-num");
    var nodename = $(this).attr("data-node-name");
    var node = nodenum + " " + nodename;
    var message = 'Are you certain you want to delete\n  --> ' + ark + '\nfrom the secondary storage node\n  --> ' + node +
      '?\n\nPlease explain the reason for this deletion.';
    params = {
      path: 'storage-del-object-from-node',
      ark: ark,
      nodenum: nodenum
    }
    showPrompt(message, params);
  });
  $("button.storage-force-audit-for-object").on("click", function(){
    var objid = $(this).attr("data-id");
    var nodeid = $(this).attr("data-node-id");
    params = {
      path: 'storage-force-audit-for-object',
      objid: objid,
      nodeid: nodeid
    }
    invoke(params, false);
  });
  $("button.storage-rerun-audit-for-object").on("click", function(){
    var objid = $(this).attr("data-id");
    var nodeid = $(this).attr("data-node-id");
    params = {
      path: 'storage-rerun-audit-for-object',
      objid: objid,
      nodeid: nodeid
    }
    invoke(params, false);
  });
  $("button.storage-force-replic-for-object").on("click", function(){
    var objid = $(this).attr("data-id");
    $(this).parents("tr").find("button").attr("disabled", true);
    params = {
      path: 'storage-force-replic-for-object',
      objid: objid
    }
    invoke(params, false);
  });
  $("button.storage-clear-audit-batch").on("click", function(){
    params = {
      path: 'storage-clear-audit-batch'
    }
    invoke(params, false);
  });
  $("button.storage-scan-node").on("click", function(){
    var nodenum = $(this).attr("data-node-num");
    var nodename = $(this).attr("data-node-name");
    params = {
      path: 'storage-scan-node',
      nodename: nodename,
      nodenum: nodenum
    }
    invoke(params, true);
  });
  $("button.storage-cancel-scan-node").on("click", function(){
    var nodenum = $(this).attr("data-node-num");
    var nodename = $(this).attr("data-node-name");
    params = {
      path: 'storage-cancel-scan-node',
      nodename: nodename,
      nodenum: nodenum
    }
    invoke(params, true);
  });
  $("button.storage-resume-scan-node").on("click", function(){
    var nodenum = $(this).attr("data-node-num");
    var nodename = $(this).attr("data-node-name");
    params = {
      path: 'storage-resume-scan-node',
      nodename: nodename,
      nodenum: nodenum
    }
    invoke(params, true);
  });
  $("button.storage-cancel-all-scans").on("click", function(){
    params = {
      path: 'storage-cancel-all-scans'
    }
    invoke(params, true);
  });
  $("button.storage-allow-all-scans").on("click", function(){
    params = {
      path: 'storage-allow-all-scans'
    }
    invoke(params, true);
  });

}

function showPrompt(message, params) {
  var reason = "";
  while(reason == "") {
    reason = window.prompt(message);
    if (reason == null) {
      return;
    }
  }
  params['reason'] = reason;
  invoke(params, false);
}

function invoke(params, showRes) {
  var msg = "Endpoint Params:";
  Object.keys(params).forEach(function(k){
    msg += "- " + k + ": " + params[k] + "\n";
  });
  alert(msg);
  $.ajax({
    dataType: "json",
    method: "POST",
    url: "{{COLLADMIN_ROOT}}/lambda",
    data: params,
    success: function(data) {
      if ('message' in data) {
        alert(data.message);
      } else if (showRes) {
        alert(JSON.stringify(data));
      }
      if ('redirect_location' in data) {
        window.location = data['redirect_location'];
      }
    },
    error: function( xhr, status ) {
      alert(xhr.responseText);
    }
  });
}