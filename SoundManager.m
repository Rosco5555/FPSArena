// SoundManager.m - Audio generation and playback implementation
#import "SoundManager.h"

// Helper function to generate WAV data
static NSData *makeWav(float *samples, int count, int sampleRate) {
    int16_t *pcm = malloc(count * 2);
    for (int i = 0; i < count; i++) {
        float s = samples[i];
        if (s > 1) s = 1; if (s < -1) s = -1;
        pcm[i] = (int16_t)(s * 32767);
    }
    int dataSize = count * 2;
    int fileSize = 44 + dataSize;
    uint8_t header[44] = {
        'R','I','F','F',
        fileSize-8, (fileSize-8)>>8, (fileSize-8)>>16, (fileSize-8)>>24,
        'W','A','V','E',
        'f','m','t',' ',
        16,0,0,0,           // chunk size
        1,0,                 // PCM
        1,0,                 // mono
        sampleRate, sampleRate>>8, sampleRate>>16, sampleRate>>24,
        (sampleRate*2), (sampleRate*2)>>8, (sampleRate*2)>>16, (sampleRate*2)>>24,
        2,0,                 // block align
        16,0,                // bits per sample
        'd','a','t','a',
        dataSize, dataSize>>8, dataSize>>16, dataSize>>24
    };
    NSMutableData *wav = [NSMutableData dataWithBytes:header length:44];
    [wav appendBytes:pcm length:dataSize];
    free(pcm);
    return wav;
}

@implementation SoundManager

+ (instancetype)shared {
    static SoundManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SoundManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initSounds];
    }
    return self;
}

- (void)initSounds {
    int sr = 22050;

    // Door sound - load from file (SoundJay, free for use)
    {
        NSString *path = @"door_open.wav";
        _doorSound = [[NSSound alloc] initWithContentsOfFile:path byReference:NO];
    }

    // Footstep sound (~0.15 seconds) - soft grass footstep
    {
        int count = (int)(sr * 0.15);
        float *buf = calloc(count, sizeof(float));
        float brownNoise = 0.0f;
        for (int i = 0; i < count; i++) {
            float t = (float)i / sr;
            float env = sinf(M_PI * t / 0.15f) * expf(-t * 15);
            brownNoise += ((float)rand()/RAND_MAX - 0.5f) * 0.1f;
            brownNoise *= 0.98f;
            buf[i] = brownNoise * env * 0.3f;
            buf[i] += sinf(2 * M_PI * 60 * t) * env * 0.4f;
            buf[i] += sinf(2 * M_PI * 90 * t) * env * 0.2f;
        }
        NSData *wav = makeWav(buf, count, sr);
        _footstepSound = [[NSSound alloc] initWithData:wav];
        free(buf);
    }

    // Gunshot sound
    {
        int count = (int)(sr * 0.3);
        float *buf = calloc(count, sizeof(float));
        for (int i = 0; i < count; i++) {
            float t = (float)i / sr;
            float crackEnv = expf(-t * 150.0f);
            float crack = ((float)rand()/RAND_MAX * 2 - 1) * crackEnv * 0.8f;
            float boomEnv = expf(-t * 30.0f);
            float boom = sinf(2 * M_PI * 60 * t) * boomEnv * 0.5f;
            float bodyEnv = expf(-t * 50.0f);
            float body = sinf(2 * M_PI * 200 * t) * bodyEnv * 0.3f;
            float sizzleEnv = expf(-t * 80.0f);
            float sizzle = ((float)rand()/RAND_MAX * 2 - 1) * sizzleEnv * 0.2f;
            buf[i] = crack + boom + body + sizzle;
            if (buf[i] > 0.9f) buf[i] = 0.9f;
            if (buf[i] < -0.9f) buf[i] = -0.9f;
        }
        NSData *wav = makeWav(buf, count, sr);
        _gunSound = [[NSSound alloc] initWithData:wav];
        free(buf);
    }

    // Enemy gunshot sound
    {
        int count = (int)(sr * 0.25);
        float *buf = calloc(count, sizeof(float));
        for (int i = 0; i < count; i++) {
            float t = (float)i / sr;
            float crackEnv = expf(-t * 200.0f);
            float crack = ((float)rand()/RAND_MAX * 2 - 1) * crackEnv * 0.7f;
            float boomEnv = expf(-t * 40.0f);
            float boom = sinf(2 * M_PI * 90 * t) * boomEnv * 0.4f;
            float bodyEnv = expf(-t * 60.0f);
            float body = sinf(2 * M_PI * 300 * t) * bodyEnv * 0.25f;
            buf[i] = crack + boom + body;
            if (buf[i] > 0.9f) buf[i] = 0.9f;
            if (buf[i] < -0.9f) buf[i] = -0.9f;
        }
        NSData *wav = makeWav(buf, count, sr);
        _enemyGunSound = [[NSSound alloc] initWithData:wav];
        free(buf);
    }
}

- (void)playGunSound {
    [_gunSound stop];
    [_gunSound play];
}

- (void)playEnemyGunSoundWithVolume:(float)volume {
    [_enemyGunSound stop];
    [_enemyGunSound setVolume:volume];
    [_enemyGunSound play];
}

- (void)playDoorSound {
    if (_doorSound) {
        [_doorSound stop];
        [_doorSound play];
    }
}

- (void)playFootstepSound {
    if (_footstepSound) {
        [_footstepSound stop];
        [_footstepSound play];
    }
}

@end
