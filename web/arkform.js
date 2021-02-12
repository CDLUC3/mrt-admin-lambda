$(document).ready(function(){
  $("#arkinput").on("blur", function(){
    updateOutput();
  });
});

function updateOutput() {
  var s = $("#arkinput").val();
  s = s.replaceAll(/[^\/0-9a-z:]+/g, " ");
  res = s.match(/ark:\/[a-z0-9]+\/[a-z0-9]+/g);
  s=res.join(",\n");
  $("#arkoutput").val(s);
  $("#arkcount").val(res.length);
  localStorage.setItem('arklist', res.join(","));
}