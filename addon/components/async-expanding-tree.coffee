`import Ember from 'ember'`
`import layout from '../templates/components/async-expanding-tree'`
`import KeyboardShortcuts from 'ember-keyboard-shortcuts/mixins/component';`
`import TooltipManager from '../mixins/tooltip-manager'`

AsyncExpandingTreeComponent = Ember.Component.extend KeyboardShortcuts, TooltipManager,
  keyboardShortcuts: Ember.computed 'disableShortcuts', ->
    if @get('disableShortcuts') then return {}
    else
      {
        # open / close current nod #
        'shift':
          action: 'expand'
          global: false
        # expand children #
        'ctrl+alt+e':
          action: 'expandChildren'
          global: false
          preventDefault: true
        'right':
          action: 'right'
          global: false
        'left':
          action: 'left'
          global: false
        'up':
          action: 'up'
          global: false
        'down':
          action: 'down'
          global: false
      }
  layout: layout
  classNames: ["aet"]
  classNameBindings: ["currentSelected:selected", "leafNode:leaf"]
# an array (as per Ember.isArray) of identifier or a single identifier of the selected item(s)
  selected: null
# default configuration
  config:
# property path to the property that should be used as label
# e.g. model.label.en would be label.en
    labelPropertyPath: 'label'
# function that is called with the selected model when the label of the model is clicked
    onActivate: (model) ->
# function to retrieve children of the parent object
# this function should return a Promise that returns the children of this item
# this result will be stored in _childrenCache locally in this component
    getChildren: (model) ->
      model.reload()
# list of concept ids that are expanded
# will auto expand a node in the tree if it's id is cont
# ained in this array
    expandedConcepts: []
# max amount (n) of children to be shown before a load more button is presented
# load more button shows an extra n children
    showMaxChildren: 50
# component to be rendered before the tree node
# model wil be passed to the component
    beforeComponent: null
# component to be rendered after the tree node
# model wil be passed to the component
    afterComponent: null
# whether the children of the tree should display the tooltips
    showChildrenTooltips: true
# whether default tooltips should be displayed if none are present
    showDefaultTooltips: false
# sort order as an array [ 'property1', 'thenproperty2' ]
    sortBy: null

  fetchChildrenOnInit: false

  init: () ->
    @_super(arguments)
    if @get('fetchChildrenOnInit')
      @fetchChildren()
    if @get('expandedConcepts')?.contains(@get('model.id')) and not @get('expanded')
      @toggleExpandF()

  leafNode: Ember.computed '_childrenCache', 'loading',  ->
    (not @get('loading')) and not @get('_childrenCache.length')
  labelPropertyPath: Ember.computed.alias 'config.labelPropertyPath'
  getChildren: Ember.computed.alias 'config.getChildren'
  expandedConcepts: Ember.computed.alias 'config.expandedConcepts'
  showMaxChildren: Ember.computed.alias 'config.showMaxChildren'
  beforeComponent: Ember.computed.alias 'config.beforeComponent'
  afterComponent: Ember.computed.alias 'config.afterComponent'
