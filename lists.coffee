Items = new Meteor.Collection 'items'
Lists = new Meteor.Collection 'lists'

Lists.allow {
  insert: (userId, list) ->
    userId && list.owner == userId && list.name.length > 0
  update: (userId, list, fields, modifier) ->
    userId
  remove: (userId, list) ->
    (list.owner == userId) && _.isUndefined(Items.findOne({listId: list._id}))
  fetch: ['owner']
}

Items.allow {
  insert: (userId, item) ->
    userId && item.name.length > 0 && item.owner == userId && Lists.findOne({owner: userId, _id: item.listId}) != null
  update: (userId, item, fields, modifier) ->
    userId
  remove: (userId, item) ->
    item.owner == userId
  fetch: ['owner']
}

Lists.deny {
  update: (userId, list, fields, modifier) ->
    return _.contains(fields, 'owner')
}

Items.deny {
  update: (userId, item, fields, modifier) ->
    return _.contains(fields, 'owner')
}

if Meteor.isClient
  Meteor.subscribe 'lists'
  Meteor.subscribe 'items'

  Template.lists.lists = ->
    lists = Lists.find({}).fetch()
    lists.push {_id: null}
    lists

  Template.lists.events {
    'keypress .js-list-new-input': (event) ->
      if event.which == 13
        input = $(event.currentTarget)
        Lists.insert {owner: Meteor.userId(), name: input.val()}
        input.val('')
    'blur .js-list-input': (event) ->
        input = $(event.currentTarget)
        id = input.parents('[data-id]').attr('data-id')
        Lists.update id, {$set: {name: input.val()}}
    'click .js-list-input': (event) ->
      if $('body').hasClass 'is-deleting'
        id = $(event.currentTarget).parents('[data-id]').attr 'data-id'
        Lists.remove id
  }

  Template.items.items = ->
    Items.find {listId: this._id}

  Template.items.events {
    'keypress .js-item-new-input': (event) ->
      if event.which == 13
        input = $(event.currentTarget)
        listId = input.parents('[data-id]').attr('data-id')
        Items.insert {owner: Meteor.userId(), name: input.val(), listId: listId}
        input.val('')
    'blur .js-item-input': (event) ->
        input = $(event.currentTarget)
        id = input.parents('[data-id]').attr('data-id')
        Items.update id, {$set: {name: input.val()}}
    'click .js-item-input': (event) ->
      if $('body').hasClass 'is-deleting'
        id = $(event.currentTarget).parent('[data-id]').attr 'data-id'
        Items.remove id
  }

if Meteor.isServer
  Meteor.publish 'lists', ->
    Lists.find {owner: this.userId}
  Meteor.publish 'items', ->
    Items.find {owner: this.userId}

  Accounts.validateNewUser (user) ->
    user.emails[0].address == 'kevin.lin.p@gmail.com'

  ###
  Meteor.startup ->
    Lists.remove {}
    Items.remove {}
  ###
