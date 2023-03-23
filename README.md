# Qlift-uic

## Description

qlift-uic takes a Qt5 user interface description file and compiles it to Swift code for use with QLift.
Splitted from main QLift repo. 

## Use with Swift package manager plugin

Add dependency to your swift package manifest: 
```swift
    dependencies: [
        .package(url: "https://github.com/DimaRU/QliftUIC", branch: "master"),
    ],

```
Then add plugin to target declaration:
```swift
plugins: [
    .plugin(name: "QliftUICPlugin", package: "QliftUIC"),
]
```
and .ui files to your target. These files will be automatically converted to .swift during build process. 

This is the structure of an example client package of qlift-uic:

```
MyPackage
 ├ Package.swift
 └ Sources
    └ MyExe
       ├ MainWindow.ui
       └ main.swift
```

## Installation for use with command line

#### Homebrew

Run the following command to install using [Homebrew](https://brew.sh/):

```console
brew install DimaRU/formulae/qlift-uic
```

## Command line USAGE

```
USAGE: qlift-uic <file> ... [--verbose] [--code] [--localizable] [--strings] [--extension] [--output-directory <path>]

ARGUMENTS:
  <file>                  UI file to compile.

OPTIONS:
  -v, --verbose           Verbose output
  --code/--localizable/--strings/--extension
                          Output Behaviour (default: --code)
        Explanation:
        --code: Generate UI code
        --localizable: Generate localizable UI code
        --strings: Generate .strings files
        --extension: Generate localization resource accessor extension
  -o, --output-directory <path>
                          The output path for generated files.
        By default generated files written to current directory.
  --version               Show the version.
  -h, --help              Show help information.
 
```

## Build

Use swift package manager for build.

```console
git clone https://github.com/DimaRU/QliftUIC.git
cd QliftUIC
swift build
```

## Credits
Thanks to Andi Schulz (Longhanks)

Initially forked from [https://github.com/Longhanks/qlift]()
