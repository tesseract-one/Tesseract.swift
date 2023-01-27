#pragma once

/* Generated with cbindgen:0.24.3 */

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

typedef enum COptionResponseResult {
  COptionResponseResult_Error = 0,
  COptionResponseResult_None,
  COptionResponseResult_Some,
} COptionResponseResult;

typedef const uint8_t *SyncPtr_u8;

typedef struct CData {
  SyncPtr_u8 ptr;
  uintptr_t len;
} CData;

typedef const char *CString;

typedef enum CError_Tag {
  CError_NullPtr,
  CError_Canceled,
  CError_Panic,
  CError_Utf8Error,
  CError_ErrorCode,
  CError_DynamicCast,
} CError_Tag;

typedef struct CError_ErrorCode_Body {
  uint32_t _0;
  CString _1;
} CError_ErrorCode_Body;

typedef struct CError {
  CError_Tag tag;
  union {
    struct {
      CString panic;
    };
    struct {
      CString utf8_error;
    };
    CError_ErrorCode_Body error_code;
    struct {
      CString dynamic_cast_;
    };
  };
} CError;

typedef void Void;

typedef const Void *SyncPtr_Void;

typedef struct CAnyRustPtr {
  SyncPtr_Void _0;
} CAnyRustPtr;

typedef const char *CStringRef;

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

typedef enum CFutureValue_Nothing_Tag {
  CFutureValue_Nothing_None_Nothing,
  CFutureValue_Nothing_Value_Nothing,
  CFutureValue_Nothing_Error_Nothing,
} CFutureValue_Nothing_Tag;

typedef struct CFutureValue_Nothing {
  CFutureValue_Nothing_Tag tag;
  union {
    struct {
      struct Nothing value;
    };
    struct {
      struct CError error;
    };
  };
} CFutureValue_Nothing;

typedef void (*CFutureOnCompleteCallback_Nothing)(SyncPtr_Void context, struct Nothing *value, struct CError *error);

typedef struct CFuture_Nothing {
  struct CAnyDropPtr ptr;
  struct CFutureValue_Nothing (*set_on_complete)(const struct CFuture_Nothing *future, SyncPtr_Void context, CFutureOnCompleteCallback_Nothing cb);
} CFuture_Nothing;

typedef struct CFuture_Nothing CFutureNothing;

typedef enum CFutureValue_CString_Tag {
  CFutureValue_CString_None_CString,
  CFutureValue_CString_Value_CString,
  CFutureValue_CString_Error_CString,
} CFutureValue_CString_Tag;

typedef struct CFutureValue_CString {
  CFutureValue_CString_Tag tag;
  union {
    struct {
      CString value;
    };
    struct {
      struct CError error;
    };
  };
} CFutureValue_CString;

typedef void (*CFutureOnCompleteCallback_CString)(SyncPtr_Void context, CString *value, struct CError *error);

typedef struct CFuture_CString {
  struct CAnyDropPtr ptr;
  struct CFutureValue_CString (*set_on_complete)(const struct CFuture_CString *future, SyncPtr_Void context, CFutureOnCompleteCallback_CString cb);
} CFuture_CString;

typedef struct CFuture_CString CFutureString;

typedef struct CInt128 {
  int64_t w1;
  uint64_t w2;
} CInt128;

typedef enum CFutureValue_CInt128_Tag {
  CFutureValue_CInt128_None_CInt128,
  CFutureValue_CInt128_Value_CInt128,
  CFutureValue_CInt128_Error_CInt128,
} CFutureValue_CInt128_Tag;

typedef struct CFutureValue_CInt128 {
  CFutureValue_CInt128_Tag tag;
  union {
    struct {
      struct CInt128 value;
    };
    struct {
      struct CError error;
    };
  };
} CFutureValue_CInt128;

typedef void (*CFutureOnCompleteCallback_CInt128)(SyncPtr_Void context, struct CInt128 *value, struct CError *error);

typedef struct CFuture_CInt128 {
  struct CAnyDropPtr ptr;
  struct CFutureValue_CInt128 (*set_on_complete)(const struct CFuture_CInt128 *future, SyncPtr_Void context, CFutureOnCompleteCallback_CInt128 cb);
} CFuture_CInt128;

typedef struct CFuture_CInt128 CFutureInt128;

typedef struct CUInt128 {
  uint64_t w1;
  uint64_t w2;
} CUInt128;

typedef enum CFutureValue_CUInt128_Tag {
  CFutureValue_CUInt128_None_CUInt128,
  CFutureValue_CUInt128_Value_CUInt128,
  CFutureValue_CUInt128_Error_CUInt128,
} CFutureValue_CUInt128_Tag;

typedef struct CFutureValue_CUInt128 {
  CFutureValue_CUInt128_Tag tag;
  union {
    struct {
      struct CUInt128 value;
    };
    struct {
      struct CError error;
    };
  };
} CFutureValue_CUInt128;

typedef void (*CFutureOnCompleteCallback_CUInt128)(SyncPtr_Void context, struct CUInt128 *value, struct CError *error);

typedef struct CFuture_CUInt128 {
  struct CAnyDropPtr ptr;
  struct CFutureValue_CUInt128 (*set_on_complete)(const struct CFuture_CUInt128 *future, SyncPtr_Void context, CFutureOnCompleteCallback_CUInt128 cb);
} CFuture_CUInt128;

typedef struct CFuture_CUInt128 CFutureUInt128;

typedef enum CFutureValue_CData_Tag {
  CFutureValue_CData_None_CData,
  CFutureValue_CData_Value_CData,
  CFutureValue_CData_Error_CData,
} CFutureValue_CData_Tag;

