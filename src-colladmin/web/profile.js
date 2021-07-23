$(document).ready(function(){
    init();
});
  
function init() {
  $("#context").on("blur keyup", function(){
    $("#name").val($("#context").val() + "_content");
    statusCheck();
  });
  $("#mint").on("click", function(){
    $("#collection").val("ark:/99999/collection");
    statusCheck();
  });

  $("#description,#collection,#notifications").on("blur keyup", function(){
    statusCheck();
  });
  $("#owner").on("change", function(){
    statusCheck();
  });
  statusCheck();
}

function statusCheck() {
  $(".collsec p.proval").removeClass("error");
  if ($("#context").val() == "") {
    $("#context").parents("p.proval").addClass("error");
  }
  if ($("#name").val() == "") {
    $("#name").parents("p.proval").addClass("error");
  }
  if ($("#description").val() == "") {
    $("#description").parents("p.proval").addClass("error");
  }
  if ($("#owner").val() == "") {
    $("#owner").parents("p.proval").addClass("error");
  }
  if ($("#collection").val() == "") {
    $("#collection").parents("p.proval").addClass("error");
  }
  if ($("#notifications").val() == "") {
    $("#notifications").parents("p.proval").addClass("error");
  }
  $("#profile-button").attr("disabled", $(".collsec p.proval.error").length > 0);
}
  