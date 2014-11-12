React = require 'react-atom-fork'
{div} = require 'reactionary-atom-fork'

module.exports = React.createClass
  getInitialState: ->
    firstRow: 0
    lastRow: 0
    totalRows: 0
    rowHeight: 0
    columnsWidths: []
    columnsAligns: []

  render: ->
    {firstRow, lastRow, rowHeight, columnsWidths, columnsAligns} = @state
    {parentView} = @props

    rows = for row in [firstRow...lastRow]
      rowData = @props.table.getRow(row)
      cells = []

      rowData.eachCell (cell,i) ->

        classes = ['table-edit-cell']
        if parentView.isActiveCell(cell)
          classes.push 'active'
        else if parentView.isActiveColumn(i)
          classes.push 'active-column'

        cells.push new cell.column.componentClass({
          parentView
          row
          cell
          classes
          index: i
          columnWidth: columnsWidths[i]
          columnAlign: columnsAligns[i]
        })

      classes = ['table-edit-row']
      classes.push 'active-row' if parentView.isActiveRow(row)

      div {
        key: "row-#{row}"
        className: classes.join(' ')
        'data-row-id': row + 1
        style:
          height: "#{rowHeight}px"
          top: "#{row * rowHeight}px"
      }, cells

    div {
      className: 'table-edit-content'
      style:
        height: @getTableHeight()
    }, rows

  getTableHeight: ->
    @state.totalRows * @state.rowHeight
