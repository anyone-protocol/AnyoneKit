//
//  AppDelegate.m
//  AnyoneKit
//
//  Created by Benjamin Erhart on 13.01.22.
//  Copyright © 2022 Benjamin Erhart. All rights reserved.
//

#import "AppDelegate.h"
#import <AnyoneKit/NSBundle+GeoIP.h>
#import <AnyoneKit/AnonConfiguration.h>
#import <AnyoneKit/AnonController.h>
#import <AnyoneKit/AnonThread.h>

@interface AppDelegate ()


@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSFileManager *fm = NSFileManager.defaultManager;
    NSURL *appSuppDir = [fm URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask].firstObject;

    AnonConfiguration *configuration = [AnonConfiguration new];
    configuration.ignoreMissingTorrc = YES;
    configuration.avoidDiskWrites = YES;
    configuration.clientOnly = YES;
    configuration.cookieAuthentication = YES;
    configuration.autoControlPort = YES;
    configuration.dataDirectory = [appSuppDir URLByAppendingPathComponent:@"anon"];
    configuration.geoipFile = NSBundle.geoIpBundle.geoipFile;
    configuration.geoip6File = NSBundle.geoIpBundle.geoip6File;

    AnonThread *thread = [[AnonThread alloc] initWithConfiguration:configuration];
    [thread start];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        NSData *cookie = configuration.cookie;
        AnonController *controller = [[AnonController alloc] initWithControlPortFile:configuration.controlPortFile];
        [controller authenticateWithData:cookie completion:^(BOOL success, NSError *error) {
            __weak AnonController *c = controller;

            NSLog(@"authenticated success=%d", success);

            if (!success)
            {
                return;
            }

            [c addObserverForCircuitEstablished:^(BOOL established) {
                NSLog(@"established=%d", established);

                if (!established)
                {
                    return;
                }

                CFTimeInterval startTime = CACurrentMediaTime();

                [c getCircuits:^(NSArray<AnonCircuit *> * _Nonnull circuits) {
                    NSLog(@"Circuits: %@", circuits);

                    NSLog(@"Elapsed Time: %f", CACurrentMediaTime() - startTime);
                }];
            }];
        }];
    });
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}


@end
