_ = require 'underscore-plus'
fs = require 'fs'
csv = require 'csv'
path = require 'path'
{CompositeDisposable, Emitter} = require 'atom'
TableEditor = require './table-editor'

module.exports =
class CSVEditor
  @tableEditorForPath: {}

  constructor: (@uriToOpen, @options={}, @choice) ->
    @subscriptions = new CompositeDisposable
    @emitter = new Emitter

  getTitle: ->
    if sessionPath = @getPath()
      path.basename(sessionPath)
    else
      'untitled'

  getLongTitle: ->
    if sessionPath = @getPath()
      fileName = path.basename(sessionPath)
      directory = atom.project.relativize(path.dirname(sessionPath))
      directory = if directory.length > 0 then directory else path.basename(path.dirname(sessionPath))
      "#{fileName} - #{directory}"
    else
      'untitled'

  getPath: -> @uriToOpen

  getURI: -> @uriToOpen

  isDestroyed: -> @destroyed

  isModified: -> @editor?.isModified() ? false

  copy: -> new CSVEditor(@uriToOpen, _.clone(@options), @choice)

  shouldPromptToSave: (options) ->
    @editor?.shouldPromptToSave(options) ? false

  onDidOpen: (callback) ->
    @emitter.on 'did-open', callback

  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy', callback

  onDidChangeModified: (callback) ->
    @emitter.on 'did-change-modified', callback

  applyChoice: ->
    if @choice?
      switch @choice
        when 'TextEditor' then @openTextEditor(@options)
        when 'TableEditor' then @openTableEditor(@options)

  openTextEditor: (@options={}) ->
    atom.project.open(@uriToOpen).then (editor) =>
      pane = atom.workspace.paneForItem(this)
      @emitter.emit('did-open', {editor, options: _.clone(@options)})
      @destroy()

      pane.activateItem(editor)

  openTableEditor: (@options={}) ->
    @openCSV().then (@editor) =>
      @subscriptions.add @editor.onDidChangeModified (status) =>
        @emitter.emit 'did-change-modified', status

      @emitter.emit('did-open', {@editor, options: _.clone(options)})
      @editor

  destroy: ->
    return if @destroyed

    @editor?.destroy()
    @destroyed = true
    @emitter.emit('did-destroy', this)
    @emitter.dispose()

  openCSV: ->
    new Promise (resolve, reject) =>
      if CSVEditor.tableEditorForPath[@uriToOpen]?
        tableEditor = new TableEditor(table: CSVEditor.tableEditorForPath[@uriToOpen].getTable())
        resolve(tableEditor)
      else
        fileContent = fs.readFileSync(@uriToOpen)
        options = _.clone(@options)

        csv.parse String(fileContent), options, (err, data) =>
          return reject(err) if err?

          tableEditor = new TableEditor
          return resolve(tableEditor) if data.length is 0
          tableEditor.lockModifiedStatus()

          if @options.header
            for column in data.shift()
              tableEditor.addColumn(column, {}, false)
          else
            for i in [0...data[0].length]
              tableEditor.addColumn(tableEditor.getColumnName(i), {}, false)

          tableEditor.addRows(data)
          tableEditor.setSaveHandler(@save)
          tableEditor.initializeAfterOpen()
          tableEditor.unlockModifiedStatus()

          CSVEditor.tableEditorForPath[@uriToOpen] = tableEditor
          resolve(tableEditor)

  previewCSV: (options) ->
    new Promise (resolve, reject) =>
      input = fs.createReadStream(@uriToOpen)
      parser = csv.parse(options)
      output = []

      limit = 5
      limit = 6 if options.header

      stop = ->
        input.unpipe(parser)
        parser.end()
        resolve(output[0...limit])

      read = ->
        output.push record while record = parser.read()
        stop() if output.length > limit

      end = ->
        resolve(output)

      error = (err) -> reject(err)

      parser.on 'readable', read
      parser.on 'end', end
      parser.on 'error', error

      input.pipe(parser)

  save: =>
    @saveAs(@getPath())

  saveAs: (path) ->
    new Promise (resolve, reject) =>
      options = _.clone(@options)
      options.columns = @editor.getColumns() if options.header

      csv.stringify @editor.getTable().getRows(), options, (err, data) =>
        return reject(err) if err?

        fs.writeFile path, data, (err) =>
          return reject(err) if err?
          resolve()
