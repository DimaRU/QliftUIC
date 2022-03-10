# Qlift-uic

## Description

qlift-uic takes a Qt5 user interface description file and compiles it to Swift code for use with QLift.
Splitted from main QLift repo. 

## Use with Swift package manager plugin

Add dependency to your swift package manifest: 
```swift
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
    ],

```
Then add plugin to target declaration:
```swift
.plugin(name: "QliftUICPlugin", capability: .buildTool(), dependencies: ["qlift-uic"])
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
USAGE: qlift-uic [<file> ...] [--verbose] [--output-directory <path>]

ARGUMENTS:
  <file>                  UI file to compile.

OPTIONS:
  -v, --verbose           Verbose output
  -o, --output-directory <path>
                          The the output path to write generated .swift files.
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