typedef struct CFutureValue_CData {
  CFutureValue_CData_Tag tag;
  union {
    struct {
      struct CData value;
    };
    struct {
      struct CError error;
    };
  };
} CFutureValue_CData;

typedef void (*CFutureOnCompleteCallback_CData)(SyncPtr_Void context, struct CData *value, struct CError *error);

typedef struct CFuture_CData {
  struct CAnyDropPtr ptr;
  struct CFutureValue_CData (*set_on_complete)(const struct CFuture_CData *future, SyncPtr_Void context, CFutureOnCompleteCallback_CData cb);
} CFuture_CData;

typedef struct CFuture_CData CFutureData;

typedef enum CFutureValue_CBigInt_Tag {
  CFutureValue_CBigInt_None_CBigInt,
  CFutureValue_CBigInt_Value_CBigInt,
  CFutureValue_CBigInt_Error_CBigInt,
} CFutureValue_CBigInt_Tag;

typedef struct CFutureValue_CBigInt {
  CFutureValue_CBigInt_Tag tag;
  union {
    struct {
      struct CBigInt value;
    };
    struct {
      struct CError error;
    };
  };
} CFutureValue_CBigInt;

typedef void (*CFutureOnCompleteCallback_CBigInt)(SyncPtr_Void context, struct CBigInt *value, struct CError *error);

typedef struct CFuture_CBigInt {
  struct CAnyDropPtr ptr;
  struct CFutureValue_CBigInt (*set_on_complete)(const struct CFuture_CBigInt *future, SyncPtr_Void context, CFutureOnCompleteCallback_CBigInt cb);
} CFuture_CBigInt;

typedef struct CFuture_CBigInt CFutureBigInt;

typedef enum CFutureValue_CAnyRustPtr_Tag {
  CFutureValue_CAnyRustPtr_None_CAnyRustPtr,
  CFutureValue_CAnyRustPtr_Value_CAnyRustPtr,
  CFutureValue_CAnyRustPtr_Error_CAnyRustPtr,
} CFutureValue_CAnyRustPtr_Tag;

typedef struct CFutureValue_CAnyRustPtr {
  CFutureValue_CAnyRustPtr_Tag tag;
  union {
    struct {
      struct CAnyRustPtr value;
    };
    struct {
      struct CError error;
    };
  };
} CFutureValue_CAnyRustPtr;

typedef void (*CFutureOnCompleteCallback_CAnyRustPtr)(SyncPtr_Void context, struct CAnyRustPtr *value, struct CError *error);

typedef struct CFuture_CAnyRustPtr {
  struct CAnyDropPtr ptr;
  struct CFutureValue_CAnyRustPtr (*set_on_complete)(const struct CFuture_CAnyRustPtr *future, SyncPtr_Void context, CFutureOnCompleteCallback_CAnyRustPtr cb);
} CFuture_CAnyRustPtr;

typedef struct CFuture_CAnyRustPtr CFutureAnyRustPtr;

typedef enum CFutureValue_CAnyDropPtr_Tag {
  CFutureValue_CAnyDropPtr_None_CAnyDropPtr,
  CFutureValue_CAnyDropPtr_Value_CAnyDropPtr,
  CFutureValue_CAnyDropPtr_Error_CAnyDropPtr,
} CFutureValue_CAnyDropPtr_Tag;

typedef struct CFutureValue_CAnyDropPtr {
  CFutureValue_CAnyDropPtr_Tag tag;
  union {
    struct {
      struct CAnyDropPtr value;
    };
    struct {
      struct CError error;
    };
  };
} CFutureValue_CAnyDropPtr;

typedef void (*CFutureOnCompleteCallback_CAnyDropPtr)(SyncPtr_Void context, struct CAnyDropPtr *value, struct CError *error);

typedef struct CFuture_CAnyDropPtr {
  struct CAnyDropPtr ptr;
  struct CFutureValue_CAnyDropPtr (*set_on_complete)(const struct CFuture_CAnyDropPtr *future, SyncPtr_Void context, CFutureOnCompleteCallback_CAnyDropPtr cb);
} CFuture_CAnyDropPtr;

typedef struct CFuture_CAnyDropPtr CFutureAnyDropPtr;

typedef enum CFutureValue_bool_Tag {
  CFutureValue_bool_None_bool,
  CFutureValue_bool_Value_bool,
  CFutureValue_bool_Error_bool,
} CFutureValue_bool_Tag;

typedef struct CFutureValue_bool {
  CFutureValue_bool_Tag tag;
  union {
    struct {
      bool value;
    };
    struct {
      struct CError error;
    };
  };
} CFutureValue_bool;

typedef void (*CFutureOnCompleteCallback_bool)(SyncPtr_Void context, bool *value, struct CError *error);

typedef struct CFuture_bool {
  struct CAnyDropPtr ptr;
  struct CFutureValue_bool (*set_on_complete)(const struct CFuture_bool *future, SyncPtr_Void context, CFutureOnCompleteCallback_bool cb);
} CFuture_bool;

typedef struct CFuture_bool CFutureBool;

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

void tesseract_utils_init(void);

bool tesseract_utils_data_new(const uint8_t *ptr,
                              uintptr_t len,
                              struct CData *res,
                              struct CError *err);

bool tesseract_utils_data_clone(const struct CData *data, struct CData *res, struct CError *err);

void tesseract_utils_data_free(struct CData *data);

void tesseract_utils_error_free(struct CError *err);

void tesseract_utils_any_rust_ptr_free(struct CAnyRustPtr *ptr);

bool tesseract_utils_cstring_new(CStringRef cstr, CString *res, struct CError *err);

void tesseract_utils_cstring_free(CString cstr);

void tesseract_utils_big_int_free(struct CBigInt *big_int);

#ifdef __cplusplus
} // extern "C"
#endif // __cplusplus
