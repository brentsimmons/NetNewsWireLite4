//
//  RSFileUtilities.m
//  RSCoreTests
//
//  Created by Brent Simmons on 8/20/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSFileUtilities.h"
#import "RSFoundationExtras.h"

#if !TARGET_OS_IPHONE
#pragma mark Names

NSString *RSAppNameWithAppSuffixStripped(NSString *appName) {
	if ([appName hasSuffix:@".app"])
		return [appName rs_stringByStrippingCaseInsensitiveSuffix:@".app"];
	return appName;
}


NSString *RSFileDisplayNameAtPath(NSString *f, BOOL stripAppSuffix) {
	NSString *s = [[NSFileManager defaultManager] displayNameAtPath:f];
	if (stripAppSuffix)
		return RSAppNameWithAppSuffixStripped(s);
	return s;
}


#pragma mark Existence

BOOL RSFileExists(NSString *f) {
	return f && [[NSFileManager defaultManager] fileExistsAtPath:f];
}


BOOL RSFileExistsAndIsNotFolder(NSString *f) {
	if (!f)
		return NO;
	BOOL isFolder = NO;
	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:f isDirectory:&isFolder];
	return exists && !isFolder;
}


#pragma mark Folders

BOOL RSFileIsFolder(NSString *f) {
	BOOL isFolder = NO;	
	if (![[NSFileManager defaultManager] fileExistsAtPath:f isDirectory:&isFolder])
		return NO;
	return isFolder;
}


BOOL RSFolderCreate(NSString *folder) {
	
	BOOL exists = RSFileExists (folder);
	BOOL isFolder = exists && RSFileIsFolder (folder);
	
	if (exists && !isFolder)
		return NO;
	if (exists)
		return YES;
	return [[NSFileManager defaultManager] createDirectoryAtPath:folder withIntermediateDirectories:NO attributes:nil error:nil];
}


void RSSureFolder(NSString *folder) {
	/*Makes sure folder exists, but doesn't check parent folders.*/
	if (!RSFileExists(folder))
		RSFolderCreate(folder);
}


NSString *RSSubFolderInFolder(NSString *folder, NSString *subFolder, BOOL createIfNeeded) {
	NSString *path = [folder stringByAppendingPathComponent:subFolder];
	if (createIfNeeded)
		RSSureFolder(path);
	return path;
}


BOOL RSFolderHasAtLeastOneVisibleFile(NSString *folder) {
	NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:folder];
	NSString *oneFileName;
	while ((oneFileName = [enumerator nextObject])) {
		if (![oneFileName hasPrefix:@"."])
			return YES;
	}	
	return NO;
}


#pragma mark Folder Contents

NSArray *RSFilenameArrayForFolder(NSString *folder) {
	return [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folder error:nil];
}


NSArray *RSFilePathArrayForFolder(NSString *folder, BOOL includeFolders) {
	
	NSArray *filenamesArray = RSFilenameArrayForFolder (folder);
	if (!filenamesArray)
		return nil;
	
	NSEnumerator *enumerator = [filenamesArray objectEnumerator];
	NSString *oneFilename;
	NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:[filenamesArray count]];
	while ((oneFilename = [enumerator nextObject])) {
		if ([oneFilename hasPrefix:@"."])
			continue;
		NSString *onePath = [folder stringByAppendingPathComponent:oneFilename];
		if ((!includeFolders) && (RSFileIsFolder (onePath)))
			continue;
		[tempArray addObject:onePath];
	}
	
	return [[tempArray copy] autorelease];
}


#pragma mark Copying

BOOL RSFileCopy(NSString *source, NSString *dest) {
	if (RSIsEmpty(source) || RSIsEmpty(dest) || !RSFileExists(source))
		return NO;
	if (RSFileExists(dest))
		RSFileDelete(dest);
	return [[NSFileManager defaultManager] copyItemAtPath:source toPath:dest error:nil];
	//return [[NSFileManager defaultManager] copyPath:source toPath:dest handler:nil];
}


