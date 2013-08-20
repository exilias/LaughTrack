//
//  FFT.m
//  WhiteOut
//
//  Created by Norihisa Nagano
//

#import "FFT.h"


@implementation FFT

/***********************************************************
 fft.c -- FFT (高速Fourier変換)
 ***********************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
/*
 関数{\tt fft()}の下請けとして三角関数表を作る.
 */
static void make_sintbl(int n, float sintbl[])
{
    int i, n2, n4, n8;
    double c, s, dc, ds, t;
    
    n2 = n / 2;  n4 = n / 4;  n8 = n / 8;
    t = sin(M_PI / n);
    dc = 2 * t * t;  ds = sqrt(dc * (2 - dc));
    t = 2 * dc;  c = sintbl[n4] = 1;  s = sintbl[0] = 0;
    for (i = 1; i < n8; i++) {
        c -= dc;  dc += t * c;
        s += ds;  ds -= t * s;
        sintbl[i] = s;  sintbl[n4 - i] = c;
    }
    if (n8 != 0) sintbl[n8] = sqrt(0.5);
    for (i = 0; i < n4; i++)
        sintbl[n2 - i] = sintbl[i];
    for (i = 0; i < n2 + n4; i++)
        sintbl[i + n2] = - sintbl[i];
}
/*
 関数{\tt fft()}の下請けとしてビット反転表を作る.
 */
static void make_bitrev(int n, int bitrev[])
{
    int i, j, k, n2;
    
    n2 = n / 2;  i = j = 0;
    for ( ; ; ) {
        bitrev[i] = j;
        if (++i >= n) break;
        k = n2;
        while (k <= j) {  j -= k;  k /= 2;  }
        j += k;
    }
}
/*
 高速Fourier変換 (Cooley--Tukeyのアルゴリズム).
 標本点の数 {\tt n} は2の整数乗に限る.
 {\tt x[$k$]} が実部, {\tt y[$k$]} が虚部 ($k = 0$, $1$, $2$,
 \ldots, $|{\tt n}| - 1$).
 結果は {\tt x[]}, {\tt y[]} に上書きされる.
 ${\tt n} = 0$ なら表のメモリを解放する.
 ${\tt n} < 0$ なら逆変換を行う.
 前回と異なる $|{\tt n}|$ の値で呼び出すと,
 三角関数とビット反転の表を作るために多少余分に時間がかかる.
 この表のための記憶領域獲得に失敗すると1を返す (正常終了時
 の戻り値は0).
 これらの表の記憶領域を解放するには ${\tt n} = 0$ として
 呼び出す (このときは {\tt x[]}, {\tt y[]} の値は変わらない).
 */
int fft(int n, float *x, float *y)
{
    static int    last_n = 0;    /* 前回呼出し時の {\tt n} */
    static int   *bitrev = NULL; /* ビット反転表 */
    static float *sintbl = NULL; /* 三角関数表 */
    int i, j, k, ik, h, d, k2, n4, inverse;
    float t, s, c, dx, dy;
    
    /* 準備 */
    if (n < 0) {
        n = -n;  inverse = 1;  /* 逆変換 */
    } else inverse = 0;
    n4 = n / 4;
    if (n != last_n || n == 0) {
        last_n = n;
        if (sintbl != NULL) free(sintbl);
        if (bitrev != NULL) free(bitrev);
        if (n == 0) return 0;  /* 記憶領域を解放した */
        sintbl = malloc((n + n4) * sizeof(float));
        bitrev = malloc(n * sizeof(int));
        if (sintbl == NULL || bitrev == NULL) {
            fprintf(stderr, "記憶領域不足\n");  return 1;
        }
        make_sintbl(n, sintbl);
        make_bitrev(n, bitrev);
    }
    for (i = 0; i < n; i++) {    /* ビット反転 */
        j = bitrev[i];
        if (i < j) {
            t = x[i];  x[i] = x[j];  x[j] = t;
            t = y[i];  y[i] = y[j];  y[j] = t;
        }
    }
    for (k = 1; k < n; k = k2) {    /* 変換 */
        h = 0;  k2 = k + k;  d = n / k2;
        for (j = 0; j < k; j++) {
            c = sintbl[h + n4];
            if (inverse) s = - sintbl[h];
            else         s =   sintbl[h];
            for (i = j; i < n; i += k2) {
                ik = i + k;
                dx = s * y[ik] + c * x[ik];
                dy = c * y[ik] - s * x[ik];
                x[ik] = x[i] - dx;  x[i] += dx;
                y[ik] = y[i] - dy;  y[i] += dy;
            }
            h += d;
        }
    }
    
    return 0;  /* 正常終了 */
}



-(id)initWithFrameSize:(UInt32)frameSize{
    self = [super init];
    if (self != nil) {
        _frameSize = frameSize;
        [self setup];
    }
    return self;
}


-(void)setup{
    HanningWindow = malloc(sizeof(float) * _frameSize);
    for(int i = 0; i < _frameSize; i++){
        HanningWindow[i] = 0.5 - 0.5 * cos(2.0 * M_PI * i / _frameSize);
    }
    imag = malloc(sizeof(float) * _frameSize);
}

-(void)calcPowerSpectrum:(float*)real
           powerSpectrum:(float*)powerSpectrum{
    
    //窓かけ
    for(int i = 0; i < _frameSize; i++){
        real[i] = real[i] * HanningWindow[i];
    }
    memset(imag, 0, sizeof(float) * _frameSize);
    
    fft(_frameSize, real, imag);
    
    for(int i = 0; i < _frameSize / 2; i++){
        float sp = sqrt((real[i] * real[i]) + (imag[i] *imag[i]));
        powerSpectrum[i] = sp;
    }
}

- (void) dealloc
{
    free(imag);
    free(HanningWindow);
    [super dealloc];
}

@end
