$(document).ready(function(){
  init();
});

function init() {
  $("p.buttons").show();
  $("button.store-obj-node").on("click", function(){
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
  $.ajax({
    dataType: "json",
    method: "POST",
    url: "{{COLLADMIN_ROOT}}/lambda",
    data: params,
    success: function(data) {
      if ('message' in data) {
        alert(data.message);
      }
      if ('redirect_location' in data) {
        var msg = "Endpoint Params:";
        Object.keys(params).forEach(function(k){
          msg += "- " + k + ": " + params[k] + "\n";
        });
        alert(msg);
        window.location = data['redirect_location'];
      }
    },
    error: function( xhr, status ) {
      alert(xhr.responseText);
    }
  });
}
