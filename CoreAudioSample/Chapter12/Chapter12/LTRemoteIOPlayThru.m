//
//  LTRemoteIOPlayThru.m
//  Chapter12
//
//  Created by 石井 晃 on 13/08/19.
//  Copyright (c) 2013年 OneChance. All rights reserved.
//

#import "LTRemoteIOPlayThru.h"

#import <CoreAudio/CoreAudioTypes.h>
#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>

#import "iPhoneCoreAudio.h"


@interface LTRemoteIOPlayThru ()

@property AUGraph mAuGraph;
@property BOOL isPlaying;

@end


@implementation LTRemoteIOPlayThru

- (id)init
{
	self = [super init];
	
	if (self != nil) {
		[self prepareAUGraph];
	}
	
	return self;
}


- (void)prepareAUGraph
{
	AUNode		remoteIONode;
	AudioUnit	remoteIOUnit;
	
	NewAUGraph(&_mAuGraph);
	AUGraphOpen(self.mAuGraph);
	
	AudioComponentDescription cd;
	cd.componentType		= kAudioUnitType_Output;
	cd.componentSubType		= kAudioUnitSubType_RemoteIO;
	cd.componentManufacturer= kAudioUnitManufacturer_Apple;
	cd.componentFlags		= cd.componentFlagsMask = 0;
	
	AUGraphAddNode(self.mAuGraph, &cd, &remoteIONode);
	AUGraphNodeInfo(self.mAuGraph, remoteIONode, NULL, &remoteIOUnit);
	
	// マイク入力をオンにする
	UInt32 flag = 1;
	AudioUnitSetProperty(remoteIOUnit,
						 kAudioOutputUnitProperty_EnableIO,
						 kAudioUnitScope_Input,
						 1, // Remote Input
						 &flag,
						 sizeof(flag));
	
	// オーディオ正準系
	AudioStreamBasicDescription audioFormat = CanonicalASBD(44100.0, 1);
	
	// モノラルに設定
	AudioUnitSetProperty(remoteIOUnit,
						 kAudioUnitProperty_StreamFormat,
						 kAudioUnitScope_Output,	// 出力スコープ
						 1,							// Remote input
						 &audioFormat,
						 sizeof(AudioStreamBasicDescription));
	AudioUnitSetProperty(remoteIOUnit,
						 kAudioUnitProperty_StreamFormat,
						 kAudioUnitScope_Input,		// 入力スコープ
						 0,							// Remote output
						 &audioFormat,
						 sizeof(AudioStreamBasicDescription));
	
	AUGraphConnectNodeInput(self.mAuGraph,
							remoteIONode, 1,	// Remote Inputと
							remoteIONode, 0);	// Remote Outputを接続
	
	AUGraphInitialize(self.mAuGraph);
	
}

@end
