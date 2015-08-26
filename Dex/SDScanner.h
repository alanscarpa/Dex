//
//  SDScanner.h
//  Dex
//
//  Created by Alan Scarpa on 8/26/15.
//  Copyright (c) 2015 Skytop Designs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@interface SDScanner : NSObject <AVCaptureMetadataOutputObjectsDelegate, UIAlertViewDelegate>


@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) CALayer *targetLayer;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) NSMutableArray *codeObjects;
@property (nonatomic, strong) NSMutableArray *readableCodeObjects;
@property (nonatomic) BOOL isDecodingScanResult;
@property (nonatomic, strong) UIViewController *captureViewController;
@property (nonatomic, strong) UIView *captureView;



-(instancetype)initWithViewController:(UIViewController*)vc;


@end
