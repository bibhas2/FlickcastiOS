//
//  FlickrCastViewController.h
//  FlickrCast
//
//  Created by BIBHAS BHATTACHARYA on 5/21/12.
//  Copyright (c) 2012 Self. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BoundedBlockingQueue.h"
#import "PhotoDAO.h"

@class RequestProcessor;

@interface FlickrCastViewController : UIViewController {
    RequestProcessor *reqMgr;
    PhotoDAO *dao;
    CGRect toolbarFrame;
    NSTimer *timer;
    Photo *currentPhoto;
    BOOL isPaused;
}

@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *waitIndicator;
@property (nonatomic, strong) IBOutlet UILabel *titleView;
@property (nonatomic, strong) BoundedBlockingQueue *displayQueue;
@property (nonatomic, strong) IBOutlet UIToolbar *toolbar;

- (void) showWaitIndicator: (BOOL) show;
- (void) queuePhotoForDisplay: (Photo*) p;
- (IBAction) showPrevImage:(id)sender;
- (IBAction) startShowAgain:(id)sender;
- (IBAction) shareImage:(id)sender;
- (IBAction) saveImageToGallery:(id)sender;
- (IBAction) showNextImage:(id)sender;
@end
