`import Ember from 'ember'`
`import layout from '../templates/components/async-expanding-tree'`

AsyncExpandingTreeComponent = Ember.Component.extend
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
    inheritTooltips: true
# whether default tooltips should be displayed if none are present
    showDefaultTooltips: false

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
  currentSelected: Ember.computed 'model.id', 'selected', ->
    selected = @get('selected')
    id = @get('model.id')
    if Ember.isArray(selected)
      selected?.contains(id)
    else
      selected == id
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

# current level of the tree #
  level: 0
  nextLevel: Ember.computed 'level', ->
    @get('level')+1
# decides whether the children of the tree should display their tooltips
  shouldDisplayTooltip: Ember.computed 'level', 'inheritTooltips', ->
    if @get('level') is 0 then return true
    else unless @get('inheritTooltips') is false then return true
    else return false
# override those if you want default values
  defaultTooltipNode: undefined
  defaultTooltipExpander: undefined
  defaultTooltipLabel: undefined
  defaultTooltipLoadMore: undefined

# the different tooltips
  tooltipNode: Ember.computed 'config.tooltipNode', ->
    @getTooltip('config.getTooltipNode', 'defaultTooltipNode')
  tooltipExpander: Ember.computed 'config.tooltipExpander', ->
    @getTooltip('config.getTooltipExpander', 'defaultTooltipExpander')
  tooltipLabel: Ember.computed 'config.tooltipLabel', ->
    @getTooltip('config.getTooltipLabel', 'defaultTooltipLabel')
  tooltipLoadMore: Ember.computed 'config.tooltipLoadMore', ->
    @getTooltip('config.getTooltipLoadMore', 'defaultTooltipLoadMore')
  getTooltip: (tooltipName, defaultName) ->
    if @get 'shouldDisplayTooltip'
      tooltip = @get(tooltipName)?(@get('level'))
      if tooltip
        tooltip
      else unless @get('showDefaultTooltips') is false then return @get(defaultName)
# by default when not specified, is considered true
  inheritTooltips: Ember.computed.alias 'config.inheritTooltips'
# by default when not specified, is considered true
  showDefaultTooltips: Ember.computed.alias 'config.showDefaultTooltips'

`export default AsyncExpandingTreeComponent`
