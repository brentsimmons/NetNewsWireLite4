//
//  NNWInstapaperCredentialsEditor.m
//  nnw
//
//  Created by Brent Simmons on 1/16/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWInstapaperCredentialsEditor.h"
#import "NNWCredentialsWindowController.h"
#import "RSKeychain.h"


NSString *NNWInstapaperAccountUsernameKey = @"instapaper_account";
NSString *NNWInstapaperDomain = @"www.instapaper.com";
NSString *NNWInstapaperPath = @"/api/add";


@interface NNWInstapaperCredentialsEditor ()

@property (nonatomic, retain, readwrite) NSString *username;
@property (nonatomic, retain, readwrite) NSString *password;
@end


@implementation NNWInstapaperCredentialsEditor


- (BOOL)editInstapaperCredentials {

	NNWCredentialsWindowController *credentialsWindowController = [[[NNWCredentialsWindowController alloc] init] autorelease];
	
	credentialsWindowController.username = self.username;
	credentialsWindowController.password = self.password;
	
	[[credentialsWindowController window] setTitle:NSLocalizedStringFromTable(@"Instapaper Account", @"Instapaper", @"Credentials window - window title")];
	[[credentialsWindowController.usernameTextField cell] setPlaceholderString:NSLocalizedStringFromTable(@"Email address (probably)", @"Instapaper", @"Credentials window - username placeholder")];
	[[credentialsWindowController.passwordTextField cell] setPlaceholderString:NSLocalizedStringFromTable(@"If you have one", @"Instapaper", @"Credentials window - password placeholder")];
	[credentialsWindowController.messageTextField setStringValue:NSLocalizedStringFromTable(@"Type your username below. It’s probably your email address. Also enter your password, if you have one.", @"Instapaper", @"Credentials window - message")];
	[credentialsWindowController.imageView setImage:[NSImage imageNamed:@"instapaper"]];
	
	NNWCredentialsResult *credentialsResult = [credentialsWindowController runModalForBackgroundWindow:[NSApp mainWindow]];
	
	if (credentialsResult.userDidCancel)
		return NO;
	self.username = credentialsResult.username;
	self.password = credentialsResult.password;
	return YES;
}


- (NSString *)username {
	return [[NSUserDefaults standardUserDefaults] objectForKey:NNWInstapaperAccountUsernameKey];
}


- (void)setUsername:(NSString *)aUsername {
	if (aUsername == nil)
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:NNWInstapaperAccountUsernameKey];
	else
		[[NSUserDefaults standardUserDefaults] setObject:aUsername forKey:NNWInstapaperAccountUsernameKey];
}


- (NSString *)password {
	return [RSKeychain fetchInternetPasswordFromKeychain:nil username:self.username serverName:NNWInstapaperDomain path:NNWInstapaperPath protocolType:kSecProtocolTypeHTTP error:nil];
}


- (void)setPassword:(NSString *)aPassword {
	if (aPassword == nil)
		aPassword = @"";
	[RSKeychain storeInternetPasswordInKeychain:aPassword username:self.username serverName:NNWInstapaperDomain path:NNWInstapaperPath protocolType:kSecProtocolTypeHTTP error:nil];

}


@end
