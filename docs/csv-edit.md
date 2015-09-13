<img src='https://cdn.rawgit.com/abe33/atom-tablr/master/resources/logo.svg' width='146' height='50'>

## Edit A CSV File

This package provides a specific opener for `CSV` files that will allow you to choose between editing the file as text or with the table editor.

![CSV Opener](https://github.com/abe33/atom-tablr/blob/master/resources/csv-opener.png?raw=true)

As you can see in the screenshot above, there's a bunch of settings available before opening a file with the table editor. This is necessary as `CSV` isn't a [strictly defined format](https://en.wikipedia.org/wiki/Comma-separated_values) and delimiter and other options can't be guessed from the plain-text version. These settings aren't necessary when using the text editor mode but you can still set them, they'll be save for later use.

At the bottom of the panel lies the preview area. It displays a preview of the `.csv` file parsed using the current settings. If the file can't be parsed using the current configuration, a notice with the encountered error is displayed in place of the preview.

This panel will appear every time you open the same file using Atom open dialog or `fuzzy-finder`. You can check the `Remember my choice` checkbox to set once and for all how you want a file to be edited.

### CSV Settings

These settings are only used when using the `Table Editor` mode.

The [node-csv](https://github.com/wdavidw/node-csv) module is used to parse and serialize `.csv` files and so the settings available are mostly based on the ones supported by node-csv.

Setting|Description
---|---
`Row Delimiter`|The character used to separate each rows. By default it uses the `auto` mode that will use the typical newline of the host system.
`Column Delimiter`|The character used to separate each columns in a row. By default it uses a comma as delimiter.
`Quotes`|The character used to surround a field. Defaults to double quotes.
`Escape`|The character used to escape quotes in a quoted field. Defaults to a double quote.
`Comments`|The character used to differentiate comments from rows in the source. Defaults to a `#`.
`Trim`|How to treat space characters surrounding a field. By defaults they are not trimmed.
`Header`|If checked, the first row will be used to populate the table header. The header line will be also serialized along the rows on save.
`End Of File`|When checked, the file will always be saved with an extra empty line at the end.
`Quoted`|When checked, each field will be wrapped with the quote character on save.
`Skip Empty Lines`|When checked, the empty lines in the file will be ignored and no rows will be created for them.

As you probably noticed, many fields in the settings form have a `custom` option and an additional text input. This allow you to define your own values when they're not available in the predefined options. Starting to type in the text input will automatically set the option on `custom`, and removing all its content will make the setting come back to its default.

### Table Editor

![TableEditor](https://github.com/abe33/atom-tablr/blob/master/resources/table-editor.png?raw=true "In this screenshot the Header option was checked.")

Working with a table editor is done pretty much as you could expect. You can select one or many cells, edit them, copy/paste them and so on.

#### Multiple Selections

One big difference with other widespread spreadsheet editors is the use of multiple selections.

![Multiple selections](https://github.com/abe33/atom-tablr/blob/master/resources/multiple-selections.png?raw=true)

Tablr implements multiple selections using the same controls than those of a text editor. However, tables multiple selections behavior is different than in a text editor. Here are the main differences:

- Selections can intersect with other selections. In a text editor a range spans from the start character to the end one by including every lines between them and can be merged whenever two selections intersect. In a table, a range is a surface that group cells together and are merged only when one selection contains another one.<br/>![Intersecting selections](https://github.com/abe33/atom-tablr/blob/master/resources/iintersecting-selections.png?raw=true)
- When copying multiple selections from a table, each cell can be considered as a selection on its own. Various settings exist to allow you to alter this behavior to match your taste.
- When editing a selection you only edit the cell at the cursor position and not the whole selection. In the case of multiple selections, an edit will change the value of each cursor cells. Commands exist to move the cursors within their own selection.

#### Copy & Paste

Copy, cut and paste works within a table editor as well as from and to a text editor.
When copying from or pasting to a table, Tablr uses three data formats to support every source and targets:

From|To|Description
--|--|--
Table Editor|Table Editor|Each selection is stored as a two dimensions array, keeping information about the structure of the selection. On paste, each target selection will receive the content from the corresponding clipboard selection. If there is more targets than sources it will cycle through the sources when reaching the end. If there is more sources than targets, the extra sources will be ignored. When a target selection is smaller than the source, it gets expanded to match the source selection. When it's the source that is smaller, the copy will cycle in the source selection through each axis to fill the target selection.
Table Editor|Text Editor|Each selection is stored using the same format the text editor use for multiple selections. When a selection has many cells it will either use the format used when pasting to another context (using `\t` and `\n`) or it will create a selection for each cell when the `Treat Each Cell As A Selection When Pasting To A Buffer` setting is enabled.
Text Editor|Table Editor|
Table Editor|Other|Each selection will be serialized using a `\t` character to separate the columns and a `\n` character to separate each rows and selections.
Other|Table Editor|Each selected cell will be filled with the content of the clipboard.
