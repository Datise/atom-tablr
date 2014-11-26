{$} = require 'space-pen'

path = require 'path'

Table = require '../lib/table'
TableView = require '../lib/table-view'
Column = require '../lib/column'
Row = require '../lib/row'
Cell = require '../lib/cell'
CustomCellComponent = require './fixtures/custom-cell-component'
{mousedown, mousemove, mouseup, textInput} = require './helpers/events'

stylesheetPath = path.resolve __dirname, '..', 'stylesheets', 'table-edit.less'
stylesheet = atom.themes.loadStylesheet(stylesheetPath)

describe 'TableView', ->
  [tableView, table, nextAnimationFrame, noAnimationFrame, requestAnimationFrameSafe, styleNode, row, cells] = []

  beforeEach ->
    spyOn(window, "setInterval").andCallFake window.fakeSetInterval
    spyOn(window, "clearInterval").andCallFake window.fakeClearInterval

    noAnimationFrame = -> throw new Error('No animation frame requested')
    nextAnimationFrame = noAnimationFrame

    requestAnimationFrameSafe = window.requestAnimationFrame
    spyOn(window, 'requestAnimationFrame').andCallFake (fn) ->
      nextAnimationFrame = ->
        nextAnimationFrame = noAnimationFrame
        fn()

  beforeEach ->
    table = new Table
    table.addColumn 'key'
    table.addColumn 'value'
    table.addColumn 'foo'

    for i in [0...100]
      table.addRow [
        "row#{i}"
        i * 100
        if i % 2 is 0 then 'yes' else 'no'
      ]

    atom.config.set 'table-edit.rowHeight', 20
    atom.config.set 'table-edit.rowOverdraw', 10

    tableView = new TableView(table)

    styleNode = $('body').prepend("<style>
      #{stylesheet}

      .table-edit {
        height: 200px;
        width: 400px;
      }

      .table-edit-header {
        height: 27px;
      }

      .table-edit-row {
        border: 0;
      }

      .table-edit-cell {
        border: none;
        padding: 0;
      }
    </style>").find('style')

    $('body').prepend(tableView)
    tableView.onAttach()
    nextAnimationFrame()

  it 'holds a table', ->
    expect(tableView.table).toEqual(table)

  #     ######   #######  ##    ## ######## ######## ##    ## ########
  #    ##    ## ##     ## ###   ##    ##    ##       ###   ##    ##
  #    ##       ##     ## ####  ##    ##    ##       ####  ##    ##
  #    ##       ##     ## ## ## ##    ##    ######   ## ## ##    ##
  #    ##       ##     ## ##  ####    ##    ##       ##  ####    ##
  #    ##    ## ##     ## ##   ###    ##    ##       ##   ###    ##
  #     ######   #######  ##    ##    ##    ######## ##    ##    ##

  it 'has a scroll-view', ->
    expect(tableView.find('.scroll-view').length).toEqual(1)

  describe 'when not scrolled yet', ->
    it 'renders the lines at the top of the table', ->
      rows = tableView.find('.table-edit-row')
      expect(rows.length).toEqual(18)
      expect(rows.first().data('row-id')).toEqual(1)
      expect(rows.last().data('row-id')).toEqual(18)

    describe '::getFirstVisibleRow', ->
      it 'returns 0', ->
        expect(tableView.getFirstVisibleRow()).toEqual(0)

    describe '::getLastVisibleRow', ->
      it 'returns 8', ->
        expect(tableView.getLastVisibleRow()).toEqual(8)

  describe 'once rendered', ->
    beforeEach ->
      row = tableView.find('.table-edit-row').first()
      cells = row.find('.table-edit-cell')

    it 'has as many columns as the model row', ->
      expect(cells.length).toEqual(3)

    it 'renders undefined cells based on a config', ->
      atom.config.set('table-edit.undefinedDisplay', 'foo')

      tableView.getActiveCell().setValue(undefined)
      nextAnimationFrame()
      expect(cells.first().text()).toEqual('foo')

    it 'renders undefined cells based on the view property', ->
      tableView.undefinedDisplay = 'bar'
      atom.config.set('table-edit.undefinedDisplay', 'foo')

      tableView.getActiveCell().setValue(undefined)
      nextAnimationFrame()
      expect(cells.first().text()).toEqual('bar')


    describe 'without any columns layout data', ->
      it 'has cells that all have the same width', ->
        cells.each ->
          expect(@clientWidth).toBeCloseTo(tableView.width() / 3, -2)

    describe 'with a columns layout defined', ->
      describe 'with an array with enough values', ->
        it 'modifies the columns widths', ->
          tableView.setColumnsWidths([0.2, 0.3, 0.5])
          nextAnimationFrame()

          expect(cells.first().width()).toBeCloseTo(tableView.width() * 0.2, -2)
          expect(cells.eq(1).width()).toBeCloseTo(tableView.width() * 0.3, -2)
          expect(cells.last().width()).toBeCloseTo(tableView.width() * 0.5, -2)

      describe 'with an array with sparse values', ->
        it 'computes the other columns width', ->
          tableView.setColumnsWidths([0.2, null, 0.5])
          nextAnimationFrame()

          expect(cells.first().width()).toBeCloseTo(tableView.width() * 0.2, -2)
          expect(cells.eq(1).width()).toBeCloseTo(tableView.width() * 0.3, -2)
          expect(cells.last().width()).toBeCloseTo(tableView.width() * 0.5, -2)

      describe 'with an array with more than one missing value', ->
        it 'divides the rest width between the missing columns', ->
          tableView.setColumnsWidths([0.2])
          nextAnimationFrame()

          expect(cells.first().width()).toBeCloseTo(tableView.width() * 0.2, -2)
          expect(cells.eq(1).width()).toBeCloseTo(tableView.width() * 0.4, -2)
          expect(cells.last().width()).toBeCloseTo(tableView.width() * 0.4, -2)

      describe 'with an array whose sum is greater than 1', ->
        it 'divides the rest width between the missing columns', ->
          tableView.setColumnsWidths([0.5, 0.5, 1])
          nextAnimationFrame()

          expect(cells.first().width()).toBeCloseTo(tableView.width() * 0.25, -2)
          expect(cells.eq(1).width()).toBeCloseTo(tableView.width() * 0.25, -2)
          expect(cells.last().width()).toBeCloseTo(tableView.width() * 0.5, -2)

      describe 'with a sparse array whose sum is greater or equal than 1', ->
        it 'divides the rest width between the missing columns', ->
          tableView.setColumnsWidths([0.5, 0.5])
          nextAnimationFrame()

          expect(cells.first().width()).toBeCloseTo(tableView.width() * 0.25, -2)
          expect(cells.eq(1).width()).toBeCloseTo(tableView.width() * 0.25, -2)
          expect(cells.last().width()).toBeCloseTo(tableView.width() * 0.5, -2)

      describe "by setting the width on model's columns", ->
        it 'uses the columns data', ->
          table.getColumn(0).width = 0.2
          table.getColumn(1).width = 0.3

          nextAnimationFrame()

          expect(cells.first().width()).toBeCloseTo(tableView.width() * 0.2, -2)
          expect(cells.eq(1).width()).toBeCloseTo(tableView.width() * 0.3, -2)
          expect(cells.last().width()).toBeCloseTo(tableView.width() * 0.5, -2)

      describe "from both the model's columns and in the view", ->
        it 'uses the view data and fallback to the columns data if available', ->
          table.getColumn(0).width = 0.2
          table.getColumn(1).width = 0.3

          tableView.setColumnsWidths([0.8])
          nextAnimationFrame()

          expect(cells.first().width()).toBeCloseTo(tableView.width() * 0.8, -2)
          expect(cells.eq(1).width()).toBeCloseTo(tableView.width() * 0.1, -2)
          expect(cells.last().width()).toBeCloseTo(tableView.width() * 0.1, -2)

      describe 'with alignements defined in the columns models', ->
        it 'sets the cells text-alignement using the model data', ->
          table.getColumn(0).align = 'right'
          table.getColumn(1).align = 'center'

          nextAnimationFrame()

          expect(cells.first().css('text-align')).toEqual('right')
          expect(cells.eq(1).css('text-align')).toEqual('center')
          expect(cells.last().css('text-align')).toEqual('left')

      describe 'with alignements defined in the view', ->
        it 'sets the cells text-alignement with the view data', ->
          tableView.setColumnsAligns(['right', 'center'])
          nextAnimationFrame()

          expect(cells.first().css('text-align')).toEqual('right')
          expect(cells.eq(1).css('text-align')).toEqual('center')
          expect(cells.last().css('text-align')).toEqual('left')

      describe 'with both alignements defined on the view and models', ->
        it 'sets the cells text-alignement with the view data', ->
          table.getColumn(0).align = 'left'
          table.getColumn(1).align = 'right'
          table.getColumn(2).align = 'center'

          tableView.setColumnsAligns(['right', 'center'])
          nextAnimationFrame()

          expect(cells.first().css('text-align')).toEqual('right')
          expect(cells.eq(1).css('text-align')).toEqual('center')
          expect(cells.last().css('text-align')).toEqual('center')

    describe 'with a custom cell renderer defined on a column', ->
      it 'uses the provided renderer to render the columns cells', ->
        table.getColumn(2).componentClass = CustomCellComponent

        nextAnimationFrame()

        expect(tableView.find('.table-edit-row:first-child .table-edit-cell:last-child').text()).toEqual('foo: yes')

  describe 'when scrolled by 100px', ->
    beforeEach ->
      tableView.scrollTop(100)
      nextAnimationFrame()

    describe '::getFirstVisibleRow', ->
      it 'returns 5', ->
        expect(tableView.getFirstVisibleRow()).toEqual(5)

    describe '::getLastVisibleRow', ->
      it 'returns 13', ->
        expect(tableView.getLastVisibleRow()).toEqual(13)

    it 'translates the content by the amount of scroll', ->
      expect(tableView.find('.scroll-view').scrollTop()).toEqual(100)

    it 'does not render new rows', ->
      rows = tableView.find('.table-edit-row')
      expect(rows.length).toEqual(18)
      expect(rows.first().data('row-id')).toEqual(1)
      expect(rows.last().data('row-id')).toEqual(18)

  describe 'when scrolled by 300px', ->
    beforeEach ->
      tableView.scrollTop(300)
      nextAnimationFrame()

    describe '::getFirstVisibleRow', ->
      it 'returns 15', ->
        expect(tableView.getFirstVisibleRow()).toEqual(15)

    describe '::getLastVisibleRow', ->
      it 'returns 23', ->
        expect(tableView.getLastVisibleRow()).toEqual(23)

    it 'renders new rows', ->
      rows = tableView.find('.table-edit-row')
      expect(rows.length).toEqual(28)
      expect(rows.first().data('row-id')).toEqual(6)
      expect(rows.last().data('row-id')).toEqual(33)

  describe 'when the table rows are modified', ->
    describe 'by adding one at the end', ->
      it 'does not render new rows', ->
        table.addRow ['foo', 'bar', 'baz']

        nextAnimationFrame()

        rows = tableView.find('.table-edit-row')
        expect(rows.length).toEqual(18)
        expect(rows.first().data('row-id')).toEqual(1)
        expect(rows.last().data('row-id')).toEqual(18)

    describe 'by adding one at the begining', ->
      it 'updates the rows', ->
        rows = tableView.find('.table-edit-row')
        expect(rows.first().find('.table-edit-cell').first().text()).toEqual('row0')

        table.addRowAt 0, ['foo', 'bar', 'baz']

        nextAnimationFrame()

        rows = tableView.find('.table-edit-row')
        expect(rows.length).toEqual(18)
        expect(rows.first().data('row-id')).toEqual(1)
        expect(rows.first().find('.table-edit-cell').first().text()).toEqual('foo')
        expect(rows.last().data('row-id')).toEqual(18)

    describe 'by adding one in the middle', ->
      it 'updates the rows', ->
        rows = tableView.find('.table-edit-row')
        expect(rows.eq(6).find('.table-edit-cell').first().text()).toEqual('row6')

        table.addRowAt 6, ['foo', 'bar', 'baz']

        nextAnimationFrame()

        rows = tableView.find('.table-edit-row')
        expect(rows.length).toEqual(18)
        expect(rows.first().data('row-id')).toEqual(1)
        expect(rows.eq(6).find('.table-edit-cell').first().text()).toEqual('foo')
        expect(rows.last().data('row-id')).toEqual(18)

    describe 'by updating the content of a row', ->
      it 'update the rows', ->
        rows = tableView.find('.table-edit-row')
        expect(rows.eq(6).find('.table-edit-cell').first().text()).toEqual('row6')

        table.getRow(6).key = 'foo'

        nextAnimationFrame()

        rows = tableView.find('.table-edit-row')
        expect(rows.eq(6).find('.table-edit-cell').first().text()).toEqual('foo')

  describe 'setting a custom height for a row', ->
    beforeEach ->
      tableView.setRowHeightAt(2, 100)
      nextAnimationFrame()

    it 'sets the proper height on the table body content', ->
      bodyContent = tableView.find('.table-edit-content')

      expect(bodyContent.outerHeight()).toBeCloseTo(2080)

    it "renders the row's cells with the provided height", ->
      cells = tableView.find('.table-edit-row:nth-child(3) .table-edit-cell')

      expect(cells.first().outerHeight()).toEqual(100)

    it 'offsets the cells after the modified one', ->
      row = tableView.find('.table-edit-row:nth-child(4)')

      expect(row.css('top')).toEqual('140px')

    it 'activates the cell under the mouse when pressed', ->
      cell = tableView.find('.table-edit-row:nth-child(4) .table-edit-cell:nth-child(2)')
      offset = cell.offset()
      mousedown(cell, offset.left + 50, offset.top + 5)

      expect(tableView.getActiveCell().getValue()).toEqual(300)

    it 'gives the size of the cell to the editor when starting an edit', ->
      tableView.activateCellAtPosition(row: 2, column: 0)
      nextAnimationFrame()
      tableView.startEdit()

      expect(tableView.find('.editor').outerHeight()).toEqual(100)

    it 'uses the offset to position the editor', ->
      tableView.activateCellAtPosition(row: 3, column: 0)
      nextAnimationFrame()
      tableView.startEdit()

      expect(tableView.find('.editor').offset().top)
      .toBeCloseTo(tableView.find('.table-edit-cell.active').offset().top, -2)

    describe 'when scrolled by 300px', ->
      beforeEach ->
        tableView.scrollTop(300)
        nextAnimationFrame()

      it 'activates the cell under the mouse when pressed', ->
        cell = tableView.find('.table-edit-row[data-row-id=15] .table-edit-cell:nth-child(2)')
        offset = cell.offset()
        mousedown(cell, offset.left + 50, offset.top + 5)

        expect(tableView.getActiveCell().getValue()).toEqual(1400)

    describe 'when scrolled all way down to the bottom edge', ->
      beforeEach ->
        tableView.scrollTop(2000)
        nextAnimationFrame()

      it 'activates the cell under the mouse when pressed', ->
        cell = tableView.find('.table-edit-row:last-child .table-edit-cell:nth-child(2)')
        offset = cell.offset()
        mousedown(cell, offset.left + 50, offset.top + 5)

        expect(tableView.getActiveCell().getValue()).toEqual(9900)

  #    ##     ## ########    ###    ########  ######## ########
  #    ##     ## ##         ## ##   ##     ## ##       ##     ##
  #    ##     ## ##        ##   ##  ##     ## ##       ##     ##
  #    ######### ######   ##     ## ##     ## ######   ########
  #    ##     ## ##       ######### ##     ## ##       ##   ##
  #    ##     ## ##       ##     ## ##     ## ##       ##    ##
  #    ##     ## ######## ##     ## ########  ######## ##     ##

  it 'has a header', ->
    expect(tableView.find('.table-edit-header').length).toEqual(1)

  describe 'header', ->
    header = null

    beforeEach ->
      header = tableView.head

    it 'has as many cell as there is columns in the table', ->
      cells = tableView.find('.table-edit-header-cell')
      expect(cells.length).toEqual(3)
      expect(cells.first().text()).toEqual('key')
      expect(cells.eq(1).text()).toEqual('value')
      expect(cells.last().text()).toEqual('foo')

    it 'has cells that have the same width as the body cells', ->
      tableView.setColumnsWidths([0.2, 0.3, 0.5])
      nextAnimationFrame()

      cells = tableView.find('.table-edit-header-cell')
      rowCells = tableView.find('.table-edit-row:first-child .table-edit-cell')

      expect(cells.first().width()).toBeCloseTo(rowCells.first().width(), -2)
      expect(cells.eq(1).width()).toBeCloseTo(rowCells.eq(1).width(), -2)
      expect(cells.last().width()).toBeCloseTo(rowCells.last().width(), -2)

    describe 'when the gutter is enabled', ->
      beforeEach ->
        tableView.showGutter()
        nextAnimationFrame()

      it 'contains a filler div to figurate the gutter width', ->
        expect(header.find('.table-edit-header-filler').length).toEqual(1)

  #     ######   ##     ## ######## ######## ######## ########
  #    ##    ##  ##     ##    ##       ##    ##       ##     ##
  #    ##        ##     ##    ##       ##    ##       ##     ##
  #    ##   #### ##     ##    ##       ##    ######   ########
  #    ##    ##  ##     ##    ##       ##    ##       ##   ##
  #    ##    ##  ##     ##    ##       ##    ##       ##    ##
  #     ######    #######     ##       ##    ######## ##     ##

  describe 'gutter', ->
    it 'is rendered only when the flag is enabled', ->
      expect(tableView.find('.table-edit-gutter').length).toEqual(0)

      tableView.showGutter()
      nextAnimationFrame()

      expect(tableView.find('.table-edit-gutter').length).toEqual(1)

    describe 'rows numbers', ->
      [content, gutter] = []

      beforeEach ->
        tableView.showGutter()
        nextAnimationFrame()
        content = tableView.find('.table-edit-content')
        gutter = tableView.find('.table-edit-gutter')

      it 'contains a filler div to set the gutter width', ->
        expect(gutter.find('.table-edit-gutter-filler').length).toEqual(1)

      it 'matches the count of rows in the body', ->
        expect(gutter.find('.table-edit-row-number').length)
        .toEqual(content.find('.table-edit-row').length)

      describe 'when an editor is opened', ->
        [editor] = []

        beforeEach ->
          tableView.startEdit()
          editor = tableView.find('.editor').view()

        it 'opens a text editor above the active cell', ->
          cell = tableView.find('.table-edit-row:first-child .table-edit-cell:first-child')
          cellOffset = cell.offset()

          editorOffset = editor.offset()

          expect(editor.length).toEqual(1)
          expect(editorOffset.top).toBeCloseTo(cellOffset.top, -2)
          expect(editorOffset.left).toBeCloseTo(cellOffset.left, -2)
          expect(editor.outerWidth()).toBeCloseTo(cell.outerWidth(), -2)
          expect(editor.outerHeight()).toBeCloseTo(cell.outerHeight(), -2)

  #     ######   #######  ##    ## ######## ########   #######  ##
  #    ##    ## ##     ## ###   ##    ##    ##     ## ##     ## ##
  #    ##       ##     ## ####  ##    ##    ##     ## ##     ## ##
  #    ##       ##     ## ## ## ##    ##    ########  ##     ## ##
  #    ##       ##     ## ##  ####    ##    ##   ##   ##     ## ##
  #    ##    ## ##     ## ##   ###    ##    ##    ##  ##     ## ##
  #     ######   #######  ##    ##    ##    ##     ##  #######  ########

  it 'gains focus when mouse is pressed on the table view', ->
    tableView.mousedown()

    expect(tableView.hiddenInput.is(':focus')).toBeTruthy()

  it 'activates the cell under the mouse when pressed', ->
    cell = tableView.find('.table-edit-row:nth-child(4) .table-edit-cell:last-child')
    offset = cell.offset()
    mousedown(cell, offset.left + 50, offset.top + 5)

    expect(tableView.getActiveCell().getValue()).toEqual('no')

  it 'does not focus the hidden input twice when multiple press occurs', ->
    spyOn(tableView.hiddenInput, 'focus').andCallThrough()

    tableView.mousedown()
    tableView.mousedown()

    expect(tableView.hiddenInput.focus).toHaveBeenCalled()
    expect(tableView.hiddenInput.focus.calls.length).toEqual(1)
    expect(tableView.hiddenInput.is(':focus')).toBeTruthy()

  it 'has an active cell', ->
    activeCell = tableView.getActiveCell()
    expect(activeCell).toBeDefined()
    expect(activeCell.getValue()).toEqual('row0')

  it 'renders the active cell using a class', ->
    expect(tableView.find('.table-edit-header-cell.active-column').length).toEqual(1)
    expect(tableView.find('.table-edit-row.active-row').length).toEqual(1)
    expect(tableView.find('.table-edit-cell.active').length).toEqual(1)
    expect(tableView.find('.table-edit-cell.active-column').length)
    .toBeGreaterThan(1)

  describe '::moveRight', ->
    it 'requests an update', ->
      spyOn(tableView, 'requestUpdate')
      tableView.moveRight()

      expect(tableView.requestUpdate).toHaveBeenCalled()

    it 'attempts to make the active row visible', ->
      spyOn(tableView, 'makeRowVisible')
      tableView.moveRight()

      expect(tableView.makeRowVisible).toHaveBeenCalled()

    it 'is triggered on core:move-right', ->
      spyOn(tableView, 'moveRight')

      tableView.trigger('core:move-right')

      expect(tableView.moveRight).toHaveBeenCalled()

    it 'moves the active cell cursor to the right', ->
      tableView.moveRight()

      expect(tableView.getActiveCell().getValue()).toEqual(0)

      tableView.moveRight()

      expect(tableView.getActiveCell().getValue()).toEqual('yes')

    it 'moves the active cell to the next row when on last cell of a row', ->
      tableView.moveRight()
      tableView.moveRight()
      tableView.moveRight()
      expect(tableView.getActiveCell().getValue()).toEqual('row1')

    it 'moves the active cell to the first row when on last cell of last row', ->
      tableView.activeCellPosition.row = 99
      tableView.activeCellPosition.column = 2

      tableView.moveRight()
      expect(tableView.getActiveCell().getValue()).toEqual('row0')

  describe '::moveLeft', ->
    it 'requests an update', ->
      spyOn(tableView, 'requestUpdate')
      tableView.moveLeft()

      expect(tableView.requestUpdate).toHaveBeenCalled()

    it 'attempts to make the active row visible', ->
      spyOn(tableView, 'makeRowVisible')
      tableView.moveLeft()

      expect(tableView.makeRowVisible).toHaveBeenCalled()

    it 'is triggered on core:move-left', ->
      spyOn(tableView, 'moveLeft')

      tableView.trigger('core:move-left')

      expect(tableView.moveLeft).toHaveBeenCalled()

    it 'moves the active cell to the last cell when on the first cell', ->
      tableView.moveLeft()
      expect(tableView.getActiveCell().getValue()).toEqual('no')

    it 'moves the active cell cursor to the left', ->
      tableView.moveRight()
      tableView.moveLeft()
      expect(tableView.getActiveCell().getValue()).toEqual('row0')

    it 'moves the active cell cursor to the upper row', ->
      tableView.moveRight()
      tableView.moveRight()
      tableView.moveRight()
      tableView.moveLeft()
      expect(tableView.getActiveCell().getValue()).toEqual('yes')

  describe '::moveUp', ->
    it 'requests an update', ->
      spyOn(tableView, 'requestUpdate')
      tableView.moveUp()

      expect(tableView.requestUpdate).toHaveBeenCalled()

    it 'attempts to make the active row visible', ->
      spyOn(tableView, 'makeRowVisible')
      tableView.moveUp()

      expect(tableView.makeRowVisible).toHaveBeenCalled()

    it 'is triggered on core:move-up', ->
      spyOn(tableView, 'moveUp')

      tableView.trigger('core:move-up')

      expect(tableView.moveUp).toHaveBeenCalled()

    it 'moves the active cell to the last row when on the first row', ->
      tableView.moveUp()
      expect(tableView.getActiveCell().getValue()).toEqual('row99')

    it 'moves the active cell on the upper row', ->
      tableView.activeCellPosition.row = 10

      tableView.moveUp()
      expect(tableView.getActiveCell().getValue()).toEqual('row9')

  describe '::moveDown', ->
    it 'requests an update', ->
      spyOn(tableView, 'requestUpdate')
      tableView.moveDown()

      expect(tableView.requestUpdate).toHaveBeenCalled()

    it 'attempts to make the active row visible', ->
      spyOn(tableView, 'makeRowVisible')
      tableView.moveDown()

      expect(tableView.makeRowVisible).toHaveBeenCalled()

    it 'is triggered on core:move-down', ->
      spyOn(tableView, 'moveDown')

      tableView.trigger('core:move-down')

      expect(tableView.moveDown).toHaveBeenCalled()

    it 'moves the active cell to the row below', ->
      tableView.moveDown()
      expect(tableView.getActiveCell().getValue()).toEqual('row1')

    it 'moves the active cell to the first row when on the last row', ->
      tableView.activeCellPosition.row = 99

      tableView.moveDown()
      expect(tableView.getActiveCell().getValue()).toEqual('row0')

  describe '::makeRowVisible', ->
    it 'scrolls the view until the passed-on row become visible', ->
      tableView.makeRowVisible(50)

      expect(tableView.body.scrollTop()).toEqual(849)

  describe 'core:undo', ->
    it 'triggers an undo on the table', ->
      spyOn(table, 'undo')

      tableView.trigger('core:undo')

      expect(table.undo).toHaveBeenCalled()

  describe 'core:redo', ->
    it 'triggers an redo on the table', ->
      spyOn(table, 'redo')

      tableView.trigger('core:redo')

      expect(table.redo).toHaveBeenCalled()

  describe 'core:page-down', ->
    beforeEach ->
      atom.config.set 'table-edit.pageMovesAmount', 20

    it 'moves the active cell 20 rows below', ->
      tableView.trigger('core:page-down')

      expect(tableView.activeCellPosition.row).toEqual(20)

    it 'stops to the last row without looping', ->
      tableView.activeCellPosition.row = 90

      tableView.trigger('core:page-down')

      expect(tableView.activeCellPosition.row).toEqual(99)

    describe 'with a custom amount on the instance', ->
      it 'moves the active cell 30 rows below', ->
        tableView.pageMovesAmount = 30

        tableView.trigger('core:page-down')

        expect(tableView.activeCellPosition.row).toEqual(30)

      it 'keeps using its own amount even when the config change', ->
        tableView.pageMovesAmount = 30
        atom.config.set 'table-edit.pageMovesAmount', 50

        tableView.trigger('core:page-down')

        expect(tableView.activeCellPosition.row).toEqual(30)

  describe 'core:page-up', ->
    beforeEach ->
      atom.config.set 'table-edit.pageMovesAmount', 20

    it 'moves the active cell 20 rows up', ->
      tableView.activeCellPosition.row = 20

      tableView.trigger('core:page-up')

      expect(tableView.activeCellPosition.row).toEqual(0)

    it 'stops to the first cell without looping', ->
      tableView.activeCellPosition.row = 10

      tableView.trigger('core:page-up')

      expect(tableView.activeCellPosition.row).toEqual(0)

  describe 'core:move-to-top', ->
    beforeEach ->
      atom.config.set 'table-edit.pageMovesAmount', 20

    it 'moves the active cell to the first row', ->
      tableView.activeCellPosition.row = 50

      tableView.trigger('core:move-to-top')

      expect(tableView.activeCellPosition.row).toEqual(0)

  describe 'core:move-to-bottom', ->
    beforeEach ->
      atom.config.set 'table-edit.pageMovesAmount', 20

    it 'moves the active cell to the first row', ->
      tableView.activeCellPosition.row = 50

      tableView.trigger('core:move-to-bottom')

      expect(tableView.activeCellPosition.row).toEqual(99)

  #    ######## ########  #### ########
  #    ##       ##     ##  ##     ##
  #    ##       ##     ##  ##     ##
  #    ######   ##     ##  ##     ##
  #    ##       ##     ##  ##     ##
  #    ##       ##     ##  ##     ##
  #    ######## ########  ####    ##

  describe 'pressing a key when the table view has focus', ->
    beforeEach ->
      textInput(tableView.hiddenInput, 'x')

    it 'starts the edition of the active cell', ->
      expect(tableView.isEditing()).toBeTruthy()

    it 'fills the editor with the input data', ->
      editor = tableView.find('.editor').view()
      expect(editor.getText()).toEqual('x')

  describe 'double clicking on a cell', ->
    beforeEach ->
      cell = tableView.find('.table-edit-row:last-child .table-edit-cell:last-child')
      cell.trigger('dblclick')

    it 'starts the edition of the cell', ->
      expect(tableView.isEditing()).toBeTruthy()

  describe '::startEdit', ->
    [editor] = []

    beforeEach ->
      tableView.startEdit()
      editor = tableView.find('.editor').view()

    it 'opens a text editor above the active cell', ->
      cell = tableView.find('.table-edit-row:first-child .table-edit-cell:first-child')
      cellOffset = cell.offset()

      editorOffset = editor.offset()

      expect(editor.length).toEqual(1)
      expect(editorOffset.top).toBeCloseTo(cellOffset.top, -2)
      expect(editorOffset.left).toBeCloseTo(cellOffset.left, -2)
      expect(editor.outerWidth()).toBeCloseTo(cell.outerWidth(), -2)
      expect(editor.outerHeight()).toBeCloseTo(cell.outerHeight(), -2)

    it 'gives the focus to the editor', ->
      expect(editor.is('.is-focused')).toBeTruthy()

    it 'fills the editor with the cell value', ->
      expect(editor.getText()).toEqual('row0')

    it 'cleans the buffer history', ->
      expect(editor.getModel().getBuffer().history.undoStack.length).toEqual(0)
      expect(editor.getModel().getBuffer().history.redoStack.length).toEqual(0)

  describe '::stopEdit', ->
    beforeEach ->
      tableView.startEdit()
      tableView.stopEdit()

    it 'closes the editor', ->
      expect(tableView.isEditing()).toBeFalsy()
      expect(tableView.find('.editor:visible').length).toEqual(0)

    it 'gives the focus back to the table view', ->
      expect(tableView.hiddenInput.is(':focus')).toBeTruthy()

    it 'leaves the cell value as is', ->
      expect(tableView.getActiveCell().getValue()).toEqual('row0')

  describe 'with an editor opened', ->
    [editor] = []

    beforeEach ->
      tableView.startEdit()
      editor = tableView.find('.editor').view()

    describe 'core:cancel', ->
      it 'closes the editor', ->
        editor.trigger('core:cancel')
        expect(tableView.isEditing()).toBeFalsy

    describe 'table-edit:move-right', ->
      it 'confirms the current edit and moves the active cursor to the right', ->
        previousActiveCell = tableView.getActiveCell()
        spyOn(tableView, 'moveRight')
        editor.setText('Foo Bar')
        editor.trigger('table-edit:move-right')

        expect(tableView.isEditing()).toBeFalsy()
        expect(previousActiveCell.getValue()).toEqual('Foo Bar')
        expect(tableView.moveRight).toHaveBeenCalled()

    describe 'table-edit:move-left', ->
      it 'confirms the current edit and moves the active cursor to the left', ->
        previousActiveCell = tableView.getActiveCell()
        spyOn(tableView, 'moveLeft')
        editor.setText('Foo Bar')
        editor.trigger('table-edit:move-left')

        expect(tableView.isEditing()).toBeFalsy()
        expect(previousActiveCell.getValue()).toEqual('Foo Bar')
        expect(tableView.moveLeft).toHaveBeenCalled()

    describe 'core:confirm', ->
      describe 'when the content of the editor has changed', ->
        beforeEach ->
          editor.setText('foobar')
          editor.trigger('core:confirm')

        it 'closes the editor', ->
          expect(tableView.find('.editor:visible').length).toEqual(0)

        it 'gives the focus back to the table view', ->
          expect(tableView.hiddenInput.is(':focus')).toBeTruthy()

        it 'changes the cell value', ->
          expect(tableView.getActiveCell().getValue()).toEqual('foobar')

      describe 'when the content of the editor did not changed', ->
        beforeEach ->
          spyOn(tableView.getActiveCell(), 'setValue').andCallThrough()
          editor.trigger('core:confirm')

        it 'closes the editor', ->
          expect(tableView.find('.editor:visible').length).toEqual(0)

        it 'gives the focus back to the table view', ->
          expect(tableView.hiddenInput.is(':focus')).toBeTruthy()

        it 'leaves the cell value as is', ->
          expect(tableView.getActiveCell().getValue()).toEqual('row0')
          expect(tableView.getActiveCell().setValue).not.toHaveBeenCalled()

    describe 'clicking on another cell', ->
      beforeEach ->
        cell = tableView.find('.table-edit-row:nth-child(4) .table-edit-cell:last-child')
        offset = cell.offset()
        mousedown(cell, offset.left + 50, offset.top + 5)

      it 'closes the editor', ->
        expect(tableView.isEditing()).toBeFalsy()

  #     ######  ######## ##       ########  ######  ########
  #    ##    ## ##       ##       ##       ##    ##    ##
  #    ##       ##       ##       ##       ##          ##
  #     ######  ######   ##       ######   ##          ##
  #          ## ##       ##       ##       ##          ##
  #    ##    ## ##       ##       ##       ##    ##    ##
  #     ######  ######## ######## ########  ######     ##

  it 'has a selection', ->
    expect(tableView.getSelection()).toEqual([[0,0], [0,0]])

  describe 'selection', ->
    it 'follows the active cell when it moves', ->
      tableView.pageMovesAmount = 10
      tableView.pageDown()
      tableView.moveRight()

      expect(tableView.getSelection()).toEqual([[10,1], [10,1]])

    it 'can spans on several rows and columns', ->
      tableView.setSelection([[2,0],[3,2]])

      expect(tableView.getSelection()).toEqual([[2,0],[3,2]])

    it 'marks the cells covered by the selection with a selected class', ->
      tableView.setSelection([[2,0],[3,2]])

      nextAnimationFrame()

      expect(tableView.find('.selected').length).toEqual(6)

    it 'marks the row number with a selected class', ->
      tableView.showGutter()
      tableView.setSelection([[2,0],[3,2]])

      nextAnimationFrame()

      expect(tableView.find('.table-edit-row-number.selected').length).toEqual(2)

  describe '::setSelection', ->
    it 'change the active cell so that the upper left cell is active', ->
      tableView.setSelection([[4,0],[6,2]])

      expect(tableView.activeCellPosition).toEqual([4,0])

  describe '::selectionSpansManyCells', ->
    it 'returns true when the selection as at least two cells', ->
      tableView.setSelection([[4,0],[6,2]])

      expect(tableView.selectionSpansManyCells()).toBeTruthy()

  describe 'core:select-right', ->
    it 'expands the selection by one cell on the right', ->
      tableView.trigger('core:select-right')
      expect(tableView.getSelection()).toEqual([[0,0],[0,1]])

    it 'stops at the last column', ->
      tableView.trigger('core:select-right')
      tableView.trigger('core:select-right')
      tableView.trigger('core:select-right')

      expect(tableView.getSelection()).toEqual([[0,0],[0,2]])

    describe 'then triggering core:select-left', ->
      it 'collapse the selection back to the left', ->
        tableView.activateCellAtPosition([0,1])

        tableView.trigger('core:select-right')
        tableView.trigger('core:select-left')

        expect(tableView.getSelection()).toEqual([[0,1],[0,1]])

  describe 'core:select-left', ->
    beforeEach ->
      tableView.activateCellAtPosition([0,2])

    it 'expands the selection by one cell on the left', ->
      tableView.trigger('core:select-left')
      expect(tableView.getSelection()).toEqual([[0,1],[0,2]])

    it 'stops at the first column', ->
      tableView.trigger('core:select-left')
      tableView.trigger('core:select-left')
      tableView.trigger('core:select-left')
      expect(tableView.getSelection()).toEqual([[0,0],[0,2]])

    describe 'then triggering core:select-right', ->
      it 'collapse the selection back to the right', ->
        tableView.activateCellAtPosition([0,1])

        tableView.trigger('core:select-left')
        tableView.trigger('core:select-right')

        expect(tableView.getSelection()).toEqual([[0,1],[0,1]])

  describe 'core:select-up', ->
    beforeEach ->
      tableView.activateCellAtPosition([2,0])

    it 'expands the selection by one cell to the top', ->
      tableView.trigger('core:select-up')
      expect(tableView.getSelection()).toEqual([[1,0],[2,0]])

    it 'stops at the first row', ->
      tableView.trigger('core:select-up')
      tableView.trigger('core:select-up')
      tableView.trigger('core:select-up')
      expect(tableView.getSelection()).toEqual([[0,0],[2,0]])

    it 'scrolls the view to make the added row visible', ->
      tableView.scrollTop(200)
      tableView.activateCellAtPosition([10,0])

      tableView.trigger('core:select-up')

      expect(tableView.body.scrollTop()).toEqual(180)

    describe 'then triggering core:select-down', ->
      it 'collapse the selection back to the bottom', ->
        tableView.activateCellAtPosition([1,0])

        tableView.trigger('core:select-up')
        tableView.trigger('core:select-down')

        expect(tableView.getSelection()).toEqual([[1,0],[1,0]])

  describe 'core:select-down', ->
    beforeEach ->
      tableView.activateCellAtPosition([97,0])

    it 'expands the selection by one cell to the bottom', ->
      tableView.trigger('core:select-down')
      expect(tableView.getSelection()).toEqual([[97,0],[98,0]])

    it 'stops at the last row', ->
      tableView.trigger('core:select-down')
      tableView.trigger('core:select-down')
      tableView.trigger('core:select-down')
      expect(tableView.getSelection()).toEqual([[97,0],[99,0]])

    it 'scrolls the view to make the added row visible', ->
      tableView.activateCellAtPosition([8,0])

      tableView.trigger('core:select-down')

      expect(tableView.body.scrollTop()).not.toEqual(0)

    describe 'then triggering core:select-up', ->
      it 'collapse the selection back to the bottom', ->
        tableView.activateCellAtPosition([1,0])

        tableView.trigger('core:select-down')
        tableView.trigger('core:select-up')

        expect(tableView.getSelection()).toEqual([[1,0],[1,0]])

  describe 'table-edit:select-to-end-of-line', ->
    it 'expands the selection to the end of the current row', ->
      tableView.trigger('table-edit:select-to-end-of-line')

      expect(tableView.getSelection()).toEqual([[0,0],[0,2]])

    describe 'then triggering table-edit:select-to-beginning-of-line', ->
      it 'expands the selection to the beginning of the current row', ->
        tableView.activateCellAtPosition([0,1])

        tableView.trigger('table-edit:select-to-end-of-line')
        tableView.trigger('table-edit:select-to-beginning-of-line')

        expect(tableView.getSelection()).toEqual([[0,0],[0,1]])

  describe 'table-edit:select-to-beginning-of-line', ->
    it 'expands the selection to the beginning of the current row', ->
      tableView.activateCellAtPosition([0,2])

      tableView.trigger('table-edit:select-to-beginning-of-line')

      expect(tableView.getSelection()).toEqual([[0,0],[0,2]])

    describe 'table-edit:select-to-end-of-line', ->
      it 'expands the selection to the end of the current row', ->
        tableView.activateCellAtPosition([0,1])

        tableView.trigger('table-edit:select-to-beginning-of-line')
        tableView.trigger('table-edit:select-to-end-of-line')

        expect(tableView.getSelection()).toEqual([[0,1],[0,2]])

  describe 'table-edit:select-to-end-of-table', ->
    it 'expands the selection to the end of the table', ->
      tableView.trigger('table-edit:select-to-end-of-table')

      expect(tableView.getSelection()).toEqual([[0,0],[99,0]])

    it 'scrolls the view to make the added row visible', ->
      tableView.trigger('table-edit:select-to-end-of-table')

      expect(tableView.body.scrollTop()).not.toEqual(0)

    describe 'then triggering table-edit:select-to-beginning-of-table', ->
      it 'expands the selection to the beginning of the table', ->
        tableView.activateCellAtPosition([1,0])

        tableView.trigger('table-edit:select-to-end-of-table')
        tableView.trigger('table-edit:select-to-beginning-of-table')

        expect(tableView.getSelection()).toEqual([[0,0],[1,0]])

  describe 'table-edit:select-to-beginning-of-table', ->
    it 'expands the selection to the beginning of the table', ->
      tableView.activateCellAtPosition([2,0])

      tableView.trigger('table-edit:select-to-beginning-of-table')

      expect(tableView.getSelection()).toEqual([[0,0],[2,0]])

    it 'scrolls the view to make the added row visible', ->
      tableView.activateCellAtPosition([99,0])

      tableView.trigger('table-edit:select-to-beginning-of-table')

      expect(tableView.body.scrollTop()).toEqual(0)

    describe 'table-edit:select-to-end-of-table', ->
      it 'expands the selection to the end of the table', ->
        tableView.activateCellAtPosition([1,0])

        tableView.trigger('table-edit:select-to-beginning-of-table')
        tableView.trigger('table-edit:select-to-end-of-table')

        expect(tableView.getSelection()).toEqual([[1,0],[99,0]])

  describe 'dragging the mouse pressed over cell', ->
    it 'creates a selection with the cells from the mouse movements', ->
      startCell = tableView.find('.table-edit-row:nth-child(4) .table-edit-cell:nth-child(1)')
      endCell = tableView.find('.table-edit-row:nth-child(7) .table-edit-cell:nth-child(3)')
      startOffset = startCell.offset()
      endOffset = endCell.offset()

      mousedown(startCell, startOffset.left + 50, startOffset.top + 5)
      mousemove(endCell, endOffset.left + 50, endOffset.top + 5)

      expect(tableView.getSelection()).toEqual([[3,0],[6,2]])

      mousedown(endCell, endOffset.left + 50, endOffset.top + 5)
      mousemove(startCell, startOffset.left + 50, startOffset.top + 5)

      expect(tableView.getSelection()).toEqual([[3,0],[6,2]])

  #     ######   #######  ########  ######## #### ##    ##  ######
  #    ##    ## ##     ## ##     ##    ##     ##  ###   ## ##    ##
  #    ##       ##     ## ##     ##    ##     ##  ####  ## ##
  #     ######  ##     ## ########     ##     ##  ## ## ## ##   ####
  #          ## ##     ## ##   ##      ##     ##  ##  #### ##    ##
  #    ##    ## ##     ## ##    ##     ##     ##  ##   ### ##    ##
  #     ######   #######  ##     ##    ##    #### ##    ##  ######

  describe 'sorting', ->
    describe 'when a column have been set as the table order', ->
      beforeEach ->
        tableView.sortBy 'value', -1
        nextAnimationFrame()

      it 'sorts the rows accordingly', ->
        expect(tableView.find('.table-edit-row:first-child .table-edit-cell:first-child').text()).toEqual('row99')

      it 'leaves the active cell position as it was before', ->
        expect(tableView.activeCellPosition).toEqual([0,0])
        expect(tableView.getActiveCell()).toEqual(table.cellAtPosition([99,0]))

    describe 'opening an editor', ->
      beforeEach ->
        tableView.startEdit()

      it 'opens the editor at the cell position', ->
        editorOffset = tableView.find('.editor').offset()
        cellOffset = tableView.find('.table-edit-row:first-child .table-edit-cell:first-child').offset()

        expect(editorOffset.top).toBeCloseTo(cellOffset.top, -1)
        expect(editorOffset.left).toBeCloseTo(cellOffset.left, -1)

  afterEach ->
    window.requestAnimationFrame = requestAnimationFrameSafe
    styleNode.remove()
    tableView.destroy()
