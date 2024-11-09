//
//  CNimBLE.h
//  NimBLE
//
//  Created by Alsey Coleman Miller on 11/6/24.
//

#include <time.h>
#include <stdbool.h>
#include <pthread.h>
#include <semaphore.h>
#include <sys/types.h>
#include "nimble/ble.h"
#include "nimble/transport.h"
#include "nimble/nimble_port.h"
#include "host/ble_hs.h"
#include "host/ble_gap.h"
#include "host/ble_gatt.h"
