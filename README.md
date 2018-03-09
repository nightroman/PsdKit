
# PsdKit

The module provides commands for the following scenarios:

- Data persistence via PowerShell data (psd1) files:
    - `ConvertTo-Psd` - Converts objects to psd1 strings.
    - `Import-Psd` - Imports objects from a psd1 file.

- Updates of psd1 files preserving comments and structure:
    - `Convert-PsdToXml` - Converts a psd1 string to PSD-XML.
    - `Convert-XmlToPsd` - Converts PSD-XML to a psd1 string.
    - `Export-PsdXml` - Exports PSD-XML to a psd1 file.
    - `Import-PsdXml` - Imports a psd1 file as PSD-XML.
    - `Get-PsdXml` - Gets node PowerShell data.
    - `Set-PsdXml` - Sets node PowerShell data.

For more details, see the online version of [about_PsdKit.help.txt](https://github.com/nightroman/PsdKit/blob/master/about_PsdKit.help.txt).

See also [Examples](https://github.com/nightroman/PsdKit/blob/master/Examples):

- [Build-Manifest.ps1] - Builds this module manifest automatically.
- [Update-PsdWebData.ps1] - Updates "web data islands" in psd1 files.

## How to install and get help

Install [PsdKit from PSGallery](https://www.powershellgallery.com/packages/PsdKit):

    Install-Module PsdKit

Import the module and get the conceptual help:

    Import-Module PsdKit
    help about_PsdKit

Get help for individual commands:

    help ConvertTo-Psd -Full

[Build-Manifest.ps1]: https://github.com/nightroman/PsdKit/blob/master/Examples/Build-Manifest.ps1
[Update-PsdWebData.ps1]: https://github.com/nightroman/PsdKit/blob/master/Examples/Update-PsdWebData.ps1
