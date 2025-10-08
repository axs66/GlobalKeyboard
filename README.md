# KeyBoardModule

为 **键盘增强助手** 注册自定义快捷按钮的模块。

## ✨ 功能
- 动态注册自定义按钮
- 支持 SF Symbols 图标
- 自动加载到键盘工具栏
- 按钮动作由用户类定义

## 🧩 安装
1. 下载 `.deb` 并使用 Filza 或 Sileo 安装
2. 打开黄白键盘，查看新增按钮

## ⚙️ 开发者自定义
示例注册代码：
```objc
[[objc_getClass("KeyBoardButtonManager") sharedInstance]
    registerButtonWithId:@"hello"
                    title:@"Hello!"
                 iconName:@"heart.fill"
          targetClassName:@"MyNewKeyboardAction"
           selectorString:@"helloworld"
           defaultEnabled:YES];
