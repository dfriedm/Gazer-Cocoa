//
//  AppDelegate.m
//  og3
//
//  Created by Ryan Kabir on 11/22/11.
//  Copyright (c) 2011 Grow20 Corporation. All rights reserved.
//

#import "AppDelegate.hpp"

#import "CoreFoundation/CoreFoundation.h"
#import "LCCalibrationPoint.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize calibrationFlag;

-(void)applicationWillFinishLaunching:(NSNotification*)aNotification{
    [[NSApplication sharedApplication] disableRelaunchOnLogin];
     calibrationWindowController = [[LCCalibrationWindowController alloc] initWithWindowNibName:@"CalibrationWindow"];
    [[calibrationWindowController window] makeKeyAndOrderFront:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moveCalibrationPoint:)
                                                 name:@"changeCalibrationTarget"
                                               object:nil];

}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{  // set the right path so the classifiers can find their data
    CFBundleRef mainBundle = CFBundleGetMainBundle();
    CFURLRef resourcesURL = CFBundleCopyResourcesDirectoryURL(mainBundle);
    char path[PATH_MAX];
    if (!CFURLGetFileSystemRepresentation(resourcesURL, TRUE, (UInt8 *)path, PATH_MAX))
    {
        // error!
    }
    CFRelease(resourcesURL);
    chdir(path);
    // end path settings
    // NSArray *args = [[NSProcessInfo processInfo] arguments];
    //int count = [args count];
    
    //NSView* view = [[self window] contentView];
    
    // calibrationWindowController.hostView
    NSLog(@"HostView:%@", calibrationWindowController.hostView);
    OGc* openGazerCocoa = new OGc::OGc(0, NULL, calibrationWindowController.hostView);
    openGazerCocoa->loadClassifiers();

    MainGazeTracker *gazeTracker = openGazerCocoa->gazeTracker;
//    new MainGazeTracker(argc, argv, getStores(win.hostView), win.hostView);

    calibrationWindowController.openGazerCocoaPointer = [NSValue valueWithPointer:openGazerCocoa];

    cvNamedWindow(MAIN_WINDOW_NAME, CV_GUI_EXPANDED);
    cvResizeWindow(MAIN_WINDOW_NAME, 640, 480);

    //    createButtons();
    //openGazerCocoa->registerMouseCallbacks();

    gazeTracker->doprocessing();
    openGazerCocoa->drawFrame();

//    findEyes();
//    YourAppDelegate *appDelegate = (YourAppDelegate *)[[UIApplication sharedApplication] delegate];
//    app.delegate.calibrationFlag = NO;
    
    // to declare an object Object* blah = &gazeTracker
    
    
    GlobalManager *gm = [GlobalManager sharedGlobalManager];
    gm.calibrationFlag = NO;
    NSLog(@"Entering while loop");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,0), ^{ // Run on a background thread - dispatch_get_main_queue()
        while(1){
        gazeTracker->doprocessing();

        openGazerCocoa->drawFrame();
        if (gm.calibrationFlag) {
            gazeTracker->startCalibration();
            gm.calibrationFlag = NO;
        }
        char c = cvWaitKey(33);
        switch(c) {
            case 'c':
                gazeTracker->startCalibration();
                break;
            case 't':
                gazeTracker->startTesting();
                break;
            case 's':
                gazeTracker->savepoints();
                break;
            case 'l':
                gazeTracker->loadpoints();
                break;
            case 'x':
                gazeTracker->clearpoints();
                break;
            case 'r':
                openGazerCocoa->findEyes();
                break;
            default:
                break;
        }

        if(c == 27) break;
    }
    });

}

#pragma mark - Notifications

-(void)moveCalibrationPoint:(NSNotification*)note{
    NSLog(@"Receive move calibration Point");
    NSPoint point = [(NSValue*)[(NSDictionary*)[note userInfo] objectForKey:@"point"] pointValue];
    LCCalibrationPoint* calibrationPoint = [[LCCalibrationPoint alloc] init];
    NSLog(@"Points: %f %f", point.x, point.y);
    calibrationPoint.x = point.x;
    calibrationPoint.y = point.y;
    [calibrationWindowController moveToNextPoint:calibrationPoint];
}

@end
