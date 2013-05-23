Items = new Meteor.Collection 'items'
Lists = new Meteor.Collection 'lists'

Lists.allow {
  insert: (userId, list) ->
    userId && list.owner == userId
  remove: (userId, list) ->
    list.owner == userId
  fetch: ['owner']
}

if Meteor.isClient
  Meteor.subscribe 'lists'
  Template.lists.lists = ->
    lists = Lists.find({}).fetch()
    lists.push {_id: null}
    lists

  Template.lists.events {
    'keypress .list-new-input': (event) ->
      if event.which == 13
        input = $(event.currentTarget)
        Lists.insert {owner: Meteor.userId(), name: input.val()}
        input.val('')
    'click .js-list-target': (event) ->
      if $('body').hasClass 'is-deleting'
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
    'click .js-item-target': (event) ->
      if $('body').hasClass 'is-deleting'
        window.getSelection().empty()
        event.preventDefault
        event.stopPropagation
        id = $(event.currentTarget).attr 'data-id'
        Items.remove {_id: id}
  }

  $('body').dblclick -> 
    $('body').toggleClass 'is-editing'

if Meteor.isServer
  Meteor.publish 'lists', ->
    Lists.find {owner: this.userId}

  Meteor.startup ->
    Lists.remove {}
    Items.remove {}

