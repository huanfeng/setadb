# setadb

[中文](https://github.com/huanfeng/setadb/blob/main/README.md)|[English](https://github.com/huanfeng/setadb/blob/main/README.en.md)

A script to easily set ADB device environment variables

Works by modifying ANDROID_SERIAL variable

Supports Windows CMD/PowerShell, Linux bash (other shells untested)

## Instructions

### Windows

* Add this directory to the PATH environment variable
* Or copy setadb.bat (for CMD) / setadb.ps1 (for PowerShell) to a directory already in PATH
* In CMD/PowerShell, run `setadb` to use it

### Linux

* Add this directory to the PATH variable
* Run `source setadb` to use it
* Can add `alias setadb='source setadb'` to your config to simplify usage

### Usage

After running the command, it will output the list of connected devices. Select by number, or select 0 to clear.
