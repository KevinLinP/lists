Items = new Meteor.Collection 'items'
Lists = new Meteor.Collection 'lists'

if Meteor.isClient
  Template.lists.lists = ->
    lists = Lists.find({}).fetch()
    lists.push {_id: null}
    lists

  Template.lists.events {
    'keypress .list-new-input': (event) ->
      if event.which == 13
        input = $(event.currentTarget)
        Lists.insert {name: input.val()}
        input.val('')
    'click .delete': (event) ->
      id = $(event.currentTarget).parents('[data-id]').attr 'data-id'
      Lists.remove {_id: id}
      Items.remove {listId: id}
  }

  Template.items.items = ->
    Items.find {listId: this._id}

  Template.items.events {
    'keypress .js-items-new-input': (event) ->
      if event.which == 13
        input = $(event.currentTarget)
        listId = input.parents('[data-id]').attr('data-id')
        Items.insert {name: input.val(), listId: listId}
        input.val('')
    'click .js-items-delete': (event) ->
      id = $(event.currentTarget).parents('[data-id]').attr 'data-id'
      Items.remove {_id: id}
  }

  $('body').dblclick -> 
    $('body').toggleClass 'is-editing'

if Meteor.isServer
  Meteor.startup ->
    Lists.remove {}
    Items.remove {}
    listId = Lists.insert {name: 'list 1'}
    Lists.insert {name: 'list 2'}
    Lists.insert {name: 'list 3'}
    Lists.insert {name: 'list 4'}
    Lists.insert {name: 'list 5'}
    Items.insert {name: 'item 1', listId: listId}
    Items.insert {name: 'item 2', listId: listId}
