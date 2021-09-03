$(document).ready(function(){
    init();
});
  
function init() {
  $(".toggle_harvest").on("click", function(){
    do_action({
      path: "toggle_harvest",
      ark: $(this).attr("data")
    });
  });
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
  $("p.buttons").show();
  showCounts();
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
      window.location.reload()
    },
    error: function( xhr, status ) {
      alert(xhr.responseText);
    }
  });
}
  