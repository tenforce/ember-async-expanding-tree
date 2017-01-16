`import Ember from 'ember'`
`import TooltipManagerMixin from '../../../mixins/tooltip-manager'`
`import { module, test } from 'qunit'`

module 'Unit | Mixin | tooltip manager'

# Replace this with your real tests.
test 'it works', (assert) ->
  TooltipManagerObject = Ember.Object.extend TooltipManagerMixin
  subject = TooltipManagerObject.create()
  assert.ok subject
