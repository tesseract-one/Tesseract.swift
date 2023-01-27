use super::string::*;
use super::traits::{IntoC, TryAsRef};
use std::error::Error;
use std::fmt::Display;
use std::mem::ManuallyDrop;

#[repr(C)]
#[derive(Debug, Clone)]
pub enum CError {
    NullPtr,
    Canceled,
    Panic(CString),
    Utf8Error(CString),
    ErrorCode(u32, CString),
    DynamicCast(CString),
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

impl Display for CError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            CError::Canceled => write!(f, "C error: Canceled"),
            CError::NullPtr => write!(f, "C error: Null Pointer"),
            CError::Utf8Error(str) => write!(f, "C error: utf8: {}", str.try_as_ref().unwrap()),
            CError::Panic(reason) => write!(f, "C error: panic: {}", reason.try_as_ref().unwrap()),
            CError::DynamicCast(typ) => {
                write!(f, "C error: cast failed for: {}", typ.try_as_ref().unwrap())
            }
            CError::ErrorCode(code, reason) => write!(
                f,
                "C error: code: {}, reason: {}",
                code,
                reason.try_as_ref().unwrap()
            ),
        }
    }
}

impl Error for CError {}

impl<T: Into<CError>> IntoC for T {
    type CVal = CError;

    fn into_c(self) -> Self::CVal {
        self.into()
    }
}

#[no_mangle]
pub unsafe extern "C" fn tesseract_utils_error_free(err: &mut ManuallyDrop<CError>) {
    ManuallyDrop::drop(err);
}