BOOL RSFileCopyFilesInFolder(NSString *source, NSString *dest) {
	
	if (!RSFileExists(source) || !RSFileIsFolder(source))
		return NO;
	if (!RSFileExists(dest) || !RSFileIsFolder(dest))
		return NO;
	for (NSString *oneFilename in RSFilenameArrayForFolder(source)) {
		if ([oneFilename hasPrefix:@"."])
			continue;
		NSString *sourceFile = [source stringByAppendingPathComponent:oneFilename];
		NSString *destFile = [dest stringByAppendingPathComponent:oneFilename];
		if (!RSFileCopy(sourceFile, destFile))
			return NO;
	}
	
	return YES;
}


#pragma mark -
#pragma mark Delete Delegate

@interface RSFileManagerDeleteHandler : NSObject
@end

@implementation RSFileManagerDeleteHandler
+ (BOOL)fileManager:(NSFileManager *)manager shouldProcessAfterError:(NSDictionary *)errorInfo {	
	NSLog(@"File delete error: %@", errorInfo);
	return NO;
}
@end


#pragma mark Deleting

BOOL RSFileDelete(NSString *f) {
	if (RSIsEmpty (f) || !RSFileExists (f))
		return YES;
	return [[NSFileManager defaultManager] removeItemAtPath:f error:nil];
//	return [[NSFileManager defaultManager] removeFileAtPath:f handler:[RSFileManagerDeleteHandler class]];
}


#pragma mark Permissions


void RSFileSetPermissionsToOwnerReadAndWriteOnly(NSString *f) {
	NSDictionary *fileAtts = [[NSFileManager defaultManager] attributesOfItemAtPath:f error:nil];
//	NSDictionary *fileAtts = [[NSFileManager defaultManager] fileAttributesAtPath:f traverseLink:NO];
	NSMutableDictionary *newAtts = [[fileAtts mutableCopy] autorelease];
	[newAtts setObject:[NSNumber numberWithUnsignedLong:S_IRUSR + S_IWUSR] forKey:NSFilePosixPermissions];
	[[NSFileManager defaultManager] setAttributes:newAtts ofItemAtPath:f error:nil];
//	[[NSFileManager defaultManager] changeFileAttributes:newAtts atPath:f];
}

#pragma mark Attributes

unsigned long long RSFileSize(NSString *f) {
	NSDictionary *d = [[NSFileManager defaultManager] attributesOfItemAtPath:f error:nil];
	//NSDictionary *d = [[NSFileManager defaultManager] fileAttributesAtPath:f traverseLink:NO];
	if (!d)
		return 0;
	return [d fileSize];
}

#pragma mark Temp Directory

NSString *RSTempDirectory(void) {
	NSString *baseFolder = NSTemporaryDirectory();
	if (RSIsEmpty(baseFolder)) {
		baseFolder = [@"~/.tmp" stringByExpandingTildeInPath];
		if (!RSFileExists(baseFolder))
			RSFolderCreate(baseFolder);
	}
	NSString *folder = [baseFolder stringByAppendingPathComponent:[[NSProcessInfo processInfo] processName]];
	if (!RSFileExists(folder))
		RSFolderCreate(folder);
	return folder;
}


NSString *RSTempFilePathWithFilename(NSString *fname) {
	return [RSTempDirectory() stringByAppendingPathComponent:fname];
}

#endif


BOOL RSFileIsPNG(NSString *path) {
	/*Read just the first part of the file. Caller should have already locked access.*/
	NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
	NSData *topOfFileData = nil;
	@try {
		topOfFileData = [fileHandle readDataOfLength:8];
	}
	@catch (NSException * e) {
		NSLog(@"RSFileIsPNG: error reading %@", path); //really shouldn't happen, but docs say readDataOfLength can throw NSFileHandleOperationException
		topOfFileData = nil;
	}
	if (topOfFileData != nil)
		return [topOfFileData dataIsPNG];
	return NO;
}

