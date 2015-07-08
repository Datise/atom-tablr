{Point} = require 'atom'
Table = require '../lib/table'

describe 'Table', ->
  [table, row, column, spy] = []
  beforeEach ->
    table = new Table

  it 'has 0 columns', ->
    expect(table.getColumnsCount()).toEqual(0)

  it 'has 0 rows', ->
    expect(table.getRowsCount()).toEqual(0)

  it 'has 0 cells', ->
    expect(table.getCellsCount()).toEqual(0)

  describe 'adding a row on a table without columns', ->
    it 'raises an exception', ->
      expect(-> table.addRow {}).toThrow()

  #     ######   #######  ##       ##     ## ##     ## ##    ##  ######
  #    ##    ## ##     ## ##       ##     ## ###   ### ###   ## ##    ##
  #    ##       ##     ## ##       ##     ## #### #### ####  ## ##
  #    ##       ##     ## ##       ##     ## ## ### ## ## ## ##  ######
  #    ##       ##     ## ##       ##     ## ##     ## ##  ####       ##
  #    ##    ## ##     ## ##       ##     ## ##     ## ##   ### ##    ##
  #     ######   #######  ########  #######  ##     ## ##    ##  ######

  describe 'with columns added to the table', ->
    beforeEach ->
      table.addColumn('key')
      table.addColumn('value')

    it 'has 2 columns', ->
      expect(table.getColumnsCount()).toEqual(2)
      expect(table.getColumn(0)).toEqual('key')
      expect(table.getColumn(1)).toEqual('value')

    it 'raises an exception when adding a column whose name already exist in table', ->
      expect(-> table.addColumn('key')).toThrow()

    describe 'when there is already rows in the table', ->
      beforeEach ->
        table.addRow ['foo', 'bar']
        table.addRow ['oof', 'rab']

      describe 'adding a column', ->
        it 'extend all the rows with a new cell', ->
          table.addColumn 'required'

          expect(table.getRow(0).length).toEqual(3)

        it 'dispatches a did-add-column event', ->
          spy = jasmine.createSpy 'addColumn'

          table.onDidAddColumn spy
          table.addColumn 'required'

          expect(spy).toHaveBeenCalled()

      describe 'adding a column at a given index', ->
        beforeEach ->
          column = table.addColumnAt 1, 'required'

        it 'adds the column at the right place', ->
          expect(table.getColumnsCount()).toEqual(3)
          expect(table.getColumn(1)).toEqual('required')
          expect(table.getColumn(2)).toEqual('value')

        it 'extend the existing rows at the right place', ->
          expect(table.getRow(0).length).toEqual(3)
          expect(table.getRow(1).length).toEqual(3)

        it 'throws an error if the index is negative', ->
          expect(-> table.addColumnAt -1, 'foo').toThrow()

    describe 'removing a column', ->
      describe 'when there is alredy rows in the table', ->
        beforeEach ->
          spy = jasmine.createSpy 'removeColumn'

          table.addRow ['foo', 'bar']
          table.addRow ['oof', 'rab']

          table.onDidRemoveColumn spy
          table.removeColumn('value')

        it 'removes the column', ->
          expect(table.getColumnsCount()).toEqual(1)

        it 'dispatches a did-add-column event', ->
          expect(spy).toHaveBeenCalled()

        it 'removes the corresponding row cell', ->
          expect(table.getRow(0).length).toEqual(1)
          expect(table.getRow(1).length).toEqual(1)

      it 'throws an exception when the column is undefined', ->
        expect(-> table.removeColumn()).toThrow()

      it 'throws an error with a negative index', ->
        expect(-> table.removeColumnAt(-1)).toThrow()

      it 'throws an error with an index greater that the columns count', ->
        expect(-> table.removeColumnAt(2)).toThrow()

    describe 'changing a column name', ->
      beforeEach ->
        row = table.addRow ['foo', 'bar']
        table.addRow ['oof', 'rab']

        table.changeColumnName 'value', 'content'

      it 'changes the column name', ->
        expect(table.getColumn(1)).toEqual('content')

    #    ########   #######  ##      ##  ######
    #    ##     ## ##     ## ##  ##  ## ##    ##
    #    ##     ## ##     ## ##  ##  ## ##
    #    ########  ##     ## ##  ##  ##  ######
    #    ##   ##   ##     ## ##  ##  ##       ##
    #    ##    ##  ##     ## ##  ##  ## ##    ##
    #    ##     ##  #######   ###  ###   ######

    describe 'adding a row', ->
      describe 'with an object', ->
        it 'creates a row containing the values', ->
          table.addRow key: 'foo', value: 'bar'

          expect(table.getRowsCount()).toEqual(1)
          expect(table.getRow(0)).toEqual(['foo', 'bar'])

        it 'dispatches a did-add-row event', ->
          spy = jasmine.createSpy 'addRow'
          table.onDidAddRow spy
          table.addRow key: 'foo', value: 'bar'

          expect(spy).toHaveBeenCalled()

        it 'dispatches a did-change-rows event', ->
          spy = jasmine.createSpy 'changeRows'
          table.onDidChangeRows spy
          table.addRow key: 'foo', value: 'bar'

          expect(spy).toHaveBeenCalled()
          expect(spy.calls[0].args[0]).toEqual({
            oldRange: {start: 0, end: 0}
            newRange: {start: 0, end: 1}
          })

        it "fills the row with undefined values", ->
          row = table.addRow {}

          expect(row).toEqual(new Array(2))

        it 'ignores data that not match any column', ->
          row = table.addRow key: 'foo', data: 'fooo'

          expect(row).toEqual(['foo', undefined])

        describe 'at a specified index', ->
          beforeEach ->
            table.addRow key: 'foo', value: 'bar'
            table.addRow key: 'oof', value: 'rab'

          it 'inserts the row at the specified position', ->
            table.addRowAt(1, key: 'hello', value: 'world')

            expect(table.getRowsCount()).toEqual(3)
            expect(table.getRow(1)).toEqual(['hello','world'])

          it 'throws an error if the index is negative', ->
            expect(-> table.addRowAt -1, {}).toThrow()

          it 'dispatches a did-change-rows event', ->
            spy = jasmine.createSpy 'changeRows'
            table.onDidChangeRows spy
            table.addRowAt(1, key: 'hello', value: 'world')

            expect(spy).toHaveBeenCalled()
            expect(spy.calls[0].args[0]).toEqual({
              oldRange: {start: 1, end: 1}
              newRange: {start: 1, end: 2}
            })

      describe 'with an array', ->
        it 'creates a row with a cell for each value', ->
          table.addRow ['foo', 'bar']

          expect(table.getRowsCount()).toEqual(1)
          expect(table.getRow(0)).toEqual(['foo', 'bar'])

        it "fills the row with undefined values", ->
          row = table.addRow []

          expect(row).toEqual(new Array(2))

        describe 'at a specified index', ->
          beforeEach ->
            table.addRow ['foo', 'bar']
            table.addRow ['oof', 'rab']

          it 'inserts the row at the specified position', ->
            table.addRowAt(1, ['hello', 'world'])

            expect(table.getRowsCount()).toEqual(3)
            expect(table.getRow(1)).toEqual(['hello', 'world'])

    describe 'adding many rows', ->
      beforeEach ->
        spy = jasmine.createSpy 'changeRows'
        table.onDidChangeRows spy
        table.addRows [
          { key: 'foo', value: 'bar' }
          { key: 'oof', value: 'rab' }
        ]

      it 'adds the rows in the table', ->
        expect(table.getRowsCount()).toEqual(2)

      it 'dispatch only one did-change-rows event', ->
        expect(spy).toHaveBeenCalled()
        expect(spy.calls.length).toEqual(1)
        expect(spy.calls[0].args[0]).toEqual({
          oldRange: {start: 0, end: 0}
          newRange: {start: 0, end: 2}
        })

      describe 'at a given index', ->
        beforeEach ->
          spy = jasmine.createSpy 'changeRows'
          table.onDidChangeRows spy
          table.addRowsAt 1, [
            { key: 'foo', value: 'bar' }
            { key: 'oof', value: 'rab' }
          ]

        it 'adds the rows in the table', ->
          expect(table.getRowsCount()).toEqual(4)

        it 'dispatch only one did-change-rows event', ->
          expect(spy).toHaveBeenCalled()
          expect(spy.calls.length).toEqual(1)
          expect(spy.calls[0].args[0]).toEqual({
            oldRange: {start: 1, end: 1}
            newRange: {start: 1, end: 3}
          })

    describe 'removing a row', ->
      beforeEach ->
        spy = jasmine.createSpy 'removeRow'

        row = table.addRow key: 'foo', value: 'bar'
        table.addRow key: 'oof', value: 'rab'

        table.onDidRemoveRow spy

      it 'removes the row', ->
        table.removeRow(row)
        expect(table.getRowsCount()).toEqual(1)

      it 'dispatches a did-remove-row event', ->
        table.removeRow(row)
        expect(spy).toHaveBeenCalled()

      it 'dispatches a did-change-rows event', ->
        spy = jasmine.createSpy 'changeRows'
        table.onDidChangeRows spy
        table.removeRow(row)

        expect(spy).toHaveBeenCalled()
        expect(spy.calls[0].args[0]).toEqual({
          oldRange: {start: 0, end: 1}
          newRange: {start: 0, end: 0}
        })

      it 'throws an exception when the row is undefined', ->
        expect(-> table.removeRow()).toThrow()

      it 'throws an exception when the row is not in the table', ->
        expect(-> table.removeRow({})).toThrow()

      it 'throws an error with a negative index', ->
        expect(-> table.removeRowAt(-1)).toThrow()

      it 'throws an error with an index greater that the rows count', ->
        expect(-> table.removeRowAt(2)).toThrow()

    describe 'removing many rows', ->
      beforeEach ->
        table.addRow key: 'foo', value: 'bar'
        table.addRow key: 'oof', value: 'rab'
        table.addRow key: 'ofo', value: 'arb'

        spy = jasmine.createSpy 'removeRows'

        table.onDidChangeRows spy

      it 'removes the rows from the table', ->
        table.removeRowsInRange([0,2])
        expect(table.getRowsCount()).toEqual(1)
        expect(table.getRow(0)).toEqual(['ofo', 'arb'])

      it 'dispatches a single did-change-rows', ->
        table.removeRowsInRange([0,2])
        expect(spy).toHaveBeenCalled()
        expect(spy.calls.length).toEqual(1)
        expect(spy.calls[0].args[0]).toEqual({
          oldRange: {start: 0, end: 2}
          newRange: {start: 0, end: 0}
        })

      describe 'with a range running to infinity', ->
        it 'removes all the rows in the table', ->
          table.removeRowsInRange([0, Infinity])

          expect(table.getRowsCount()).toEqual(0)

    describe '::removeRowsInRange', ->
      it 'throws an error without range', ->
        expect(-> table.removeRowsInRange()).toThrow()

      it 'throws an error with an invalid range', ->
        expect(-> table.removeRowsInRange {start: 1}).toThrow()
        expect(-> table.removeRowsInRange [1]).toThrow()

  #     ######  ######## ##       ##        ######
  #    ##    ## ##       ##       ##       ##    ##
  #    ##       ##       ##       ##       ##
  #    ##       ######   ##       ##        ######
  #    ##       ##       ##       ##             ##
  #    ##    ## ##       ##       ##       ##    ##
  #     ######  ######## ######## ########  ######

  describe '::getValueAtPosition', ->
    beforeEach ->
      table.addColumn('name')
      table.addColumn('age')

      table.addRow(['John Doe', 30])
      table.addRow(['Jane Doe', 30])

    it 'returns the cell at the given position array', ->
      expect(table.getValueAtPosition([1,0])).toEqual('Jane Doe')

    it 'returns the cell at the given position object', ->
      expect(table.getValueAtPosition(row: 1, column: 0)).toEqual('Jane Doe')

    it 'throws an error without a position', ->
      expect(-> table.getValueAtPosition()).toThrow()

    it 'returns undefined with a position out of bounds', ->
      expect(table.getValueAtPosition(row: 2, column: 0)).toBeUndefined()
      expect(table.getValueAtPosition(row: 0, column: 2)).toBeUndefined()

  # FIXME we can't be find the position of a primitive value if there's
  # duplicates
  xdescribe '::positionOfCell', ->
    beforeEach ->
      table.addColumn('name')
      table.addColumn('age')

      table.addRow(['John Doe', 30])
      table.addRow(['Jane Doe', 30])

    it 'returns the position of the cell', ->
      cell = table.getValueAtPosition([1,1])

      expect(table.positionOfCell(cell)).toEqual(row: 1, column: 1)

    it 'throws an error without a cell', ->
      expect(-> table.positionOfCell()).toThrow()

  #    ##     ## ##    ## ########   #######
  #    ##     ## ###   ## ##     ## ##     ##
  #    ##     ## ####  ## ##     ## ##     ##
  #    ##     ## ## ## ## ##     ## ##     ##
  #    ##     ## ##  #### ##     ## ##     ##
  #    ##     ## ##   ### ##     ## ##     ##
  #     #######  ##    ## ########   #######

  describe 'transactions', ->
    it 'drops old transactions when reaching the size limit', ->
      Table.MAX_HISTORY_SIZE = 10

      table.addColumn('foo')

      table.addRow ["foo#{i}"] for i in [0...20]

      expect(table.undoStack.length).toEqual(10)

      table.undo()

      expect(table.getLastRow()).toEqual(['foo18'])

    it 'rolls back a column addition', ->
      table.addColumn('key')

      table.undo()

      expect(table.getColumnsCount()).toEqual(0)
      expect(table.undoStack.length).toEqual(0)
      expect(table.redoStack.length).toEqual(1)

      table.redo()

      expect(table.undoStack.length).toEqual(1)
      expect(table.redoStack.length).toEqual(0)
      expect(table.getColumnsCount()).toEqual(1)
      expect(table.getColumn(0)).toEqual('key')

    it 'rolls back a column deletion', ->
      column = table.addColumn('key')

      table.addRow(['foo'])
      table.addRow(['bar'])
      table.addRow(['baz'])
      table.clearUndoStack()

      table.removeColumn(column)

      table.undo()

      expect(table.getColumnsCount()).toEqual(1)
      expect(table.undoStack.length).toEqual(0)
      expect(table.redoStack.length).toEqual(1)
      expect(table.getColumn(0)).toEqual('key')
      expect(table.getRow(0)).toEqual(['foo'])
      expect(table.getRow(1)).toEqual(['bar'])
      expect(table.getRow(2)).toEqual(['baz'])

      table.redo()

      expect(table.undoStack.length).toEqual(1)
      expect(table.redoStack.length).toEqual(0)
      expect(table.getColumnsCount()).toEqual(0)

    describe 'with columns in the table', ->
      beforeEach ->
        table.addColumn('key')
        column = table.addColumn('value')

      it 'rolls back a row addition', ->
        table.clearUndoStack()

        row = table.addRow ['foo', 'bar']

        table.undo()

        expect(table.getRowsCount()).toEqual(0)
        expect(table.undoStack.length).toEqual(0)
        expect(table.redoStack.length).toEqual(1)

        table.redo()

        expect(table.undoStack.length).toEqual(1)
        expect(table.redoStack.length).toEqual(0)
        expect(table.getRowsCount()).toEqual(1)
        expect(table.getRow(0)).toEqual(['foo', 'bar'])

      it 'rolls back a batched rows addition', ->
        table.clearUndoStack()

        rows = table.addRows [
          ['foo', 'bar']
          ['bar', 'baz']
        ]

        table.undo()

        expect(table.getRowsCount()).toEqual(0)
        expect(table.undoStack.length).toEqual(0)
        expect(table.redoStack.length).toEqual(1)

        table.redo()

        expect(table.undoStack.length).toEqual(1)
        expect(table.redoStack.length).toEqual(0)
        expect(table.getRowsCount()).toEqual(2)
        expect(table.getRow(0)).toEqual(['foo', 'bar'])
        expect(table.getRow(1)).toEqual(['bar', 'baz'])

      it 'rolls back a row deletion', ->
        row = table.addRow ['foo', 'bar']

        table.clearUndoStack()

        table.removeRowAt(0)

        table.undo()

        expect(table.getRowsCount()).toEqual(1)
        expect(table.undoStack.length).toEqual(0)
        expect(table.redoStack.length).toEqual(1)
        expect(table.getRow(0)).toEqual(['foo', 'bar'])

        table.redo()

        expect(table.undoStack.length).toEqual(1)
        expect(table.redoStack.length).toEqual(0)
        expect(table.getRowsCount()).toEqual(0)

      it 'rolls back a batched rows deletion', ->
        table.addRows [
          ['foo', 'bar']
          ['bar', 'baz']
        ]

        table.clearUndoStack()

        table.removeRowsInRange([0,2])

        table.undo()

        expect(table.getRowsCount()).toEqual(2)
        expect(table.undoStack.length).toEqual(0)
        expect(table.redoStack.length).toEqual(1)
        expect(table.getRow(0)).toEqual(['foo', 'bar'])
        expect(table.getRow(1)).toEqual(['bar', 'baz'])

        table.redo()

        expect(table.undoStack.length).toEqual(1)
        expect(table.redoStack.length).toEqual(0)
        expect(table.getRowsCount()).toEqual(0)

      it 'rolls back a change in a column', ->
        table.clearUndoStack()

        table.changeColumnName('value', 'foo')

        table.undo()

        expect(table.getColumn(1)).toEqual('value')

        expect(table.undoStack.length).toEqual(0)
        expect(table.redoStack.length).toEqual(1)

        table.redo()

        expect(table.getColumn(1)).toEqual('foo')

        expect(table.undoStack.length).toEqual(1)
        expect(table.redoStack.length).toEqual(0)

      it 'rolls back a change in a row data', ->
        table.addRows [
          ['foo', 'bar']
          ['bar', 'baz']
        ]

        table.clearUndoStack()

        table.setValueAtPosition([0,0], 'hello')
        expect(table.getRow(0)).toEqual(['hello', 'bar'])

        table.undo()

        expect(table.undoStack.length).toEqual(0)
        expect(table.redoStack.length).toEqual(1)

        expect(table.getRow(0)).toEqual(['foo', 'bar'])

        table.redo()

        expect(table.undoStack.length).toEqual(1)
        expect(table.redoStack.length).toEqual(0)

        expect(table.getRow(0)).toEqual(['hello', 'bar'])

      xit 'rolls back a change in a row options', ->
        table.addRows [
          ['foo', 'bar']
          ['bar', 'baz']
        ]

        table.clearUndoStack()

        row = table.getRow(0)
        row.height = 100

        table.undo()

        expect(table.undoStack.length).toEqual(0)
        expect(table.redoStack.length).toEqual(1)

        expect(row.height).toEqual(undefined)

        table.redo()

        expect(table.undoStack.length).toEqual(1)
        expect(table.redoStack.length).toEqual(0)

        expect(row.height).toEqual(100)

      describe '::clearUndoStack', ->
        it 'removes all the transactions in the undo stack', ->
          table.addRows [
            ['foo', 'bar']
            ['bar', 'baz']
          ]

          table.setValueAtPosition([0, 0], 'hello')

          table.undo()

          table.clearUndoStack()

          expect(table.undoStack.length).toEqual(0)

      describe '::clearRedoStack', ->
        it 'removes all the transactions in the redo stack', ->
          table.addRows [
            ['foo', 'bar']
            ['bar', 'baz']
          ]

          table.setValueAtPosition([0, 0], 'hello')

          table.undo()

          table.clearRedoStack()

          expect(table.redoStack.length).toEqual(0)
