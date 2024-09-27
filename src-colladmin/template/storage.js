$(document).ready(function(){
  init();
});

function getMaintIdList() {
  var maintidlist = [];
  $(".maintid").each(function(){
    maintidlist.push($(this).text());
  });
  return maintidlist.join(',');
}

function store_alert(msg) {
  $("#alertmsg").text(msg).dialog({
    show: { effect: "blind", duration: 800 }
  });
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
    invoke(params, true, false);
  });
  $("button.storage-rerun-audit-for-object").on("click", function(){
    params = {
      path: 'storage-rerun-audit-for-object',
      objid: $(this).attr("data-id"),
      nodeid: $(this).attr("data-node-id")
    }
    invoke(params, true, false);
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
      path: 'storage-clear-audit-batch',
      hours: $(this).attr("hours")
    }
    invoke(params, true, true);
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
    var nodenum = $(this).attr("data-node-num");
    params = {
      path: 'storage-perform-delete-node-batch',
      nodenum: nodenum
    }
    if (showConfirm("Are you sure you want to remove ALL files marked for DELETE from node " + nodenum + "?", params)) {
      $("div.page-actions button").attr("disabled", true);
    }
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
  $("button.storage-delete-obj").on("click", function(){
    var reason = confirm("Please provide a reason for the delete?");
    store_alert("This function is not yet implemented.");
  });
  $("button.storage-review-csv").on("click", function(){
    $("div.page-actions button").attr("disabled", true);
    var nodenum = $(this).attr("data-node-num");
    params = {
      path: 'storage-review-csv',
      nodenum: nodenum
    }
    invoke(params, false, false);
    store_alert('CSV will be generated on S3 for Node ' + nodenum + ".\nThis may take a moment.\nA maximum of 1M records will be exported.");    
  });

  $("button.storage-apply-csv").on("click", function(){
    $("div.page-actions button").attr("disabled", true);
    var nodenum = $(this).attr("data-node-num");
    apply_csv_changes(nodenum);
  });

  $("button.storage-add-node-for-collection").on("click", function(){
    var nodenum = $(this).attr("data-node-num");
    var coll = $(this).attr("data-collection");
    params = {
      path: 'storage-add-node-for-collection',
      nodenum: nodenum,
      coll: coll
    }
    showConfirm("This will trigger a replication for all objects in the collection.\nDo you want to continue?", params);
  });

  $("button.storage-del-node-for-collection").on("click", function(){
    var nodenum = $(this).attr("data-node-num");
    var coll = $(this).attr("data-collection");
    params = {
      path: 'storage-del-node-for-collection',
      nodenum: nodenum,
      coll: coll
    }
    showConfirm("This remove the storage node from the collection configuration.  All objects from this collection will need to be removed from the storage node. Do you want to proceded?", params);
  });

  $("button.replic-delete-coll-batch-from-node").on("click", function(){
    var nodenum = $(this).attr("data-node-num");
    var coll = $(this).attr("data-collection");
    params = {
      path: 'replic-delete-coll-batch-from-node',
      nodenum: nodenum,
      coll: coll
    }
    showConfirm("Delete a batch of objects from the collection from this node.  This may need to run iteratively. Do you want to proceded?", params);
  });

  $("button.storage-get-manifest").on("click", function(){
    var ark = $(this).attr("data-ark");
    var nodenum = $(this).attr("data-node-num");
    params = {
      path: 'storage-get-manifest',
      ark: ark,
      nodenum: nodenum
    }
    const RE=/[\/:]+/g;
    fname = "manifest." + ark.replaceAll(RE, '_') + ".xml";
    invoke_xml(params, fname);
  });

  $("button.storage-get-manifest-yaml").on("click", function(){
    var ark = $(this).attr("data-ark");
    var nodenum = $(this).attr("data-node-num");
    params = {
      path: 'storage-get-manifest-yaml',
      ark: ark,
      nodenum: nodenum
    }
    const RE=/[\/:]+/g;
    fname = "manifest." + ark.replaceAll(RE, '_') + ".yml";
    invoke_text(params, fname);
  });

  $("button.storage-get-augmented-manifest").on("click", function(){
    var ark = $(this).attr("data-ark");
    var nodenum = $(this).attr("data-node-num");
    params = {
      path: 'storage-get-augmented-manifest',
      ark: ark,
      nodenum: nodenum
    }
    invoke(params, false, false);
  });

  $("button.storage-get-ingest-checkm").on("click", function(){
    var ark = $(this).attr("data-ark");
    var nodenum = $(this).attr("data-node-num");
    var ver = $(this).attr("data-version");
    params = {
      path: 'storage-get-ingest-checkm',
      ark: ark,
      ver: ver,
      nodenum: nodenum
    }
    const RE=/[\/:]+/g;
    fname = "ingest_manifest." + ark.replaceAll(RE, '_') + ".checkm";
    invoke_text(params, fname);
  });

  $("button.storage-update-manifest").on("click", function(){
    var nodenum = $(this).attr("data-node-num");
    var ark = $(this).attr("data-ark");
    params = {
      path: 'storage-update-manifest',
      nodenum: nodenum,
      ark: ark
    }
    showConfirm("This will trigger a replication for all objects in the collection.\nDo you want to continue?", params);
  });

  $("button.storage-clear-scan-entries").on("click", function(){
    var ark = $(this).attr("data-ark");
    var nodeid = $(this).attr("data-node-id");
    params = {
      path: 'storage-clear-scan-entries',
      ark: ark
    }
    showConfirm("This will delete scan results for this object in preparation for a future scan.\nDo you want to continue?", params);
  });

  $("button.storage-rebuild-inventory").on("click", function(){
    var ark = $(this).attr("data-ark");
    var nodenum = $(this).attr("data-node-num");
    params = {
      path: 'storage-rebuild-inventory',
      ark: ark,
      nodenum: nodenum
    }
    showConfirm("This will delete and rebuild inventory entries for the object.\nDo you want to continue?", params);
  });

  $("button.storage-retry-audit-status").on("click", function(){
    var status = $(this).attr("data-status");
    params = {
      path: 'storage-retry-audit-status',
      status: status
    }
    invoke(params, false, true);
  });

  $("button.lock-coll").on("click", function(){
    var coll = $(this).attr("data-collection");
    invoke(
      {
        path: "lock-coll",
        coll: coll
      },
      false,
      true
    );
  });

  $("button.unlock-coll").on("click", function(){
    var coll = $(this).attr("data-collection");
    invoke(
      {
        path: "unlock-coll",
        coll: coll
      },
      false,
      true
    );
  });

  $("button.lock-collzk").on("click", function(){
    var coll = $(this).attr("data-collection");
    invoke(
      {
        path: "lock-collzk",
        coll: coll
      },
      false,
      true
    );
  });

  $("button.unlock-collzk").on("click", function(){
    var coll = $(this).attr("data-collection");
    invoke(
      {
        path: "unlock-collzk",
        coll: coll
      },
      false,
      true
    );
  });

  if ($("button.storage-cancel-all-scans").is("*")) {
    invoke(
      {
        path: "replication-state",
      },
      false
    );
  }

  $(".bp_storeadmin").show();
  $(".bp_title").text($("h1").text()).show();
}

