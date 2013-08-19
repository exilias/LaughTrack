//
//  LTRemoteIOViewController.m
//  Chapter9
//
//  Created by 石井 晃 on 13/08/19.
//  Copyright (c) 2013年 OneChance. All rights reserved.
//

#import "LTRemoteIOViewController.h"

#import <AudioToolbox/AudioToolbox.h>

#import "LTRemoteOutput.h"



@interface LTRemoteIOViewController ()

@property LTRemoteOutput *remoteOutput;

@end

@implementation LTRemoteIOViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	
	
	
	// RemoteIO Audio UnitのAudioComponentDescriptionを作成
	AudioComponentDescription cd;
	cd.componentType		= kAudioUnitType_Output;
	cd.componentSubType		= kAudioUnitSubType_RemoteIO;
	cd.componentManufacturer = kAudioUnitManufacturer_Apple;
	cd.componentFlags		= 0;
	cd.componentFlagsMask	= 0;
	
	// AudioComponentDescriptionからAudioComponentを取得
	AudioComponent component = AudioComponentFindNext(NULL, &cd);
	CFStringRef name;
	AudioComponentCopyName(component, &name);	// 名前を取得
	NSLog(@"name = %@", name);
	
	// Remote Outputの準備
	self.remoteOutput = [[LTRemoteOutput alloc] init];
	[self.remoteOutput prepareAudioUnit];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)pushedPlayButton:(id)sender
{
	[self.remoteOutput play];
}

- (IBAction)pushedStopButton:(id)sender
{
	[self.remoteOutput stop];
}
@end
