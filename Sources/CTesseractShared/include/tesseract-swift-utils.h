#pragma once

/* Generated with cbindgen:0.26.0 */

/* Warning, this file is autogenerated by cbindgen. Don't modify this manually. */

#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

typedef enum CBigIntSign {
  CBigIntSign_Minus,
  CBigIntSign_NoSign,
  CBigIntSign_Plus,
} CBigIntSign;

enum CErrorCode
#ifdef __cplusplus
  : uint32_t
#endif // __cplusplus
 {
  CErrorCode_Null = 0,
  CErrorCode_Panic,
  CErrorCode_Utf8,
  CErrorCode_Cast,
  CErrorCode_Swift,
  /**
   * Must be last for serialization purposes
   */
  CErrorCode_Sentinel,
};
#ifndef __cplusplus
typedef uint32_t CErrorCode;
#endif // __cplusplus

typedef enum COptionResponseResult {
  COptionResponseResult_Error = 0,
  COptionResponseResult_None,
  COptionResponseResult_Some,
} COptionResponseResult;

typedef const uint8_t *SyncPtr_u8;

typedef struct CArrayRef_u8 {
  SyncPtr_u8 ptr;
  uintptr_t len;
} CArrayRef_u8;

typedef struct CArrayRef_u8 CDataRef;

typedef struct CArray_u8 {
  SyncPtr_u8 ptr;
  uintptr_t len;
} CArray_u8;

typedef struct CArray_u8 CData;

typedef struct CString {
  const char *_0;
} CString;

typedef struct CError {
  uint32_t code;
  struct CString reason;
} CError;

typedef struct SwiftError {
  intptr_t code;
  struct CString domain;
  struct CString description;
} SwiftError;

typedef const char *CStringRef;

typedef void Void;

typedef const Void *SyncPtr_Void;

typedef struct CAnyRustPtr {
  SyncPtr_Void _0;
} CAnyRustPtr;

typedef const uint32_t *SyncPtr_u32;

typedef struct CArray_u32 {
  SyncPtr_u32 ptr;
  uintptr_t len;
} CArray_u32;

typedef struct CBigInt {
  enum CBigIntSign sign;
  struct CArray_u32 data;
} CBigInt;

typedef struct CAnyDropPtr {
  SyncPtr_Void ptr;
  void (*drop)(struct CAnyDropPtr*);
} CAnyDropPtr;

typedef struct Nothing {
  bool _0;
} Nothing;

typedef void (*CFutureOnCompleteCallback_Nothing)(SyncPtr_Void context,
                                                  struct Nothing *value,
                                                  struct CError *error);

typedef struct CFuture_Nothing {
  struct CAnyDropPtr ptr;
  enum COptionResponseResult (*set_on_complete)(const struct CFuture_Nothing *future,
                                                SyncPtr_Void context,
                                                struct Nothing *value,
                                                struct CError *error,
                                                CFutureOnCompleteCallback_Nothing cb);
} CFuture_Nothing;

typedef struct CFuture_Nothing CFutureNothing;

typedef void (*CFutureOnCompleteCallback_CString)(SyncPtr_Void context,
                                                  struct CString *value,
                                                  struct CError *error);

typedef struct CFuture_CString {
  struct CAnyDropPtr ptr;
  enum COptionResponseResult (*set_on_complete)(const struct CFuture_CString *future,
                                                SyncPtr_Void context,
                                                struct CString *value,
                                                struct CError *error,
                                                CFutureOnCompleteCallback_CString cb);
} CFuture_CString;

typedef struct CFuture_CString CFutureString;

typedef struct CInt128 {
  int64_t w1;
  uint64_t w2;
} CInt128;

typedef void (*CFutureOnCompleteCallback_CInt128)(SyncPtr_Void context,
                                                  struct CInt128 *value,
                                                  struct CError *error);

typedef struct CFuture_CInt128 {
  struct CAnyDropPtr ptr;
  enum COptionResponseResult (*set_on_complete)(const struct CFuture_CInt128 *future,
                                                SyncPtr_Void context,
                                                struct CInt128 *value,
                                                struct CError *error,
                                                CFutureOnCompleteCallback_CInt128 cb);
} CFuture_CInt128;

typedef struct CFuture_CInt128 CFutureInt128;

typedef struct CUInt128 {
  uint64_t w1;
  uint64_t w2;
} CUInt128;

typedef void (*CFutureOnCompleteCallback_CUInt128)(SyncPtr_Void context,
                                                   struct CUInt128 *value,
                                                   struct CError *error);

