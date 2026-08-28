#import "HomeViewController.h"

#import "DemoState.h"
#import "DeviceListViewController.h"
#import "LoginViewController.h"
#import "SearchViewController.h"

@import TagSdk;

@interface HomeViewController () <TagBluetoothStateListener>

@property(nonatomic, strong) UILabel *sessionLabel;
@property(nonatomic, strong) UILabel *selectedLabel;
@property(nonatomic, strong) UILabel *bluetoothLabel;
@property(nonatomic, strong) UILabel *dataResultLabel;
@property(nonatomic, strong) UILabel *statusLabel;
@property(nonatomic, strong) id<TagSubscription> bluetoothSubscription;

@end


@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Home";
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:@"Logs"
                                        style:UIBarButtonItemStylePlain
                                       target:self
                                       action:@selector(exportLogs)];
    [self buildContent];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshSessionSummary];
    self.bluetoothSubscription = [TagSdk observeBluetoothState:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.bluetoothSubscription cancel];
    self.bluetoothSubscription = nil;
    [super viewWillDisappear:animated];
}

- (void)buildContent {
    UIScrollView *scrollView = [UIScrollView new];
    scrollView.alwaysBounceVertical = YES;
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:scrollView];

    UIStackView *pageStack = [self demoVerticalStackWithSpacing:14.0];
    [scrollView addSubview:pageStack];

    UILabel *intro =
        [self demoLabelWithText:@"Load device data or enter a device workflow"
                          font:[UIFont systemFontOfSize:15.0]
                         color:UIColor.secondaryLabelColor];
    [pageStack addArrangedSubview:intro];

    self.sessionLabel = [self detailLabel];
    self.selectedLabel = [self detailLabel];
    self.bluetoothLabel = [self detailLabel];
    UIView *sessionCard = [self cardWithTitle:@"Session"
                                        views:@[self.sessionLabel,
                                                self.selectedLabel,
                                                self.bluetoothLabel]];
    [pageStack addArrangedSubview:sessionCard];

    self.dataResultLabel =
        [self demoLabelWithText:@"No data loaded"
                          font:[UIFont monospacedSystemFontOfSize:14.0 weight:UIFontWeightRegular]
                         color:UIColor.labelColor];
    UIButton *loadButton =
        [self demoPrimaryButtonWithTitle:@"Load latest data" action:@selector(loadLatestData)];
    UIView *dataCard = [self cardWithTitle:@"Latest device data"
                                     views:@[loadButton, self.dataResultLabel]];
    [pageStack addArrangedSubview:dataCard];

    UIButton *deviceListButton =
        [self demoPrimaryButtonWithTitle:@"View device list" action:@selector(openDeviceList)];
    UIButton *searchButton =
        [self demoSecondaryButtonWithTitle:@"Search, connect and bind"
                                     action:@selector(openSearch)];
    UIView *devicesCard = [self cardWithTitle:@"Devices"
                                        views:@[deviceListButton, searchButton]];
    [pageStack addArrangedSubview:devicesCard];

    UIButton *logoutButton =
        [self demoSecondaryButtonWithTitle:@"Exit / local logout" action:@selector(logout)];
    self.statusLabel =
        [self demoLabelWithText:@"Ready"
                          font:[UIFont systemFontOfSize:14.0]
                         color:UIColor.secondaryLabelColor];
    UIView *actionsCard = [self cardWithTitle:@"Account" views:@[logoutButton, self.statusLabel]];
    [pageStack addArrangedSubview:actionsCard];

    [NSLayoutConstraint activateConstraints:@[
        [scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [pageStack.leadingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.leadingAnchor constant:20.0],
        [pageStack.trailingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.trailingAnchor constant:-20.0],
        [pageStack.topAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor constant:24.0],
        [pageStack.bottomAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor constant:-32.0],
        [pageStack.widthAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor constant:-40.0],
    ]];
}

- (UILabel *)detailLabel {
    return [self demoLabelWithText:nil
                             font:[UIFont systemFontOfSize:15.0]
                            color:UIColor.labelColor];
}

- (UIView *)cardWithTitle:(NSString *)title views:(NSArray<UIView *> *)views {
    UIView *card = [self demoCardView];
    UILabel *titleLabel =
        [self demoLabelWithText:title
                          font:[UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold]
                         color:UIColor.labelColor];
    UIStackView *stack = [self demoVerticalStackWithSpacing:12.0];
    [stack addArrangedSubview:titleLabel];
    for (UIView *view in views) {
        [stack addArrangedSubview:view];
    }
    [card addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16.0],
        [stack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16.0],
        [stack.topAnchor constraintEqualToAnchor:card.topAnchor constant:16.0],
        [stack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-16.0],
    ]];
    return card;
}

- (void)refreshSessionSummary {
    TagAccount *account = TagSdk.getCurrentAccount;
    self.sessionLabel.text =
        [NSString stringWithFormat:@"Brand: %@\nAccount: %@\nSDK: %@",
                                   DemoBrandName(),
                                   account.username ?: @"not logged in",
                                   TagSdk.getSdkVersion];
    self.selectedLabel.text = DemoState.selectedDeviceKey
        ? @"Selected device: ready for data loading"
        : @"Selected device: none";
}

