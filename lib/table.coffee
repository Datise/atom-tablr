{Point} = require 'atom'
{Emitter, Disposable, CompositeDisposable} = require 'event-kit'
Identifiable = require './mixins/identifiable'
Transactions = require './mixins/transactions'

module.exports =
class Table
  Identifiable.includeInto(this)
  Transactions.includeInto(this)

  @MAX_HISTORY_SIZE: 100

  constructor: (options={}) ->
    @initID()
    @columns = []
    @rows = []
    @emitter = new Emitter
    @modified = false

  destroy: ->
    return if @destroyed
    @emitter.emit 'did-destroy', this
    @emitter.dispose()
    @columns = []
    @rows = []
    @destroyed = true

  isModified: -> @cachedContents isnt @getCacheContent()

  emitModifiedStatusChange: (modified=true) ->
    return if modified is @modified

    @modified = modified
    @emitter.emit 'did-change-modified', modified

  isDestroyed: -> @destroyed

  save: ->
    return unless @modified

    @emitter.emit 'will-save', this

    if @saveHandler?
      result = @saveHandler(this)
      if result instanceof Promise
        result.then =>
          @emitModifiedStatusChange(false)
          @updateCachedContents()
          @emitter.emit 'did-save', this
        result.catch (reason) ->
          console.error reason
      else
        @emitModifiedStatusChange(!result)

        unless @modified
          @updateCachedContents()
          @emitter.emit 'did-save', this
    else
      @emitModifiedStatusChange(false)
      @updateCachedContents()
      @emitter.emit 'did-save', this

  setSaveHandler: (@saveHandler) ->

  updateCachedContents: ->
    @cachedContents = @getCacheContent()

  getCacheContent: ->
    console.log res = @columns.concat(@rows).join('\n')
    res

  #    ######## ##     ## ######## ##    ## ########  ######
  #    ##       ##     ## ##       ###   ##    ##    ##    ##
  #    ##       ##     ## ##       ####  ##    ##    ##
  #    ######   ##     ## ######   ## ## ##    ##     ######
  #    ##        ##   ##  ##       ##  ####    ##          ##
  #    ##         ## ##   ##       ##   ###    ##    ##    ##
  #    ########    ###    ######## ##    ##    ##     ######

  onWillSave: (callback) ->
    @emitter.on 'did-save', callback

  onDidSave: (callback) ->
    @emitter.on 'did-save', callback

  onDidChangeModified: (callback) ->
    @emitter.on 'did-change-modified', callback

  onDidAddColumn: (callback) ->
    @emitter.on 'did-add-column', callback

  onDidRemoveColumn: (callback) ->
    @emitter.on 'did-remove-column', callback

  onDidRenameColumn: (callback) ->
    @emitter.on 'did-rename-column', callback

  onDidAddRow: (callback) ->
    @emitter.on 'did-add-row', callback

  onDidRemoveRow: (callback) ->
    @emitter.on 'did-remove-row', callback

  onDidChangeRows: (callback) ->
    @emitter.on 'did-change-rows', callback

  onDidChangeCellValue: (callback) ->
    @emitter.on 'did-change-cell-value', callback

  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy', callback

  #     ######   #######  ##       ##     ## ##     ## ##    ##  ######
  #    ##    ## ##     ## ##       ##     ## ###   ### ###   ## ##    ##
  #    ##       ##     ## ##       ##     ## #### #### ####  ## ##
  #    ##       ##     ## ##       ##     ## ## ### ## ## ## ##  ######
  #    ##       ##     ## ##       ##     ## ##     ## ##  ####       ##
  #    ##    ## ##     ## ##       ##     ## ##     ## ##   ### ##    ##
  #     ######   #######  ########  #######  ##     ## ##    ##  ######

  getColumns: -> @columns.slice()

  getColumn: (index) -> @columns[index]

  getColumnIndex: (column) -> @columns.indexOf(column)

  getColumnValues: (index) -> @rows.map (row) => row[index]

  getColumnNames: -> @columns.concat()

  getColumnCount: -> @columns.length

  addColumn: (name, transaction=true, event=true) ->
    @addColumnAt(@columns.length, name, transaction, event)

  addColumnAt: (index, column, transaction=true, event=true) ->
    throw new Error "Can't add column to a destroyed table" if @isDestroyed()
    throw new Error "Can't add column #{column} at index #{index}" if index < 0
    throw new Error "Can't add column without a name" unless column?

    if column in @columns
      throw new Error "Can't add column #{column} as one already exist"

    @extendExistingRows(column, index)

    if index >= @columns.length
      index = @columns.length
      @columns.push column
    else
      @columns.splice index, 0, column

    @emitModifiedStatusChange()
    @emitter.emit 'did-add-column', {column, index} if event

    if transaction
      @transaction
        undo: -> @removeColumnAt(index, false)
        redo: -> @addColumnAt(index, column, false)

    column

  removeColumn: (column, transaction=true, event=true) ->
    throw new Error "Can't remove an undefined column" unless column?

    @removeColumnAt(@columns.indexOf(column), transaction, event)

  removeColumnAt: (index, transaction=true, event=true) ->
    if index is -1 or index >= @columns.length
      throw new Error "Can't remove column at index #{index}"

    values = @getColumnValues(index) if transaction

    column = @columns[index]
    @columns.splice(index, 1)
    row.splice(index, 1) for row in @rows

    @emitModifiedStatusChange()
    @emitter.emit 'did-remove-column', {column, index} if event

    if transaction
      @transaction
        undo: ->
          @addColumnAt(index, column, false)
          @rows.forEach (row,i) -> row[index] = values[i]
        redo: -> @removeColumnAt(index, false)

  changeColumnName: (column, newName, transaction=true, event=true) ->
    index = @columns.indexOf(column)

    @columns[index] = newName
    @emitModifiedStatusChange()

    if event
      @emitter.emit('did-rename-column', {oldName: column, newName, index})

    if transaction
      @transaction
        undo: ->
          @columns[index] = column
          @emitModifiedStatusChange()
        redo: ->
          @columns[index] = newName
          @emitModifiedStatusChange()

  #    ########   #######  ##      ##  ######
  #    ##     ## ##     ## ##  ##  ## ##    ##
  #    ##     ## ##     ## ##  ##  ## ##
  #    ########  ##     ## ##  ##  ##  ######
  #    ##   ##   ##     ## ##  ##  ##       ##
  #    ##    ##  ##     ## ##  ##  ## ##    ##
  #    ##     ##  #######   ###  ###   ######

  getRows: -> @rows.slice()

  getRow: (index) -> @rows[index]

  getRowIndex: (row) -> @rows.indexOf(row)

  getRowCount: -> @rows.length

  getRowsInRange: (range) ->
    range = @rowRangeFrom(range)
    @rows[range.start...range.end]

  getFirstRow: -> @rows[0]

  getLastRow: -> @rows[@rows.length - 1]

  addRow: (values, batch=false, transaction=true) ->
    @addRowAt(@rows.length, values, batch, transaction)

  addRowAt: (index, values={}, batch=false, transaction=true) ->
    throw new Error "Can't add row to a destroyed table" if @isDestroyed()
    throw new Error "Can't add row #{values} at index #{index}" if index < 0

    if @columns.length is 0
      throw new Error "Can't add rows to a table without column"

    row = []

    if Array.isArray(values)
      row = values.concat()
    else
      row.push values[column] for column in @columns

    if index >= @rows.length
      @rows.push row
    else
      @rows.splice index, 0, row

    @emitModifiedStatusChange()
    @emitter.emit 'did-add-row', {row, index}

    unless batch
      @emitter.emit 'did-change-rows', {
        oldRange: {start: index, end: index}
        newRange: {start: index, end: index+1}
      }

    if not batch and transaction
      @transaction
        undo: -> @removeRowAt(index, false, false)
        redo: -> @addRowAt(index, values, false, false)

    row

  addRows: (rows, transaction=true) ->
    @addRowsAt(@rows.length, rows, transaction)

  addRowsAt: (index, rows, transaction=true) ->
    throw new Error "Can't add rows to a destroyed table" if @isDestroyed()

    createdRows = rows.map (row,i) => @addRowAt(index+i, row, true)

    @emitter.emit 'did-change-rows', {
      oldRange: {start: index, end: index}
      newRange: {start: index, end: index+rows.length}
    }

    if transaction
      range = {start: index, end: index+rows.length}
      @transaction
        undo: -> @removeRowsInRange(range, false)
        redo: -> @addRowsAt(index, rows, false)

    createdRows

  removeRow: (row, batch=false, transaction=true) ->
    throw new Error "Can't remove an undefined row" unless row?

    @removeRowAt(@rows.indexOf(row), batch, transaction)

  removeRowAt: (index, batch=false, transaction=true) ->
    if index is -1 or index >= @rows.length
      throw new Error "Can't remove row at index #{index}"

    row = @rows[index]
    @rows.splice(index, 1)

    @emitModifiedStatusChange()
    @emitter.emit 'did-remove-row', {row, index}
    unless batch
      @emitter.emit 'did-change-rows', {
        oldRange: {start: index, end: index+1}
        newRange: {start: index, end: index}
      }

    if not batch and transaction
      values = row.concat()
      @transaction
        undo: -> @addRowAt(index, values, false, false)
        redo: -> @removeRowAt(index, false, false)

  removeRowsInRange: (range, transaction=true) ->
    range = @rowRangeFrom(range)

    removedRows = @rows.splice(range.start, range.end - range.start)

    for row,i in removedRows
      rowsValues = removedRows.slice() if transaction
      @emitter.emit 'did-remove-row', {row, index: range.start + i}

    @emitModifiedStatusChange()
    @emitter.emit 'did-change-rows', {
      oldRange: range
      newRange: {start: range.start, end: range.start}
    }

    if transaction
      @transaction
        undo: -> @addRowsAt(range.start, rowsValues, false)
        redo: -> @removeRowsInRange(range, false)

  removeRowsAtIndices: (indices, transaction=true) ->
    removedRows = (@rows[index] for index in indices).filter (row) -> row?

    @removeRow(row, true, false) for row in removedRows

    if transaction
      indices = indices.slice()
      @transaction
        undo: ->
          @addRowAt(index, removedRows[i], true, false) for index,i in indices
        redo: ->
          @removeRowsAtIndices(indices, false)

  extendExistingRows: (column, index) ->
    row.splice index, 0, undefined for row in @rows

  rowRangeFrom: (range) ->
    throw new Error "Can't remove rows with a range" unless range?

    range = {start: range[0], end: range[1]} if Array.isArray range

    unless range.start? and range.end?
      throw new Error "Invalid range #{range}"

    range.start = 0 if range.start < 0
    range.end = @getRowCount() if range.end > @getRowCount()

    range

  #     ######  ######## ##       ##        ######
  #    ##    ## ##       ##       ##       ##    ##
  #    ##       ##       ##       ##       ##
  #    ##       ######   ##       ##        ######
  #    ##       ##       ##       ##             ##
  #    ##    ## ##       ##       ##       ##    ##
  #     ######  ######## ######## ########  ######

  getCells: -> @rows.reduce ((cells, row) -> cells.concat row), []

  getCellCount: -> @rows.length * @columns.length

  getValueAtPosition: (position) ->
    unless position?
      throw new Error "Table::getValueAtPosition called without a position"

    position = Point.fromObject(position)
    @rows[position.row]?[position.column]

  setValueAtPosition: (position, value, transaction=true) ->
    unless position?
      throw new Error "Table::setValueAtPosition called without a position"
    if position.row < 0 or position.row >= @getRowCount() or position.column < 0 or position.column >= @getColumnCount()
      throw new Error "Table::setValueAtPosition called without an invalid position #{position}"

    position = Point.fromObject(position)
    oldValue = @rows[position.row]?[position.column]
    @rows[position.row]?[position.column] = value

    @emitModifiedStatusChange()
    @emitter.emit 'did-change-cell-value', {position, oldValue, newValue: value}

    if transaction
      @transaction
        undo: -> @setValueAtPosition(position, oldValue, false)
        redo: -> @setValueAtPosition(position, value, false)

  positionOfCell: (cell) ->
    unless cell?
      throw new Error "Table::positionOfCell called without a cell"

    row = @rows.indexOf(cell.row)
    column = cell.row.cells.indexOf(cell)

    {row, column}
