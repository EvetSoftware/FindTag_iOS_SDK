#import "SearchViewController.h"

#import "DemoState.h"

@import TagSdk;

@interface DemoSearchDeviceCell : UITableViewCell

@property(nonatomic, strong) UILabel *nameLabel;
@property(nonatomic, strong) UILabel *detailsLabel;
@property(nonatomic, strong) UIButton *bindButton;
@property(nonatomic, strong) UIButton *findButton;
@property(nonatomic, copy) void (^bindHandler)(void);
@property(nonatomic, copy) void (^findHandler)(void);

- (void)configureWithDevice:(TagDevice *)device interactionEnabled:(BOOL)enabled;

@end


@implementation DemoSearchDeviceCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (!self) return nil;

    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.backgroundColor = UIColor.clearColor;
    UIView *card = [UIView new];
    card.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
    card.layer.cornerRadius = 14.0;
    card.layer.borderWidth = 1.0;
    card.layer.borderColor = UIColor.separatorColor.CGColor;
    card.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:card];

    self.nameLabel = [UILabel new];
    self.nameLabel.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightSemibold];
    self.nameLabel.textColor = UIColor.labelColor;

    self.detailsLabel = [UILabel new];
    self.detailsLabel.font = [UIFont systemFontOfSize:13.0];
    self.detailsLabel.textColor = UIColor.secondaryLabelColor;
    self.detailsLabel.numberOfLines = 0;

    self.bindButton = [self buttonWithTitle:@"Connect & bind" action:@selector(bindTapped)];
    self.findButton = [self buttonWithTitle:@"Find" action:@selector(findTapped)];
    [self.findButton.widthAnchor constraintEqualToConstant:92.0].active = YES;
    UIStackView *buttons =
        [[UIStackView alloc] initWithArrangedSubviews:@[self.bindButton, self.findButton]];
    buttons.axis = UILayoutConstraintAxisHorizontal;
    buttons.spacing = 8.0;

    UIStackView *stack =
        [[UIStackView alloc] initWithArrangedSubviews:@[self.nameLabel, self.detailsLabel, buttons]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 9.0;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:stack];

    [NSLayoutConstraint activateConstraints:@[
        [card.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16.0],
        [card.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16.0],
        [card.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:6.0],
        [card.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-6.0],
        [stack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:15.0],
        [stack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-15.0],
        [stack.topAnchor constraintEqualToAnchor:card.topAnchor constant:14.0],
        [stack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-14.0],
        [buttons.heightAnchor constraintGreaterThanOrEqualToConstant:38.0],
    ]];
    return self;
}

- (UIButton *)buttonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightSemibold];
    button.configuration = [UIButtonConfiguration tintedButtonConfiguration];
    button.configuration.cornerStyle = UIButtonConfigurationCornerStyleSmall;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)configureWithDevice:(TagDevice *)device interactionEnabled:(BOOL)enabled {
    self.nameLabel.text = device.name ?: DemoBrandName();
    self.detailsLabel.text =
        [NSString stringWithFormat:@"RSSI: %ld dBm\nBluetooth MAC: %@\nAdvertised MAC: %@\nPeripheral ID: %@",
                                   (long)device.rssi,
                                   device.platformAddress ?: @"Unavailable",
                                   device.advertisedMac ?: @"Unavailable",
                                   device.id];
    self.bindButton.enabled = enabled;
    self.findButton.enabled = enabled;
}

- (void)bindTapped {
    if (self.bindHandler) self.bindHandler();
}

- (void)findTapped {
    if (self.findHandler) self.findHandler();
}

@end


@interface SearchViewController ()
    <UITableViewDataSource, UITableViewDelegate, TagScanListener, TagBluetoothStateListener>

@property(nonatomic, strong) NSMutableArray<TagDevice *> *devices;
@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) UIButton *scanButton;
@property(nonatomic, strong) UIButton *stopButton;
@property(nonatomic, strong) UILabel *statusLabel;
@property(nonatomic, strong) UILabel *emptyLabel;
@property(nonatomic, strong) id<TagSubscription> scanSubscription;
@property(nonatomic, strong) id<TagSubscription> stateSubscription;
@property(nonatomic, strong) NSTimer *countdownTimer;
@property(nonatomic, strong) NSDate *scanEndDate;
@property(nonatomic) BOOL operationRunning;

@end


@implementation SearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Search and bind";
    self.devices = [NSMutableArray array];
    [self buildContent];
    self.stateSubscription = [TagSdk observeBluetoothState:self];
    [self startScan];
}

- (void)dealloc {
    [self.scanSubscription cancel];
    [self.stateSubscription cancel];
    [self.countdownTimer invalidate];
}

- (void)viewWillDisappear:(BOOL)animated {
    if (self.isMovingFromParentViewController) {
        [self.scanSubscription cancel];
        self.scanSubscription = nil;
        [self.stateSubscription cancel];
        self.stateSubscription = nil;
        [self.countdownTimer invalidate];
        self.countdownTimer = nil;
    }
    [super viewWillDisappear:animated];
}