# we create a dynamic computed property to check when the value of the label is changed
  setLabel: Ember.observer('labelPropertyPath', 'model', () ->
    key = "model.#{@get('labelPropertyPath')}"
    Ember.defineProperty @, "label",
      Ember.computed 'labelPropertyPath', 'model', key, ->
        @get("model.#{@get('labelPropertyPath')}")
  ).on('init')
  sortedChildren: []
  childrenSorter: Ember.observer '_childrenCache', 'sortchildrenby', 'expanded',( ->
    cached = @get '_childrenCache'
    # don't bother sorting unless expanded
    if not @get 'expanded'
      @set 'sortedChildren', cached
      return cached
    @sortByPromise(cached, @get('sortchildrenby')).then (result) =>
      @set 'sortedChildren', result
  ).on('init')
  sortchildrenby: Ember.computed 'labelPropertyPath', 'config.sortBy', ->
    sortBy = @get 'config.sortBy'
    if sortBy
      sortBy
    else
      [@get('labelPropertyPath')]
  childrenFetched: false
  childrenSlice: 50
  expandable: Ember.computed '_childrenCache', 'loading',  ->
    (not @get('loading')) and @get('_childrenCache.length')
  showLoadMore: Ember.computed '_childrenCache.length', 'childrenSlice', 'loading', ->
    (!@get('loading')) && @get('childrenSlice') < @get('_childrenCache.length')
  loading: false
  tagName: 'li'
  fetchChildren: ->
    @set('loading', true)
    @get('getChildren')(@get('model')).then( (result) =>
      @set 'loading', false
      @set 'childrenFetched', true
      @set '_childrenCache', result
      if @get('_childrenCache.length') > 0
        @set 'childrenSlice', @get('showMaxChildren')
    ).catch(=> unless @get('isDestroyed') then @set 'loading', false)
  children: Ember.computed 'sortedChildren', 'loading', 'childrenSlice', ->
    sorted = @get('sortedChildren')
    if not @get('loading') and sorted
      sorted.slice(0, @get('childrenSlice'))
    else
      []
  dirtyObserver: Ember.observer 'model.dirty', ( ->
    if @get('model.dirty') is true
      @fetchChildren()
      @set('model.dirty', false)
  ).on('init')
  toggleExpandF: ->
    @toggleProperty('expanded')
    if @get('expanded')
      @fetchChildren() unless @get('childrenFetched')
      @get('expandedConcepts').addObject(@get('model.id'))
    else
      @get('expandedConcepts').removeObject(@get('model.id'))
  configObserver: Ember.observer 'config', 'config.fetchChildren', ->
    @get 'config.fetchChildren'
    @fetchChildren()
  currentSelected: Ember.computed 'model.id', 'selected', ->
    selected = @get('selected')
    id = @get('model.id')
    if Ember.isArray(selected)
      if selected?.contains(id)
        @scrollToSelected()
        return true
    else
      if selected == id
        @scrollToSelected()
        return true
    return false

  scrollToSelected: () ->
    if @get 'config.noScroll'
      return
    Ember.run.later ->
      $('html, body').stop().animate(
        {'scrollTop': $('.selected').children('.aet-node').children('.aet-label').children('label').offset().top-250},
        900,
        'swing'
      )

  shouldExpandChildren: false
  inheritedExpanded: false
  expanded: Ember.computed 'inheritedExpanded', ->
    @get ('inheritedExpanded')

# current level of the tree #
  level: 0
  nextLevel: Ember.computed 'level', ->
    @get('level')+1

  actions:
    right: ->
      if @get('currentSelected')
        unless @get('expanded')
          @toggleExpandF()
        child = this.get('children')[0]
        if child then @get('config.onActivate')?(child)
    left: ->
      if @get('currentSelected')
        @sendAction('selectParent')
    selectParent: ->
      @get('config.onActivate')?(@get('model'))
    up: ->
      if @get('currentSelected')
        @sendAction('selectOlderBrother', @get('index'))
    selectOlderBrother: (index) ->
      child = this.get('children')[index-1]
      if child then @get('config.onActivate')?(child)
      else @get('config.onActivate')?(@get('model'))
    down: ->
      if @get('currentSelected')
        @sendAction('selectYoungerBrother', @get('index'))
    selectYoungerBrother: (index) ->
      child = this.get('children')[index+1]
      if child then @get('config.onActivate')?(child)
      else @sendAction('selectYoungerBrother', @get('index'))
    expandChildren: ->
      if @get('currentSelected')
        @set('shouldExpandChildren', true)
        unless @get('expanded')
          @toggleExpandF()
      false
    expand: ->
      if @get('currentSelected')
        # Uncomment if we want to open only one level, even if it has been opened before #
        ###@set('shouldExpandChildren', false)###
        @toggleExpandF()
    clickItem: ->
      @get('config.onActivate')?(@get('model'))
    toggleExpand: ->
      @toggleExpandF()
    loadMoreChildren: ->
      if @get('childrenSlice') + @get('showMaxChildren') > @get('_childrenCache.length')
        newSlice = @get('_childrenCache.length')
      else
        newSlice = @get('childrenSlice') + @get('showMaxChildren')
      extraSlice = @get('sortedChildren').slice(@get('childrenSlice'), newSlice)
      @get('children').pushObjects(extraSlice)
      @set('childrenSlice', newSlice)

  sortByPromise: (list, path) ->
    unless Ember.isArray(path)
      path = [path]
    if not list
      return new Ember.RSVP.Promise (resolve) -> resolve(list)

    promises = list.map (item) ->
      hash = {}
      path.map (key) ->
        hash[key] = new Ember.RSVP.Promise (resolve) -> resolve(Ember.get(item, key))
      Ember.RSVP.hash hash
    Ember.RSVP.all(promises).then (resolutions) ->
      toSort = resolutions.map (solutions, index) ->
        result = { _sorterItem: list.objectAt(index) }
        for key, solution of solutions
          result[key] = solution
        result
      sorted = toSort.sortBy.apply toSort, path
      sorted.map (item) ->
        item._sorterItem

`export default AsyncExpandingTreeComponent`
