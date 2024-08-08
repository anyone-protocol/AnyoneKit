//
//  AnonControlReplyCode.h
//  AnyoneKit
//
//  Created by Denis Kutlubaev on 30.03.2021.
//

#ifndef AnonControlReplyCode_h
#define AnonControlReplyCode_h

/**
 Anon control reply codes
 https://github.com/torproject/torspec/blob/master/control-spec.txt

 The following codes are defined:

 250 OK
 251 Operation was unnecessary
 [Tor has declined to perform the operation, but no harm was done.]

 451 Resource exhausted

 500 Syntax error: protocol

 510 Unrecognized command
 511 Unimplemented command
 512 Syntax error in command argument
 513 Unrecognized command argument
 514 Authentication required
 515 Bad authentication

 550 Unspecified Tor error

 551 Internal error
 [Something went wrong inside Tor, so that the client's
 request couldn't be fulfilled.]

 552 Unrecognized entity
 [A configuration key, a stream ID, circuit ID, event,
 mentioned in the command did not actually exist.]

 553 Invalid configuration value
 [The client tried to set a configuration option to an
 incorrect, ill-formed, or impossible value.]

 554 Invalid descriptor

 555 Unmanaged entity

 650 Asynchronous event notification
 */
typedef NS_ENUM(NSInteger, AnonControlReplyCode) {
    AnonControlReplyCodeOK                              = 250,
    AnonControlReplyCodeOperationWasUnnecessary         = 251,
    AnonControlReplyCodeResourceExhaused                = 451,
    AnonControlReplyCodeSyntaxErrorProtocol             = 500,
    AnonControlReplyCodeUnrecognizedCommand             = 510,
    AnonControlReplyCodeUnimplementedCommand            = 511,
    AnonControlReplyCodeSyntaxErrorInCommandArgument    = 512,
    AnonControlReplyCodeUnrecognizedCommandArgument     = 513,
    AnonControlReplyCodeAuthenticationRequired          = 514,
    AnonControlReplyCodeBadAuthentication               = 515,
    AnonControlReplyCodeUnspecifiedTorError             = 550,
    AnonControlReplyCodeInternalError                   = 551,
    AnonControlReplyCodeUnrecognizedEntity              = 552,
    AnonControlReplyCodeInvalidConfigurationValue       = 553,
    AnonControlReplyCodeInvalidDescriptor               = 554,
    AnonControlReplyCodeUnmanagedEntity                 = 555,
    AnonControlReplyCodeAsynchronousEventNotification   = 650
};

#endif /* AnonControlReplyCode_h */
