$(document).ready(function(){
    init();
});
  
function init() {
  $(".toggle-harvest").on("click", function(){
    do_action({
      path: "toggle-harvest",
      collid: $(this).attr("data")
    });
  });
  $(".pull-profile").on("click", function(){
    do_action({
      path: "pull-profile",
      collid: $(this).attr("data")
    });
  });
}

function do_action(formdata) {
  $.ajax({
    dataType: "json",
    method: "POST",
    url: "{{COLLADMIN_ROOT}}/lambda",
    data: formdata,
    success: function(data) {
      if ('message' in data) {
        alert(data.message);
      }
      document.location = "{{COLLADMIN_ROOT}}/web/collProperties.html"
    },
    error: function( xhr, status ) {
      alert(xhr.responseText);
    }
  });
}
  