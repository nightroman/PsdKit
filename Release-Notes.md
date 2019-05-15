
# PsdKit Release Notes

## v0.5.1

`Import-Psd` - new parameter `MergeInto`, #7.

## v0.5.0

- `ConvertTo-Psd`
    - With Depth, convert complex items to surrogates `item_<n> = @{Key = .. Value = ..}`
- `Get-Psd`
    - Support hex number notation.

## v0.4.0

- Rename `Get-PsdXml` to `Get-Psd`, `Set-PsdXml` to `Set-Psd`.
- `Get-Psd`
    - Skip non-data nodes like comments, commas, ...
    - Treat document and root nodes, too.

## v0.3.0

- Convert any objects if the new parameter `Depth` is used, #4.
- Improve conversion of collections, support `IEnumerable`.
- Add *Examples/StronglyTypedData.ps1*.

## v0.2.0

- Amend import/export of strings, #3.
- Add *Examples/Build-Manifest.ps1*.
- Export `System.Uri` as string.
- Export `DBNull` as `$null`.

## v0.1.0

- `ConvertTo-Psd`
    - write `Guid` and `Version` as strings
    - throw on `DBNull`, to be continued
- Add *Examples/Update-PsdWebData.ps1*.

## v0.0.3

- Fix #1 (for now, write enums as strings)
- Treat `SwitchParameter` as Boolean.

## v0.0.2

- Do not sort dictionary keys in `ConvertTo-Psd`.
- Fix parameter positions in help.

## v0.0.1

Initial release.
