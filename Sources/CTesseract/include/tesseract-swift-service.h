#pragma once

/* Generated with cbindgen:0.26.0 */

/* Warning, this file is autogenerated by cbindgen. Don't modify this manually. */

#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include "tesseract-swift-utils.h"
#include "tesseract-swift-shared.h"

typedef struct ServiceTransportProcessor {
  SyncPtr_Void _0;
} ServiceTransportProcessor;

typedef CAnyDropPtr ServiceBoundTransport;

typedef struct ServiceTransport {
  CAnyDropPtr ptr;
  ServiceBoundTransport (*bind)(struct ServiceTransport transport,
                                struct ServiceTransportProcessor processor);
} ServiceTransport;

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

CFuture_CData tesseract_service_transport_processor_process(struct ServiceTransportProcessor processor,
                                                            const uint8_t *data,
                                                            uintptr_t len);

void tesseract_service_transport_processor_free(struct ServiceTransportProcessor *processor);

#ifdef __cplusplus
} // extern "C"
#endif // __cplusplus