//
//  RemoteIOPlayThruViewController.m
//  RemoteIOPlayThru
//
//  Created by Norihisa Nagano
//

#import "RemoteIOPlayThruViewController.h"


@interface RemoteIOPlayThruViewController ()

@property float noiseVolume;
@property BOOL isSpeaking, isInstantSpeaking, justNow;
@property float timeInSilent, timeFromLastSpeak, timeInInstantSpeaking, timeInNonInstantSpeaking;
@property float *sampleAry;
@property UInt32 sampleIndex;

@end



@implementation RemoteIOPlayThruViewController

- (void)viewDidLoad {
	self.noiseVolume = 0.2;
	self.isSpeaking = self.isInstantSpeaking = self.justNow = NO;
	self.timeInSilent = self.timeFromLastSpeak = self.timeInInstantSpeaking = self.timeInNonInstantSpeaking = 0.0f;
	self.sampleIndex = 0;
	self.sampleAry = (float *)malloc(sizeof(float) * 10);
	for (int i = 0; i < 10; i++) {
		self.sampleAry[i] = 0;
	}
	
    [self initializeAudioSession];
    playThru = [[RemoteIOPlayThru alloc]init];
    [playThru play];
    
    [self startTimer];
}

-(void)initializeAudioSession{
    AudioSessionInitialize(NULL, NULL, NULL, NULL);
    AudioSessionSetActive(YES);    
    
    //現在のサンプリングレートを確認する
    UInt32 size = sizeof(Float64);
    Float64 sampleRate;
    AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate, 
                            &size, 
                            &sampleRate);
    printf("sampleRate = %f\n",sampleRate);
    
    //サンプリングレートを変更する
    Float64 newSampleRate = SAMPLE_RATE;
    size = sizeof(Float64);
    AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareSampleRate, 
                            size, 
                            &newSampleRate);
    
    //変更後のサンプリングレートを確認
    size = sizeof(Float64);
    AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate, 
                            &size, 
                            &sampleRate);
    printf("sampleRate = %f\n",sampleRate);
    
    size = sizeof(UInt32);
    UInt32 category = kAudioSessionCategory_PlayAndRecord;
    AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, 
                            size, 
                            &category);
    
    Float32 duration = FFT_SIZE / SAMPLE_RATE;
    printf("duration = %f\n",duration);
    printf("framesize = %f\n",SAMPLE_RATE * duration);

    //IOBufferDurationを変更する
    size = sizeof(Float32);
    AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, 
                            size,
                            &duration);
}

-(void)startTimer{
    [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(update) userInfo:nil repeats:YES];
}

-(void)update{
    float *powerSpectrum = [playThru powerSpectrum];
    UInt32 frameSize = [playThru frameSize];
    [spectrumView setSpectrum:powerSpectrum bandSize:frameSize / 2];
	
	float powerSpecAvr = 0;
	for (int i = 0; i < 8; i++) {
		powerSpecAvr += powerSpectrum[i];
	}
	powerSpecAvr /= 8;
	
	self.sampleAry[self.sampleIndex] = powerSpecAvr;
	
	self.sampleIndex++;
	
	if(self.sampleIndex >= 10){
		self.sampleIndex = 0;
	}
	
	//sample[10]の平均を求める
	float sampleAverage = 0.0;
	for(int i=0; i < 10; i++){
		sampleAverage += self.sampleAry[i];
	}
	
	sampleAverage /= 10;
	NSLog(@"%f", sampleAverage);
	
	// ここで発話アルゴリズムを書く
	// -------------------------------
	
	if (sampleAverage > (self.noiseVolume * 2)) {
		if (!self.isInstantSpeaking) {
			self.isInstantSpeaking = YES;
		}
	} else {
		if (self.isInstantSpeaking) {
			self.isInstantSpeaking = NO;
		}
	}
	
	if (self.isInstantSpeaking) {
		self.timeInInstantSpeaking += 0.01;
		self.timeInNonInstantSpeaking = 0;
	} else {
		self.timeInInstantSpeaking = 0;
		self.timeInNonInstantSpeaking += 0.01;
	}
	
	// 発話フラグのオンオフ
	if (self.isSpeaking) {
		if (self.timeInNonInstantSpeaking > 0.1) { //10くらいに設定してみる
			self.isSpeaking = NO;
		}
	} else {
		if (self.timeInInstantSpeaking > 0.1) {
			self.isSpeaking = YES;
		}
	}
	
	if (self.isSpeaking) {
		NSLog(@"発話");
		self.timeInSilent = 0;
	} else {
		NSLog(@"not発話");
		self.timeInSilent += 0.01;
	}
	
	if (self.justNow) {
		self.timeFromLastSpeak += 0.01;
		if (self.timeFromLastSpeak >= 2.1) {
			self.justNow = NO;
			self.timeFromLastSpeak = 0;
		}
		
	}

}


- (void)dealloc {
    [super dealloc];
}

@end
