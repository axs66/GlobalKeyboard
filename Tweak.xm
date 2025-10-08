#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#pragma mark - KeyBoardButtonManager Interface
@interface KeyBoardButtonManager : NSObject
+ (instancetype)sharedInstance;
- (void)registerButtonWithId:(NSString *)buttonId
                       title:(NSString *)title
                    iconName:(NSString *)iconName
             targetClassName:(NSString *)targetClassName
              selectorString:(NSString *)selectorString
              defaultEnabled:(BOOL)defaultEnabled;
@end


#pragma mark - MyNewKeyboardAction
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

#pragma mark - 获取顶层视图控制器（完全无警告）
+ (UIViewController *)topMostViewController {
    UIWindow *keyWindow = nil;

    // 遍历所有已连接的 Scene
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        // 找出活跃状态的窗口场景
        if (scene.activationState == UISceneActivationStateForegroundActive &&
            [scene isKindOfClass:[UIWindowScene class]]) {
            UIWindowScene *windowScene = (UIWindowScene *)scene;
            keyWindow = windowScene.windows.firstObject;
            if (keyWindow) break;
        }
    }

    if (!keyWindow) {
        NSLog(@"[KeyBoardModule] ⚠️ 未找到活动窗口");
        return nil;
    }

    UIViewController *topController = keyWindow.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    return topController;
}

#pragma mark - 通用弹窗方法（带防重复机制）
+ (void)showAlertWithMessage:(NSString *)message {
    UIViewController *topVC = [self topMostViewController];
    if (!topVC) return;

    if ([topVC.presentedViewController isKindOfClass:[UIAlertController class]]) {
        NSLog(@"[KeyBoardModule] 已有弹窗显示中，跳过新弹窗。");
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

#pragma mark - 自定义按钮行为
+ (void)helloworld {
    NSLog(@"[KeyBoardModule] 按钮「你好按钮」被点击");
    [self showAlertWithMessage:@"自定义按钮被触发！"];
}

+ (void)sendGreeting {
    NSLog(@"[KeyBoardModule] 按钮「发送问候」被点击");
    [self showAlertWithMessage:@"已发送问候！祝你开心！"];
}

@end


#pragma mark - 注册按钮逻辑
%ctor {
    static BOOL hasRegistered = NO;
    if (hasRegistered) return;
    hasRegistered = YES;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        NSLog(@"[KeyBoardModule] 开始注册自定义按钮...");

        KeyBoardButtonManager *manager = [objc_getClass("KeyBoardButtonManager") sharedInstance];
        if (!manager) {
            NSLog(@"[KeyBoardModule] ⚠️ 未找到 KeyBoardButtonManager 类");
            return;
        }

        [manager registerButtonWithId:@"myNewButton1"
                                title:@"你好按钮"
                             iconName:@"bubble.left.and.bubble.right.fill"
                      targetClassName:@"MyNewKeyboardAction"
                       selectorString:@"helloworld"
                       defaultEnabled:YES];

        [manager registerButtonWithId:@"myNewButton2"
                                title:@"发送问候"
                             iconName:@"hand.wave"
                      targetClassName:@"MyNewKeyboardAction"
                       selectorString:@"sendGreeting"
                       defaultEnabled:NO];

        NSLog(@"[KeyBoardModule] ✅ 两个自定义按钮已注册完成。");
    });
}
