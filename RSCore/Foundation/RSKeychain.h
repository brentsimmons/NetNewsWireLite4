//
//  RSKeychain.h
//  RSCoreTests
//
//  Created by Brent Simmons on 7/31/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#if !TARGET_OS_IPHONE
#import <Security/Security.h>
#endif



BOOL RSKeychainGetPassword(NSString *serviceName, NSString *username, NSString **password, NSError **error);
BOOL RSKeychainSetPassword(NSString *serviceName, NSString *username, NSString *password, NSError **error);
BOOL RSKeychainDeletePassword(NSString *serviceName, NSString *username, NSError **error);

#if TARGET_OS_IPHONE

NSString *RSKeychainEnglishStringForErrorCode(OSErr errorCode);

/*These are useful for Twitter and Facebook -- when you don't have a password, but you do have secure data
 that can be stored as a dictionary.*/

BOOL RSKeychainFetchPlistFromKeychain(id *plist, NSString *serviceName, NSString *username, NSError **error);
BOOL RSKeychainStorePlist(id plistToStore, NSString *serviceName, NSString *username, NSError **error);

#else //Mac

@interface RSKeychain : NSObject

+ (BOOL)storeInternetPasswordInKeychain:(NSString *)password username:(NSString *)username serverName:(NSString *)serverName path:(NSString *)path protocolType:(SecProtocolType)protocolType error:(NSError **)error;
+ (NSString *)fetchInternetPasswordFromKeychain:(SecKeychainItemRef *)keychainItemRef username:(NSString *)username serverName:(NSString *)serverName path:(NSString *)path protocolType:(SecProtocolType)protocolType error:(NSError **)error;

NSString *RSKeychainFetchInternetPassword(NSURL *URL, NSString *username);
BOOL RSKeychainStoreInternetPassword(NSURL *URL, NSString *username, NSString *password);

@end

#endif
