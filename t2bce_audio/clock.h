#ifndef T2AUDIO_CLOCK_H
#define T2AUDIO_CLOCK_H

static inline bool t2audio_clock_ready(unsigned int samples)
{
    return samples >= 1;
}
static inline unsigned long long t2audio_period_ns(unsigned int period_size,
        unsigned int rate)
{
    if (!rate)
        return 0;

    return 1000000000ULL * period_size / rate;
}

#endif
