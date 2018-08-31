//
//  RSFileUtilities.h
//  RSCoreTests
//
//  Created by Brent Simmons on 8/20/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#if !TARGET_OS_IPHONE
BOOL RSFileExists(NSString *f);
BOOL RSFileExistsAndIsNotFolder(NSString *f);
	
BOOL RSFileIsFolder(NSString *f);
BOOL RSFolderCreate(NSString *folder);
void RSSureFolder(NSString *folder);
NSString *RSSubFolderInFolder(NSString *folder, NSString *subFolder, BOOL createIfNeeded);

BOOL RSFolderHasAtLeastOneVisibleFile(NSString *folder);
NSArray *RSFilenameArrayForFolder(NSString *folder);
NSArray *RSFilePathArrayForFolder(NSString *folder, BOOL includeFolders);

NSString *RSAppNameWithAppSuffixStripped(NSString *appName);
NSString *RSFileDisplayNameAtPath(NSString *f, BOOL stripAppSuffix);

BOOL RSFileCopy(NSString *source, NSString *dest);

BOOL RSFileCopyFilesInFolder(NSString *source, NSString *dest);

BOOL RSFileDelete(NSString *f);

void RSFileSetPermissionsToOwnerReadAndWriteOnly(NSString *f);

unsigned long long RSFileSize(NSString *f);

NSString *RSTempDirectory(void);
NSString *RSTempFilePathWithFilename(NSString *fname);
#endif



BOOL RSFileIsPNG(NSString *path); //Caller should have locked access to file.
