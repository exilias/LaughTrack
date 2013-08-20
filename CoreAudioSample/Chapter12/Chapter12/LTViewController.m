//
//  LTViewController.m
//  Chapter12
//
//  Created by 石井 晃 on 13/08/19.
//  Copyright (c) 2013年 OneChance. All rights reserved.
//

#import "LTViewController.h"

#import "LTRemoteIOPlayThru.h"

@interface LTViewController ()

@property LTRemoteIOPlayThru *remoteIOPlayThru;
@property NSString *hoge;

@end

@implementation LTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	self.remoteIOPlayThru = [[LTRemoteIOPlayThru alloc] init];
	[self.remoteIOPlayThru setSuperView:self];
	[self.remoteIOPlayThru play];
}

- (void)updateCurrentLevelLabel:(NSString *)str
{
	self.hoge = [NSString stringWithFormat:@"%@", str];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)pushedNoiseRecordButton:(id)sender
{
	self.currentLevelLabel.text = self.hoge;
}
@end
