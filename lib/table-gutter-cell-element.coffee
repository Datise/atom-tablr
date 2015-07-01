
module.exports =
class TableGutterCellElement extends HTMLElement
  setModel: ({row}) ->
    @released = false
    classes = @getGutterCellClasses(row)
    @textContent = row
    @className = classes.join(' ')
    @style.cssText = "
      height: #{@tableElement.getScreenRowHeightAt(row)}px;
      top: #{@tableElement.getScreenRowOffsetAt(row)}px;
    "

  isReleased: -> @released

  release: (dispatchEvent=true) ->
    return if @released
    @style.cssText = 'display: none;'
    @released = true

  getGutterCellClasses: (row) ->
    classes = []
    classes.push 'active-row' if @tableElement.isActiveRow(row)
    classes.push 'selected' if @tableElement.isSelectedRow(row)
    classes

module.exports = TableGutterCellElement = document.registerElement 'atom-table-gutter-cell', prototype: TableGutterCellElement.prototype