- (void)buildContent {
    UILabel *subtitle =
        [self demoLabelWithText:@"Nearby compatible devices are listed below. Select an action on a device card."
                          font:[UIFont systemFontOfSize:14.0]
                         color:UIColor.secondaryLabelColor];

    self.scanButton =
        [self demoPrimaryButtonWithTitle:@"Start 15-second scan" action:@selector(startScan)];
    self.stopButton = [self demoSecondaryButtonWithTitle:@"Stop" action:@selector(stopScan)];
    [self.stopButton.widthAnchor constraintEqualToConstant:92.0].active = YES;
    UIStackView *buttons =
        [[UIStackView alloc] initWithArrangedSubviews:@[self.scanButton, self.stopButton]];
    buttons.axis = UILayoutConstraintAxisHorizontal;
    buttons.spacing = 10.0;

    self.statusLabel =
        [self demoLabelWithText:@"Ready"
                          font:[UIFont systemFontOfSize:14.0]
                         color:UIColor.secondaryLabelColor];

    UIStackView *header = [self demoVerticalStackWithSpacing:10.0];
    [header addArrangedSubview:subtitle];
    [header addArrangedSubview:buttons];
    [header addArrangedSubview:self.statusLabel];
    [self.view addSubview:header];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.backgroundColor = UIColor.clearColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 190.0;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.contentInset = UIEdgeInsetsMake(4, 0, 24, 0);
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.tableView registerClass:DemoSearchDeviceCell.class forCellReuseIdentifier:@"search"];
    [self.view addSubview:self.tableView];

    self.emptyLabel =
        [self demoLabelWithText:@"Scanning for nearby devices…"
                          font:[UIFont systemFontOfSize:16.0]
                         color:UIColor.secondaryLabelColor];
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.emptyLabel];

    [NSLayoutConstraint activateConstraints:@[
        [header.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20.0],
        [header.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20.0],
        [header.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:16.0],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.topAnchor constraintEqualToAnchor:header.bottomAnchor constant:8.0],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.emptyLabel.centerXAnchor constraintEqualToAnchor:self.tableView.centerXAnchor],
        [self.emptyLabel.centerYAnchor constraintEqualToAnchor:self.tableView.centerYAnchor],
        [self.emptyLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:20.0],
        [self.emptyLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-20.0],
    ]];
}

- (void)startScan {
    if (self.operationRunning) return;
    [self.scanSubscription cancel];
    self.scanSubscription = nil;
    [self.devices removeAllObjects];
    [self.tableView reloadData];
    self.emptyLabel.hidden = NO;
    self.emptyLabel.text = @"Scanning for nearby devices…";
    self.statusLabel.text = @"Scanning…";
    self.scanButton.enabled = NO;
    self.stopButton.enabled = YES;
    self.scanEndDate = [NSDate dateWithTimeIntervalSinceNow:15.0];
    [self.countdownTimer invalidate];
    self.countdownTimer = [NSTimer scheduledTimerWithTimeInterval:0.25
                                                           target:self
                                                         selector:@selector(updateCountdown)
                                                         userInfo:nil
                                                          repeats:YES];
    self.scanSubscription =
        [TagSdk startScanWithOptions:[[TagScanOptions alloc] initWithTimeoutMs:15000]
                            listener:self];
}

- (void)stopScan {
    [TagSdk stopScan];
}

- (void)updateCountdown {
    NSTimeInterval remaining = MAX(0, [self.scanEndDate timeIntervalSinceNow]);
    NSInteger seconds = (NSInteger)ceil(remaining);
    NSString *title = seconds > 0
        ? [NSString stringWithFormat:@"Scanning (%lds)", (long)seconds]
        : @"Start 15-second scan";
    [self.scanButton setTitle:title forState:UIControlStateNormal];
    if (seconds <= 0) {
        [self.countdownTimer invalidate];
        self.countdownTimer = nil;
    }
}

- (void)onDeviceFound:(TagDevice *)device {
    NSUInteger index = [self.devices indexOfObjectPassingTest:^BOOL(
        TagDevice *existing, NSUInteger index, BOOL *stop) {
        return [existing.id isEqualToString:device.id];
    }];
    [UIView performWithoutAnimation:^{
        if (index == NSNotFound) {
            [self.devices addObject:device];
            NSIndexPath *path = [NSIndexPath indexPathForRow:self.devices.count - 1 inSection:0];
            [self.tableView insertRowsAtIndexPaths:@[path]
                                  withRowAnimation:UITableViewRowAnimationNone];
        } else {
            self.devices[index] = device;
            NSIndexPath *path = [NSIndexPath indexPathForRow:index inSection:0];
            [self.tableView reloadRowsAtIndexPaths:@[path]
                                  withRowAnimation:UITableViewRowAnimationNone];
        }
    }];
    self.emptyLabel.hidden = YES;
    self.statusLabel.text =
        [NSString stringWithFormat:@"Found %lu device(s)", (unsigned long)self.devices.count];
}

