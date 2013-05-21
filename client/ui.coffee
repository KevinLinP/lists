$(document).ready ->
  $(document).keydown (event) ->
    if event.which == 16
      $('body').addClass 'is-deleting'

  $(document).keyup (event) ->
    if event.which == 16
      $('body').removeClass 'is-deleting'
