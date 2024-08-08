//
//  AnonController.h
//  AnyoneKit
//
//  Created by Conrad Kramer on 5/10/14.
//

#import <Foundation/Foundation.h>
#import "AnonCircuit.h"

#ifdef __cplusplus
#define TOR_EXTERN extern "C" __attribute__((visibility ("default")))
#else
#define TOR_EXTERN extern __attribute__((visibility ("default")))
#endif

NS_ASSUME_NONNULL_BEGIN

typedef BOOL (^AnonObserverBlock)(NSArray<NSNumber *> *codes, NSArray<NSData *> *lines, BOOL *stop);

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000 || __MAC_OS_X_VERSION_MAX_ALLOWED >= 101200
TOR_EXTERN NSErrorDomain const AnonControllerErrorDomain;
#else
TOR_EXTERN NSString * const AnonControllerErrorDomain;
#endif

@interface AnonController : NSObject

@property (nonatomic, readonly, copy) NSOrderedSet<NSString *> *events;
@property (nonatomic, readonly, getter=isConnected) BOOL connected;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithSocketURL:(NSURL *)url NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithSocketHost:(NSString *)host port:(in_port_t)port NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithControlPortFile:(NSURL *)file;

- (BOOL)connect:(out NSError **)error;
- (void)disconnect;

// Commands
- (void)authenticateWithData:(NSData *)data completion:(void (^__nullable)(BOOL success, NSError * __nullable error))completion;
- (void)resetConfForKey:(NSString *)key completion:(void (^__nullable)(BOOL success, NSError * __nullable error))completion;
- (void)setConfForKey:(NSString *)key withValue:(NSString *)value completion:(void (^__nullable)(BOOL success, NSError * __nullable error))completion;
- (void)setConfs:(NSArray<NSDictionary *> *)configs completion:(void (^__nullable)(BOOL success, NSError * __nullable error))completion;
- (void)listenForEvents:(NSArray<NSString *> *)events completion:(void (^__nullable)(BOOL success, NSError * __nullable error))completion;
- (void)getInfoForKeys:(NSArray<NSString *> *)keys completion:(void (^)(NSArray<NSString *> *values))completion; // TODO: Provide errors
- (void)getSessionConfiguration:(void (^)(NSURLSessionConfiguration * __nullable configuration))completion;
- (void)sendCommand:(NSString *)command arguments:(nullable NSArray<NSString *> *)arguments data:(nullable NSData *)data observer:(AnonObserverBlock)observer;

/**
 Get a list of all currently available circuits with detailed information about their nodes.

 @note There's no clear way to determine, which circuit actually was used by a specific request.

 @param completion The callback upon completion of the task. Will return A list of `AnonCircuit`s . Empty if no circuit could be found.
 */
- (void)getCircuits:(void (^)(NSArray<AnonCircuit *> * _Nonnull circuits))completion;

/**
 Resets the Anon connection: Sends "SIGNAL RELOAD" and "SIGNAL NEWNYM" to the Anon thread.

 See https://torproject.gitlab.io/torspec/control-spec.html#signal

 @param completion Completion callback. Will return true, if signal calls where successful, false if not.
 */
- (void)resetConnection:(void (^__nullable)(BOOL success))completion;

/**
 Try to close a list of circuits identified by their IDs.

 If some closings weren't successful, the most obvious reason would be, that the circuit with the given
 ID doesn't exist (anymore). So in many circumstances, you can still consider that an ok outcome.

 @param circuitIds List of circuit IDs.
 @param completion Completion callback. Will return true, if *all* closings were successful, false, if *at least one* closing failed.
 */
- (void)closeCircuitsByIds:(NSArray<NSString *> *)circuitIds completion:(void (^__nullable)(BOOL success))completion;

/**
 Try to close a list of given circuits.

 The given circuits are invalid afterwards, as you just closed them. You should throw them away on completion.

@param circuits List of circuits to close.
@param completion  Completion callback. Will return true, if *all* closings were successful, false, if *at least one* closing failed.
*/
- (void)closeCircuits:(NSArray<AnonCircuit *> *)circuits completion:(void (^__nullable)(BOOL success))completion;

/**
 Resolve countries of given `AnonNode`s and updates their `countryCode` property on success.

 Nodes which already contain a `countryCode` will be ignored.
 IPv4 addresses will be preferred, if Anon is able to resolve IPv4 addresses (if it has loaded the IPv4 geoip database),
 and if the node has a `ipv4Address` property of non-zero length.

 @param nodes List of `AnonNode`s to resolve countries for.
 @param testCapabilities Ask Anon first, if it is actually able to resolve. (If GeoDB databases are loaded.) Pass NO, if you're sure that Anon is able to to save on queries.
 @param completion Completion callback.
 */
- (void)resolveCountriesOfNodes:(NSArray<AnonNode *> * _Nullable)nodes testCapabilities:(BOOL)testCapabilities completion:(void (^__nullable)(void))completion;

// Observers
- (id)addObserverForCircuitEstablished:(void (^)(BOOL established))block;
- (id)addObserverForStatusEvents:(BOOL (^)(NSString *type, NSString *severity, NSString *action, NSDictionary<NSString *, NSString *> * __nullable arguments))block;
- (void)removeObserver:(nullable id)observer;

@end

NS_ASSUME_NONNULL_END
