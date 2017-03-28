`import Ember from 'ember'`

TooltipManagerMixin = Ember.Mixin.create
# current level of the tree #
  level: 0
  nextLevel: Ember.computed 'level', ->
    @get('level')+1
# decides whether the children of the tree should display their tooltips
  shouldDisplayTooltip: Ember.computed 'level', 'showChildrenTooltips', ->
    if @get('level') is 0 then return true
    else return (@get('showChildrenTooltips') != false)
# override those if you want default values
  defaultTooltipNode: undefined
  defaultTooltipExpander: 'Click to expand/collapse'
  defaultTooltipLabel: undefined
  defaultTooltipLoadMore: 'Load more'

# the different tooltips
  tooltipNode: Ember.computed 'config.tooltipNode', ->
    @getTooltip('config.tooltipNode', 'config.getTooltipNode', 'defaultTooltipNode')
  tooltipExpander: Ember.computed 'config.tooltipExpander', ->
    @getTooltip('config.tooltipExpander', 'config.getTooltipExpander', 'defaultTooltipExpander')
  tooltipLabel: Ember.computed 'config.tooltipLabel', ->
    @getTooltip('config.tooltipLabel', 'config.getTooltipLabel', 'defaultTooltipLabel')
  tooltipLoadMore: Ember.computed 'config.tooltipLoadMore', ->
    @getTooltip('config.tooltipLoadMore', 'config.getTooltipLoadMore', 'defaultTooltipLoadMore')
# behavior : first we check if a tooltip is provided, if there is one, we use it.
# otherwise we check if a function has been provided
# then we check if we should display the default tooltip
  getTooltip: (tooltipName, tooltipFunction, defaultName) ->
    if @get 'shouldDisplayTooltip'
      tooltip = @get(tooltipName)
      if tooltip then return tooltip
      tooltip = @get(tooltipFunction)?(@get('level'))
      if tooltip then return tooltip
      unless @get('showDefaultTooltips') is false then return @get(defaultName)
# by default when not specified, is considered true
  showChildrenTooltips: Ember.computed.alias 'config.showChildrenTooltips'
# by default when not specified, is considered true
  showDefaultTooltips: Ember.computed.alias 'config.showDefaultTooltips'

`export default TooltipManagerMixin`
