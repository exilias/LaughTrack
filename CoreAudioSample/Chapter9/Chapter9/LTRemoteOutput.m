//
//  LTRemoteOutput.m
//  Chapter9
//
//  Created by 石井 晃 on 13/08/19.
//  Copyright (c) 2013年 OneChance. All rights reserved.
//

#import "LTRemoteOutput.h"

#import <CoreAudio/CoreAudioTypes.h>
#import <AudioUnit/AudioUnit.h>

@interface LTRemoteOutput ()

@property AudioUnit audioUnit;		// 対象となるAudio Unit
@property BOOL isPlaying;

@end



@implementation LTRemoteOutput

static OSStatus renderCallback(void							*inRefCon,
							   AudioUnitRenderActionFlags	*ioActionFlags,
							   const AudioTimeStamp			*inTimeStamp,
							   UInt32						inBusNumber,
							   UInt32						inNumberFrames,
							   AudioBufferList				*ioData)
{
	// RemoteOutputのインスタンスにキャストする
	LTRemoteOutput *def = (__bridge LTRemoteOutput *)inRefCon;
	
	// サイン波の計算に使う数値の用意
	float freq = 440 * 2.0 * M_PI / def.sampleRate;
	// phaseはサウンドの再生中に継続して使うため、RemoteOutputのプロパティとしている
	double phase = def.phase;
	
	// 値を書きこむポインタ
	AudioUnitSampleType *outL = ioData->mBuffers[0].mData;
	AudioUnitSampleType *outR = ioData->mBuffers[1].mData;
	
	for (int i = 0; i < inNumberFrames; i++) {
		// サイン波を計算
		float wave = sin(phase);
		
		// 8.24固定小数点に変換
		AudioUnitSampleType sample = wave * (1 << kAudioUnitSampleFractionBits);
		*outL++ = sample;
		*outR++ = sample;
		phase = phase + freq;
	}
	
	def.phase = phase;
	
	return noErr;
}



- (void)prepareAudioUnit
{
	// RemoteIO Audio UnitのAudioComponentDescription作成
	AudioComponentDescription cd;
	cd.componentType			= kAudioUnitType_Output;
	cd.componentSubType			= kAudioUnitSubType_RemoteIO;
	cd.componentManufacturer	= kAudioUnitManufacturer_Apple;
	cd.componentFlags			= 0;
	cd.componentFlagsMask		= 0;
	
	// Audio Componentの定義を取得
	AudioComponent component = AudioComponentFindNext(NULL, &cd);
	
	// Audio Componentをインスタンス化
	AudioComponentInstanceNew(component, &_audioUnit);
	
	// Audio Unitを初期化
	AudioUnitInitialize(self.audioUnit);
	
	// AURenderCallbackStruct構造体の作成
	AURenderCallbackStruct callbackStruct;
	callbackStruct.inputProc = renderCallback;
	callbackStruct.inputProcRefCon = (__bridge void *)(self);
	
	// コールバック関数の設定
	AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_SetRenderCallback,
						 kAudioUnitScope_Input, // 入力スコープ
						 0, // バスは0
						 &callbackStruct,
						 sizeof(AURenderCallbackStruct));
	
	self.sampleRate = 44100.0;
	
	// ASBDの作成
	AudioStreamBasicDescription audioFormat;
	audioFormat.mSampleRate			= self.sampleRate;
	audioFormat.mFormatID			= kAudioFormatLinearPCM;
	audioFormat.mFormatFlags		= kAudioFormatFlagsAudioUnitCanonical;
	audioFormat.mChannelsPerFrame	= 2;
	audioFormat.mBytesPerFrame		= sizeof(AudioUnitSampleType);
	audioFormat.mBytesPerPacket		= sizeof(AudioUnitSampleType);
	audioFormat.mFramesPerPacket	= 1;
	audioFormat.mBitsPerChannel		= 8 * sizeof(AudioUnitSampleType);
	audioFormat.mReserved			= 0;
	
	// AudioUnitにASBDを設定
	AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &audioFormat, sizeof(audioFormat));
}


- (void)play
{
	if (!self.isPlaying) {
		AudioOutputUnitStart(self.audioUnit);
	}
	self.isPlaying = YES;
}


- (void)stop
{
	if (self.isPlaying) {
		AudioOutputUnitStop(self.audioUnit);
	}
	self.isPlaying = NO;
}


@end