typedef struct CFuture_CUInt128 {
  struct CAnyDropPtr ptr;
  enum COptionResponseResult (*set_on_complete)(const struct CFuture_CUInt128 *future,
                                                SyncPtr_Void context,
                                                struct CUInt128 *value,
                                                struct CError *error,
                                                CFutureOnCompleteCallback_CUInt128 cb);
} CFuture_CUInt128;

typedef struct CFuture_CUInt128 CFutureUInt128;

typedef void (*CFutureOnCompleteCallback_CData)(SyncPtr_Void context,
                                                CData *value,
                                                struct CError *error);

typedef struct CFuture_CData {
  struct CAnyDropPtr ptr;
  enum COptionResponseResult (*set_on_complete)(const struct CFuture_CData *future,
                                                SyncPtr_Void context,
                                                CData *value,
                                                struct CError *error,
                                                CFutureOnCompleteCallback_CData cb);
} CFuture_CData;

typedef struct CFuture_CData CFutureData;

typedef void (*CFutureOnCompleteCallback_CBigInt)(SyncPtr_Void context,
                                                  struct CBigInt *value,
                                                  struct CError *error);

typedef struct CFuture_CBigInt {
  struct CAnyDropPtr ptr;
  enum COptionResponseResult (*set_on_complete)(const struct CFuture_CBigInt *future,
                                                SyncPtr_Void context,
                                                struct CBigInt *value,
                                                struct CError *error,
                                                CFutureOnCompleteCallback_CBigInt cb);
} CFuture_CBigInt;

typedef struct CFuture_CBigInt CFutureBigInt;

typedef void (*CFutureOnCompleteCallback_CAnyRustPtr)(SyncPtr_Void context,
                                                      struct CAnyRustPtr *value,
                                                      struct CError *error);

typedef struct CFuture_CAnyRustPtr {
  struct CAnyDropPtr ptr;
  enum COptionResponseResult (*set_on_complete)(const struct CFuture_CAnyRustPtr *future,
                                                SyncPtr_Void context,
                                                struct CAnyRustPtr *value,
                                                struct CError *error,
                                                CFutureOnCompleteCallback_CAnyRustPtr cb);
} CFuture_CAnyRustPtr;

typedef struct CFuture_CAnyRustPtr CFutureAnyRustPtr;

typedef void (*CFutureOnCompleteCallback_CAnyDropPtr)(SyncPtr_Void context,
                                                      struct CAnyDropPtr *value,
                                                      struct CError *error);

typedef struct CFuture_CAnyDropPtr {
  struct CAnyDropPtr ptr;
  enum COptionResponseResult (*set_on_complete)(const struct CFuture_CAnyDropPtr *future,
                                                SyncPtr_Void context,
                                                struct CAnyDropPtr *value,
                                                struct CError *error,
                                                CFutureOnCompleteCallback_CAnyDropPtr cb);
} CFuture_CAnyDropPtr;

typedef struct CFuture_CAnyDropPtr CFutureAnyDropPtr;

typedef void (*CFutureOnCompleteCallback_bool)(SyncPtr_Void context,
                                               bool *value,
                                               struct CError *error);

typedef struct CFuture_bool {
  struct CAnyDropPtr ptr;
  enum COptionResponseResult (*set_on_complete)(const struct CFuture_bool *future,
                                                SyncPtr_Void context,
                                                bool *value,
                                                struct CError *error,
                                                CFutureOnCompleteCallback_bool cb);
} CFuture_bool;

typedef struct CFuture_bool CFutureBool;

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

bool tesseract_utils_data_clone(CDataRef data, CData *res, struct CError *err);

void tesseract_utils_data_free(CData *data);

struct SwiftError tesseract_utils_swift_error_new(intptr_t code,
                                                  CStringRef domain,
                                                  CStringRef description);

struct CError tesseract_utils_cerr_new_swift_error(intptr_t code,
                                                   CStringRef domain,
                                                   CStringRef description);

struct CString tesseract_utils_cerr_get_description(const struct CError *err);

struct SwiftError tesseract_utils_cerr_get_swift_error(const struct CError *error);

void tesseract_utils_swift_error_free(struct SwiftError *err);

void tesseract_utils_cerror_free(struct CError *err);

void tesseract_utils_any_rust_ptr_free(struct CAnyRustPtr *ptr);

bool tesseract_utils_cstring_new(CStringRef cstr, struct CString *res, struct CError *err);

void tesseract_utils_cstring_free(struct CString cstr);

void tesseract_utils_big_int_free(struct CBigInt *big_int);

#ifdef __cplusplus
} // extern "C"
#endif // __cplusplus