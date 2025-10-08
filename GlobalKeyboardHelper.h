#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, GKButtonType) {
    GKButtonTypeSelectAll,  // 全选
    GKButtonTypeCut,        // 剪切
    GKButtonTypeCopy,       // 复制
    GKButtonTypePaste,      // 粘贴
    GKButtonTypeDelete,     // 删除
    GKButtonTypeClose       // 关闭
};

@interface GKButtonInfo : NSObject
@property (nonatomic, assign) GKButtonType type;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *iconName;
@property (nonatomic, assign) BOOL enabled;
@end

@interface GlobalKeyboardManager : NSObject

+ (instancetype)sharedInstance;

- (void)initializeGlobalKeyboard;
- (void)showKeyboard;
- (void)hideKeyboard;
- (void)toggleKeyboard;
- (BOOL)isKeyboardVisible;
- (void)updateButtonStates;

@end

NS_ASSUME_NONNULL_END
