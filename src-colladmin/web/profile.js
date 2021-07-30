$(document).ready(function(){
    init();
});
  
function init() {
  $("#context,#description,#collection,#notification").on("blur keyup", function(){
    statusCheck();
  });
  $("#owner,#storagenode").on("change", function(){
    statusCheck();
  });
  $("#notifications").on("change", function(){
    $("#notification").val($("#notifications").val());
    statusCheck();
  });
  $("#profile-form").on("submit", function(){
    doForm();
    $("#profile-button").attr("disabled", true);
    //stop submit propagation
    return false;
  });
  statusCheck();
  $("#tabs").tabs({disabled: [1,2,3,4]});
}

function getFormData() {
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
  return formdata;
}

function showResult(index, data) {
  if (typeof data == "object") {
    try {
      data = JSON.stringify(data);
    } catch(e) {

    }
  }
  $("#result-"+index).val(data);
  $("#down-"+index)
    .attr("href", "data:text/plain;charset=utf-8," + data);
}

function generateName(index, context) {
  if (index == 0) {
    return context + "_content";
  }
  if (index == 2) {
    return context + "_owner";
  }
  if (index == 3) {
    return context + "_service_level_agreement";
  }
  return context;
}

function doForm() {
 $.each(
    [
      "createProfile/profile",
      "createProfile/collection",
      "createProfile/owner",
      "createProfile/sla"
    ],
    function(index, path){
      var formdata = getFormData();
      $("#down-"+index).attr("download", generateName(index, formdata['context']));
      formdata['path'] = path;
      formdata['name'] = generateName(index, formdata['context'])
      if (index > 0) {
        delete formdata['notification'];
      }
      console.log(path + " " + index);
      $.ajax({
        dataType: "json",
        method: "POST",
        url: "{{COLLADMIN_ROOT}}",
        data: formdata,
        success: function(data) {
          if (data == null || data == "") {
            data = {message: "no data returned for " + path}
          }
          if ("ing:genericState" in data) {
            if ("ing:string" in data['ing:genericState']) {
              showResult(index, data['ing:genericState']['ing:string'].replaceAll("&#10;","\n"));            
            } else {
              showResult(index, data);
            }
          } else {
            showResult(index, data);
          }
          $("#tabs").tabs("enable", index + 1);
        },
        error: function( xhr, status ) {
          showResult(index, xhr.responseText);
          $("#tabs").tabs("enable", index + 1);
          //alert("An error has occurred.  Possibly a timeout.\n"+xhr.responseText)
        }
      });
    }
  )

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
  if (!$("#notification").val().match(/^((.+)@([^,@]+\.[^,@]+),)*(.+)@([^,@]+\.[^,@]+)$/)) {
    $("#notification").parents("p.proval").addClass("error");
  }
  $("#profile-button").attr("disabled", $(".collsec p.proval.error").length > 0);
}
  