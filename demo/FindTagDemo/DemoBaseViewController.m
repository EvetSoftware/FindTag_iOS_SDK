#import "DemoBaseViewController.h"

@import TagSdk;

@interface DemoBaseViewController ()

@property(nonatomic, strong) UIView *loadingOverlay;
@property(nonatomic, strong) UILabel *loadingLabel;

@end


NSString *DemoBrandName(void) {
    NSString *brand = [NSBundle.mainBundle objectForInfoDictionaryKey:@"DemoBrandName"];
    return brand.length > 0 ? brand : @"FindTag";
}


@implementation DemoBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
}

- (UILabel *)demoLabelWithText:(NSString *)text
                          font:(UIFont *)font
                         color:(UIColor *)color {
    UILabel *label = [UILabel new];
    label.text = text;
    label.font = font;
    label.textColor = color;
    label.numberOfLines = 0;
    return label;
}

- (UITextField *)demoTextFieldWithPlaceholder:(NSString *)placeholder {
    UITextField *field = [UITextField new];
    field.placeholder = placeholder;
    field.borderStyle = UITextBorderStyleNone;
    field.backgroundColor = UIColor.secondarySystemBackgroundColor;
    field.layer.cornerRadius = 10.0;
    field.layer.borderWidth = 1.0;
    field.layer.borderColor = UIColor.separatorColor.CGColor;
    field.clearButtonMode = UITextFieldViewModeWhileEditing;
    field.autocapitalizationType = UITextAutocapitalizationTypeNone;
    field.autocorrectionType = UITextAutocorrectionTypeNo;
    field.translatesAutoresizingMaskIntoConstraints = NO;

    UIView *leftPadding = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 14, 1)];
    field.leftView = leftPadding;
    field.leftViewMode = UITextFieldViewModeAlways;
    [field.heightAnchor constraintEqualToConstant:50.0].active = YES;
    return field;
}

- (UIButton *)demoPrimaryButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightSemibold];
    button.configuration = [UIButtonConfiguration filledButtonConfiguration];
    button.configuration.cornerStyle = UIButtonConfigurationCornerStyleMedium;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [button.heightAnchor constraintGreaterThanOrEqualToConstant:48.0].active = YES;
    return button;
}

- (UIButton *)demoSecondaryButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightMedium];
    button.configuration = [UIButtonConfiguration tintedButtonConfiguration];
    button.configuration.cornerStyle = UIButtonConfigurationCornerStyleMedium;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [button.heightAnchor constraintGreaterThanOrEqualToConstant:46.0].active = YES;
    return button;
}

- (UIView *)demoCardView {
    UIView *view = [UIView new];
    view.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
    view.layer.cornerRadius = 14.0;
    view.layer.borderWidth = 1.0;
    view.layer.borderColor = UIColor.separatorColor.CGColor;
    return view;
}

- (UIStackView *)demoVerticalStackWithSpacing:(CGFloat)spacing {
    UIStackView *stack = [UIStackView new];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = spacing;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    return stack;
}

- (void)showLoading:(NSString *)message {
    if (!self.loadingOverlay) {
        UIView *overlay = [UIView new];
        overlay.backgroundColor = [UIColor colorWithWhite:0 alpha:0.20];
        overlay.translatesAutoresizingMaskIntoConstraints = NO;

        UIView *panel = [UIView new];
        panel.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.92];
        panel.layer.cornerRadius = 14.0;
        panel.translatesAutoresizingMaskIntoConstraints = NO;

        UIActivityIndicatorView *indicator =
            [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
        indicator.color = UIColor.whiteColor;
        [indicator startAnimating];

        UILabel *label = [self demoLabelWithText:message
                                            font:[UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium]
                                           color:UIColor.whiteColor];
        label.textAlignment = NSTextAlignmentCenter;

        UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[indicator, label]];
        stack.axis = UILayoutConstraintAxisVertical;
        stack.alignment = UIStackViewAlignmentCenter;
        stack.spacing = 12.0;
        stack.translatesAutoresizingMaskIntoConstraints = NO;

        [panel addSubview:stack];
        [overlay addSubview:panel];
        [self.view addSubview:overlay];
        [NSLayoutConstraint activateConstraints:@[
            [overlay.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
            [overlay.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
            [overlay.topAnchor constraintEqualToAnchor:self.view.topAnchor],
            [overlay.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
            [panel.centerXAnchor constraintEqualToAnchor:overlay.centerXAnchor],
            [panel.centerYAnchor constraintEqualToAnchor:overlay.centerYAnchor],
            [panel.widthAnchor constraintGreaterThanOrEqualToConstant:150.0],
            [stack.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor constant:24.0],
            [stack.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor constant:-24.0],
            [stack.topAnchor constraintEqualToAnchor:panel.topAnchor constant:20.0],
            [stack.bottomAnchor constraintEqualToAnchor:panel.bottomAnchor constant:-20.0],
        ]];
        self.loadingOverlay = overlay;
        self.loadingLabel = label;
    }

    self.loadingLabel.text = message;
    self.loadingOverlay.hidden = NO;
    [self.view bringSubviewToFront:self.loadingOverlay];
}

- (void)hideLoading {
    self.loadingOverlay.hidden = YES;
}

- (void)showMessage:(NSString *)message {
    [self showMessage:message title:DemoBrandName()];
}

- (void)showMessage:(NSString *)message title:(NSString *)title {
    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:title
                                            message:message
                                     preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                             style:UIAlertActionStyleDefault
                                           handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (NSString *)displayTextForError:(TagError *)error {
    if (!error) return @"Unknown error";
    return [NSString stringWithFormat:@"%@: %@", error.code, error.message];
}

@end
