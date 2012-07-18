//
//  PhotoDAO.h
//  FlickrCast
//
//  Created by BIBHAS BHATTACHARYA on 5/24/12.
//  Copyright (c) 2012 Self. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Photo.h"

@interface PhotoDAO : NSObject
- (NSMutableArray*) fetchPhotoList;
- (NSString*) getCacheDir;
- (NSString*) getCacheFile: (Photo*) p;
- (BOOL) hasCache: (Photo*) p;
- (void) purgeCache;
- (UIImage*) loadImageFromCache: (Photo*) p;
- (int) getIntPref: (NSString*) key default: (int) def;
- (NSString*) getStringPref: (NSString*) key default: (NSString*) def;

@end
