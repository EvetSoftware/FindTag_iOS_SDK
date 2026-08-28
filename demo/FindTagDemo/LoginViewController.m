#import "LoginViewController.h"

#import "HomeViewController.h"
#import "RegisterViewController.h"

@import TagSdk;

@interface LoginViewController () <UITextFieldDelegate>

@property(nonatomic, strong) UITextField *usernameField;
@property(nonatomic, strong) UITextField *passwordField;
@property(nonatomic, strong) UILabel *statusLabel;

@end


@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Tag SDK Demo";
    self.navigationItem.hidesBackButton = YES;

    UIScrollView *scrollView = [UIScrollView new];
    scrollView.alwaysBounceVertical = YES;
    scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:scrollView];

    UIView *contentView = [UIView new];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [scrollView addSubview:contentView];

    UILabel *titleLabel =
        [self demoLabelWithText:@"Welcome"
                          font:[UIFont systemFontOfSize:30.0 weight:UIFontWeightBold]
                         color:UIColor.labelColor];
    UILabel *subtitleLabel =
        [self demoLabelWithText:[NSString stringWithFormat:@"%@ · SDK %@",
                                                           DemoBrandName(),
                                                           TagSdk.getSdkVersion]
                          font:[UIFont systemFontOfSize:15.0]
                         color:UIColor.secondaryLabelColor];

    self.usernameField = [self demoTextFieldWithPlaceholder:@"Username"];
    self.usernameField.keyboardType = UIKeyboardTypePhonePad;
    self.usernameField.textContentType = UITextContentTypeUsername;
    self.usernameField.delegate = self;

    self.passwordField = [self demoTextFieldWithPlaceholder:@"Password"];
    self.passwordField.secureTextEntry = YES;
    self.passwordField.textContentType = UITextContentTypePassword;
    self.passwordField.returnKeyType = UIReturnKeyGo;
    self.passwordField.delegate = self;

    UIButton *loginButton = [self demoPrimaryButtonWithTitle:@"Login" action:@selector(login)];
    UIButton *registerButton =
        [self demoSecondaryButtonWithTitle:@"Create account" action:@selector(openRegister)];

    self.statusLabel =
        [self demoLabelWithText:@"Enter your account to continue"
                          font:[UIFont systemFontOfSize:14.0]
                         color:UIColor.secondaryLabelColor];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;

    UIStackView *formStack = [self demoVerticalStackWithSpacing:14.0];
    [formStack addArrangedSubview:self.usernameField];
    [formStack addArrangedSubview:self.passwordField];
    [formStack addArrangedSubview:loginButton];
    [formStack addArrangedSubview:registerButton];
    [formStack addArrangedSubview:self.statusLabel];

    UIView *card = [self demoCardView];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:formStack];

    UIStackView *pageStack = [self demoVerticalStackWithSpacing:10.0];
    [pageStack addArrangedSubview:titleLabel];
    [pageStack addArrangedSubview:subtitleLabel];
    [pageStack setCustomSpacing:30.0 afterView:subtitleLabel];
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
        [pageStack.topAnchor constraintEqualToAnchor:contentView.topAnchor constant:42.0],
        [pageStack.bottomAnchor constraintLessThanOrEqualToAnchor:contentView.bottomAnchor constant:-32.0],
        [formStack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:18.0],
        [formStack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18.0],
        [formStack.topAnchor constraintEqualToAnchor:card.topAnchor constant:20.0],
        [formStack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-20.0],
    ]];

    if (TagSdk.getCurrentAccount) {
        [self openHome];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.usernameField) {
        [self.passwordField becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
        [self login];
    }
    return YES;
}

- (void)login {
    [self.view endEditing:YES];
    NSString *username =
        [self.usernameField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    NSString *password = self.passwordField.text ?: @"";
    if (username.length == 0 || password.length == 0) {
        self.statusLabel.text = @"Enter username and password";
        return;
    }

    [self showLoading:@"Logging in…"];
    TagLoginRequest *request = [[TagLoginRequest alloc] initWithUsername:username password:password];
    __weak typeof(self) weakSelf = self;
    [TagSdk login:request
       completion:^(TagAccount *account, TagError *error) {
           __strong typeof(weakSelf) self = weakSelf;
           [self hideLoading];
           if (error) {
               self.statusLabel.text = [self displayTextForError:error];
               return;
           }
           [self openHome];
       }];
}

- (void)openRegister {
    [self.navigationController pushViewController:[RegisterViewController new] animated:YES];
}

- (void)openHome {
    [self.navigationController setViewControllers:@[[HomeViewController new]] animated:YES];
}

@end
