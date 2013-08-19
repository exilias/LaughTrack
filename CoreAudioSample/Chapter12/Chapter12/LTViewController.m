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

@end

@implementation LTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	self.remoteIOPlayThru = [[LTRemoteIOPlayThru alloc] init];
	[self.remoteIOPlayThru play];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
