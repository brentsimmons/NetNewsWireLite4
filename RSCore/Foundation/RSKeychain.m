//
//  RSKeychain.m
//  RSCoreTests
//
//  Created by Brent Simmons on 7/31/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSKeychain.h"
#import "RSFoundationExtras.h"
#if TARGET_OS_IPHONE
#import "SFHFKeychainUtils.h"
#else
#import <Security/Security.h>
#endif

#define RSKEYCHAIN_DEBUG 0

#pragma mark -
#pragma mark iOS

#if TARGET_OS_IPHONE

BOOL RSKeychainGetPassword(NSString *serviceName, NSString *username, NSString **password, NSError **error) {
    *password = [SFHFKeychainUtils getPasswordForUsername:username andServiceName:serviceName error:error];
#if RSKEYCHAIN_DEBUG
    if (*error != nil)
        NSLog(@"Error fetching from keychain: %@ [%@]", RSKeychainEnglishStringForErrorCode([*error code]), serviceName);
#endif
    return *error == nil;
}


BOOL RSKeychainSetPassword(NSString *serviceName, NSString *username, NSString *password, NSError **error) {
    BOOL didSetPassword = [SFHFKeychainUtils storeUsername:username andPassword:password forServiceName:serviceName updateExisting:YES error:error];
#if RSKEYCHAIN_DEBUG
    if (!didSetPassword)
        NSLog(@"Error setting in keychain: %@ [%@]", RSKeychainEnglishStringForErrorCode([*error code]), serviceName);
#endif
    return didSetPassword;
}


BOOL RSKeychainDeletePassword(NSString *serviceName, NSString *username, NSError **error) {
    BOOL didDeletePassword = [SFHFKeychainUtils deleteItemForUsername:username andServiceName:serviceName error:error];
#if RSKEYCHAIN_DEBUG
    if (!didDeletePassword)
        NSLog(@"Error deleting from keychain: %@ [%@]", RSKeychainEnglishStringForErrorCode([*error code]), serviceName);
#endif
    return didDeletePassword;
}


NSString *RSKeychainEnglishStringForErrorCode(OSErr errorCode) {
    /*Just borrowed from the comments in SecBase.h*/
    if (errorCode == errSecSuccess)
        return nil;
    if (errorCode == errSecUnimplemented)
        return @"Function or operation not implemented.";
    if (errorCode == errSecParam)
        return @"One or more parameters passed to a function where not valid.";
    if (errorCode == errSecAllocate)
        return @"Failed to allocate memory.";
    if (errorCode == errSecNotAvailable)
        return @"No keychain is available. You may need to restart your computer.";
    if (errorCode == errSecDuplicateItem)
        return @"The specified item already exists in the keychain.";
    if (errorCode == errSecItemNotFound)
        return @"The specified item could not be found in the keychain.";
    if (errorCode == errSecInteractionNotAllowed)
        return @"User interaction is not allowed.";
    if (errorCode == errSecDecode)
        return @"Unable to decode the provided data.";
    return [NSString stringWithFormat:@"Unknown keychain error code! %d", errorCode];
}


BOOL RSKeychainFetchPlistFromKeychain(id *plist, NSString *serviceName, NSString *username, NSError **error) {
    NSString *plistString = nil;
    if (!RSKeychainGetPassword(serviceName, username, &plistString, error))
        return NO;
    if (RSIsEmpty(plistString))
        return YES; //no error: it just wasn't found
    NSPropertyListFormat plistFormat = kCFPropertyListXMLFormat_v1_0;
    NSString *errorString = nil;
    *plist = [NSPropertyListSerialization propertyListFromData:[plistString dataUsingEncoding:NSUTF8StringEncoding] mutabilityOption:NSPropertyListImmutable format:&plistFormat errorDescription:&errorString];
    if (errorString != nil) {
        [errorString release]; //Docs say to release it
        return NO;
    }
    return YES;
}


BOOL RSKeychainStorePlist(id plistToStore, NSString *serviceName, NSString *username, NSError **error) {
    NSString *errorString = nil;
    NSData *plistToStoreData = [NSPropertyListSerialization dataFromPropertyList:plistToStore format:kCFPropertyListXMLFormat_v1_0 errorDescription:&errorString];
    if (errorString != nil) {
        [errorString release]; //Docs say to release it
        return NO;
    }
    NSString *plistString = [[[NSString alloc] initWithData:plistToStoreData encoding:NSUTF8StringEncoding] autorelease];
    return RSKeychainSetPassword(serviceName, username, plistString, error);
}


#else //Mac

#pragma mark -
#pragma mark Mac


BOOL RSKeychainGetPassword(NSString *serviceName, NSString *username, NSString **password, NSError **error) {
    return NO; //TODO: RSKeychainGetPassword - Mac
}


