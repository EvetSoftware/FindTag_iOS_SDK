#import "RegisterViewController.h"

@import TagSdk;

@interface RegisterViewController () <UITextFieldDelegate>

@property(nonatomic, strong) UITextField *usernameField;
@property(nonatomic, strong) UITextField *passwordField;
@property(nonatomic, strong) UITextField *confirmationField;
@property(nonatomic, strong) UILabel *statusLabel;

@end


@implementation RegisterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = [NSString stringWithFormat:@"Register · %@", DemoBrandName()];

    UIScrollView *scrollView = [UIScrollView new];
    scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:scrollView];

    UIView *contentView = [UIView new];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [scrollView addSubview:contentView];

    UILabel *heading =
        [self demoLabelWithText:@"Create an account"
                          font:[UIFont systemFontOfSize:28.0 weight:UIFontWeightBold]
                         color:UIColor.labelColor];
    UILabel *subtitle =
        [self demoLabelWithText:@"Registration does not log in automatically."
                          font:[UIFont systemFontOfSize:15.0]
                         color:UIColor.secondaryLabelColor];

    self.usernameField = [self demoTextFieldWithPlaceholder:@"Username"];
    self.usernameField.keyboardType = UIKeyboardTypePhonePad;
    self.usernameField.textContentType = UITextContentTypeUsername;
    self.usernameField.delegate = self;

    self.passwordField = [self demoTextFieldWithPlaceholder:@"Password"];
    self.passwordField.secureTextEntry = YES;
    self.passwordField.textContentType = UITextContentTypeNewPassword;
    self.passwordField.delegate = self;

    self.confirmationField = [self demoTextFieldWithPlaceholder:@"Confirm password"];
    self.confirmationField.secureTextEntry = YES;
    self.confirmationField.textContentType = UITextContentTypeNewPassword;
    self.confirmationField.returnKeyType = UIReturnKeyDone;
    self.confirmationField.delegate = self;

    UIButton *registerButton =
        [self demoPrimaryButtonWithTitle:@"Register" action:@selector(registerAccount)];
    self.statusLabel =
        [self demoLabelWithText:@"Ready"
                          font:[UIFont systemFontOfSize:14.0]
                         color:UIColor.secondaryLabelColor];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;

    UIStackView *formStack = [self demoVerticalStackWithSpacing:14.0];
    [formStack addArrangedSubview:self.usernameField];
    [formStack addArrangedSubview:self.passwordField];
    [formStack addArrangedSubview:self.confirmationField];
    [formStack addArrangedSubview:registerButton];
    [formStack addArrangedSubview:self.statusLabel];

    UIView *card = [self demoCardView];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:formStack];

    UIStackView *pageStack = [self demoVerticalStackWithSpacing:10.0];
    [pageStack addArrangedSubview:heading];
    [pageStack addArrangedSubview:subtitle];
    [pageStack setCustomSpacing:28.0 afterView:subtitle];
    [pageStack addArrangedSubview:card];
    [contentView addSubview:pageStack];

    [NSLayoutConstraint activateConstraints:@[
        [scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [contentView.leadingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.leadingAnchor],
        [contentView.trailingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.trailingAnchor],
        [contentView.topAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor],
        [contentView.bottomAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor],
        [contentView.widthAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor],
        [pageStack.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:24.0],
        [pageStack.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-24.0],
        [pageStack.topAnchor constraintEqualToAnchor:contentView.topAnchor constant:32.0],
        [pageStack.bottomAnchor constraintLessThanOrEqualToAnchor:contentView.bottomAnchor constant:-32.0],
        [formStack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:18.0],
        [formStack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18.0],
        [formStack.topAnchor constraintEqualToAnchor:card.topAnchor constant:20.0],
        [formStack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-20.0],
    ]];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.usernameField) {
        [self.passwordField becomeFirstResponder];
    } else if (textField == self.passwordField) {
        [self.confirmationField becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
        [self registerAccount];
    }
    return YES;
}

- (void)registerAccount {
    [self.view endEditing:YES];
    NSString *username =
        [self.usernameField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    NSString *password = self.passwordField.text ?: @"";
    if (username.length == 0 || password.length == 0) {
        self.statusLabel.text = @"Enter username and password";
        return;
    }
    if (![password isEqualToString:self.confirmationField.text ?: @""]) {
        self.statusLabel.text = @"Passwords do not match";
        return;
    }

    [self showLoading:@"Registering…"];
    TagRegisterRequest *request =
        [[TagRegisterRequest alloc] initWithUsername:username password:password];
    __weak typeof(self) weakSelf = self;
    [TagSdk register:request
          completion:^(TagAccount *account, TagError *error) {
              __strong typeof(weakSelf) self = weakSelf;
              [self hideLoading];
              if (error) {
                  self.statusLabel.text = [self displayTextForError:error];
                  return;
              }
              [self showMessage:@"Registration succeeded. Return to login to establish a session."
                           title:@"Registered"];
              self.statusLabel.text = [NSString stringWithFormat:@"Registered %@", account.username];
          }];
}

@end
