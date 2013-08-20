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
@property BOOL isRecording;
@property ExtAudioFileRef extAudioFile;	// 録音したファイル
@property AudioStreamBasicDescription audioUnitOutputFormat;	// Remote OutputのアウトプットのASBD
@property AudioUnit	remoteIOUnit;

@end


@implementation LTRemoteIOPlayThru


// グローバル変数
AudioUnitSampleType noiseVolume;
BOOL isSpeaking, isInstantSpeaking, justNow;
float timeInSilent, timeFromLastSpeak, timeInInstantSpeaking, timeInNonInstantSpeaking;
AudioUnitSampleType sampleAry[100]; //すべて0で初期化
UInt32 sampleIndex = 0;


static OSStatus renderCallback(void							*inRefCon,
							   AudioUnitRenderActionFlags	*ioActionFlags,
							   const AudioTimeStamp			*inTimeStamp,
							   UInt32						inBusNumber,
							   UInt32						inNumberFrames,
							   AudioBufferList				*ioData)
{
	// Post Render時のみ処理を行う
	if (*ioActionFlags & kAudioUnitRenderAction_PostRender) {
		ExtAudioFileRef extAudioFile = (ExtAudioFileRef)inRefCon;
		
		// バッファを書きこむ
		ExtAudioFileWriteAsync(extAudioFile, inNumberFrames, ioData);
	}
	
	return noErr;
}


static OSStatus outputCallback(void							*inRefCon,
							   AudioUnitRenderActionFlags	*ioActionFlags,
							   const AudioTimeStamp			*inTimeStamp,
							   UInt32						inBusNumber,
							   UInt32						inNumberFrames,
							   AudioBufferList				*ioData)
{
	OSStatus err;
	LTRemoteIOPlayThru *remotIOPlayThru = (__bridge LTRemoteIOPlayThru *)inRefCon;
	//AudioUnit remoteIOUnit = (AudioUnit)inRefCon;
	err = AudioUnitRender(remotIOPlayThru.remoteIOUnit, ioActionFlags, inTimeStamp, 1, inNumberFrames, ioData);
	if (err) {
		NSLog(@"recordingCallback: error %ld\n", err);
		return err;
	}

	NSLog(@"%d", (unsigned int)inNumberFrames);
	for (int j = 0; j < ioData->mNumberBuffers; j++) {
		AudioSampleType *output = ioData->mBuffers[j].mData;
				
		for (int i = 0; i < inNumberFrames; i++) {
			//AudioUnitSampleType sample = output[i]/** 3.162277*/;	// 10dB
			
			
			sampleAry[sampleIndex] = abs(output[i]);
			
			sampleIndex++;
			
			if(sampleIndex >= 100){
				sampleIndex = 0;
			}
			
			//sample[10]の平均を求める
			AudioUnitSampleType sampleAverage = 0.0;
			for(int i=0; i < 100; i++){
				sampleAverage += sampleAry[i];
			}
			
			sampleAverage /= 100;
			
			NSLog(@"%f", 20 * log10(sampleAverage/32768.0));
			
			/*
			 * 追加分おわり
			 */
			
			
			
			
			// ここで発話アルゴリズムを書く
			// -------------------------------
			
			if (abs(sampleAverage) > noiseVolume * 2) {
				if (!isInstantSpeaking) {
					isInstantSpeaking = YES;
				}
			} else {
				if (isInstantSpeaking) {
					isInstantSpeaking = NO;
				}
			}
			
			if (isInstantSpeaking) {
				timeInInstantSpeaking++;
				timeInNonInstantSpeaking = 0;
			} else {
				timeInInstantSpeaking = 0;
				timeInNonInstantSpeaking++;
			}
			
			// 発話フラグのオンオフ
			if (isSpeaking) {
				if (timeInNonInstantSpeaking > 10) { //10くらいに設定してみる
					isSpeaking = NO;
				}
			} else {
				if (timeInInstantSpeaking > 10) {
					isSpeaking = YES;
				}
			}
			
			if (isSpeaking) {
				NSLog(@"発話");
				timeInSilent = 0;
			} else {
				NSLog(@"not発話");
				timeInSilent++;
			}
			
			if (justNow) {
				timeFromLastSpeak += inNumberFrames;
				if (timeFromLastSpeak >= 2.1 * 44100.0) {
					justNow = NO;
					timeFromLastSpeak = 0;
				}
				
			}
			
			
			
			// -32768 〜 32767の範囲を超えないようにする
//			if (sample > 32767) {
//				sample = 32767;
//			} else if (sample < -32768) {
//				sample = -32768;
//			}
//			
			//output[i] = (AudioSampleType)sample;
		}
	}
	
	return noErr;
}


