#include <assert.h>
#include <stdbool.h>

#include "../t2bce_audio/clock.h"

int main(void)
{
    assert(t2audio_clock_ready(0) == false);
    assert(t2audio_clock_ready(1) == true);
    assert(t2audio_clock_ready(2) == true);

    return 0;
}
