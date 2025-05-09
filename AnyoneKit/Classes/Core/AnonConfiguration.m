//
//  AnonConfiguration.m
//  AnyoneKit
//
//  Created by Conrad Kramer on 8/10/15.
//

#import "AnonConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@implementation AnonConfiguration

- (NSMutableDictionary *)options
{
    if (!_options) _options = [NSMutableDictionary new];

    return _options;
}

- (NSMutableArray *)arguments
{
    if (!_arguments) _arguments = [NSMutableArray new];
    
    return _arguments;
}

- (nullable NSURL *)controlPortFile
{
    return [self.dataDirectory URLByAppendingPathComponent:@"controlport"];
}

- (nullable NSURL *)serviceAuthDirectory
{
    return [self.hiddenServiceDirectory URLByAppendingPathComponent:@"authorized_clients"];
}

- (BOOL)isLocked
{
    NSURL *url = [self.dataDirectory URLByAppendingPathComponent:@"lock"];
    NSString *path = url.path;

    if (!path || !url.isFileURL) return false;

    return [NSFileManager.defaultManager fileExistsAtPath:path];
}

- (nullable NSData *)cookie
{
    NSURL *url = [self.dataDirectory URLByAppendingPathComponent:@"control_auth_cookie"];

    if (!url || !url.isFileURL) return nil;

    return [[NSData alloc] initWithContentsOfURL:url];
}

- (NSString *)valueOf:(NSString *)key
{
    for (NSString *dictKey in self.options.allKeys) {
        if ([dictKey caseInsensitiveCompare:key] == NSOrderedSame) {
            return self.options[dictKey];
        }
    }

    key = [[NSString alloc] initWithFormat:@"--%@", key];

    for (NSString *arg in self.arguments) {
        if ([arg caseInsensitiveCompare:key] == NSOrderedSame) {
            NSUInteger i = [self.arguments indexOfObject:arg];

            if (i + 1 < self.arguments.count) {
                return self.arguments[i + 1];
            }
        }
    }

    return nil;
}

- (NSArray<NSString *> *)compile
{
    NSMutableArray<NSString *> *arguments = [NSMutableArray new];

    [arguments addObject:@"--agree-to-terms"];

    if (self.ignoreMissingAnonrc) {
        [arguments addObjectsFromArray:@[@"--allow-missing-anonrc", @"--ignore-missing-anonrc"]];
    }

    if (self.avoidDiskWrites) {
        [arguments addObjectsFromArray:@[@"--AvoidDiskWrites", @"1"]];
    }

    if (self.clientOnly) {
        [arguments addObjectsFromArray:@[@"--ClientOnly", @"1"]];
    }

    NSString *dataDir = self.dataDirectory.path;
    if (self.dataDirectory.isFileURL && dataDir) {
        [arguments addObjectsFromArray:@[@"--DataDirectory", dataDir]];
    }

    NSString *cacheDir = self.cacheDirectory.path;
    if (self.cacheDirectory.isFileURL && cacheDir) {
        [arguments addObjectsFromArray:@[@"--CacheDirectory", cacheDir]];
    }

    if (self.cookieAuthentication) {
        [arguments addObjectsFromArray:@[@"--CookieAuthentication", @"1"]];
    }

    NSString *controlPortFile = self.controlPortFile.path;
    if (self.autoControlPort && self.controlPortFile.isFileURL && controlPortFile) {
        [arguments addObjectsFromArray:@[@"--ControlPort", @"auto", @"--ControlPortWriteToFile", controlPortFile]];
    }

    NSString *controlSocket = self.controlSocket.path;
    if (self.controlSocket.isFileURL && controlSocket) {
        [arguments addObjectsFromArray:@[@"--ControlSocket", controlSocket]];
    }

    NSString *socksPath = self.socksURL.path;
    if (self.socksURL.isFileURL && socksPath) {
        [arguments addObjectsFromArray:@[@"--SocksPort", [NSString stringWithFormat:@"unix:%@", socksPath]]];
    }

    if (self.socksPort > 0) {
        [arguments addObjectsFromArray:@[@"--SocksPort", [NSString stringWithFormat:@"%lu", (unsigned long)self.socksPort]]];
    }

    if (self.dnsPort > 0) {
        [arguments addObjectsFromArray:@[@"--DnsPort", [NSString stringWithFormat:@"%lu", (unsigned long)self.dnsPort]]];
    }

    NSString *clientAuthDir = self.clientAuthDirectory.path;
    if (self.clientAuthDirectory.isFileURL && clientAuthDir) {
        [arguments addObjectsFromArray:@[@"--ClientOnionAuthDir", clientAuthDir]];
    }

    NSString *hiddenServiceDir = self.hiddenServiceDirectory.path;
    if (!self.clientOnly && self.hiddenServiceDirectory.isFileURL && hiddenServiceDir) {
        [arguments addObjectsFromArray:@[@"--HiddenServiceDir", hiddenServiceDir]];
    }

    NSString *geoipFile = self.geoipFile.path;
    if (self.geoipFile.isFileURL && geoipFile) {
        [arguments addObjectsFromArray:@[@"--GeoIPFile", geoipFile]];
    }

    NSString *geoip6File = self.geoip6File.path;
    if (self.geoip6File.isFileURL && geoip6File) {
        [arguments addObjectsFromArray:@[@"--GeoIPv6File", geoip6File]];
    }

    NSString *logfile = self.logfile.path;
    if (self.logfile.isFileURL && logfile) {
        [arguments addObjectsFromArray:@[@"--Log", [NSString stringWithFormat:@"notice file %@", logfile]]];
    }

    [arguments addObjectsFromArray:self.arguments];

    for (NSString *key in self.options.allKeys) {
        [arguments addObject:[NSString stringWithFormat:@"--%@", key]];

        NSString *value = self.options[key];
        if (value) [arguments addObject:value];
    }

    return arguments;
}

@end

NS_ASSUME_NONNULL_END
