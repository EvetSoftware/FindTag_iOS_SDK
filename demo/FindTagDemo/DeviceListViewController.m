#import "DeviceListViewController.h"

#import "DemoState.h"

@import TagSdk;

@interface DemoDeviceCell : UITableViewCell

@property(nonatomic, strong) UILabel *nameLabel;
@property(nonatomic, strong) UILabel *detailsLabel;
@property(nonatomic, strong) UIButton *selectButton;
@property(nonatomic, copy) void (^selectHandler)(void);
@property(nonatomic, copy) void (^editHandler)(void);
@property(nonatomic, copy) void (^unbindHandler)(void);

- (void)configureWithDevice:(TagDeviceInfo *)device selected:(BOOL)selected;

@end


@implementation DemoDeviceCell

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

    self.selectButton = [self buttonWithTitle:@"Use this device" action:@selector(selectTapped)];
    UIButton *editButton = [self buttonWithTitle:@"Edit" action:@selector(editTapped)];
    UIButton *unbindButton = [self buttonWithTitle:@"Unbind" action:@selector(unbindTapped)];
    UIStackView *buttons =
        [[UIStackView alloc] initWithArrangedSubviews:@[self.selectButton, editButton, unbindButton]];
    buttons.axis = UILayoutConstraintAxisHorizontal;
    buttons.spacing = 8.0;
    buttons.distribution = UIStackViewDistributionFillEqually;

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

- (void)configureWithDevice:(TagDeviceInfo *)device selected:(BOOL)selected {
    self.nameLabel.text = device.deviceName;
    NSString *mac = device.macAddresses.count > 0
        ? [device.macAddresses componentsJoinedByString:@", "]
        : @"n/a";
    NSString *battery = device.batteryLevel != nil ? device.batteryLevel.stringValue : @"n/a";
    NSString *tagDeviceId = device.tagDeviceId ?: @"n/a";
    NSString *relationship = device.relationshipType ?: @"n/a";
    self.detailsLabel.text =
        [NSString stringWithFormat:@"tagDeviceId: %@\nMAC: %@\nBattery: %@ · Type: %@\nRelationship: %@",
                                   tagDeviceId,
                                   mac,
                                   battery,
                                   device.deviceType,
                                   relationship];
    [self.selectButton setTitle:selected ? @"Selected" : @"Use this device"
                        forState:UIControlStateNormal];
    self.selectButton.enabled = !selected;
}

- (void)selectTapped {
    if (self.selectHandler) self.selectHandler();
}

- (void)editTapped {
    if (self.editHandler) self.editHandler();
}

- (void)unbindTapped {
    if (self.unbindHandler) self.unbindHandler();
}

@end


@interface DeviceListViewController () <UITableViewDataSource, UITableViewDelegate>

@property(nonatomic, strong) NSArray<TagDeviceInfo *> *devices;
@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) UILabel *statusLabel;
@property(nonatomic, strong) UILabel *emptyLabel;

@end


@implementation DeviceListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Device list";
    self.devices = @[];
    [self buildContent];
    [self loadDevices];
}

- (void)buildContent {
    UIButton *refreshButton =
        [self demoPrimaryButtonWithTitle:@"Refresh device list" action:@selector(loadDevices)];
    self.statusLabel =
        [self demoLabelWithText:@"Ready"
                          font:[UIFont systemFontOfSize:14.0]
                         color:UIColor.secondaryLabelColor];
    UIStackView *header = [self demoVerticalStackWithSpacing:10.0];
    [header addArrangedSubview:refreshButton];
    [header addArrangedSubview:self.statusLabel];
    [self.view addSubview:header];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.backgroundColor = UIColor.clearColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 170.0;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.contentInset = UIEdgeInsetsMake(4, 0, 24, 0);
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.tableView registerClass:DemoDeviceCell.class forCellReuseIdentifier:@"device"];
    [self.view addSubview:self.tableView];

    UIRefreshControl *refreshControl = [UIRefreshControl new];
    [refreshControl addTarget:self action:@selector(loadDevices) forControlEvents:UIControlEventValueChanged];
    self.tableView.refreshControl = refreshControl;

    self.emptyLabel =
        [self demoLabelWithText:@"No bound devices"
                          font:[UIFont systemFontOfSize:16.0]
                         color:UIColor.secondaryLabelColor];
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.emptyLabel.hidden = YES;
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
    ]];
}

