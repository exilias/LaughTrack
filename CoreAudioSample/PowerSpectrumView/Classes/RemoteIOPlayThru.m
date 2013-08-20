//
//  RemoteIOPlayThru.m
//  RemoteIOPlayThru
//
//  Created by Norihisa Nagano
//

#import "RemoteIOPlayThru.h"


@implementation RemoteIOPlayThru

@synthesize fft;
@synthesize remoteIOUnit;

static void checkError(OSStatus err,const char *message){
    if(err){
        char property[5];
        *(UInt32 *)property = CFSwapInt32HostToBig(err);
        property[4] = '\0';
        NSLog(@"%s = %-4.4s, %d",message, property,err);
        exit(1);
    }
}

static OSStatus outputCallback(
                               void *inRefCon,
                               AudioUnitRenderActionFlags *ioActionFlags,
                               const AudioTimeStamp *inTimeStamp,
                               UInt32 inBusNumber,
                               UInt32 inNumberFrames,
                               AudioBufferList *ioData
){
	OSStatus err;
    RemoteIOPlayThru *remoteIOPlayThru = inRefCon;
    FFT *fft = remoteIOPlayThru.fft;
	AudioUnit remoteIOUnit = remoteIOPlayThru.remoteIOUnit;
    
	err = AudioUnitRender(remoteIOUnit,
                          ioActionFlags,
                          inTimeStamp,
                          1,
                          inNumberFrames,
                          ioData);
	if(err){
		printf("recordingCallback: error %d\n", err);
		return err;
	}
    
    AudioSampleType *output = ioData->mBuffers[0].mData;
    //解析対象のバッファを用意する
    float real[inNumberFrames];
    for(int i = 0; i < inNumberFrames; i++){
        real[i] = output[i] / 32767.0;
    }
    
    float powerSpectrum[inNumberFrames / 2];
    [fft calcPowerSpectrum:real powerSpectrum:powerSpectrum];
    
    float *_powerSpectrum = [remoteIOPlayThru powerSpectrum];
    //解析結果をコピーする
    //Viewクラスはこの_powerSpectrumを取得して表示する
    memcpy(_powerSpectrum, powerSpectrum, sizeof(float) * (inNumberFrames / 2));
    
    return noErr;
}


- (id) init{
    self = [super init];
    if (self != nil) {
        [self prepareAUGraph];
    }
    return self;
}

-(float*)powerSpectrum{
    return powerSpectrum;
}

-(UInt32)frameSize{
    return frameSize;
}


-(void)prepareAUGraph{
    OSStatus err;
    AUNode remoteIONode;
    
    NewAUGraph(&mAuGraph);
    AUGraphOpen(mAuGraph);
    
    AudioComponentDescription cd;
	cd.componentType = kAudioUnitType_Output;
	cd.componentSubType = kAudioUnitSubType_RemoteIO;
	cd.componentManufacturer = kAudioUnitManufacturer_Apple;
	cd.componentFlags = cd.componentFlagsMask = 0;
	
	AUGraphAddNode(mAuGraph, &cd, &remoteIONode);
    AUGraphNodeInfo(mAuGraph, remoteIONode, NULL, &remoteIOUnit);
    
    //マイク入力をオンにする
    UInt32 flag = 1;
    AudioUnitSetProperty(remoteIOUnit,
                         kAudioOutputUnitProperty_EnableIO,
                         kAudioUnitScope_Input,
                         1, //Remote Input
                         &flag,
                         sizeof(flag));
    //オーディオ正準形
    AudioStreamBasicDescription audioFormat = CanonicalASBD(SAMPLE_RATE, 1);
    err = AudioUnitSetProperty(remoteIOUnit,
                         kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Output, //Remote inputのアウトプットバス
                         1, //Remote input
                         &audioFormat,
                         sizeof(AudioStreamBasicDescription));
    checkError(err, "kAudioUnitProperty_StreamFormat 1");
    
    
    err = AudioUnitSetProperty(remoteIOUnit,
                         kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Input,
                         0, //Remote output
                         &audioFormat,
                         sizeof(AudioStreamBasicDescription));
    checkError(err, "kAudioUnitProperty_StreamFormat 2");
    
    AURenderCallbackStruct callbackStruct;
	callbackStruct.inputProc = outputCallback;
	callbackStruct.inputProcRefCon = self;
    AUGraphSetNodeInputCallback(mAuGraph,
                                remoteIONode, 
                                0,
                                &callbackStruct);
    
    AUGraphInitialize(mAuGraph);
    
    frameSize = FFT_SIZE;
    powerSpectrum = malloc(sizeof(float) * frameSize / 2);
    fft = [[FFT alloc] initWithFrameSize:frameSize];
}


-(void)play{
    if(!isPlaying)AUGraphStart(mAuGraph);
    isPlaying = YES;
}

-(void)stop{
    if(isPlaying)AUGraphStop(mAuGraph);
    isPlaying = NO;
}


- (void)dealloc{
    [self stop];
    AUGraphUninitialize(mAuGraph);
    AUGraphClose(mAuGraph);
    DisposeAUGraph(mAuGraph);
    free(powerSpectrum);
    [fft release];
    [super dealloc];
}

@end