BOOL RSKeychainSetPassword(NSString *serviceName, NSString *username, NSString *password, NSError **error) {
    return NO; //TODO: RSKeychainSetPassword - Mac
}


BOOL RSKeychainDeletePassword(NSString *serviceName, NSString *username, NSError **error) {
    return NO; //TODO: RSKeychainDeletePassword - Mac
}




@implementation RSKeychain

static const char *_UTF8StringForString(NSString *s) {
    return RSStringIsEmpty(s) ? nil : [s UTF8String];
}


+ (BOOL)storeInternetPasswordInKeychain:(NSString *)password username:(NSString *)username serverName:(NSString *)serverName path:(NSString *)path protocolType:(SecProtocolType)protocolType error:(NSError **)error {
    
    //OSErr err = noErr;
    SecKeychainItemRef keychainItemRef = nil;
    NSString *foundPassword = [self fetchInternetPasswordFromKeychain:&keychainItemRef username:username serverName:serverName path:path protocolType:protocolType error:error];
    
    if (!RSStringIsEmpty(foundPassword) && [foundPassword isEqualToString:password])
        return YES; /*no need to store or update*/
    if (!password)
        password = @"";
        const char *passwordUTF8String = _UTF8StringForString(password);
        if (!passwordUTF8String) {
            return YES;
        }
    
    if (!keychainItemRef) { /*store new item*/
        
        const char *serverNameUTF8String = _UTF8StringForString(serverName);
        const char *usernameUTF8String = _UTF8StringForString(username);
        const char *pathUTF8String = _UTF8StringForString(path);
        
        if (!serverNameUTF8String || !usernameUTF8String)
            return YES;
        if (!pathUTF8String)
            pathUTF8String = [@"" UTF8String];
        
        /*err =*/ SecKeychainAddInternetPassword(nil,
                                                 (UInt32)strlen(serverNameUTF8String), serverNameUTF8String,
                                                 0, nil,
                                                 (UInt32)strlen(usernameUTF8String), usernameUTF8String,
                                                 (UInt32)strlen(pathUTF8String), pathUTF8String,
                                                 0,
                                                 protocolType,
                                                 kSecAuthenticationTypeAny,
                                                 (UInt32)strlen(passwordUTF8String), passwordUTF8String,
                                                 nil);
    }
    
    else { /*update item with new password*/    
        /*err = */ SecKeychainItemModifyContent (keychainItemRef, nil, (UInt32)strlen (passwordUTF8String), passwordUTF8String);
    }
    return YES;
}


+ (NSString *)fetchInternetPasswordFromKeychain:(SecKeychainItemRef *)keychainItemRef username:(NSString *)username serverName:(NSString *)serverName path:(NSString *)path protocolType:(SecProtocolType)protocolType error:(NSError **)error {
    
    OSStatus err = noErr;
    const char *serverNameUTF8String = _UTF8StringForString(serverName);
    const char *usernameUTF8String = _UTF8StringForString(username);
    const char *pathUTF8String = _UTF8StringForString(path);
    UInt32 passwordLength = 0;
    char *passwordData;
    
    if (!serverNameUTF8String || !usernameUTF8String)
        return nil;    
    if (!pathUTF8String)
        pathUTF8String = [@"" UTF8String];
        
        err = SecKeychainFindInternetPassword(nil,
                                              (UInt32)strlen(serverNameUTF8String), serverNameUTF8String,
                                              0, nil, 
                                              (UInt32)strlen(usernameUTF8String), usernameUTF8String, 
                                              (UInt32)strlen(pathUTF8String), pathUTF8String, 
                                              0,
                                              protocolType, 
                                              kSecAuthenticationTypeAny, 
                                              &passwordLength, 
                                              (void**)&passwordData,
                                              keychainItemRef);
        
        if (err == noErr && passwordLength > 0) {
            NSString *p = [[NSString alloc] initWithBytes:(const void *)passwordData length:passwordLength encoding:NSUTF8StringEncoding];
            SecKeychainItemFreeContent(nil, passwordData);
            return p;
        }
    
    return nil;
}


NSString *RSKeychainFetchInternetPassword(NSURL *URL, NSString *username) {
    SecKeychainItemRef keychainItemRef = nil;
    NSError *error = nil;
    return [RSKeychain fetchInternetPasswordFromKeychain:&keychainItemRef username:username serverName:[URL host] path:[URL path] protocolType:kSecProtocolTypeAny error:&error];
}


BOOL RSKeychainStoreInternetPassword(NSURL *URL, NSString *username, NSString *password) {
    NSError *error = nil;
    BOOL success = [RSKeychain storeInternetPasswordInKeychain:password username:username serverName:[URL host] path:[URL path] protocolType:kSecProtocolTypeAny error:&error];
    if (!success && error != nil)
        NSLog(@"Error storing in keychain: %@", error);
    return success;
}


@end

#endif
