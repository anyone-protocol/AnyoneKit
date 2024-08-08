//
//  AnonControlCommand.h
//  AnyoneKit
//
//  Created by Denis Kutlubaev on 30.03.2021.
//

#ifndef AnonControlCommand_h
#define AnonControlCommand_h

/** Anon control commands
 https://github.com/torproject/torspec/blob/master/control-spec.txt
 */
static NSString * const AnonCommandAuthenticate     = @"AUTHENTICATE";
static NSString * const AnonCommandSignalShutdown   = @"SIGNAL SHUTDOWN";
static NSString * const AnonCommandResetConf        = @"RESETCONF";
static NSString * const AnonCommandSetConf          = @"SETCONF";
static NSString * const AnonCommandSetEvents        = @"SETEVENTS";
static NSString * const AnonCommandGetInfo          = @"GETINFO";
static NSString * const AnonCommandSignalReload     = @"SIGNAL RELOAD";
static NSString * const AnonCommandSignalNewnym     = @"SIGNAL NEWNYM";
static NSString * const AnonCommandCloseCircuit     = @"CLOSECIRCUIT";

#endif /* AnonControlCommand_h */