async function apply_changes(nodenum, changes) {
  var params = {
    path: 'apply-review-changes',
    nodenum: nodenum,
    changes: JSON.stringify(changes)
  }  
  // Use return to treat as a promise
  return $.ajax({
    dataType: "json",
    method: "POST",
    url: "{{COLLADMIN_ROOT}}/lambda",
    data: params
  });
}

async function apply_csv_changes(nodenum) {
  var [fileHandle] = await window.showOpenFilePicker();
  const file = await fileHandle.getFile();
  const contents = await file.text();
  var arr = contents.csvToArray();
  var total_changes = 0;
  for(var i=1, ib=1; ib < arr.length; i = i + 1000) {
    var changes = []
    for(ib = i; ib < i + 1000 && ib < arr.length; ib++) {
      var row = arr[ib];
      if (row == null) continue;
      if (row.length < 13) continue;
      var curnote = row[7]
      var nnum = row[8]
      var maintid = row[9]
      var curstatus = row[10]
      var newstatus = row[11]
      var newnote = row[12]
      if (nnum != nodenum) continue;
      if (newstatus == '' && newnote == '') continue;
      if (curstatus == newstatus && curnote == newnote) continue;
      changes.push([
        maintid, 
        newstatus == '' ? curstatus : newstatus,
        newnote == '' ? curnote : newnote
      ]);
    }
    if (changes.length > 0) {
      total_changes += changes.length;
      await apply_changes(nodenum, changes);
    }
  }
  store_alert(total_changes + " changes submitted.\n\nReload page to review changes.");
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

function showConfirm(message, params) {
  if (window.confirm(message)) {
    invoke(params, false);
    return true;
  }
  return false;
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
        } else if (showRes) {
          store_alert(data.message);
        }
      } else if ('log' in data) {
        console.log(data.log);
      } else if (showRes) {
        store_alert(JSON.stringify(data));
      }
      if ('redirect_location' in data) {
        window.location = data['redirect_location'];
      }
      if ('download_url' in data) {
        var a = $("<a/>")
          .text(data['label'])
          .attr("href", data['download_url'])
          .attr("target", "_blank");
        $("span.download-link").empty().append(a);
      }
      if (reload) {
        window.location.reload();
      }
    },
    error: function( xhr, status ) {
      store_alert(xhr.responseText);
    }
  });
}

function invoke_xml(params, download_name) {
  $.ajax({
    dataType: "text",
    method: "POST",
    url: "{{COLLADMIN_ROOT}}/lambda",
    data: params,
    success: function(data) {
      var parser = new DOMParser();
      var xmlDoc = parser.parseFromString(data, "text/xml");
      var root = xmlDoc.documentElement;
      if (root.tagName == "message") {
        store_alert(root.textContent);
        return;
      }
      var blob = new Blob([data]);
      let a = document.createElement('a');
      a.href = window.URL.createObjectURL(blob);
      a.download = download_name;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      window.URL.revokeObjectURL(a.href);
    },
    error: function( xhr, status ) {
      store_alert(xhr.responseText);
    }
  });
}

function invoke_text(params, download_name) {
  $.ajax({
    dataType: "text",
    method: "POST",
    url: "{{COLLADMIN_ROOT}}/lambda",
    data: params,
    success: function(data) {
      var blob = new Blob([data]);
      let a = document.createElement('a');
      a.href = window.URL.createObjectURL(blob);
      a.download = download_name;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      window.URL.revokeObjectURL(a.href);
    },
    error: function( xhr, status ) {
      store_alert(xhr.responseText);
    }
  });
}