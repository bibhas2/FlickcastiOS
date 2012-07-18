//
//  PhotoDAO.m
//  FlickrCast
//
//  Created by BIBHAS BHATTACHARYA on 5/24/12.
//  Copyright (c) 2012 Self. All rights reserved.
//

#import "PhotoDAO.h"
#import "XMLUtil.h"
#import <dirent.h>
#include <sys/stat.h>

@implementation PhotoDAO

- (NSMutableArray*) fetchPhotoList {
    int fetchCount = [self getIntPref:@"num_images" default:100];
    NSString* qualityFlag = [self computeQualityFlag];

    NSLog(@"Num images: %d", fetchCount);
    
    NSLog(@"Quality flag: %@", qualityFlag);
    NSString *url = [NSString stringWithFormat:
        @"http://api.flickr.com/services/rest/?method=flickr.interestingness.getList&api_key=8fa47539dde7b426a299aa41da9b02fb&per_page=%d", fetchCount];

    NSLog(@"Getting list: %@", url);
    TBXML* doc = [XMLUtil loadXML: url];
    NSMutableArray* photoList = [self buildPhotoList: qualityFlag doc: doc];

    return photoList;
}

- (UIImage*) loadImageFromCache: (Photo*) p {
    if ([self hasCache:p] == FALSE) {
        return nil;
    }
    
    return [UIImage imageWithContentsOfFile:[self getCacheFile:p]];
}

- (NSString*) computeQualityFlag {
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    CGSize screenSize = CGSizeMake(screenBounds.size.width * screenScale, screenBounds.size.height * screenScale);
    NSString *flagList[] = {@"n", nil, @"z", @"c", @"b"};
    int sizeList[] = {320, 500, 640, 800, 1024};
    int sizeLength = sizeof(sizeList) / sizeof(int);
    int dimension = screenSize.height > screenSize.width ? screenSize.height : screenSize.width;

    //Return the smallest image size which is larger than the 
    //device
    for (int i = 0; i < sizeLength; ++i) {
        if (sizeList[i] >= dimension) {
            return flagList[i];
        }
    }
    
    //return max image size
    return flagList[sizeLength - 1];

}

- (NSMutableArray*) buildPhotoList: (NSString*) qualityFlag doc: (TBXML*) doc {
    NSMutableArray *photoList = [NSMutableArray arrayWithCapacity: 500];
    
    TBXMLElement *e = [TBXML childElementNamed:@"photos" parentElement:doc.rootXMLElement];
    e = [TBXML childElementNamed:@"photo" parentElement:e];
    while (e) {
        Photo *p = [[Photo alloc] init];
        
        p.photoId = [TBXML valueOfAttributeNamed:@"id" forElement:e];
        p.title = [TBXML valueOfAttributeNamed:@"title" forElement:e];
        
        NSString* farm = [TBXML valueOfAttributeNamed:@"farm" forElement:e];
        NSString* server = [TBXML valueOfAttributeNamed:@"server" forElement:e];
        NSString* secret = [TBXML valueOfAttributeNamed:@"secret" forElement:e];
        NSMutableString *url = [NSMutableString stringWithFormat:
            @"http://farm%@.staticflickr.com/%@/%@_%@", farm, server, p.photoId, secret];
        if (qualityFlag != nil) {
            [url appendFormat:@"_%@", qualityFlag];
        }
        [url appendString:@".jpg"];
        p.url = url; 
        
        [photoList addObject:p];
        e = [TBXML nextSiblingNamed:@"photo" searchFromElement:e];
    }
    //Randomize the list
    [self shuffleArray: photoList];
    return photoList;
}

- (void)shuffleArray: (NSMutableArray*) array
{
    static BOOL seeded = NO;
    if(!seeded)
    {
        seeded = YES;
        srandom(time(NULL));
    }
    
    NSUInteger count = [array count];
    for (NSUInteger i = 0; i < count; ++i) {
        // Select a random element between i and end of array to swap with.
        int nElements = count - i;
        int n = (random() % nElements) + i;
        [array exchangeObjectAtIndex:i withObjectAtIndex:n];
    }
}

- (NSString*) getCacheDir {
    NSArray *myPathList = NSSearchPathForDirectoriesInDomains(
            NSCachesDirectory, NSUserDomainMask, YES);
    return [myPathList objectAtIndex:0];
}

- (NSString*) getCacheFile: (Photo*) p {
    return [NSString stringWithFormat: @"%@/%@", 
        [self getCacheDir],
            p.photoId];
}

- (void) purgeCache {
    NSLog(@"Purging cache");
    time_t maxAge = 1 * 24 * 60 * 60;
    const char* cacheDir = [[self getCacheDir] cStringUsingEncoding: NSUTF8StringEncoding];
    DIR *dir = opendir(cacheDir);
    struct dirent *ent = nil;
    struct stat st;
    time_t now = time(NULL);
    
    while ((ent = readdir(dir)) != nil) {
        const char *fullName = [[NSString stringWithFormat:@"%s/%s",
                           cacheDir, ent->d_name] cStringUsingEncoding: NSUTF8StringEncoding];
        if (stat(fullName, &st) != 0) {
            NSLog(@"Failed to get stat for file: %s", fullName);
            return;
        }
        if (!S_ISREG(st.st_mode)) {
            continue;
        }
        time_t age = (now - st.st_mtime);
        if (age > maxAge) {
            unlink(fullName);
            NSLog(@"Deleting cache file: %s", ent->d_name);
        }
    }
    closedir(dir);
    
    /*
     for(int i = 0; i < listFiles.count; ++i) {
     NSString *filePath = [listFiles objectAtIndex: i];
     NSDictionary *dictionary = [fmgr attributesOfItemAtPath:filePath error:&error];
     NSDate *fileDate =[dictionary objectForKey:NSFileModificationDate];
     if ([[cacheLimitDate earlierDate:fileDate] isEqualToDate:fileDate]) {
     //file is  older delete it
     [fmgr removeItemAtPath: filePath error: nil];
     }
     }
     */
}

- (BOOL) hasCache:(Photo *)p {
    struct stat st;
    
    return [self getCacheStat:p withStat:&st];
}

- (BOOL) getCacheStat: (Photo*) p withStat: (struct stat*) st {
    const char* file = [[self getCacheFile:p] cStringUsingEncoding:NSUTF8StringEncoding];
    if (stat(file, st) != 0) {
        return FALSE;
    }
    
    return TRUE;
}

- (int) getIntPref: (NSString*) key default: (int) def {
    NSString *val = [self getStringPref:key default:nil];
    if (val == nil) {
        return def;
    }
    return [val intValue];
}

- (NSString*) getStringPref: (NSString*) key default: (NSString*) def {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString* val = [defaults stringForKey:key];

    if (val == nil) {
        val = def;
    }

    return val;
}
@end
