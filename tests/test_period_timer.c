#include <assert.h>
#include <stdbool.h>

#include "../t2bce_audio/clock.h"

int main(void)
{
    assert(t2audio_period_ns(489, 48000) == 10187500ULL);
    assert(t2audio_period_ns(0, 48000) == 0);
    assert(t2audio_period_ns(489, 0) == 0);

    return 0;
}
