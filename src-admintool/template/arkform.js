$(document).ready(function(){
  init();
});

function init() {
  $("#arkinput").on("blur", function(){
    updateArkOutput();
  });
  $("#doiinput").on("blur", function(){
    updateDoiOutput();
  });
  $("#localinput").on("blur", function(){
    updateLocalidOutput();
  });
  $("#parse").on("click", function(){
    parse();
  });
  $(".bp_search").show();
  $(".bp_title").text($("h1").text()).show();
}

window.onpageshow = function(event) {
  init();
};

function updateArkOutput() {
  var s = $("#arkinput").val();
  if (s == undefined) return;
  s = s.replaceAll(/[^\/0-9a-z:]+/g, " ");
  res = s.match(/ark:\/[a-z0-9]+\/[a-z0-9]+/g);
  s=res.join(",\n");
  $("#arkoutput").val(s);
  $("#arkcount").val(res.length);
  localStorage.setItem('arklist', res.join(","));
}

function updateDoiOutput() {
  var s = $("#doiinput").val();
  if (s == undefined) return;
  s = s.replaceAll(/[^\/0-9a-zA-Z\.:]+/g, " ");
  res = s.match(/doi:[A-Za-z0-9\.]+\/[A-Za-z0-9\.]+/g);
  s=res.join(",\n");
  $("#doioutput").val(s);
  $("#doicount").val(res.length);
  localStorage.setItem('locallist', res.join(","));
}

function updateLocalidOutput() {
  var s = $("#localinput").val();
  if (s == undefined) return;
  s = s.replaceAll(/[\s;\|]+/g, " ");
  res = s.match(/[^\s]+/g);
  s=res.join(",\n");
  $("#localoutput").val(s);
  $("#localcount").val(res.length);
  localStorage.setItem('locallist', res.join(","));
}

function parse() {
  updateArkOutput();
  updateDoiOutput();
  updateLocalidOutput();
}