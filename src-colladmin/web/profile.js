function get_artifact() {
  return $("input[name=artifact]:checked").val();
}

function get_manifest() {
  return `#%checkm_0.7
#%profile | http://uc3.cdlib.org/registry/ingest/manifest/mrt-single-file-batch-manifest
#%columns | nfo:fileURL | nfo:hashAlgorithm | nfo:hashValue | nfo:fileSize | nfo:fileLastModified | nfo:fileName | mrt:primaryIdentifier | mrt:localIdentifier | mrt:creator | mrt:title | mrt:date
https://merritt-aws-stg.cdlib.org/README | | | | | | | | | ARTIFACTDESC
#%EOF`.replace('ARTIFACTDESC', $("#description").val());
}

function get_curl(artifact_name) {
  var artifact_name = $("#artifact-name").val();
  return `curl -v \\
-F "file=@/tdr/ingest/admin-submit/ARTIFACTNAME.checkm" \\
-F "type=single-file-batch-manifest" \\
-F "submitter=merritt-test" \\
-F "responseForm=xml" \\
-F "profile=ARTIFACTPATH" \\
http://ingest:8080/ingest/poster/update`
  .replaceAll('ARTIFACTPATH', get_path(get_artifact(), artifact_name))
  .replaceAll('ARTIFACTNAME', artifact_name);
}

$(document).ready(function(){
    init();
});
  
function init() {
  $("#context,#description,#notification").on("blur keyup", function(){
    statusCheck();
  });
  $("#owner,#owner-admin,#storagenode,input[name=artifact],#collection-sla").on("change", function(){
    statusCheck();
  });
  $("#collection").on("change", function(){
    $("#description").val($("#collection option:selected").text())
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
  $("#tabs").tabs({disabled: [1,2]});
  $("#intabs").tabs({});
  //default to object owned by Merritt
  $("#owner-admin").val("{{ADMIN_OWNER}}");
  //default to most commonly used storage node
  $("#nodes options[1]").attr("selected", true);
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

function set_download(selector, filename, filepath, data) {
  $(selector)
    .attr("download", filename)
    .attr("href", "data:text/plain;charset=utf-8," + data)
    .find(".downname").text(filepath);
}

function makefilecmd(filename, data) {
  return 'cat > ' + filename + ' << EOF' + "\n" + data + "\nEOF\n\n";
}

function get_path(artifact, artifact_name) {
  return artifact == 'profile' ? artifact_name : 'admin/docker/' + artifact + '/' + artifact_name;
}

function showResult(data) {
  if (typeof data == "object") {
    try {
      data = JSON.stringify(data);
    } catch(e) {

    }
  }
  var artifact_name = $("#artifact-name").val();
  $("#result").val(data);
  set_download("#down", artifact_name, get_path(get_artifact(), artifact_name), data);
  var cmdline = makefilecmd('/tdr/ingest/profiles/' + get_path(get_artifact(), artifact_name), data);
  if (get_artifact() != 'profile') {
    cmdline += makefilecmd('/tdr/ingest/admin-submit/'+artifact_name+'.checkm', get_manifest()) +
      get_curl(artifact_name);
  } 

  $("#manifest").val(cmdline);
}

function generateName(artifact, context) {
  if (artifact == 'profile') {
    return context + "_content";
  }
  if (artifact == 'owner') {
    return context + "_owner";
  }
  if (artifact == 'sla') {
    return context + "_service_level_agreement";
  }
  return context;
}

function doForm() {
  var formdata = getFormData();
  var artifact = formdata['artifact'];
  var name = generateName(artifact, formdata['context']);
  $("#down").attr("download", name).attr("data", artifact)
  formdata['path'] = "createProfile/" + artifact;
  formdata['name'] = name;
  if (artifact == 'profile' || artifact == 'collection') {
    formdata['ark'] = formdata['collection']
  }
  $.ajax({
    dataType: "json",
    method: "POST",
    url: "{{COLLADMIN_ROOT}}/lambda",
    data: formdata,
    success: function(data) {
      if (data == null || data == "") {
        data = {message: "no data returned for " + path}
      }
      if ("ing:genericState" in data) {
        if ("ing:string" in data['ing:genericState']) {
          showResult(data['ing:genericState']['ing:string'].replaceAll("&#10;","\n"));            
        } else {
          showResult(data);
        }
      } else {
        showResult(data);
      }
      $("#tabs")
        .tabs("enable", 1)
        .tabs("enable", 2)
        .tabs("enable", 3)
        .tabs('select', 1);
    },
    error: function( xhr, status ) {
      showResult(xhr.responseText);
      $("#tabs").tabs("enable", 1);
      $('#tabs').tabs('select', 1)
    }
  });
}

function statusCheck() {
  $(".collsec p.proval").removeClass("error");
  $(".intabs").attr("disabled", true).parents("p.proval").removeClass("error");
  var n = $("#context").val();
  var a = $("input[name=artifact]:checked").val();
  if (a != undefined){
    $(".intabs-"+a).attr("disabled", false);
  }
  if (n == "" || a == undefined) {
    $("#context").parents("p.proval").addClass("error");
    $("#artifact-name").val("...");
    $("#artifact-details").hide();
  } else {
    if (a == "profile") {
      n += "_content";
    } else if (a == "owner") {
      n += "_owner";
    } else if (a == "sla") {
      n += "_service_level_agreement";
    }
    $("#artifact-name").val(n);
    $("#artifact-details").show();
  }
  if ($("#name").val() == "") {
    $("#name").parents("p.proval").addClass("error");
  }
  if ($("#description").val() == "") {
    $("#description").parents("p.proval").addClass("error");
  }
  if ($("#owner-admin:enabled").val() == "") {
    $("#owner-admin").parents("p.proval").addClass("error");
  }
  if ($("#owner:enabled").val() == "") {
    $("#owner").parents("p.proval").addClass("error");
  }
  if ($("#storagenode").val() == "") {
    $("#storagenode").parents("p.proval").addClass("error");
  }
  if ($("#collection:enabled").val() == "") {
    $("#collection").parents("p.proval").addClass("error");
  }
  if ($("#collection-sla:enabled").val() == "") {
    $("#collection-sla").parents("p.proval").addClass("error");
  }
  if (!$("#notification").val().match(/^((.+)@([^,@]+\.[^,@]+),)*(.+)@([^,@]+\.[^,@]+)$/)) {
    $("#notification").parents("p.proval").addClass("error");
  }
  $("#profile-button").attr("disabled", $(".collsec p.proval.error").length > 0);
}
  