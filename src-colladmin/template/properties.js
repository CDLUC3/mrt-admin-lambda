$(document).ready(function(){
  init();
});

function init() {
$(".set_mnemonic").on("click", function(){
  do_action({
    path: "set_mnemonic",
    ark: $(this).attr("data")
  });
});
$(".set_coll_name").on("click", function(){
  do_action({
    path: "set_coll_name",
    ark: $(this).attr("data")
  });
});
$(".set_own_name").on("click", function(){
  do_action({
    path: "set_own_name",
    ark: $(this).attr("data")
  });
});
$(".set_sla_name").on("click", function(){
  do_action({
    path: "set_sla_name",
    ark: $(this).attr("data")
  });
});
$(".create_owner_record").on("click", function(){
  do_action({
    path: "create_owner_record",
    ark: $(this).attr("data"),
    id: $(this).attr("data-id")
  });
});
$(".create_coll_record").on("click", function(){
  do_action({
    path: "create_coll_record",
    ark: $(this).attr("data"),
    id: $(this).attr("data-id")
  });
});
$("p.buttons").show();
showCounts();
$(".bp_colladmin").show();
$(".bp_title").text($("h1").text()).show();
}

function do_action(formdata) {
$("input.button").attr("disabled", true);
$.ajax({
  dataType: "json",
  method: "POST",
  url: "{{COLLADMIN_ROOT}}/lambda",
  data: formdata,
  success: function(data) {
    if ('message' in data) {
      alert(data.message);
    }
    window.location.reload();
  },
  error: function( xhr, status ) {
    alert(xhr.responseText);
  }
});
}
