$(document).ready(function(){
    init();
});
  
function init() {
    $("input.submit-profile").on("click", function(){
        data = {
            path: "submit-profile",
            submitter: "tbrady",
            title: "foo",
            "profile-path": $(this).attr("data")
        };
        $.ajax({
            dataType: "json",
            method: "POST",
            url: "{{COLLADMIN_ROOT}}/lambda",
            data: data,
            success: function(data) {
              alert(data);
            },
            error: function( xhr, status ) {
              alert(xhr.responseText);
            }
        });
    });
}