//
//  AnonLogging.h
//  AnyoneKit
//
//  Created by Benjamin Erhart on 9/9/17.
//

#import <Foundation/Foundation.h>
#import <os/log.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(* anon_log_cb)(os_log_type_t severity, const char* msg);

extern void AnonInstallEventLogging(void);

extern void AnonInstallEventLoggingCallback(anon_log_cb cb);

extern void AnonInstallAnonLogging(void);

extern void AnonInstallAnonLoggingCallback(anon_log_cb cb);

NS_ASSUME_NONNULL_END
