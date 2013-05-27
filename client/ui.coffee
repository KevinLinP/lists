$(document).ready ->
  $(document).keydown (event) ->
    if event.which == 16
      $('body').addClass 'is-deleting'
      $('body').addClass 'is-sorting'

  $(document).keyup (event) ->
    if event.which == 16
      $('body').removeClass 'is-deleting'
      $('body').removeClass 'is-sorting'

  $(document).on 'keypress', '.js-item-input:focus', (event) ->
    if event.which == 13
      $(event.currentTarget).blur()

  $(document).on 'keypress', '.js-list-input:focus', (event) ->
    if event.which == 13
      $(event.currentTarget).blur()
