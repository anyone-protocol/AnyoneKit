//
//  AnonThread.h
//  AnyoneKit
//
//  Created by Conrad Kramer on 7/19/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AnonConfiguration;

@interface AnonThread : NSThread

#if __has_feature(objc_class_property)
@property (class, readonly, nullable) AnonThread *activeThread;
#else
+ (nullable AnonThread *)activeThread;
#endif

- (instancetype)initWithConfiguration:(nullable AnonConfiguration *)configuration;
- (instancetype)initWithArguments:(nullable NSArray<NSString *> *)arguments NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
