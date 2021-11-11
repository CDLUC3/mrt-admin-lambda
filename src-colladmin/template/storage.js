$(document).ready(function(){
  init();
});

function getMaintIdList() {
  var maintidlist = [];
  $("input.maintid").each(function(){
    maintidlist.push($(this).val());
  });
  return maintidlist.join(',');
}

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
    params = {
      path: 'storage-force-audit-for-object',
      objid: $(this).attr("data-id"),
      nodeid: $(this).attr("data-node-id")
    }
    invoke(params, false, false);
  });
  $("button.storage-rerun-audit-for-object").on("click", function(){
    params = {
      path: 'storage-rerun-audit-for-object',
      objid: $(this).attr("data-id"),
      nodeid: $(this).attr("data-node-id")
    }
    invoke(params, false, false);
  });
  $("button.storage-force-replic-for-object").on("click", function(){
    $(this).parents("tr").find("button").attr("disabled", true);
    params = {
      path: 'storage-force-replic-for-object',
      objid: $(this).attr("data-id")
    }
    invoke(params, false, false);
  });
  $("button.storage-clear-audit-batch").on("click", function(){
    params = {
      path: 'storage-clear-audit-batch'
    }
    invoke(params, false, false);
  });
  $("button.storage-scan-node").on("click", function(){
    $(this).attr("disabled", true);
    params = {
      path: 'storage-scan-node',
      nodenum: $(this).attr("data-node-num")
    }
    invoke(params, true, true);
  });
  $("button.storage-cancel-scan-node").on("click", function(){
    $(this).attr("disabled", true);
    params = {
      path: 'storage-cancel-scan-node',
      scanid: $(this).attr("data-scan-id")
    }
    invoke(params, true, true);
  });
  $("button.storage-resume-scan-node").on("click", function(){
    $(this).attr("disabled", true);
    params = {
      path: 'storage-resume-scan-node',
      scanid: $(this).attr("data-scan-id")
    }
    invoke(params, true, true);
  });
  $("button.storage-cancel-all-scans").on("click", function(){
    $(this).attr("disabled", true);
    params = {
      path: 'storage-cancel-all-scans'
    }
    invoke(params, true, false); 
  });
  $("button.storage-allow-all-scans").on("click", function(){
    $(this).attr("disabled", true);
    params = {
      path: 'storage-allow-all-scans'
    }
    invoke(params, true, false);
  });
  $("button.replication-state").on("click", function(){
    params = {
      path: 'replication-state'
    }
    invoke(params, true, false);
  });
  $("button.storage-delete-node-key").on("click", function(){
    $(this).attr("disabled", true);
    params = {
      path: 'storage-delete-node-key',
      maintid: $(this).attr("data-maint-id")
    }
    invoke(params, true, false);
  });
  $("button.storage-delete-node-page").on("click", function(){
    params = {
      path: 'storage-delete-node-page',
      maintidlist: getMaintIdList()
    }
    invoke(params, true, true);
  });
  $("button.storage-perform-delete-node-key").on("click", function(){
    $(this).attr("disabled", true);
    params = {
      path: 'storage-perform-delete-node-key',
      maintid: $(this).attr("data-maint-id")
    }
    invoke(params, true, true);
  });
  $("button.storage-perform-delete-node-batch").on("click", function(){
    $(this).attr("disabled", true);
    params = {
      path: 'storage-perform-delete-node-batch',
      nodenum: $(this).attr("data-node-num")
    }
    invoke(params, true, true);
  });
  $("button.storage-hold-node-key").on("click", function(){
    $(this).attr("disabled", true);
    params = {
      path: 'storage-hold-node-key',
      maintid: $(this).attr("data-maint-id")
    }
    invoke(params, true, false);
  });
  $("button.storage-hold-node-page").on("click", function(){
    params = {
      path: 'storage-hold-node-page',
      maintidlist: getMaintIdList()
    }
    invoke(params, true, true);
  });
  $("button.storage-review-node-key").on("click", function(){
    $(this).attr("disabled", true);
    params = {
      path: 'storage-review-node-key',
      maintid: $(this).attr("data-maint-id")
    }
    invoke(params, true, false);
  });
  $("button.storage-review-node-page").on("click", function(){
    params = {
      path: 'storage-review-node-page',
      maintidlist: getMaintIdList()
    }
    invoke(params, true, true);
  });

  if ($("button.storage-cancel-all-scans").is("*")) {
    invoke(
      {
        path: "replication-state",
      },
      false
    );
  }
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

function scanEnabled(b) {
  $("button.storage-cancel-all-scans").attr("disabled", !b);
  $("button.storage-scan-node").attr("disabled", !b);
  $("button.storage-cancel-scan-node").attr("disabled", !b);
  $("button.storage-resume-scan-node").attr("disabled", !b);
  $("button.storage-allow-all-scans").attr("disabled", b);
}


function invoke(params, showRes, reload) {
  $.ajax({
    dataType: "json",
    method: "POST",
    url: "{{COLLADMIN_ROOT}}/lambda",
    data: params,
    success: function(data) {
      if ('message' in data) {
        if (data.message == "Scan Allowed: true") {
          scanEnabled(true);
        } else if (data.message == "Scan Allowed: false") {
          scanEnabled(false);
        } else {
          alert(data.message);
        }
      } else if (showRes) {
        alert(JSON.stringify(data));
      }
      if ('redirect_location' in data) {
        window.location = data['redirect_location'];
      }
      if (reload) {
        window.location.reload();
      }
    },
    error: function( xhr, status ) {
      alert(xhr.responseText);
    }
  });
}