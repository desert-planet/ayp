$(document).ready(function () {

  $(document).keyup(function(e) {

    if($(document.activeElement).is("input, textarea")) return false; // Abort if active element is an input or a textarea.

      var url = false;
      if (e.which == 37) {  // Left arrow key code
        url = $('#prev').attr('href');
      }
      else if (e.which == 39) {  // Right arrow key code
        url = $('#next').attr('href');
      }
      else if (e.which == 65) {  // A key code
        url = $('.archive').attr('href');
      }
      else if (e.which == 72) {  // H key code
        url = $('.home').attr('href');
      }
      else if (e.which == 82) {  // R key code
        url = $('.random').attr('href');
      }
      if (url) {
        window.location = url;
      }
    });

});
