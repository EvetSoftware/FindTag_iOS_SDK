#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class TagDeviceKey;

@interface DemoState : NSObject

@property(class, nonatomic, strong, nullable) TagDeviceKey *selectedDeviceKey;

@end

NS_ASSUME_NONNULL_END
