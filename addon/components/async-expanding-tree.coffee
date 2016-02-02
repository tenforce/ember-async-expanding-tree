`import Ember from 'ember'`
`import layout from '../templates/components/async-expanding-tree'`

AsyncExpandingTreeComponent = Ember.Component.extend(
  layout
  init: ->
    @_super()
    if @get('expandedConcepts')?.contains(@get('model.id')) and not @get('expanded')
      @toggleExpandF()

  sortedChildren: Ember.computed.sort 'model.children', 'sortchildrenby'
  sortchildrenby: ['label']
  childrenSlice: 50
  expandable: Ember.computed 'model.children', 'model.grouping', 'loading',  ->
    (not @get('loading')) and (@get('model.grouping') or @get('model.children.length'))
  showLoadMore: Ember.computed 'model.children.length', 'childrenSlice', 'loading', ->
    (!@get('loading')) && @get('childrenSlice') < @get('model.children.length')
  expanded: false
  loading: false
  tagName: 'li'
  activeConcepts: []
  modelReloaded: false
  showSublist: Ember.computed 'model.children.@each.grouping', 'includeLeafs', ->
    if @get('model.children.length') > 0
      @get('includeLeafs') || @get('model.children.firstObject.grouping')
    else
      true
  reloadModel: ->
    @set('loading', true)
    @get('model').reload().then(=>
      @set 'modelReloaded', true
      @set 'loading', false
      if @get('model.children.length') > 0
        @set 'children', @get('sortedChildren').slice(0, @get('childrenSlice'))
    ).catch(=> @set 'loading', false)
  toggleExpandF: ->
    @toggleProperty('expanded')
    if @get('expanded')
      @reloadModel() unless @get('modelReloaded')
      @get('expandedConcepts').addObject(@get('model.id'))
    else
      @get('expandedConcepts').removeObject(@get('model.id'))
  actions:
    toggleExpand: ->
      @toggleExpandF()
    loadMoreChildren: ->
      if @get('childrenSlice') + 50 > @get('model.children.length')
        newSlice = @get('model.children.length')
      else
        newSlice = @get('childrenSlice') + 20
      extraSlice = @get('sortedChildren').slice(@get('childrenSlice'), newSlice)
      @get('children').pushObjects(extraSlice)
      @set('childrenSlice', newSlice)
)

`export default AsyncExpandingTreeComponent`
