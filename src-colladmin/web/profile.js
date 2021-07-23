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
  $("#owner,#storagenode").on("change", function(){
    statusCheck();
  });
  $("#profile-form").on("submit", function(){
    var formdata = {}
    $.each($('#profile-form').serializeArray(), function(_, kv) {
      if (formdata.hasOwnProperty(kv.name)) {
        formdata[kv.name] = $.makeArray(formdata[kv.name]);
        formdata[kv.name].push(kv.value);
      }
      else {
        formdata[kv.name] = kv.value;
      }
    });
    $.ajax({
      dataType: "json",
      method: "POST",
      url: "{{COLLADMIN_ROOT}}",
      data: formdata,
      success: function(data) {
        if ("ing:genericState" in data) {
          if ("ing:string" in data['ing:genericState']) {
            $("#result").val(data['ing:genericState']['ing:string'].replaceAll("&#10;","\n"));            
          }
        }
      },
      error: function( xhr, status ) {
        alert("An error has occurred.  Possibly a timeout.\n"+xhr.responseText)
      }
    });
    return false;
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
  if ($("#storagenode").val() == "") {
    $("#storagenode").parents("p.proval").addClass("error");
  }
  if ($("#collection").val() == "") {
    $("#collection").parents("p.proval").addClass("error");
  }
  if ($("#notifications").val() == "") {
    $("#notifications").parents("p.proval").addClass("error");
  }
  $("#profile-button").attr("disabled", $(".collsec p.proval.error").length > 0);
}
  