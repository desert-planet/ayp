KeyCodes =
  left: 37
  right: 39
  a: 65
  h: 72
  r: 82
  j: 74
  k: 75

getHrefById = (id) ->
  element = document.getElementById(id)
  if element
    element.href

getHrefByClassName = (className) ->
  element = document.getElementsByClassName(className)[0]
  if element
    element.href

document.addEventListener 'DOMContentLoaded', ->
  window.onkeyup = (e) ->
    # Abort if active element is an input or a textarea.
    activeTagName = document.activeElement.tagName
    return false if activeTagName == 'input'
    return false if activeTagName == 'textarea'

    switch e.which
      when KeyCodes.left, KeyCodes.k
        url = getHrefById 'prev'
      when KeyCodes.right, KeyCodes.j
        url = getHrefById 'next'
      when KeyCodes.a
        url = getHrefByClassName 'archive'
      when KeyCodes.h
        url = getHrefByClassName 'home'
      when KeyCodes.r
        url = getHrefByClassName 'random'

    window.location = url if url
