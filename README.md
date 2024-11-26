# AnyoneKit

[![Version](https://img.shields.io/cocoapods/v/AnyoneKit.svg?style=flat)](https://cocoapods.org/pods/AnyoneKit)
[![License](https://img.shields.io/cocoapods/l/AnyoneKit.svg?style=flat)](https://cocoapods.org/pods/AnyoneKit)
[![Platform](https://img.shields.io/cocoapods/p/AnyoneKit.svg?style=flat)](https://cocoapods.org/pods/AnyoneKit)

AnyoneKit is the easiest way to embed the Anyone/anon network in your iOS and macOS application.

Currently, the framework contains the following versions of `anon`, `libevent`, `openssl`, and `liblzma`:

| Component | Version  |
|:--------- | --------:|
| anon      | 0.4.9.8  |
| libevent  | 2.1.12   |
| OpenSSL   | 3.4.0    |
| liblzma   | 5.6.3    |


## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

- iOS 12.0 or later
- MacOS 10.13 or later
- Xcode 15.0 or later
- `autoconf`,  `automake`, `libtool` and  `gettext` in your `PATH`


## Installation

AnyoneKit is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
use_frameworks!
pod 'AnyoneKit', '~> 409'
```


## Preparing a new release

For maintainers/contributors of AnyoneKit, a new release should be prepared by 
doing the following:

- Install build tools via [Homebrew](https://brew.sh):

```sh
brew install automake autoconf libtool gettext
```

- Update the version numbers of the libraries used in [`build-xcframework.sh`](build-xcframework.sh).

- Run [`build-xcframework.sh`](build-xcframework.sh), check the logs and test the created `anon.xcframework`
  with the contained example apps.

- Update info and version numbers in `README.md` and `AnyoneKit.podspec`!

- Commit, tag and push new release.

- Zip `anon.framework`:

```sh
zip -r anon.xcframework.zip anon.xcframework
```

- Create a pre-release on https://github.com/anyone-protocol/AnyoneKit/releases with the latest 
  info as per older releases and zip and upload the created anon.xcframework.

- Then lint like this:

```sh
pod lib lint --allow-warnings
```

- If the linting went well, create a git tag for the version, push to GitHub and then publish to CocoaPods:

```sh
pod trunk push --allow-warnings --skip-import-validation --skip-tests
```

- Then update the [release](https://github.com/anyone-protocol/AnyoneKit/releases) in GitHub, 
  setting it as the latest release.


## Usage

Starting an instance of the anon client involves using three classes: `AnonThread`, `AnonConfiguration` and `AnonController`.

Here is an example of integrating anon with `NSURLSession`:

```objc
AnonConfiguration *configuration = [AnonConfiguration new];
configuration.ignoreMissingAnonrc = YES;
configuration.cookieAuthentication = YES;
configuration.dataDirectory = [NSURL fileURLWithPath:NSTemporaryDirectory()];
configuration.controlSocket = [configuration.dataDirectory URLByAppendingPathComponent:@"control_port"];

AnonThread *thread = [[AnonThread alloc] initWithConfiguration:configuration];
[thread start];

NSData *cookie = configuration.cookie;
AnonController *controller = [[AnonController alloc] initWithSocketURL:configuration.controlSocket];

NSError *error;
[controller connect:&error];

if (error) {
    NSLog(@"Error: %@", error);
    return;
}

[controller authenticateWithData:cookie completion:^(BOOL success, NSError *error) {
    if (!success)
        return;

    [controller addObserverForCircuitEstablished:^(BOOL established) {
        if (!established)
            return;

        [controller getSessionConfiguration:^(NSURLSessionConfiguration *configuration) {
            NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
            ...
        }];
    }];
}];
```

You might also want to have a look at the example iOS and macOS apps contained in the repository:
https://github.com/anyone-protocol/AnyoneKit/tree/pure_pod/Example 


### GeoIP

If you want to use the provided GeoIP files, add this to your configuration:

```objc
AnonConfiguration *configuration = [AnonConfiguration new];
configuration.geoipFile = NSBundle.geoIpBundle.geoipFile;
configuration.geoip6File = NSBundle.geoIpBundle.geoip6File;
```


## Authors

### The original Tor.framework

- Conrad Kramer, conrad@conradkramer.com
- Chris Ballinger, chris@chatsecure.org
- Mike Tigas, mike@tig.as
- Benjamin Erhart, berhart@netzarchitekten.com

### AnyoneKit

- Benjamin Erhart, berhart@netzarchitekten.com


## License

AnyoneKit is available under the MIT license. See the 
[`LICENSE`](LICENSE) file for more info.
