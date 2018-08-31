//
//  SFHFKeychainUtils.m
//
//  Created by Buzz Andersen on 10/20/08.
//  Based partly on code by Jonathan Wight, Jon Crosby, and Mike Malone.
//  Copyright 2008 Sci-Fi Hi-Fi. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//


/* PBS Aug. 22 2009: just use NSUserDefaults when in simulator, since simulator code doesn't work with this code when using OS 3.0. Using NSUserDefaults means it works for both 2.x and 3.x. Uses the keychain only when running on the device, in other words.*/

#import "SFHFKeychainUtils.h"
#import <Security/Security.h>

static NSString *SFHFKeychainUtilsErrorDomain = @"SFHFKeychainUtilsErrorDomain";


@implementation SFHFKeychainUtils
	
#if TARGET_IPHONE_SIMULATOR

+ (NSString *)_keyForUsername:(NSString *)username andServiceName:(NSString *)serviceName {
	return [NSString stringWithFormat:@"%@ - %@", username, serviceName];
}


+ (NSString *)getPasswordForUsername:(NSString *)username andServiceName:(NSString *)serviceName error:(NSError **)error {
	if (!username || !serviceName) {
		if (error)
			*error = [NSError errorWithDomain: SFHFKeychainUtilsErrorDomain code: -2000 userInfo: nil];
		return nil;
	}
	return [[NSUserDefaults standardUserDefaults] stringForKey:[self _keyForUsername:username andServiceName:serviceName]];
}



+ (BOOL)storeUsername:(NSString *)username andPassword:(NSString *)password forServiceName:(NSString *)serviceName updateExisting:(BOOL)updateExisting error:(NSError **)error {
	if (!username || !password || !serviceName) {
		if (error)
			*error = [NSError errorWithDomain: SFHFKeychainUtilsErrorDomain code: -2000 userInfo: nil];
		return NO;
	}
	[[NSUserDefaults standardUserDefaults] setObject:password forKey:[self _keyForUsername:username andServiceName:serviceName]];
	return YES;
}



+ (BOOL)deleteItemForUsername:(NSString *)username andServiceName:(NSString *)serviceName error:(NSError **)error {
	if (!username || !serviceName) {
		if (error)
			*error = [NSError errorWithDomain: SFHFKeychainUtilsErrorDomain code: 2000 userInfo: nil];
		return NO;
	}
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:[self _keyForUsername:username andServiceName:serviceName]];
	return YES;
}


#else

+ (NSString *) getPasswordForUsername: (NSString *) username andServiceName: (NSString *) serviceName error: (NSError **) error {
	if (!username || !serviceName) {
		if (error)
			*error = [NSError errorWithDomain: SFHFKeychainUtilsErrorDomain code: -2000 userInfo: nil];
		return nil;
	}
	if (error)
		*error = nil;
		
	// Set up a query dictionary with the base query attributes: item type (generic), username, and service
	
	NSArray *keys = [[[NSArray alloc] initWithObjects: (NSString *) kSecClass, kSecAttrAccount, kSecAttrService, nil] autorelease];
	NSArray *objects = [[[NSArray alloc] initWithObjects: (NSString *) kSecClassGenericPassword, username, serviceName, nil] autorelease];
	
	NSMutableDictionary *query = [[[NSMutableDictionary alloc] initWithObjects: objects forKeys: keys] autorelease];
	
	// First do a query for attributes, in case we already have a Keychain item with no password data set.
	// One likely way such an incorrect item could have come about is due to the previous (incorrect)
	// version of this code (which set the password as a generic attribute instead of password data).
	
	NSDictionary *attributeResult = NULL;
	NSMutableDictionary *attributeQuery = [query mutableCopy];
	[attributeQuery setObject: (id) kCFBooleanTrue forKey:(id) kSecReturnAttributes];
	OSStatus status = SecItemCopyMatching((CFDictionaryRef) attributeQuery, (CFTypeRef *) &attributeResult);
	
	[attributeResult release];
	[attributeQuery release];
	
	if (status != noErr) {
		// No existing item found--simply return nil for the password
		if (status != errSecItemNotFound) {
			//Only return an error if a real exception happened--not simply for "not found."
			if (error)
				*error = [NSError errorWithDomain: SFHFKeychainUtilsErrorDomain code: status userInfo: nil];
		}
		
		return nil;
	}
	
	// We have an existing item, now query for the password data associated with it.
	
	NSData *resultData = nil;
	NSMutableDictionary *passwordQuery = [query mutableCopy];
	[passwordQuery setObject: (id) kCFBooleanTrue forKey: (id) kSecReturnData];

	status = SecItemCopyMatching((CFDictionaryRef) passwordQuery, (CFTypeRef *) &resultData);
	
	[resultData autorelease];
	[passwordQuery release];
	
	if (status != noErr) {
		if (status == errSecItemNotFound) {
			// We found attributes for the item previously, but no password now, so return a special error.
			// Users of this API will probably want to detect this error and prompt the user to
			// re-enter their credentials.  When you attempt to store the re-entered credentials
			// using storeUsername:andPassword:forServiceName:updateExisting:error
			// the old, incorrect entry will be deleted and a new one with a properly encrypted
			// password will be added.
			if (error)
				*error = [NSError errorWithDomain: SFHFKeychainUtilsErrorDomain code: -1999 userInfo: nil];			
		}
		else {
			// Something else went wrong. Simply return the normal Keychain API error code.
			if (error)
				*error = [NSError errorWithDomain: SFHFKeychainUtilsErrorDomain code: status userInfo: nil];
		}
		
		return nil;
	}

	NSString *password = nil;	
		
	if (resultData) {
		password = [[NSString alloc] initWithData: resultData encoding: NSUTF8StringEncoding];
	}
	else {
		// There is an existing item, but we weren't able to get password data for it for some reason,
		// Possibly as a result of an item being incorrectly entered by the previous code.
		// Set the -1999 error so the code above us can prompt the user again.
		if (error)
			*error = [NSError errorWithDomain: SFHFKeychainUtilsErrorDomain code: -1999 userInfo: nil];		
	}
			
	return [password autorelease];
}

