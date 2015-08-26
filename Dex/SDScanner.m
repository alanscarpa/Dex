//
//  SDScanner.m
//  Dex
//
//  Created by Alan Scarpa on 8/26/15.
//  Copyright (c) 2015 Skytop Designs. All rights reserved.
//

#import "SDScanner.h"

@implementation SDScanner 


-(instancetype)initWithViewController:(UIViewController*)vc {
    
    self = [super init];
    if (self){
        _captureViewController = vc;
        _captureView = vc.view;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidEnterBackground:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillEnterForeground:)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
    }
    return self;
    
}

- (NSMutableArray *)codeObjects
{
    if (!_codeObjects)
    {
        _codeObjects = [NSMutableArray new];
    }
    return _codeObjects;
}


-(NSMutableArray *)readableCodeObjects
{
    if (!_readableCodeObjects)
    {
        _readableCodeObjects = [NSMutableArray new];
    }
    return _readableCodeObjects;
    
}

- (AVCaptureSession *)captureSession
{
    if (!_captureSession)
    {
        NSError *error = nil;
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if (device.isAutoFocusRangeRestrictionSupported)
        {
            if ([device lockForConfiguration:&error])
            {
                [device setAutoFocusRangeRestriction:AVCaptureAutoFocusRangeRestrictionNear];
                [device unlockForConfiguration];
            }
        }
        
        // The first time AVCaptureDeviceInput creation will present a dialog to the user
        // requesting camera access. If the user refuses the creation fails.
        // See WWDC 2013 session #610 for details, but note this behaviour does not seem to
        // be enforced on iOS 7 where as it is with iOS 8.
        
        AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
        if (deviceInput)
        {
            _captureSession = [[AVCaptureSession alloc] init];
            if ([_captureSession canAddInput:deviceInput])
            {
                [_captureSession addInput:deviceInput];
            }
            
            AVCaptureMetadataOutput *metadataOutput = [[AVCaptureMetadataOutput alloc] init];
            if ([_captureSession canAddOutput:metadataOutput])
            {
                [_captureSession addOutput:metadataOutput];
                [metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
                [metadataOutput setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
            }
            
            self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
            self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            self.previewLayer.frame = self.captureView.bounds;
            [self.captureView.layer addSublayer:self.previewLayer];
            
            self.targetLayer = [CALayer layer];
            self.targetLayer.frame = self.captureView.bounds;
            [self.captureView.layer addSublayer:self.targetLayer];
            
        }
        else
        {
            NSLog(@"Input Device error: %@",[error localizedDescription]);
            [self showAlertForCameraError:error];
        }
    }
    return _captureSession;
}

#pragma mark -
#pragma mark === View Lifecycle ===
#pragma mark -



//- (void)viewDidAppear:(BOOL)animated
//{
//    
//    self.isDecodingScanResult = NO;
//    
//    
//    [self startRunning];
//}


- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    [self stopRunning];
}

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    [self startRunning];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
   // [self stopRunning];

}




#pragma mark -
#pragma mark === AVCaptureMetadataOutputObjectsDelegate ===
#pragma mark -

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if (self.isDecodingScanResult == NO)
    {
        self.isDecodingScanResult = YES;
        self.codeObjects = nil;
        for (AVMetadataObject *metadataObject in metadataObjects)
        {
            AVMetadataObject *transformedObject = [self.previewLayer transformedMetadataObjectForMetadataObject:metadataObject];
            // MAY NOT NEED THIS ARRAY
            [self.codeObjects addObject:transformedObject];
            AVMetadataMachineReadableCodeObject *readableCodeObject = (AVMetadataMachineReadableCodeObject *)metadataObject;
            // STORING IN ARRAY FOR FUTURE POSSIBILITY OF MULTIPLE QR CODES
            [self.readableCodeObjects addObject:readableCodeObject];
            NSLog(@"%@", readableCodeObject.stringValue);
        }
        
        [self clearTargetLayer];
        [self showDetectedObjects];
        [self.captureViewController performSegueWithIdentifier:@"resultsSegue" sender:self];
    }
}


#pragma mark -
#pragma mark === UIAlertViewDelegate ===
#pragma mark -

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [[UIApplication sharedApplication] openURL:url];
    }
}

#pragma mark -
#pragma mark === Utility methods ===
#pragma mark -

- (void)showAlertForCameraError:(NSError *)error
{
    NSString *buttonTitle = nil;
    NSString *message = error.localizedFailureReason ? error.localizedFailureReason : error.localizedDescription;
    
    if ((error.code == AVErrorApplicationIsNotAuthorizedToUseDevice) &&
        UIApplicationOpenSettingsURLString)
    {
        // Starting with iOS 8 we can directly open the settings bundle
        // for this App so add a settings button to the alert view.
        buttonTitle = NSLocalizedString(@"AlertViewSettingsButton", @"Settings");
    }
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"AlertViewTitleCameraError", @"Camera Error")
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"AlertViewCancelButton", @"Cancel")
                                              otherButtonTitles:buttonTitle, nil];
    [alertView show];
}

- (void)startRunning
{
    self.codeObjects = nil;
    [self.captureSession startRunning];
}

- (void)stopRunning
{
    [self.captureSession stopRunning];
    self.captureSession = nil;
}

- (void)clearTargetLayer
{
    NSArray *sublayers = [[self.targetLayer sublayers] copy];
    for (CALayer *sublayer in sublayers)
    {
        [sublayer removeFromSuperlayer];
    }
}

- (void)showDetectedObjects
{
    for (AVMetadataObject *object in self.codeObjects)
    {
        if ([object isKindOfClass:[AVMetadataMachineReadableCodeObject class]])
        {
            CAShapeLayer *shapeLayer = [CAShapeLayer layer];
            shapeLayer.strokeColor = [UIColor redColor].CGColor;
            shapeLayer.fillColor = [UIColor clearColor].CGColor;
            shapeLayer.lineWidth = 4.0;
            shapeLayer.lineJoin = kCALineJoinRound;
            CGPathRef path = createPathForPoints([(AVMetadataMachineReadableCodeObject *)object corners]);
            shapeLayer.path = path;
            CFRelease(path);
            [self.targetLayer addSublayer:shapeLayer];
        }
    }
}

CGMutablePathRef createPathForPoints(NSArray* points)
{
    CGMutablePathRef path = CGPathCreateMutable();
    CGPoint point;
    
    if ([points count] > 0)
    {
        CGPointMakeWithDictionaryRepresentation((CFDictionaryRef)[points objectAtIndex:0], &point);
        CGPathMoveToPoint(path, nil, point.x, point.y);
        
        int i = 1;
        while (i < [points count])
        {
            CGPointMakeWithDictionaryRepresentation((CFDictionaryRef)[points objectAtIndex:i], &point);
            CGPathAddLineToPoint(path, nil, point.x, point.y);
            i++;
        }
        
        CGPathCloseSubpath(path);
    }
    
    return path;
}


@end
