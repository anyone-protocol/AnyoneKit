//
//  AnonThread.m
//  AnyoneKit
//
//  Created by Conrad Kramer on 7/19/15.
//

#import <anon/feature/api/tor_api.h>

#import "AnonThread.h"
#import "AnonLogging.h"
#import "AnonConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

static __weak AnonThread *_thread = nil;

@interface AnonThread ()

@property (nonatomic, readonly, copy, nullable) NSArray<NSString *> *arguments;

@end

@implementation AnonThread

+ (nullable AnonThread *)activeThread {
    return _thread;
}

- (instancetype)init {
    return [self initWithArguments:nil];
}

- (instancetype)initWithConfiguration:(nullable AnonConfiguration *)configuration {
    return [self initWithArguments:[configuration compile]];
}

- (instancetype)initWithArguments:(nullable NSArray<NSString *> *)arguments {
    NSAssert(_thread == nil, @"There can only be one AnonThread per process");
    self = [super init];
    if (!self)
        return nil;
    
    _thread = self;
    _arguments = [arguments copy];
    
    self.name = @"Anon";

    return self;
}

- (void)main {
    NSArray *arguments = self.arguments;
    int argc = (int)(arguments.count + 1);
    char *argv[argc];
    argv[0] = "tor";
    for (NSUInteger idx = 0; idx < arguments.count; idx++)
        argv[idx + 1] = (char *)[arguments[idx] UTF8String];
    argv[argc] = NULL;

//#if DEBUG
//    event_enable_debug_mode();
//#endif

    tor_main_configuration_t *cfg = tor_main_configuration_new();
    tor_main_configuration_set_command_line(cfg, argc, argv);
    tor_run_main(cfg);
    tor_main_configuration_free(cfg);
}

@end

NS_ASSUME_NONNULL_END
