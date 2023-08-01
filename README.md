# setadb

[中文](https://github.com/huanfeng/setadb/blob/main/README.md)|[English](https://github.com/huanfeng/setadb/blob/main/README.en.md)

方便设置ADB的设备环境变量的脚本

原理是修改 ANDROID_SERIAL 环境变量

支持 Windows 的 CMD/PowerShell, Linux bash (其它 Shell 未测试)

## 说明

### Windows

* 添加此目录到环境变量 PATH 中
* 或将 setadb.bat (适用于CMD) / setadb.ps1 (适用于PowerShell) 复制到已经添加到环境变量的目录中
* 在CMD/PowerShell 中, 输入 `setadb` 来使用

### Linux

* 将此目录添加到 PATH 变量中
* 使用 `source setadb` 来使用
* 可以在用户配置中增加 `alias setadb='source setadb'` 来简化使用

### 使用方法

输入命令后会输出当前连接的设备列表, 按序号进行选择, 如果想清空, 选择0