- (void)onScanFinished:(TagScanFinishReason)reason {
    NSArray<NSString *> *values = @[@"timeout", @"stopped", @"operationStarted"];
    NSString *value = reason >= 0 && reason < values.count ? values[reason] : @"unknown";
    [self finishScanUI:[NSString stringWithFormat:@"Scan finished: %@; %lu device(s)",
                                                  value,
                                                  (unsigned long)self.devices.count]];
}

- (void)onScanFailed:(TagError *)error {
    [self finishScanUI:[self displayTextForError:error]];
}

- (void)onStateChanged:(TagBluetoothState)state {
    NSArray<NSString *> *values = @[@"unknown", @"poweredOff", @"poweredOn", @"unauthorized"];
    NSString *value = state >= 0 && state < values.count ? values[state] : @"unknown";
    if (state != TagBluetoothStatePoweredOn) {
        self.statusLabel.text = [NSString stringWithFormat:@"Bluetooth: %@", value];
    }
}

- (void)finishScanUI:(NSString *)message {
    [self.countdownTimer invalidate];
    self.countdownTimer = nil;
    self.scanEndDate = nil;
    [self.scanButton setTitle:@"Start 15-second scan" forState:UIControlStateNormal];
    self.scanButton.enabled = !self.operationRunning;
    self.stopButton.enabled = NO;
    self.statusLabel.text = message;
    if (self.devices.count == 0) {
        self.emptyLabel.text = @"No compatible devices found";
        self.emptyLabel.hidden = NO;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.devices.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DemoSearchDeviceCell *cell = [tableView dequeueReusableCellWithIdentifier:@"search"
                                                                  forIndexPath:indexPath];
    TagDevice *device = self.devices[indexPath.row];
    [cell configureWithDevice:device interactionEnabled:!self.operationRunning];
    __weak typeof(self) weakSelf = self;
    cell.bindHandler = ^{
        [weakSelf connectAndBind:device];
    };
    cell.findHandler = ^{
        [weakSelf findDevice:device];
    };
    return cell;
}

- (void)connectAndBind:(TagDevice *)device {
    [self updateOperationRunning:YES];
    [self showLoading:[NSString stringWithFormat:@"Connecting and binding %@…",
                                                 device.name ?: DemoBrandName()]];
    __weak typeof(self) weakSelf = self;
    [TagSdk connectAndBindDevice:device
                     completion:^(TagBindingInfo *info, TagError *error) {
                         __strong typeof(weakSelf) self = weakSelf;
                         [self hideLoading];
                         [self updateOperationRunning:NO];
                         if (error) {
                             if ([error.code isEqualToString:[TagErrorCode alreadyBound]]) {
                                 self.statusLabel.text = @"Device is already bound";
                                 [self showMessage:self.statusLabel.text title:@"Already bound"];
                                 return;
                             }
                             self.statusLabel.text = [self displayTextForError:error];
                             [self showMessage:self.statusLabel.text title:@"Binding failed"];
                             return;
                         }
                         DemoState.selectedDeviceKey = info.primaryDeviceKey;
                         self.statusLabel.text = @"Binding succeeded";
                         [self showMessage:@"The device is bound and selected for data loading."
                                      title:@"Binding succeeded"];
                     }];
}

- (void)findDevice:(TagDevice *)device {
    [self updateOperationRunning:YES];
    [self showLoading:@"Connecting and triggering Find…"];
    __weak typeof(self) weakSelf = self;
    [TagSdk findDevice:device
            completion:^(FindDeviceResult *result, TagError *error) {
                __strong typeof(weakSelf) self = weakSelf;
                [self hideLoading];
                [self updateOperationRunning:NO];
                if (error) {
                    self.statusLabel.text = [self displayTextForError:error];
                    [self showMessage:self.statusLabel.text title:@"Find failed"];
                    return;
                }
                NSString *battery = result.battery
                    ? [NSString stringWithFormat:@"%ld", (long)result.battery.serverLevel]
                    : @"n/a";
                self.statusLabel.text =
                    [NSString stringWithFormat:@"Find triggered=%@ · battery=%@",
                                               result.triggered ? @"true" : @"false",
                                               battery];
                [self showMessage:self.statusLabel.text title:@"Find completed"];
            }];
}

- (void)updateOperationRunning:(BOOL)running {
    self.operationRunning = running;
    self.scanButton.enabled = !running;
    self.stopButton.enabled = !running && self.scanEndDate != nil;
    if (running) {
        [self.countdownTimer invalidate];
        self.countdownTimer = nil;
        self.scanEndDate = nil;
    }
    [UIView performWithoutAnimation:^{
        [self.tableView reloadData];
    }];
}

@end
