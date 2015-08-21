//
//  SDResultsViewController.m
//  Dex
//
//  Created by Alan Scarpa on 8/21/15.
//  Copyright (c) 2015 Skytop Designs. All rights reserved.
//

#import "SDResultsViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface SDResultsViewController ()
@property (weak, nonatomic) IBOutlet UILabel *resultsLabel;

@end

@implementation SDResultsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self updateUI];
}


-(void)updateUI
{
    
    
    for (AVMetadataMachineReadableCodeObject *readableCodeObject in self.readableCodeObjects){
        
        self.resultsLabel.text = readableCodeObject.stringValue;
        
    }
    
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
