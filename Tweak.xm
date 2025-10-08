#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#pragma mark - KeyBoardButtonManager Interface (外部管理器)
@interface KeyBoardButtonManager : NSObject
+ (instancetype)sharedInstance;
- (void)registerButtonWithId:(NSString *)buttonId
                       title:(NSString *)title
                    iconName:(NSString *)iconName
             targetClassName:(NSString *)targetClassName
              selectorString:(NSString *)selectorString
              defaultEnabled:(BOOL)defaultEnabled;
@end


#pragma mark - MyNewKeyboardAction 实现
@interface MyNewKeyboardAction : NSObject
+ (instancetype)sharedInstance;
+ (void)showAlertWithMessage:(NSString *)message;
+ (void)helloworld;
+ (void)sendGreeting;
@end

@implementation MyNewKeyboardAction

+ (instancetype)sharedInstance {
    static MyNewKeyboardAction *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[MyNewKeyboardAction alloc] init];
    });
    return instance;
}

#pragma mark - 通用方法
// 获取最顶层控制器（兼容 iOS 15+）
+ (UIViewController *)topMostViewController {
    UIWindow *keyWindow = [UIApplication sharedApplication].windows.firstObject;
    if (!keyWindow) return nil;
    UIViewController *topController = keyWindow.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    return topController;
}

// 展示通用 Alert（带防重复机制）
+ (void)showAlertWithMessage:(NSString *)message {
    UIViewController *topVC = [self topMostViewController];
    if (!topVC) return;

    // 防止重复弹出
    if ([topVC.presentedViewController isKindOfClass:[UIAlertController class]]) {
        NSLog(@"[KeyBoardModule] 已有 Alert 弹出，忽略新弹窗");
        return;
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"好的"
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];
    [topVC presentViewController:alert animated:YES completion:nil];
}

#pragma mark - 自定义按钮动作
+ (void)helloworld {
    NSLog(@"[KeyBoardModule] 自定义按钮『你好按钮』被点击");
    [self showAlertWithMessage:@"自定义按钮被触发！"];
}

+ (void)sendGreeting {
    NSLog(@"[KeyBoardModule] 自定义按钮『发送问候』被点击");
    [self showAlertWithMessage:@"已发送问候！祝你开心！"];
}

@end


#pragma mark - 注册按钮逻辑
%ctor {
    static BOOL hasRegistered = NO;
    if (hasRegistered) {
        NSLog(@"[KeyBoardModule] 按钮已注册，跳过重复注册。");
        return;
    }
    hasRegistered = YES;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        NSLog(@"[KeyBoardModule] 开始向键盘注册自定义按钮...");

        KeyBoardButtonManager *manager = [objc_getClass("KeyBoardButtonManager") sharedInstance];
        if (!manager) {
            NSLog(@"[KeyBoardModule] ⚠️ KeyBoardButtonManager 类未找到！");
            return;
        }

        // 注册按钮 1
        [manager registerButtonWithId:@"myNewButton1"
                                title:@"你好按钮"
                             iconName:@"bubble.left.and.bubble.right.fill"
                      targetClassName:@"MyNewKeyboardAction"
                       selectorString:@"helloworld"
                       defaultEnabled:YES];

        // 注册按钮 2
        [manager registerButtonWithId:@"myNewButton2"
                                title:@"发送问候"
                             iconName:@"hand.wave"
                      targetClassName:@"MyNewKeyboardAction"
                       selectorString:@"sendGreeting"
                       defaultEnabled:NO];

        NSLog(@"[KeyBoardModule] ✅ 两个自定义按钮已注册完成。");
    });
}