+ (BOOL) storeUsername: (NSString *) username andPassword: (NSString *) password forServiceName: (NSString *) serviceName updateExisting: (BOOL) updateExisting error: (NSError **) error {		
	if (!username || !password || !serviceName) {
		if (error)
			*error = [NSError errorWithDomain: SFHFKeychainUtilsErrorDomain code: -2000 userInfo: nil];
		return NO;
	}
	
	// See if we already have a password entered for these credentials.
	
	NSString *existingPassword = [SFHFKeychainUtils getPasswordForUsername: username andServiceName: serviceName error: error];

	if (error && [*error code] == -1999) {
		// There is an existing entry without a password properly stored (possibly as a result of the previous incorrect version of this code.
		// Delete the existing item before moving on entering a correct one.

		*error = nil;
		
		[self deleteItemForUsername: username andServiceName: serviceName error: error];
	
		if ([*error code] != noErr) {
			return NO;
		}
	}
	else if (error && [*error code] != noErr) {
		return NO;
	}
	if (error)
		*error = nil;
	
	OSStatus status = noErr;
		
	if (existingPassword) {
		// We have an existing, properly entered item with a password.
		// Update the existing item.
		
		if ((existingPassword != password) && updateExisting) {
			//Only update if we're allowed to update existing.  If not, simply do nothing.
			
			NSArray *keys = [[[NSArray alloc] initWithObjects: (NSString *) kSecClass, 
							  kSecAttrService, 
							  kSecAttrLabel, 
							  kSecAttrAccount, 
							  nil] autorelease];
			
			NSArray *objects = [[[NSArray alloc] initWithObjects: (NSString *) kSecClassGenericPassword, 
								 serviceName,
								 serviceName,
								 username,
								 nil] autorelease];
			
			NSDictionary *query = [[[NSDictionary alloc] initWithObjects: objects forKeys: keys] autorelease];			
			
			status = SecItemUpdate((CFDictionaryRef) query, (CFDictionaryRef) [NSDictionary dictionaryWithObject: [password dataUsingEncoding: NSUTF8StringEncoding] forKey: (NSString *) kSecValueData]);
		}
	}
	else {
		// No existing entry (or an existing, improperly entered, and therefore now
		// deleted, entry).  Create a new entry.
		
		NSArray *keys = [[[NSArray alloc] initWithObjects: (NSString *) kSecClass, 
						  kSecAttrService, 
						  kSecAttrLabel, 
						  kSecAttrAccount, 
						  kSecValueData, 
						  nil] autorelease];
		
		NSArray *objects = [[[NSArray alloc] initWithObjects: (NSString *) kSecClassGenericPassword, 
							 serviceName,
							 serviceName,
							 username,
							 [password dataUsingEncoding: NSUTF8StringEncoding],
							 nil] autorelease];
		
		NSDictionary *query = [[[NSDictionary alloc] initWithObjects: objects forKeys: keys] autorelease];			

		status = SecItemAdd((CFDictionaryRef) query, NULL);
	}
	
	if (status != noErr) {
		// Something went wrong with adding the new item. Return the Keychain error code.
		if (error)
			*error = [NSError errorWithDomain: SFHFKeychainUtilsErrorDomain code: status userInfo: nil];
	}
	return status == noErr;
}

+ (BOOL) deleteItemForUsername: (NSString *) username andServiceName: (NSString *) serviceName error: (NSError **) error {
	if (!username || !serviceName) {
		if (error)
			*error = [NSError errorWithDomain: SFHFKeychainUtilsErrorDomain code: -2000 userInfo: nil];
		return NO;
	}
	if (error)
		*error = nil;
		
	NSArray *keys = [[[NSArray alloc] initWithObjects: (NSString *) kSecClass, kSecAttrAccount, kSecAttrService, kSecReturnAttributes, nil] autorelease];
	NSArray *objects = [[[NSArray alloc] initWithObjects: (NSString *) kSecClassGenericPassword, username, serviceName, kCFBooleanTrue, nil] autorelease];
	
	NSDictionary *query = [[[NSDictionary alloc] initWithObjects: objects forKeys: keys] autorelease];
	
	OSStatus status = SecItemDelete((CFDictionaryRef) query);
	
	if (error && status != noErr) {
		*error = [NSError errorWithDomain: SFHFKeychainUtilsErrorDomain code: status userInfo: nil];		
	}
	return status == noErr;
}

#endif

@end
