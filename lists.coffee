Items = new Meteor.Collection 'items'
Lists = new Meteor.Collection 'lists'

if Meteor.isClient
  Template.lists.lists = ->
    lists = []
    for list, i in Lists.find({}).fetch()
      if i % 3 == 0
        lists.push []
      lists[lists.length - 1].push list

    lists[lists.length - 1].push {_id: null}
    lists

  Template.lists.events {
    'keypress #new-list': (event) ->
      if event.which == 13
        input = $(event.currentTarget)
        Lists.insert {name: input.val()}
        input.val('')
    'click .delete': (event) ->
      id = $(event.currentTarget).parents('[data-id]').attr 'data-id'
      Lists.remove {_id: id}
  }

  Template.items.items = ->
    Items.find {listId: this._id}

  Template.items.events {
    'keypress #new-item': (event) ->
      if event.which == 13
        input = $(event.currentTarget)
        listId = input.parent('[data-id]').attr('data-id')
        Items.insert {name: input.val(), listId: listId}
        input.val('')
    'click .delete': (event) ->
      id = $(event.currentTarget).parent('[data-id]').attr 'data-id'
      Items.remove {_id: id}
  }

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