- (void)loadDevices {
    if (!self.tableView.refreshControl.refreshing) {
        [self showLoading:@"Loading device list…"];
    }
    self.statusLabel.text = @"Loading device list…";
    __weak typeof(self) weakSelf = self;
    [TagSdk getDeviceList:^(NSArray<TagDeviceInfo *> *devices, TagError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        [self hideLoading];
        [self.tableView.refreshControl endRefreshing];
        if (error) {
            self.statusLabel.text = [self displayTextForError:error];
            return;
        }
        self.devices = devices ?: @[];
        self.emptyLabel.hidden = self.devices.count > 0;
        self.statusLabel.text = self.devices.count == 0
            ? @"No bound devices"
            : [NSString stringWithFormat:@"Loaded %lu device(s)",
                                         (unsigned long)self.devices.count];
        [self.tableView reloadData];
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.devices.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DemoDeviceCell *cell = [tableView dequeueReusableCellWithIdentifier:@"device"
                                                           forIndexPath:indexPath];
    TagDeviceInfo *device = self.devices[indexPath.row];
    BOOL selected = [DemoState.selectedDeviceKey.deviceKey
        isEqualToString:device.primaryDeviceKey.deviceKey];
    [cell configureWithDevice:device selected:selected];

    __weak typeof(self) weakSelf = self;
    cell.selectHandler = ^{
        DemoState.selectedDeviceKey = device.primaryDeviceKey;
        weakSelf.statusLabel.text = @"Device selected for Home data loading";
        [weakSelf.tableView reloadData];
    };
    cell.editHandler = ^{
        [weakSelf showUpdateDialogForDevice:device];
    };
    cell.unbindHandler = ^{
        [weakSelf confirmUnbindDevice:device];
    };
    return cell;
}

- (void)showUpdateDialogForDevice:(TagDeviceInfo *)device {
    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"Update device"
                                            message:@"Change the device name and type."
                                     preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = @"Device name";
        field.text = device.deviceName;
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = @"Device type";
        field.text = device.deviceType;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                             style:UIAlertActionStyleCancel
                                           handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:
        [UIAlertAction actionWithTitle:@"Save"
                                 style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action) {
                                   NSString *name = [alert.textFields[0].text
                                       stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
                                   NSString *type = [alert.textFields[1].text
                                       stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
                                   if (name.length == 0 || type.length == 0) {
                                       weakSelf.statusLabel.text = @"Device name and type are required";
                                       return;
                                   }
                                   [weakSelf updateDevice:device name:name type:type];
                               }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)updateDevice:(TagDeviceInfo *)device name:(NSString *)name type:(NSString *)type {
    [self showLoading:@"Updating device…"];
    TagDeviceUpdateRequest *request =
        [[TagDeviceUpdateRequest alloc] initWithDeviceKey:device.primaryDeviceKey
                                              deviceName:name
                                              deviceType:type];
    __weak typeof(self) weakSelf = self;
    [TagSdk updateDeviceInfo:request
                  completion:^(NSNumber *success, TagError *error) {
                      __strong typeof(weakSelf) self = weakSelf;
                      [self hideLoading];
                      if (error) {
                          self.statusLabel.text = [self displayTextForError:error];
                          return;
                      }
                      self.statusLabel.text = @"Device updated";
                      [self loadDevices];
                  }];
}

- (void)confirmUnbindDevice:(TagDeviceInfo *)device {
    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"Unbind device"
                                            message:[NSString stringWithFormat:@"Unbind %@?", device.deviceName]
                                     preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                             style:UIAlertActionStyleCancel
                                           handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:
        [UIAlertAction actionWithTitle:@"Unbind"
                                 style:UIAlertActionStyleDestructive
                               handler:^(UIAlertAction *action) {
                                   [weakSelf unbindDevice:device];
                               }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)unbindDevice:(TagDeviceInfo *)device {
    [self showLoading:@"Unbinding…"];
    __weak typeof(self) weakSelf = self;
    [TagSdk unbindDevice:device.primaryDeviceKey
              completion:^(NSNumber *success, TagError *error) {
                  __strong typeof(weakSelf) self = weakSelf;
                  [self hideLoading];
                  if (error) {
                      self.statusLabel.text = [self displayTextForError:error];
                      return;
                  }
                  if ([DemoState.selectedDeviceKey.deviceKey
                          isEqualToString:device.primaryDeviceKey.deviceKey]) {
                      DemoState.selectedDeviceKey = nil;
                  }
                  self.statusLabel.text = @"Unbound";
                  [self loadDevices];
              }];
}

@end