- (void)onStateChanged:(TagBluetoothState)state {
    NSArray<NSString *> *values = @[@"unknown", @"poweredOff", @"poweredOn", @"unauthorized"];
    NSString *value = state >= 0 && state < values.count ? values[state] : @"unknown";
    self.bluetoothLabel.text = [NSString stringWithFormat:@"Bluetooth: %@", value];
}

- (void)openDeviceList {
    [self.navigationController pushViewController:[DeviceListViewController new] animated:YES];
}

- (void)openSearch {
    [self.navigationController pushViewController:[SearchViewController new] animated:YES];
}

- (void)loadLatestData {
    TagDeviceKey *selected = DemoState.selectedDeviceKey;
    if (selected) {
        [self requestLatestData:selected];
    } else {
        [self selectFirstDevice];
    }
}

- (void)selectFirstDevice {
    [self showLoading:@"Loading device list…"];
    __weak typeof(self) weakSelf = self;
    [TagSdk getDeviceList:^(NSArray<TagDeviceInfo *> *devices, TagError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (error) {
            [self hideLoading];
            self.statusLabel.text = [self displayTextForError:error];
            return;
        }
        TagDeviceInfo *first = devices.firstObject;
        if (!first) {
            [self hideLoading];
            self.statusLabel.text = @"No bound device. Search and bind a device first.";
            return;
        }
        DemoState.selectedDeviceKey = first.primaryDeviceKey;
        [self refreshSessionSummary];
        [self requestLatestData:first.primaryDeviceKey];
    }];
}

- (void)requestLatestData:(TagDeviceKey *)deviceKey {
    [self showLoading:@"Loading latest device data…"];
    TagDeviceDataQuery *query =
        [[TagDeviceDataQuery alloc] initWithDeviceKey:deviceKey
                                              preset:TagDeviceDataPresetLatest
                                         startTimeMs:nil
                                           endTimeMs:nil];
    __weak typeof(self) weakSelf = self;
    [TagSdk getDeviceData:query
               completion:^(NSArray<TagDeviceData *> *data, TagError *error) {
                   __strong typeof(weakSelf) self = weakSelf;
                   [self hideLoading];
                   if (error) {
                       self.dataResultLabel.text = @"Load failed";
                       self.statusLabel.text = [self displayTextForError:error];
                       return;
                   }
                   TagDeviceData *latest = data.firstObject;
                   if (!latest) {
                       self.dataResultLabel.text = @"No location data";
                       self.statusLabel.text = @"Loaded 0 records";
                       return;
                   }
                   self.dataResultLabel.text = [self textForDeviceData:latest];
                   self.statusLabel.text =
                       [NSString stringWithFormat:@"Loaded %lu record(s)", (unsigned long)data.count];
               }];
}

- (NSString *)textForDeviceData:(TagDeviceData *)data {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:data.collectionTimeMs / 1000.0];
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSString *battery = data.batteryLevel != nil ? data.batteryLevel.stringValue : @"n/a";
    NSString *accuracy = data.accuracyLevel != nil
        ? [NSString stringWithFormat:@"%@ m", data.accuracyLevel]
        : @"n/a";
    return [NSString stringWithFormat:@"Time: %@\nCoordinate: %.6f, %.6f\nBattery: %@\nAccuracy: %@\nPoint: %@",
                                      [formatter stringFromDate:date],
                                      data.latitude,
                                      data.longitude,
                                      battery,
                                      accuracy,
                                      data.googleLocation ? @"G" : @"I"];
}

- (void)exportLogs {
    [self showLoading:@"Preparing SDK logs…"];
    __weak typeof(self) weakSelf = self;
    [TagSdk exportLogs:^(TagLogArchive *archive, TagError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        [self hideLoading];
        if (error) {
            self.statusLabel.text = [self displayTextForError:error];
            return;
        }
        NSURL *fileURL = [NSURL fileURLWithPath:archive.filePath];
        UIActivityViewController *share =
            [[UIActivityViewController alloc] initWithActivityItems:@[fileURL]
                                              applicationActivities:nil];
        share.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItem;
        [self presentViewController:share animated:YES completion:nil];
    }];
}

- (void)logout {
    [TagSdk logout];
    [TagSdk releaseSdk];
    DemoState.selectedDeviceKey = nil;
    TagSdkConfig *config =
        [[TagSdkConfig alloc] initWithIntegrationMode:TagIntegrationModeOfficial
                                   openApiCredential:nil
                            customerBindingTimeoutMs:30000
                             customerBindingHandler:nil
                                         logEnabled:YES];
    TagError *initializationError = [TagSdk initializeWithConfig:config];
    if (initializationError) {
        NSLog(@"Tag SDK reinitialization failed: %@", initializationError.code);
    }
    [self.navigationController setViewControllers:@[[LoginViewController new]] animated:YES];
}

@end