- (id)init
{
	self = [super init];
	
	if (self != nil) {
		[self prepareAUGraph];
		
		isSpeaking = isInstantSpeaking = justNow = false;
		timeInSilent = timeFromLastSpeak = timeInInstantSpeaking = timeInNonInstantSpeaking = 0.0f;
		noiseVolume = 100;
		
		for (int i = 0; i < 100; i++) {
			sampleAry[i] = 0;
		}
	}
	
	return self;
}


- (void)prepareAUGraph
{
	AUNode		remoteIONode;
	
	
	NewAUGraph(&_mAuGraph);
	AUGraphOpen(self.mAuGraph);
	
	AudioComponentDescription cd;
	cd.componentType		= kAudioUnitType_Output;
	cd.componentSubType		= kAudioUnitSubType_RemoteIO;
	cd.componentManufacturer= kAudioUnitManufacturer_Apple;
	cd.componentFlags		= cd.componentFlagsMask = 0;
	
	AUGraphAddNode(self.mAuGraph, &cd, &remoteIONode);
	AUGraphNodeInfo(self.mAuGraph, remoteIONode, NULL, &_remoteIOUnit);
	
	// マイク入力をオンにする
	UInt32 flag = 1;
	AudioUnitSetProperty(self.remoteIOUnit,
						 kAudioOutputUnitProperty_EnableIO,
						 kAudioUnitScope_Input,
						 1, // Remote Input
						 &flag,
						 sizeof(flag));
	
	// オーディオ正準系
	AudioStreamBasicDescription audioFormat = CanonicalASBD(44100.0, 1);
	
	// モノラルに設定
	AudioUnitSetProperty(self.remoteIOUnit,
						 kAudioUnitProperty_StreamFormat,
						 kAudioUnitScope_Output,	// 出力スコープ
						 1,							// Remote input
						 &audioFormat,
						 sizeof(AudioStreamBasicDescription));
	AudioUnitSetProperty(self.remoteIOUnit,
						 kAudioUnitProperty_StreamFormat,
						 kAudioUnitScope_Input,		// 入力スコープ
						 0,							// Remote output
						 &audioFormat,
						 sizeof(AudioStreamBasicDescription));
	
	AURenderCallbackStruct callbackStruct;
	callbackStruct.inputProc		= outputCallback;
	callbackStruct.inputProcRefCon	= (__bridge void *)(self);
	OSStatus err = AUGraphSetNodeInputCallback(self.mAuGraph, remoteIONode, 0, &callbackStruct);
	NSLog(@"AUGraphSetNodeInputCallback: error %ld\n", err);
	
	UInt32 size;
	AudioUnitGetProperty(self.remoteIOUnit,
						 kAudioUnitProperty_StreamFormat,
						 kAudioUnitScope_Output,		// 出力スコープ
						 0,								// Remote Output
						 &_audioUnitOutputFormat,
						 &size);
	
	AUGraphInitialize(self.mAuGraph);
}


- (void)record:(NSURL *)toURL
{
	if (self.isRecording) {
		return;
	}
	
	// 変換するフォーマット(AIFF)
	AudioStreamBasicDescription outputFormat;
	outputFormat.mSampleRate			= 44100.0;
	outputFormat.mFormatID				= kAudioFormatLinearPCM;
	outputFormat.mFormatFlags			= kAudioFormatFlagIsBigEndian |
										  kLinearPCMFormatFlagIsSignedInteger |
										  kLinearPCMFormatFlagIsPacked;
	outputFormat.mFramesPerPacket		= 1;
	outputFormat.mChannelsPerFrame		= 1;
	outputFormat.mBitsPerChannel		= 16;
	outputFormat.mBytesPerPacket		= 2;
	outputFormat.mBytesPerFrame			= 2;
	outputFormat.mReserved				= 0;
	
	ExtAudioFileCreateWithURL((__bridge CFURLRef)toURL,
							  kAudioFileAIFFType,
							  &outputFormat,
							  NULL,
							  kAudioFileFlags_EraseFile,
							  &_extAudioFile);
	
	// Remote OutputのアウトプットのASBDが入力
	ExtAudioFileSetProperty(self.extAudioFile,
							kExtAudioFileProperty_ClientDataFormat,
							sizeof(AudioStreamBasicDescription),
							&_audioUnitOutputFormat);
	
	// レンダリング通知関数の設定
	AUGraphAddRenderNotify(self.mAuGraph, renderCallback, self.extAudioFile);
	self.isRecording = YES;
}


- (void)stopRecording
{
	// 通知を受けない
	AUGraphRemoveRenderNotify(self.mAuGraph, renderCallback, self.extAudioFile);
	
	// Ext Audioを閉じる
	ExtAudioFileDispose(self.extAudioFile);
	self.isRecording = NO;
}


- (void)play
{
	AUGraphStart(self.mAuGraph);
}

@end
