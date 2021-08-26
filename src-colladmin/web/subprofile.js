$(document).ready(function(){
    init();
});
  
function init() {
    $("input.submit-admin").on("click", function(){
        data = {
            path: "submit-profile",
            title: $(this).attr("data-title"),
            "profile-path": $(this).attr("data")
        };
        $.ajax({
            dataType: "xml",
            method: "POST",
            url: "{{COLLADMIN_ROOT}}/lambda",
            data: data,
            success: function(data) {
              alert("Admin Object Submitted.  Check back in a couple minutes to confirm that an ark has been minted.");
            },
            error: function( xhr, status ) {
              alert(xhr.responseText);
            }
        });
    });
}