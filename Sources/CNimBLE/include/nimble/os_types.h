/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

#ifndef _NPL_OS_TYPES_H
#define _NPL_OS_TYPES_H

#include <time.h>
#include <stdbool.h>
#include <pthread.h>
#include <semaphore.h>

#ifdef __APPLE__
#include <stdbool.h>
#include <mach/boolean.h>
#include <sys/errno.h>
#include <stdlib.h>

#include <dispatch/dispatch.h>

struct itimerspec {
    struct timespec it_interval;    /* timer period */
    struct timespec it_value;        /* timer expiration */
};

struct sigevent;

/* If used a lot, queue should probably be outside of this struct */
struct macos_timer {
    dispatch_queue_t tim_queue;
    dispatch_source_t tim_timer;
    void (*tim_func)(union sigval);
    void *tim_arg;
};

typedef struct macos_timer *timer_t;

static inline void
_timer_cancel(void *arg)
{
    struct macos_timer *tim = (struct macos_timer *)arg;
    dispatch_release(tim->tim_timer);
    dispatch_release(tim->tim_queue);
    tim->tim_timer = NULL;
    tim->tim_queue = NULL;
    free(tim);
}

static inline void
_timer_handler(void *arg)
{
    struct macos_timer *tim = (struct macos_timer *)arg;
    union sigval sv;

    sv.sival_ptr = tim->tim_arg;

    if (tim->tim_func != NULL)
        tim->tim_func(sv);
}

static inline int
timer_create(clockid_t clockid, struct sigevent *sevp,
    timer_t *timerid)
{
    struct macos_timer *tim;

    *timerid = NULL;

    switch (clockid) {
        case CLOCK_REALTIME:

            /* What is implemented so far */
            if (sevp->sigev_notify != SIGEV_THREAD) {
                errno = ENOTSUP;
                return (-1);
            }

            tim = (struct macos_timer *)
                malloc(sizeof (struct macos_timer));
            if (tim == NULL) {
                errno = ENOMEM;
                return (-1);
            }

            tim->tim_queue =
                dispatch_queue_create("org.apache.nimble.timerqueue",
                0);
            tim->tim_timer =
                dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,
                0, 0, tim->tim_queue);

            tim->tim_func = sevp->sigev_notify_function;
            tim->tim_arg = sevp->sigev_value.sival_ptr;
            *timerid = tim;

            /* Opting to use pure C instead of Block versions */
            dispatch_set_context(tim->tim_timer, tim);
            dispatch_source_set_event_handler_f(tim->tim_timer,
                _timer_handler);
            dispatch_source_set_cancel_handler_f(tim->tim_timer,
                _timer_cancel);

            return (0);
        default:
            break;
    }

    errno = EINVAL;
    return (-1);
}

static inline int
timer_settime(timer_t tim, int flags,
    const struct itimerspec *its, struct itimerspec *remainvalue)
{
    if (tim != NULL) {

        /* Both zero, is disarm */
        if (its->it_value.tv_sec == 0 &&
            its->it_value.tv_nsec == 0) {
        /* There's a comment about suspend count in Apple docs */
            dispatch_suspend(tim->tim_timer);
            return (0);
        }

        dispatch_time_t start;
        start = dispatch_time(DISPATCH_TIME_NOW,
            NSEC_PER_SEC * its->it_value.tv_sec +
            its->it_value.tv_nsec);
        dispatch_source_set_timer(tim->tim_timer, start,
            NSEC_PER_SEC * its->it_value.tv_sec +
            its->it_value.tv_nsec,
            0);
        dispatch_resume(tim->tim_timer);
    }
    return (0);
}

/*
 timer_gettime() returns the time until next expiration, and the interval, for the timer specified by timerid, in the buffer pointed to by curr_value. The time remaining until the next timer expiration is returned in curr_value->it_value; this is always a relative value, regardless of whether the TIMER_ABSTIME flag was used when arming the timer. If the value returned in curr_value->it_value is zero, then the timer is currently disarmed. The timer interval is returned in curr_value->it_interval. If the value returned in curr_value->it_interval is zero, then this is a "one-shot" timer.
 */
static inline int
timer_gettime(timer_t timerid, struct itimerspec *curr_value)
{
    if (timerid != NULL) {
        // TODO: Implement in macOS
        
    }
    return 0;
}

static inline int
timer_delete(timer_t tim)
{
    /* Calls _timer_cancel() */
    if (tim != NULL)
        dispatch_source_cancel(tim->tim_timer);

    return (0);
}

// https://lists.apple.com/archives/xcode-users/2007/Apr/msg00331.html
static inline int pthread_mutex_timedlock(pthread_mutex_t * mutex, const struct timespec * abs_timeout)
{
    int result;
    do
    {
        result = pthread_mutex_trylock(mutex);
        if (result == EBUSY)
        {
            struct timespec ts;
            ts.tv_sec = 0;
            ts.tv_sec = 10000000;

            /* Sleep for 10,000,000 nanoseconds before trying again. */
            int status = -1;
            while (status == -1)
                status = nanosleep(&ts, &ts);
        }
        else
            break;
    }
    while (result != 0); // and (abs_timeout is 0 or the timeout time has passed));
    return result;
}
#endif

/* The highest and lowest task priorities */
#define OS_TASK_PRI_HIGHEST (sched_get_priority_max(SCHED_RR))
#define OS_TASK_PRI_LOWEST  (sched_get_priority_min(SCHED_RR))

typedef uint32_t ble_npl_time_t;
typedef int32_t ble_npl_stime_t;

//typedef int os_sr_t;
typedef int ble_npl_stack_t;


struct ble_npl_event {
    uint8_t                 ev_queued;
    ble_npl_event_fn       *ev_cb;
    void                   *ev_arg;
};

struct ble_npl_eventq {
    void               *q;
};

struct ble_npl_callout {
    struct ble_npl_event    c_ev;
    struct ble_npl_eventq  *c_evq;
    uint32_t                c_ticks;
    timer_t                 c_timer;
    bool                    c_active;
};

struct ble_npl_mutex {
    pthread_mutex_t         lock;
    pthread_mutexattr_t     attr;
    struct timespec         wait;
};

struct ble_npl_sem {
    sem_t                   lock;
};

struct ble_npl_task {
    pthread_t               handle;
    pthread_attr_t          attr;
    struct sched_param      param;
    const char*             name;
};

typedef void *(*ble_npl_task_func_t)(void *);

int ble_npl_task_init(struct ble_npl_task *t, const char *name, ble_npl_task_func_t func,
		 void *arg, uint8_t prio, ble_npl_time_t sanity_itvl,
		 ble_npl_stack_t *stack_bottom, uint16_t stack_size);

int ble_npl_task_remove(struct ble_npl_task *t);

uint8_t ble_npl_task_count(void);

void ble_npl_task_yield(void);

#endif // _NPL_OS_TYPES_H
