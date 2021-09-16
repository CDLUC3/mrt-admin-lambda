$(document).ready(function(){
  init();
});

function init() {
  $("button.store-obj-node").on("click", function(){
    var ark = $(this).attr("data-ark");
    var node = $(this).attr("data-node");
    var message = 'Are you certain you want to delete\n  --> ' + ark + '\nfrom the secondary storage node\n  --> ' + node +
      '?\n\nPlease explain the reason for this deletion.';
    var loc = 'https://cdluc3.github.io/mrt-doc/diagrams/store-admin-del-node-keys';
    showPrompt(message, loc);
  });
}

function showPrompt(message, location) {
  var reason = "";
  while(reason == "") {
    reason = window.prompt(message);
    if (reason == null) {
      return;
    }
  }
  document.location = location;
}
