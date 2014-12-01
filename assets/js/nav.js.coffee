KeyCodes =
  left: 37
  right: 39
  escape: 27
  slash: 191
  a: 65
  h: 72
  r: 82
  j: 74
  k: 75
  p: 80
  n: 78

$ ->

  $("#show-nav").on "click", -> # clicking that link shows shortcuts help
    $("#modal-container").show()

  $("#modal-container").on "click", ->
    $(this).hide()

  $(document).keyup (e) ->
    # Abort if active element is an input or a textarea.
    return false if $(document.activeElement).is("input, textarea")

    switch e.which
      when KeyCodes.left, KeyCodes.k, KeyCodes.p
        url = $('#prev').attr 'href'
      when KeyCodes.right, KeyCodes.j, KeyCodes.n
        url = $('#next').attr 'href'
      when KeyCodes.a
        url = $('.archive').attr 'href'
      when KeyCodes.h
        url = $('.home').attr 'href'
      when KeyCodes.r
        url = $('.random').attr 'href'
      when KeyCodes.escape
        $('#modal-container').hide()
      when KeyCodes.slash
        $('#modal-container').toggle() if e.shiftKey == true

    window.location = url if url
