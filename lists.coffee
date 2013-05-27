Groups = new Meteor.Collection 'groups'
Items = new Meteor.Collection 'items'
Lists = new Meteor.Collection 'lists'

Groups.allow {
  insert: (userId, group) ->
    userId && group.owner == userId && group.name.length > 0
  update: (userId, group, fields, modifier) ->
    userId
  remove: (userId, group) ->
    (group.owner == userId) && _.isUndefined(Lists.findOne({groupId: group._id}))
  fetch: ['owner']
}

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
  Meteor.subscribe 'groups'
  Deps.autorun ->
    Meteor.subscribe 'lists', Session.get('currentGroup')
    Meteor.subscribe 'items', Session.get('currentGroup')

  Template.groups.groups = ->
    Groups.find {}, {sort: ['position']}

  Template.groups.isActive = (group) ->
    group._id == Session.get 'currentGroup'

  Template.lists.lists = ->
    Lists.find {}, {sort: ['position']}

  Meteor.startup ->
    first = Groups.findOne {}, {sort: ['position']}
    if first
      Session.set 'currentGroup', first._id

  Template.groups.events {
    'keypress .js-group-new-input': (event) ->
      if event.which == 13
        input = $(event.currentTarget)
        position = Groups.find({}).count()
        Groups.insert {owner: Meteor.userId(), name: input.val(), position: position}
        input.val('')
    'click .groups-group': (event) ->
      id = $(event.currentTarget).attr 'data-id'
      return unless id

      if $('body').hasClass 'is-deleting'
        Groups.remove id
      else
        Session.set 'currentGroup', id
  }

  Template.lists.events {
    'keypress .js-list-new-input': (event) ->
      if event.which == 13
        input = $(event.currentTarget)
        group = Groups.findOne(Session.get('currentGroup'))
        return false unless group
        position = Lists.find({}).count()
        Lists.insert {owner: Meteor.userId(), groupId: group._id, name: input.val(), position: position}
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

  Template.lists.rendered = ->
    $('#lists').sortable {
      items: '> :not(:last-child)'
      update: (event, ui) ->
        ids = $(event.target).sortable('toArray', {attribute: 'data-id'})
        _.each ids, (id, index, ids) ->
          Lists.update id, {$set: {position: index}}
    }
    $('.js-list-list').sortable {
      items: '> li:not(:last-child)'
      handle: '.handle'
      axis: 'y',
      update: (event, ui) ->
        ids = $(event.target).sortable('toArray', {attribute: 'data-id'})
        _.each ids, (id, index, ids) ->
          Items.update id, {$set: {position: index}}
    }

  Template.items.items = ->
    Items.find {listId: this._id}, {sort: ['position']}

  Template.items.events {
    'keypress .js-item-new-input': (event) ->
      if event.which == 13
        input = $(event.currentTarget)
        listId = input.parents('[data-id]').attr('data-id')
        position = Items.find({listId: listId}).count()
        Items.insert {owner: Meteor.userId(), name: input.val(), listId: listId, position: position}
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
  Meteor.publish 'groups', ->
    Groups.find {owner: this.userId}
  Meteor.publish 'lists', (groupId) ->
    Lists.find {owner: this.userId, groupId: groupId}
  Meteor.publish 'items', (groupId) ->
    Items.find {owner: this.userId}

  Accounts.validateNewUser (user) ->
    user.emails[0].address == 'kevin.lin.p@gmail.com'

  Meteor.startup ->
    Lists.remove {}
    Items.remove {}
