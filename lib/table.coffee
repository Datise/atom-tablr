{Model} = require 'theorist'
{Emitter, Disposable, CompositeDisposable} = require 'event-kit'

Column = require './column'
Row = require './row'
Cell = require './cell'

module.exports =
class Table extends Model
  constructor: (options={}) ->
    @columns = []
    @rows = []

  #     ######   #######  ##       ##     ## ##     ## ##    ##  ######
  #    ##    ## ##     ## ##       ##     ## ###   ### ###   ## ##    ##
  #    ##       ##     ## ##       ##     ## #### #### ####  ## ##
  #    ##       ##     ## ##       ##     ## ## ### ## ## ## ##  ######
  #    ##       ##     ## ##       ##     ## ##     ## ##  ####       ##
  #    ##    ## ##     ## ##       ##     ## ##     ## ##   ### ##    ##
  #     ######   #######  ########  #######  ##     ## ##    ##  ######

  getColumns: -> @columns

  getColumn: (index) -> @columns[index]

  getColumnNames: -> @columns.map (column) -> column.name

  getColumnsCount: -> @columns.length

  addColumn: (name, options={}) ->
    if name in @getColumnNames()
      throw new Error "Can't add column #{name} as one already exist"
    column = new Column {name, options}
    @columns.push column
    @extendExistingRows(column)
    column

  removeColumn: (column) ->
    throw new Error "Can't remove an undefined column" unless column?

    @removeColumnAt(@columns.indexOf(column))

  removeColumnAt: (index) ->
    if index is -1 or index >= @columns.length
      throw new Error "Can't remove column at index #{index}"

    @columns.splice(index, 1)
    row.removeCellAt(index) for row in @rows

  #    ########   #######  ##      ##  ######
  #    ##     ## ##     ## ##  ##  ## ##    ##
  #    ##     ## ##     ## ##  ##  ## ##
  #    ########  ##     ## ##  ##  ##  ######
  #    ##   ##   ##     ## ##  ##  ##       ##
  #    ##    ##  ##     ## ##  ##  ## ##    ##
  #    ##     ##  #######   ###  ###   ######

  getRows: -> @rows

  getRow: (index) -> @rows[0]

  getRowsCount: -> @rows.length

  addRow: (values) ->
    if @getColumns().length is 0
      throw new Error "Can't add rows to a table without column"

    cells = []

    if Array.isArray(values)
    else
      for column in @columns
        value = values[column.name]
        cell = new Cell {value, column}
        cells.push cell

    row = new Row {cells, table: this}
    @rows.push row
    row

  removeRow: (row) ->
    throw new Error "Can't remove an undefined row" unless row?

    @removeRowAt(@rows.indexOf(row))

  removeRowAt: (index) ->
    if index is -1 or index >= @rows.length
      throw new Error "Can't remove row at index #{index}"

    @rows.splice(index, 1)

  extendExistingRows: (column) ->
    row.addCell new Cell {column} for row in @rows


  #     ######  ######## ##       ##        ######
  #    ##    ## ##       ##       ##       ##    ##
  #    ##       ##       ##       ##       ##
  #    ##       ######   ##       ##        ######
  #    ##       ##       ##       ##             ##
  #    ##    ## ##       ##       ##       ##    ##
  #     ######  ######## ######## ########  ######

  getCells: ->
    cells = []
    @rows.forEach (row) -> cells = cells.concat(row.getCells())
    cells

  getCellsCount: -> @getCells().length
