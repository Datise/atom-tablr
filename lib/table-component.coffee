React = require 'react-atom-fork'
{div} = require 'reactionary-atom-fork'

module.exports = React.createClass
  getInitialState: ->
    firstRow: 0
    lastRow: 0
    totalRows: 0
    rowHeight: 0
    columnsWidths: []

  render: ->
    {firstRow, lastRow, rowHeight, columnsWidths} = @state

    rows = for row in [firstRow...lastRow]
      rowData = @props.table.getRow(row)
      columns = []
      rowData.eachCell (cell,i) ->
        columns.push div {
          key: "cell-#{row}-#{i}"
          className: 'table-edit-column'
          style:
            width: columnsWidths[i]
        }, cell.getValue()

      div {
        key: "row-#{row}"
        className: 'table-edit-row'
        'data-row-id': row + 1
        style:
          height: "#{rowHeight}px"
          top: "#{row * rowHeight}px"
      }, columns

    div {
      className: 'table-edit-content'
      style:
        height: @getTableHeight()
    }, rows

  getTableHeight: ->
    @state.totalRows * @state.rowHeight
