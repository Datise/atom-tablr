_ = require 'underscore-plus'
{Point, Range, Emitter, CompositeDisposable} = require 'atom'
Delegator = require 'delegato'
Table = require './table'
DisplayTable = require './display-table'
Cursor = require './cursor'
Selection = require './selection'

module.exports =
class TableEditor
  Delegator.includeInto(this)

  @delegatesMethods 'screenPosition', 'modelPosition', 'getValueAtPosition', 'getValueAtScreenPosition', 'getScreenRowCount', 'getScreenColumnCount', toProperty: 'displayTable'

  constructor: (options={}) ->
    {@table} = options
    @table = new Table unless @table?
    @displayTable = new DisplayTable({@table})
    @emitter = new Emitter
    @subscriptions = new CompositeDisposable
    @cursors = []
    @selections = []

    @addCursorAtScreenPosition(new Point(0,0))

  onDidAddCursor: (callback) ->
    @emitter.on 'did-add-cursor', callback

  onDidRemoveCursor: (callback) ->
    @emitter.on 'did-remove-cursor', callback

  onDidAddSelection: (callback) ->
    @emitter.on 'did-add-selection', callback

  onDidRemoveSelection: (callback) ->
    @emitter.on 'did-remove-selection', callback

  ##     ######  ######## ##       ########  ######  ########
  ##    ##    ## ##       ##       ##       ##    ##    ##
  ##    ##       ##       ##       ##       ##          ##
  ##     ######  ######   ##       ######   ##          ##
  ##          ## ##       ##       ##       ##          ##
  ##    ##    ## ##       ##       ##       ##    ##    ##
  ##     ######  ######## ######## ########  ######     ##

  getSelections: ->
    @selections.slice()

  hasMultipleSelections: ->
    @getSelections().length > 1

  getLastSelection: ->
    @selections[@selections.length - 1]

  removeSelection: (selection) ->
    @selections.splice(@selections.indexOf(selection), 1)
    @emitter.emit 'did-remove-selection', {selection, tableEditor: this}

  ##     ######  ##     ## ########   ######   #######  ########   ######
  ##    ##    ## ##     ## ##     ## ##    ## ##     ## ##     ## ##    ##
  ##    ##       ##     ## ##     ## ##       ##     ## ##     ## ##
  ##    ##       ##     ## ########   ######  ##     ## ########   ######
  ##    ##       ##     ## ##   ##         ## ##     ## ##   ##         ##
  ##    ##    ## ##     ## ##    ##  ##    ## ##     ## ##    ##  ##    ##
  ##     ######   #######  ##     ##  ######   #######  ##     ##  ######

  getCursors: ->
    @cursors.slice()

  hasMultipleCursors: ->
    @getCursors().length > 1

  getLastCursor: ->
    @cursors[@cursors.length - 1]

  getCursorPosition: ->
    @modelPosition(@getLastCursor().getPosition())

  getCursorPositions: ->
    @modelPosition(cursor.getPosition()) for cursor in @getCursors()

  getCursorScreenPosition: ->
    @getLastCursor().getPosition()

  getCursorScreenPositions: ->
    cursor.getPosition() for cursor in @getCursors()

  getCursorValue: ->
    @getValueAtScreenPosition(@getCursorScreenPosition())

  getCursorValues: ->
    @getValueAtScreenPosition(cursor.getPosition()) for cursor in @getCursors()

  addCursorAtPosition: (position) ->
    @addCursorAtScreenPosition(@screenPosition(position))

  addCursorAtScreenPosition: (position) ->
    position = Point.fromObject(position)
    return if @cursors.some (cursor) -> cursor.getPosition().isEqual(position)

    cursor = new Cursor({position, tableEditor: this})
    selection = new Selection({cursor, tableEditor: this})
    @selections.push selection
    @cursors.push cursor
    @emitter.emit 'did-add-selection', {selection, tableEditor: this}
    @emitter.emit 'did-add-cursor', {cursor, tableEditor: this}

  setCursorAtPosition: (position) ->
    position = @screenPosition(position)
    @moveCursors (cursor) -> cursor.setPosition(position)

  setCursorAtScreenPosition: (position) ->
    @moveCursors (cursor) -> cursor.setPosition(position)

  removeCursor: (cursor) ->
    @cursors.splice(@cursors.indexOf(cursor), 1)
    @emitter.emit 'did-remove-cursor', {cursor, tableEditor: this}

  moveCursors: (fn) ->
    fn(cursor) for cursor in @getCursors()
    @mergeCursors()

  # Merge cursors that have the same screen position
  mergeCursors: ->
    positions = {}
    for cursor in @getCursors()
      position = cursor.getPosition().toString()
      if positions.hasOwnProperty(position)
        cursor.destroy()
        cursor.selection.destroy()
      else
        positions[position] = true
    return
