
# PsdKit Release Notes

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
