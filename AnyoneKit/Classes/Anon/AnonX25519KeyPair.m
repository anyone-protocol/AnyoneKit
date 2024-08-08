//
//  AnonX25519KeyPair.m
//  AnyoneKit
//
//  Created by Benjamin Erhart on 11.10.21.
//

#import "AnonX25519KeyPair.h"
#import <lib/malloc/malloc.h>
#import <lib/crypt_ops/crypto_curve25519.h>
#import <lib/encoding/binascii.h>


@implementation AnonX25519KeyPair


- (instancetype)init
{
    if ((self = [super init]))
    {
        curve25519_keypair_t *keypair = tor_malloc_zero(sizeof(curve25519_keypair_t));

        curve25519_init();

        curve25519_keypair_generate(keypair, 0);

        _privateKey = [AnonX25519KeyPair base32Encode:[
            NSData dataWithBytes:keypair->seckey.secret_key
            length:sizeof(keypair->seckey.secret_key)]];

        _publicKey = [AnonX25519KeyPair base32Encode:[
            NSData dataWithBytes:keypair->pubkey.public_key
            length:sizeof(keypair->pubkey.public_key)]];

        tor_free(keypair);
    }

    return self;
}

- (instancetype)initWithBase32PrivateKey:(NSString *)privateKey andPublicKey:(NSString *)publicKey
{
    if ((self = [super init]))
    {
        _privateKey = privateKey;
        _publicKey = publicKey;
    }

    return self;
}

- (instancetype)initWithPrivateKey:(NSData *)privateKey andPublicKey:(NSData *)publicKey
{
    if ((self = [super init]))
    {
        _privateKey = [AnonX25519KeyPair base32Encode:privateKey];
        _publicKey = [AnonX25519KeyPair base32Encode:publicKey];
    }

    return self;
}


// MARK: Public Methods

- (nullable AnonAuthKey *)getPrivateAuthKeyForDomain:(nonnull NSString *)domain
{
    if (domain.length < 1) return nil;

    NSURLComponents *urlc = [NSURLComponents new];
    urlc.scheme = @"http";
    urlc.host = domain;

    NSURL *url = urlc.URL;
    if (!url) return nil;

    return [self getPrivateAuthKeyForUrl:url];
}

- (nullable AnonAuthKey *)getPrivateAuthKeyForUrl:(nonnull NSURL *)url
{
    NSString *privateKey = _privateKey;
    if (!privateKey) return nil;

    return [[AnonAuthKey alloc] initPrivate:privateKey forDomain:url];
}

- (nullable AnonAuthKey *)getPublicAuthKeyWithName:(nonnull NSString *)name
{
    NSString *publicKey = _publicKey;
    if (!publicKey) return nil;

    if (name.length < 1) return nil;

    return [[AnonAuthKey alloc] initPublic:publicKey withName:name];
}


// MARK: Public Class Methods

+ (nullable NSString *)base32Encode:(NSData *)raw
{
    char dest[base32_encoded_size(raw.length)];

    base32_encode(dest, sizeof(dest), raw.bytes, raw.length);

    return [NSString stringWithUTF8String:dest];
}

+ (nullable NSData *)base32Decode:(NSString *)encoded
{
    const char *src = [encoded cStringUsingEncoding:kCFStringEncodingUTF8];

    char dest[sizeof(src) * 5 / 8];

    base32_decode(dest, sizeof(dest), src, sizeof(src));

    return [NSData dataWithBytes:dest length:sizeof(dest)];
}


@end
