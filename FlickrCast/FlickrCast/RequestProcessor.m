//
//  RequestProcessor.m
//  FlickrCast
//
//  Created by BIBHAS BHATTACHARYA on 5/23/12.
//  Copyright (c) 2012 Self. All rights reserved.
//

#import "RequestProcessor.h"

#define MAX_CYCLES 2

@implementation RequestProcessor
@synthesize controller;

- (id) initWithController:(FlickrCastViewController *)ctr {
    self = [super init];
    if (self) {
        self.controller = ctr;
        photoList = nil;
        dao = [[PhotoDAO alloc] init];
        nextIndex = 0;
        numCycles = 0;
    }
    return self;
}

- (void) start {
    [NSThread detachNewThreadSelector:@selector(startRequestProcessor) toTarget:self withObject:nil];        
}

- (void) stop {
    
}

- (void) startRequestProcessor {
    @autoreleasepool {
        //Download and parse XML
        photoList = [dao fetchPhotoList];
        
		if (photoList == nil) {
			//[self.controller postMessage: @"Failed to connect to Flickr"];
			return;
		}
		//Purge cache
		[dao purgeCache];
		
		while (TRUE) {
            @autoreleasepool {
                Photo* p = [photoList objectAtIndex: nextIndex];

                [self processPhoto: p];
                [self queueForDisplay: p]; //This can block if queue is full
                ++nextIndex;
                if (nextIndex == photoList.count) {
                    nextIndex = 0;
                    ++numCycles;
                    if (numCycles == MAX_CYCLES) {
                        break;
                    }
                }
            }
		}
        if (numCycles == MAX_CYCLES) {
            NSLog(@"Realoading list from server.");
            numCycles = 0;
            [self start];
        }
    }
}

- (void) processPhoto: (Photo*) p {
    if ([dao hasCache:p]) {
        NSLog(@"Got a cache hit");
        return;
    }
    //Load the image from URL
    NSLog(@"Downloading image from: %@", p.url);
    NSData *data = [NSData dataWithContentsOfURL: [NSURL URLWithString: p.url]];
    if (data == nil) {
        NSLog(@"Failed to get image from Flickr");
        return;
    }
    //Save cache
    if ([data writeToFile: [dao getCacheFile:p] atomically: TRUE] == FALSE) {
        NSLog(@"Failed to write to cache");
        return;
    }
   
}

- (void) queueForDisplay: (Photo*) p {
    [controller queuePhotoForDisplay:p]; 
}

- (Photo*) getPreviousPhoto: (Photo*) from {
    for (int i = 0; i < photoList.count; ++i) {
        Photo *p = [photoList objectAtIndex:i];
        if (p == from) {
            //Found it!
            int resultIdx = i - 1;
            if (resultIdx < 0) {
                resultIdx = photoList.count - 1; //wrap to end
            }
            return [photoList objectAtIndex:resultIdx];
        }
    }
    return nil;
}
/*
 * Returns next photo.
 */
- (Photo*) getNextPhoto: (Photo*) from {
    for (int i = 0; i < photoList.count; ++i) {
        Photo *p = [photoList objectAtIndex:i];
        if (p == from) {
            //Found it!
            int resultIdx = i + 1;
            if (resultIdx == photoList.count) {
                resultIdx = 0; //wrap to end
            }
            return [photoList objectAtIndex:resultIdx];
        }
    }
    return nil;
}
@end
