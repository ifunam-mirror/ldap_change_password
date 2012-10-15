$(document).ready(function() {
  $(".close").live('click', function() {
    $(this).parent().remove();
    return false;
  });
})
