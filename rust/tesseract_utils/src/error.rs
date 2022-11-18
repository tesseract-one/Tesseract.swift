use super::string::*;
use super::traits::TryAsRef;
use std::mem::ManuallyDrop;
use std::error::Error;
use std::fmt::Display;

#[repr(C)]
#[derive(Debug, Clone)]
pub enum CError {
    NullPtr,
    Canceled,
    Panic(CString),
    Utf8Error(CString),
    ErrorCode(u32, CString),
}

impl From<std::str::Utf8Error> for CError {
    fn from(error: std::str::Utf8Error) -> Self {
        Self::Utf8Error(format!("{}", error).into())
    }
}

impl From<std::ffi::IntoStringError> for CError {
    fn from(error: std::ffi::IntoStringError) -> Self {
        Self::Utf8Error(format!("{}", error).into())
    }
}

impl From<String> for CError {
    fn from(string: String) -> Self {
        Self::ErrorCode(0, string.into())
    }
}

impl From<&str> for CError {
    fn from(string: &str) -> Self {
        Self::ErrorCode(0, string.into())
    }
}

impl Display for CError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            CError::Canceled => write!(f, "C error: Canceled"),
            CError::NullPtr => write!(f, "C error: Null Pointer"),
            CError::Utf8Error(str) => write!(f, "C error: utf8: {}", str.try_as_ref().unwrap()),
            CError::Panic(reason) => write!(f, "C error: panic: {}", reason.try_as_ref().unwrap()),
            CError::ErrorCode(code, reason) => 
                write!(f, "C error: code: {}, reason: {}", code, reason.try_as_ref().unwrap()),
        }
    }
}

impl Error for CError {}

#[no_mangle]
pub unsafe extern "C" fn tesseract_utils_error_free(err: &mut ManuallyDrop<CError>) {
    ManuallyDrop::drop(err);
}
