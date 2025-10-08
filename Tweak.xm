#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface KeyBoardButtonManager : NSObject
+ (instancetype)sharedInstance;
- (void)registerButtonWithId:(NSString *)buttonId
                       title:(NSString *)title
                    iconName:(NSString *)iconName
             targetClassName:(NSString *)targetClassName
              selectorString:(NSString *)selectorString
              defaultEnabled:(BOOL)defaultEnabled;
@end

// 定义你的类
@interface MyNewKeyboardAction : NSObject
+ (instancetype)sharedInstance;
+ (void)helloworld;
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

+ (void)helloworld {
    NSLog(@"[YellowKeyBoardModule] 自定义按钮被点击啦！");
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                   message:@"自定义按钮被触发！"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil]];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
}
@end

// 注册按钮
%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        NSLog(@"[YellowKeyBoardModule] 开始向黄白键盘注册按钮...");
        [[objc_getClass("KeyBoardButtonManager") sharedInstance]
            registerButtonWithId:@"myNewButton1"
                            title:@"你好按钮！"
                         iconName:@"bubble.left.and.bubble.right.fill"
                  targetClassName:@"MyNewKeyboardAction"
                   selectorString:@"helloworld"
                   defaultEnabled:YES];
    });
}
