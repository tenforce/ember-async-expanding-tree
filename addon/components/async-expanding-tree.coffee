`import Ember from 'ember'`
`import layout from '../templates/components/async-expanding-tree'`

AsyncExpandingTreeComponent = Ember.Component.extend
  layout: layout
  classNames: ["aet"]
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

  fetchChildrenOnInit: false

  init: () ->
    @_super(arguments)
    if @get('fetchChildrenOnInit')
      @fetchChildren()
    if @get('expandedConcepts')?.contains(@get('model.id')) and not @get('expanded')
      @toggleExpandF()

  labelPropertyPath: Ember.computed.alias 'config.labelPropertyPath'
  getChildren: Ember.computed.alias 'config.getChildren'
  expandedConcepts: Ember.computed.alias 'config.expandedConcepts'
  showMaxChildren: Ember.computed.alias 'config.showMaxChildren'
  label: Ember.computed 'labelPropertyPath', 'model', ->
    @get("model.#{@get('labelPropertyPath')}")
  sortedChildren: Ember.computed.sort '_childrenCache', 'sortchildrenby'
  sortchildrenby: Ember.computed 'labelPropertyPath', ->
    [@get('labelPropertyPath')]
  childrenFetched: false
  childrenSlice: 50
  expandable: Ember.computed '_childrenCache', 'loading',  ->
    (not @get('loading')) and @get('_childrenCache.length')
  showLoadMore: Ember.computed '_childrenCache.length', 'childrenSlice', 'loading', ->
    (!@get('loading')) && @get('childrenSlice') < @get('_childrenCache.length')
  expanded: false
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
    ).catch(=> @set 'loading', false)
  children: Ember.computed 'sortedChildren', 'loading', 'childrenSlice', ->
    if not @get('loading')
      @get('sortedChildren').slice(0, @get('childrenSlice'))
    else
      []
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
  actions:
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


`export default AsyncExpandingTreeComponent`
