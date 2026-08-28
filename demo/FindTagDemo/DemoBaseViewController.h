#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class TagError;

@interface DemoBaseViewController : UIViewController

- (UILabel *)demoLabelWithText:(nullable NSString *)text
                          font:(UIFont *)font
                         color:(UIColor *)color;
- (UITextField *)demoTextFieldWithPlaceholder:(NSString *)placeholder;
- (UIButton *)demoPrimaryButtonWithTitle:(NSString *)title action:(SEL)action;
- (UIButton *)demoSecondaryButtonWithTitle:(NSString *)title action:(SEL)action;
- (UIView *)demoCardView;
- (UIStackView *)demoVerticalStackWithSpacing:(CGFloat)spacing;

- (void)showLoading:(NSString *)message;
- (void)hideLoading;
- (void)showMessage:(NSString *)message;
- (void)showMessage:(NSString *)message title:(NSString *)title;
- (NSString *)displayTextForError:(TagError *)error;

@end

FOUNDATION_EXPORT NSString *DemoBrandName(void);

NS_ASSUME_NONNULL_END
