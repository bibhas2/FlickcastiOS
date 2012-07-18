//
//  FlickrCastViewController.m
//  FlickrCast
//
//  Created by BIBHAS BHATTACHARYA on 5/21/12.
//  Copyright (c) 2012 Self. All rights reserved.
//

#import "FlickrCastViewController.h"
#import "RequestProcessor.h"
#import <QuartzCore/QuartzCore.h>
#import "ALToastView.h"

@interface FlickrCastViewController ()

@end

@implementation FlickrCastViewController

@synthesize imageView, waitIndicator, displayQueue, titleView, toolbar;

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) != nil) {
        displayQueue = [[BoundedBlockingQueue alloc] initWithSize: 10];
        reqMgr = [[RequestProcessor alloc] initWithController:self];
        [reqMgr start];
        
        dao = [[PhotoDAO alloc] init];
        //Prevent device sleeping
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        isPaused = FALSE;
        //Start the timer
        [self startTimerWithInterval:2];
    }
    
    return self;
}

/*
 * Must be called from main thread.
 */
- (void) startTimer {
    int interval = [dao getIntPref:@"show_speed" default:5];
    [self startTimerWithInterval:interval];
}

- (void) startTimerWithInterval: (int) interval {
    timer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(requestNextPicture) userInfo:nil repeats:false];
    //isPaused = false;
}

- (void) stopTimer {
    NSLog(@"Stopping timer");
    [timer invalidate];
    timer = nil;
    //isPaused = true;
}
/*
 * Get photo from display queue, load from cache file.
 * All of this can time and hence done in a separate thread.
 */
- (void) requestNextPicture {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            NSLog(@"Waiting to get next photo from queue");
            Photo *p = [displayQueue take: 5];
            UIImage *img = nil;
            
            if (p == nil) {
                NSLog(@"Wait timed out. Queue is empty.");
            } else {
                NSLog(@"Got from display queue: %@", p.photoId);
                img = [dao loadImageFromCache:p];
            }
            
            [self showPhoto: p image:img];
        }        
    });
}
- (IBAction) showNextImage:(id)sender {
    Photo *p = [reqMgr getNextPhoto: currentPhoto];
    if ([displayQueue isInQueue:p]) {
            [self requestNextPicture];
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            @autoreleasepool {
                [reqMgr processPhoto: p];
                UIImage *img = [dao loadImageFromCache:p];         
                [self showPhoto: p image:img];
            }        
        });
    }
}

- (IBAction) showPrevImage:(id)sender{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            Photo *p = [reqMgr getPreviousPhoto: currentPhoto];
            [reqMgr processPhoto: p];
            UIImage *img = [dao loadImageFromCache:p];         
            [self showPhoto: p image:img];
        }        
    });
}
/*
 * Show an image from the main thread. UIImage is nil
 * in case the queue is empty or if there is an error up the chain.
 */
- (void) showPhoto: (Photo*) p image: (UIImage*) img {
    dispatch_async(dispatch_get_main_queue(), ^{
        //If image is nil, show waiting sign.
        [self showWaitIndicator: img == nil];
        
        if (img != nil) {
            currentPhoto = p;
            imageView.image = img;
            titleView.text = p.title;
            [titleView sizeToFit];
            //Add padding
            int padding = 10;
            CGRect frame = titleView.frame;
            frame.size.width += padding;
            frame.size.height += padding;
            
            CGSize parentSize = imageView.frame.size;

            frame.origin.x = (parentSize.width - frame.size.width) / 2;
            frame.origin.y = parentSize.height - frame.size.height;
            titleView.frame = frame;
            roundCorner(titleView);
        }
        if (isPaused == FALSE) {
            //Keep going if not paused
            [self startTimer];
        }
    });    
}

- (void) queuePhotoForDisplay: (Photo*) p {
    NSLog(@"Adding to display queue: %@", p.photoId);
    
    [displayQueue put:p];
}

void roundCorner(UIView *view) {
    // Create the path (with only the top-left corner rounded)
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:view.bounds 
        byRoundingCorners:UIRectCornerTopLeft| UIRectCornerTopRight
                                                     
        cornerRadii:CGSizeMake(5.0, 5.0)];

// Create the shape layer and set its path

    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = view.bounds;
    maskLayer.path = maskPath.CGPath;

    // Set the newly created shape layer as the mask for the image view's layer
    view.layer.mask = maskLayer;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.waitIndicator.hidden = TRUE;
    //self.titleView.layer.opacity=0.5;
    self.titleView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.5];
    toolbarFrame = self.toolbar.frame;
    self.toolbar.hidden = TRUE;
    
    [self.imageView setTag:0];
    [self.imageView setUserInteractionEnabled:TRUE];
    UITapGestureRecognizer  *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showToolbar:)];
    tapRecognizer.numberOfTapsRequired = 1;
    [self.imageView addGestureRecognizer:tapRecognizer];
    
    UISwipeGestureRecognizer *recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(onSwipeRight:)];
    [recognizer setDirection:(UISwipeGestureRecognizerDirectionRight)];
    [self.imageView addGestureRecognizer:recognizer];

    recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(onSwipeLeft:)];
    [recognizer setDirection:(UISwipeGestureRecognizerDirectionLeft)];
    [self.imageView addGestureRecognizer:recognizer];

}

- (void) onSwipeRight: (id) sender {
    [self stopTimer];
    [self showPrevImage:sender];
}

- (void) onSwipeLeft: (id) sender {
    [self stopTimer];
    [self showNextImage:sender];    
}

- (IBAction) showToolbar:(id)sender {
    BOOL show = self.toolbar.hidden;
    //If showing the stop the timer
    if (show) {
        [self stopTimer];
        isPaused = true;
    } else {
        [self startTimerWithInterval:1];
        isPaused = false;
    }
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:1];
    self.toolbar.hidden = !show;
    self.titleView.hidden = show;
    [UIView commitAnimations];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

/*
 * Must be called from main thread.
 */
- (void) showWaitIndicator: (BOOL) show {
    [self.waitIndicator setHidden: !show];
    if (show == TRUE) {
        [self.waitIndicator startAnimating];
    } else {
        [self.waitIndicator stopAnimating];
    }
}


- (IBAction) startShowAgain:(id)sender{
    [self showToolbar:sender];
}

- (IBAction) shareImage:(id)sender{

}

- (IBAction) saveImageToGallery:(id)sender{
    UIImageWriteToSavedPhotosAlbum(self.imageView.image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
}

- (void)image:(UIImage *) image didFinishSavingWithError: (NSError *) error contextInfo: (void *) contextInfo {
    if(error != nil) {
        [self showMessage:@"Error saving photo to gallery"];
    } else {
        [self showMessage:@"Photo saved to gallery"];
    }
    image = nil;
}

- (void) showMessage: (NSString*) msg {
    [ALToastView toastInView:imageView withText:msg];
}
@end
