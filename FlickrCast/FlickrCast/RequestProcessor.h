//
//  RequestProcessor.h
//  FlickrCast
//
//  Created by BIBHAS BHATTACHARYA on 5/23/12.
//  Copyright (c) 2012 Self. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FlickrCastViewController.h"
#import "PhotoDAO.h"

@interface RequestProcessor : NSObject {
    NSMutableArray *photoList;
    PhotoDAO *dao;
    int nextIndex;
    int numCycles;
}

@property (nonatomic, strong) FlickrCastViewController *controller;

- (id) initWithController: (FlickrCastViewController*) ctr;
- (void) start;
- (void) stop;
- (Photo*) getPreviousPhoto: (Photo*) from;
- (Photo*) getNextPhoto: (Photo*) from;
- (void) processPhoto: (Photo*) p;
@end
