#import "DemoState.h"

@import TagSdk;

@implementation DemoState

static TagDeviceKey *_selectedDeviceKey;

+ (TagDeviceKey *)selectedDeviceKey {
    return _selectedDeviceKey;
}

+ (void)setSelectedDeviceKey:(TagDeviceKey *)selectedDeviceKey {
    _selectedDeviceKey = selectedDeviceKey;
}

@end
