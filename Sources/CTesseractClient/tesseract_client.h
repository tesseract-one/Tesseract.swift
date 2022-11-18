#pragma once

/* Generated with cbindgen:0.24.3 */

/* Warning, this file is autogenerated by cbindgen. Don't modify this manually. */

#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
@import CTesseractUtils;

typedef enum Status_Tag {
  Status_Ready,
  Status_Unavailable,
  Status_Error,
} Status_Tag;

typedef struct Status {
  Status_Tag tag;
  union {
    struct {
      CString unavailable;
    };
    struct {
      CError error;
    };
  };
} Status;

typedef enum CFutureValue_Status_Tag {
  CFutureValue_Status_None_Status,
  CFutureValue_Status_Value_Status,
  CFutureValue_Status_Error_Status,
} CFutureValue_Status_Tag;

typedef struct CFutureValue_Status {
  CFutureValue_Status_Tag tag;
  union {
    struct {
      struct Status value;
    };
    struct {
      CError error;
    };
  };
} CFutureValue_Status;

typedef void (*CFutureOnCompleteCallback_Status)(SyncPtr_Void context, struct Status *value, CError *error);

typedef struct CFuture_Status {
  SyncPtr_Void ptr;
  struct CFutureValue_Status (*set_on_complete)(const struct CFuture_Status *future, SyncPtr_Void context, CFutureOnCompleteCallback_Status cb);
  void (*release)(struct CFuture_Status *fut);
} CFuture_Status;

typedef struct NativeConnection {
  SyncPtr_Void ptr;
  CFuture_Nothing (*send)(const struct NativeConnection *connection, const uint8_t *data, uintptr_t len);
  CFuture_CData (*receive)(const struct NativeConnection *connection);
  void (*release)(struct NativeConnection *connection);
} NativeConnection;

typedef struct NativeTransport {
  SyncPtr_Void ptr;
  CString (*id)(const struct NativeTransport *transport);
  struct CFuture_Status (*status)(const struct NativeTransport *transport, CStringRef protocol);
  struct NativeConnection (*connect)(const struct NativeTransport *transport, CStringRef protocol);
  void (*release)(struct NativeTransport *transport);
} NativeTransport;

typedef struct CFuture_Status CFutureStatus;
