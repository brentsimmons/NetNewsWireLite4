/*
    NNWStyleSheetController.h
    NetNewsWire

    Created by Brent Simmons on Sat Jun 19 2004.
    Copyright (c) 2004 Ranchero Software. All rights reserved.
*/


#import <Foundation/Foundation.h>


extern NSString *NNWStyleSheetDefaultsNameKey;

@class NNWArticleTheme;


@interface NNWStyleSheetController : NSObject {
@private
    BOOL installDidError;
    NNWArticleTheme *defaultArticleTheme;
    NSArray *styleSheetNames;
    NSCache *styleSheetCache;
    NSString *folderPath;
    NSString *installError;
}


+ (NNWStyleSheetController *)sharedController;


@property (nonatomic, strong, readonly) NSArray *styleSheetNames;
@property (nonatomic, strong, readonly) NNWArticleTheme *defaultArticleTheme; //user's global setting (set in NSUserDefaults)


#pragma mark NNWStyleDocument Support

@property (nonatomic, strong, readonly) NSString *installError;

- (BOOL)installStyleDocument:(NSString *)pathToDocument;
- (BOOL)styleIsInstalled:(NSString *)pathToDocument;
- (BOOL)styleWithSameNameIsInstalled:(NSString *)pathToDocument;


@end
