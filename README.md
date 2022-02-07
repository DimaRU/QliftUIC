# Qlift-uic

## Description

qlift-uic takes a Qt5 user interface description file and compiles it to Swift code for use with QLift.
Splitted from main QLift repo. 

## USAGE

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

## Installation

#### Homebrew

Run the following command to install using [Homebrew](https://brew.sh/):

```console
$ brew install DimaRU/formulae/qlift-uic
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
