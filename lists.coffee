Groups = new Meteor.Collection 'groups'
Items = new Meteor.Collection 'items'
Lists = new Meteor.Collection 'lists'


# TODO: double check blur = write
# TODO: don't use shift as modifier -_-
# TODO: debug empty input not disappearing when no group selected in production (old meteor bug maybe?)
# TODO: refactor permissions
# TODO: fix window unfocus while shifted
# TODO: consolidate is-deleting and is-sorting
# TODO: Max items? or scrollable?

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
  Meteor.subscribe 'groups', ->
    first = Groups.findOne {}, {sort: {position: 1}}
    if first
      Session.set 'currentGroup', first._id

  Meteor.subscribe 'lists'
  Meteor.subscribe 'items'

  Template.groups.groups = ->
    Groups.find {}, {sort: ['position']}

  Template.groups.isActive = (group) ->
    group._id == Session.get 'currentGroup'

  Template.lists.lists = ->
    Lists.find {groupId: Session.get('currentGroup')}, {sort: ['position']}

  Template.groups.events {
    'keypress .js-group-new-input': (event) ->
      if event.which == 13
        input = $(event.currentTarget)
        lastGroup = Groups.findOne({}, {sort: {position: -1}})
        position = if lastGroup then (lastGroup.position + 1) else 0
        Groups.insert {owner: Meteor.userId(), name: input.val(), position: position}
        input.val('')
        # TODO: focuses items input on completion
    # TODO: refactor!
    'click .js-group-target': (event) ->
      target = $(event.currentTarget)
      currentGroupId = Session.get('currentGroup')
      id = target.parents('[data-id]').attr 'data-id'
      return unless id

      if $('body').hasClass 'is-deleting'
        Groups.remove id
        # TODO: smarter reassignment
        if id == currentGroupId
          Session.set 'currentGroup', null
      else
        if id == currentGroupId
          target.addClass 'hidden'
          input = target.siblings('.js-group-input')
          input.removeClass 'hidden'
          input.focus()
        else
          Session.set 'currentGroup', id
    'keypress .js-group-input, blur .js-group-input': (event) ->
      if (event.type == 'blur') || (event.which == 13)
        input = $(event.currentTarget)
        id = input.parents('[data-id]').attr 'data-id'
        Groups.update id, {$set: {name: input.val()}}
        Deps.flush()
        input.addClass 'hidden'
        input.siblings('.js-group-target').removeClass 'hidden'
  }

  Template.groups.rendered = ->
    $('#groups').sortable {
      items: '> :not(:last-child)'
      handle: '.group-handle'
      axis: 'x',
      update: (event, ui) ->
        ids = $(event.target).sortable('toArray', {attribute: 'data-id'})
        _.each ids, (id, index, ids) ->
          Groups.update id, {$set: {position: index}}
    }
    $('.groups-group').droppable {
      accept: '.list'
      tolerance: 'pointer'
      drop: (event, ui) ->
        groupId = $(this).attr 'data-id'
        listId = ui.draggable.attr 'data-id'
        Lists.update listId, {$set: {groupId: groupId, position: 0}}
    }

  Template.lists.events {
    # TODO: blurable also
    'keypress .js-list-new-input': (event) ->
      if event.which == 13
        input = $(event.currentTarget)
        group = Groups.findOne(Session.get('currentGroup'))
        return false unless group
        lastList = Lists.findOne({}, {sort: {position: -1}})
        position = if lastList then (lastList.position + 1) else 0
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
      handle: '.list-handle'
      update: (event, ui) ->
        ids = $(event.target).sortable('toArray', {attribute: 'data-id'})
        _.each ids, (id, index, ids) ->
          Lists.update id, {$set: {position: index}}
    }
    $('.js-list-list').sortable {
      items: '> li:not(:last-child)'
      handle: '.item-handle'
      axis: 'y',
      update: (event, ui) ->
        ids = $(event.target).sortable('toArray', {attribute: 'data-id'})
        _.each ids, (id, index, ids) ->
          Items.update id, {$set: {position: index}}
    }

  Template.lists.groupSelected = ->
    Session.get('currentGroup') != null

  Template.items.items = ->
    Items.find {listId: this._id}, {sort: ['position']}

  Template.items.events {
    'keypress .js-item-new-input': (event) ->
      if event.which == 13
        input = $(event.currentTarget)
        listId = input.parents('[data-id]').attr('data-id')
        lastItem = Items.findOne({listId: listId}, {sort: {position: -1}})
        position = if lastItem then (lastItem.position + 1) else 0
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
  Meteor.publish 'lists', ->
    Lists.find {owner: this.userId}
  Meteor.publish 'items', ->
    Items.find {owner: this.userId}

  # TODO: fix list order logic on list move

  Accounts.validateNewUser (user) ->
    user.emails[0].address == 'kevin.lin.p@gmail.com'

