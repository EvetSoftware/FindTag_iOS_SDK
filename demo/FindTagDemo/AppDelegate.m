#import "AppDelegate.h"
#import "LoginViewController.h"

@import TagSdk;

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    TagSdkConfig *config =
        [[TagSdkConfig alloc] initWithIntegrationMode:TagIntegrationModeOfficial
                                   openApiCredential:nil
                            customerBindingTimeoutMs:30000
                             customerBindingHandler:nil
                                         logEnabled:YES];
    TagError *error = [TagSdk initializeWithConfig:config];
    if (error) {
        NSLog(@"Tag SDK initialization failed: %@", error.code);
    }

    UINavigationBarAppearance *appearance = [UINavigationBarAppearance new];
    [appearance configureWithOpaqueBackground];
    appearance.backgroundColor = UIColor.systemBlueColor;
    appearance.titleTextAttributes = @{NSForegroundColorAttributeName: UIColor.whiteColor};
    appearance.largeTitleTextAttributes = @{NSForegroundColorAttributeName: UIColor.whiteColor};
    UINavigationBar.appearance.standardAppearance = appearance;
    UINavigationBar.appearance.scrollEdgeAppearance = appearance;
    UINavigationBar.appearance.compactAppearance = appearance;
    UINavigationBar.appearance.tintColor = UIColor.whiteColor;

    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    UINavigationController *navigation =
        [[UINavigationController alloc] initWithRootViewController:[LoginViewController new]];
    self.window.rootViewController = navigation;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
