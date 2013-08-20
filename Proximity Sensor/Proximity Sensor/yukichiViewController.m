//
//  yukichiViewController.m
//  Proximity Sensor
//
//  Created by Ueta Shunya on 2013/08/19.
//  Copyright (c) 2013年 Ueta Shunya. All rights reserved.
//

#import "yukichiViewController.h"

@interface yukichiViewController ()

@end

@implementation yukichiViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}


// 近接センサをONに
- (void)startSensor {
    // 近接センサをオン
    [UIDevice currentDevice].proximityMonitoringEnabled = YES;
    
    // 近接センサ監視
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(proximitySensorStateDidchange:)
                                                 name:UIDeviceProximityStateDidChangeNotification
                                               object:nil];
}

// 近接センサの値が変更
- (void)proximitySensorStateDidchange:(NSNotification *)notification {
    // 近接センサが反応したら
    if ([UIDevice currentDevice].proximityState == YES) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"oc" ofType:@"wave"];
        NSURL *url = [NSURL fileURLWithPath:path];
        AVAudioPlayer *audio = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
        [audio play];
    }
}

- (void)stopSensor {
    // 近接センサオフ
    [UIDevice currentDevice].proximityMonitoringEnabled = NO;
    
    // 近接センサ監視解除
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIDeviceProximityStateDidChangeNotification
                                                  object:nil];
}
- (void)viewDidAppear:(BOOL)animated
{
    [self startSensor];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
