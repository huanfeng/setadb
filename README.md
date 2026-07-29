# setadb

[中文](https://github.com/huanfeng/setadb/blob/main/README.md)|[English](https://github.com/huanfeng/setadb/blob/main/README.en.md)

方便设置 ADB 设备环境变量的脚本

原理是修改 `ANDROID_SERIAL` 环境变量

支持 Windows 的 CMD/PowerShell, Linux/macOS 的 bash/zsh

## 安装

### Windows - Scoop (推荐)

```powershell
scoop bucket add huanfeng https://github.com/huanfeng/scoop-bucket
scoop install huanfeng/setadb
```

安装后:

* **CMD**: 直接输入 `setadb` 即可
* **PowerShell**: 需要执行一次下面的命令, 之后直接输入 `setadb` 即可

  ```powershell
  & "$(scoop prefix setadb)\install-profile.ps1"
  ```

  不装也能用, 只是每次要写全名 `setadb.ps1`。原因见[下方说明](#为什么-powershell-需要多一步)。

### Windows - 手动

* 将此目录添加到环境变量 `PATH` 中, 或把脚本复制到已在 `PATH` 中的目录
* **CMD**: 输入 `setadb`
* **PowerShell**: 输入 `setadb.ps1`, 或执行一次 `.\install-profile.ps1` 之后可直接用 `setadb`

### Linux / macOS

Linux 下**必须**用 `source` 的方式加载, 因为脚本要修改的是**你当前 Shell** 的环境变量,
而普通执行的脚本运行在子进程里, 进程一结束, 它设置的一切都随之消失。

推荐做法是把 `setadb.sh` 加入 Shell 配置, 得到一个 `setadb` 函数:

```bash
# bash
echo 'source "/path/to/setadb.sh"' >> ~/.bashrc && source ~/.bashrc

# zsh
echo 'source "/path/to/setadb.sh"' >> ~/.zshrc && source ~/.zshrc
```

之后直接输入 `setadb` 即可。

不想改配置时, 也可以临时使用:

```bash
source /path/to/setadb.sh && setadb
```

忘记了怎么装? 执行 `setadb --install` 会打印可直接粘贴的安装命令。
直接执行 `./setadb` 或 `./setadb.sh` 也会给出醒目提示, 而不是默默地什么都没做。

## 使用方法

不带参数时输出当前连接的设备列表, 按序号选择, 当前生效的设备前面有 `*` 标记:

```
ADB devices
-------------------
  0. [Clear]
  1. [2dd1deb9] device
* 2. [192.168.5.67:5555] device
-------------------
Please select:
```

也可以直接带参数, 跳过菜单:

| 命令 | 说明 |
| --- | --- |
| `setadb` | 显示菜单并交互选择 |
| `setadb 1` | 直接选择菜单中序号为 1 的设备 |
| `setadb 0` | 清空 (序号 0 固定为 Clear) |
| `setadb clear` / `setadb -c` | 清空 |
| `setadb 2dd1deb9` | 直接设置为指定的序列号 |
| `setadb list` / `setadb -l` | 只列出设备, 不做修改 |
| `setadb -s` | 显示当前的 `ANDROID_SERIAL` |
| `setadb -h` | 显示帮助 |

三个平台的参数完全一致。

## 为什么 PowerShell 需要多一步

在 PowerShell 中输入 `setadb`, 系统按 `PATHEXT` 顺序查找, **`.BAT` 排在 `.PS1` 前面**,
所以实际执行的是 `setadb.bat`。而 PowerShell 运行 `.bat` 会**新开一个 cmd.exe 进程**,
环境变量设置在那个马上就要退出的进程里, 对当前 PowerShell 毫无影响。

麻烦的是这种失败是"安静"的 —— 看起来设置成功了, 实际没有任何效果。
所以 `setadb.bat` 会检测这种情况并给出明确警告:

```
[setadb] WARNING: this cmd.exe exits immediately, so the setting is lost.
```

解决办法是定义一个**函数**: PowerShell 查找命令时函数的优先级高于任何外部程序,
这样 `setadb` 就会稳定地指向 `setadb.ps1`。`install-profile.ps1` 做的就是这件事
(可重复执行, 用 `-Uninstall` 移除)。

同理, Linux 下 `setadb` 也是一个 Shell 函数, 原因是一样的。

## 文件说明

| 文件 | 用途 |
| --- | --- |
| `setadb.bat` | Windows CMD 版本 |
| `setadb.ps1` | Windows PowerShell 版本 |
| `install-profile.ps1` | 把 `setadb` 函数写入 PowerShell `$PROFILE` |
| `setadb.sh` | Linux/macOS 版本, 供 `source` 加载, 定义 `setadb` 函数 |
| `setadb` | 兼容旧用法 `source setadb`, 内部加载 `setadb.sh` |

> `.gitattributes` 强制 `.bat`/`.ps1` 使用 CRLF 换行。
> 这不是风格问题: CMD 按字节偏移定位批处理标签, 一旦 `.bat` 变成 LF 换行,
> 里面所有的 `GOTO`/`CALL` 都会跳错位置, 脚本会以非常难查的方式出错。

## 发布 (维护者)

推送 `v*` 格式的 tag 会触发 GitHub Release 流程: 校验换行符 -> 打包 zip ->
发布 Release -> 通过 `repository_dispatch` 通知 `huanfeng/scoop-bucket` 自动更新 manifest。

首次发布前, 需要先把 `.github/scoop-bucket-manifest.json` 复制到
`scoop-bucket/bucket/setadb.json`。这是因为自动更新脚本只覆盖 `version`/`url`/`hash`,
其余字段原样保留 —— `env_add_path` 和 `notes` 必须先存在, 才能在后续更新中一直留存。
