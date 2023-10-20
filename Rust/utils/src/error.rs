use crate::panic::FromPanic;
use crate::result::{Zip1, Result};

use super::string::*;
use super::traits::TryAsRef;
use std::error::Error;
use std::fmt::Display;
use std::mem::ManuallyDrop;

/// cbindgen:add-sentinel
#[repr(u32)]
#[derive(Debug, Copy, Clone, Eq, Ord, PartialOrd, PartialEq)]
pub enum CErrorCode {
    Null = 0, Panic, Utf8, Cast, Swift
}

pub trait ErrorCode: Copy {
    fn from_u32(val: u32) -> Option<Self> {
        if val < Self::FIRST || val >= Self::Sentinel { return  None; }
        unsafe { Some(std::mem::transmute_copy(&val)) }
    }
    const FIRST: u32;
    #[allow(non_upper_case_globals)]
    const Sentinel: u32;
}

impl ErrorCode for CErrorCode {
    const FIRST: u32 = Self::Null as u32;
    #[allow(non_upper_case_globals)]
    const Sentinel: u32 = Self::Swift as u32 + 1;
}

#[repr(C)]
#[derive(Debug, Clone)]
pub struct CError {
    pub code: u32,
    pub reason: CString,
}

impl CError {
    pub fn new(code: u32, reason: String) -> Self {
        Self { code: code, reason: reason.into() }
    }

    pub fn null<T: ?Sized>() -> Self {
        Self::new(CErrorCode::Null as u32, std::any::type_name::<T>().into())
    }

    pub fn panic(reason: String) -> Self {
        Self::new(CErrorCode::Panic as u32, reason.into())
    }

    pub fn utf8(reason: String) -> Self {
        Self::new(CErrorCode::Utf8 as u32, reason.into())
    }

    pub fn swift(reason: String) -> Self {
        Self::new(CErrorCode::Swift as u32, reason.into())
    }

    pub fn cast<F: ?Sized, T: ?Sized>() -> Self {
        Self::new(
            CErrorCode::Cast as u32, 
            format!("Can't cast {} into {}",
                std::any::type_name::<F>(),
                std::any::type_name::<T>()
            )
        )
    }
}

impl From<std::str::Utf8Error> for CError {
    fn from(error: std::str::Utf8Error) -> Self {
        Self::utf8(error.to_string())
    }
}

impl From<std::ffi::IntoStringError> for CError {
    fn from(error: std::ffi::IntoStringError) -> Self {
        Self::utf8(error.to_string())
    }
}

impl Display for CError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match CErrorCode::from_u32(self.code) {
            None => write!(f, "Error[{}]", self.code),
            Some(code) => match code {
                CErrorCode::Null => write!(f, "Error::Null"),
                CErrorCode::Panic => write!(f, "Error::Panic"),
                CErrorCode::Utf8 => write!(f, "Error::UTF8"),
                CErrorCode::Cast => write!(f, "Error::Cast"),
                CErrorCode::Swift => write!(f, "Error::Swift")
            }
        }?;
        let reason = self.reason.try_as_ref().map_err(|_| std::fmt::Error)?;
        if reason.len() > 0 { write!(f, ": {}", reason)? }
        Ok(())
    }
}

impl Error for CError {}

impl FromPanic for CError {
    fn from_panic(panic: &str) -> Self {
        Self::panic(panic.to_owned().into())
    }
}

#[repr(C)]
#[derive(Debug, Clone)]
pub struct SwiftError {
    pub code: isize,
    pub domain: CString,
    pub description: CString
}

impl SwiftError {
    pub fn new(code: isize, domain: CStringRef, description: CStringRef) -> Self {
        Self { code, domain: domain.try_as_ref().unwrap().into(),
               description: description.try_as_ref().unwrap().into() }
    }
}

impl TryFrom<SwiftError> for CError {
    type Error = CError;

    fn try_from(value: SwiftError) -> Result<Self> {
        value.domain.try_as_ref().zip(value.description.try_as_ref())
            .map(|(dm, ds)| {
                format!("{} ~~~ {} ~~~ {}", dm, value.code, ds)
            }).map(|str| CError::new(CErrorCode::Swift as u32, str))
    }
}

impl TryFrom<&CError> for SwiftError {
    type Error = CError;

    fn try_from(value: &CError) -> Result<Self> {
        if value.code != CErrorCode::Swift as u32 { return Err(CError::cast::<CError, SwiftError>()); }
        let reason = value.reason.try_as_ref()?;
        let parts: Vec<&str> = reason.split(" ~~~ ").collect();
        if parts.len() != 3 { return Err(CError::cast::<CError, SwiftError>()); }
        let code = parts[1].parse::<isize>().map_err(|_| CError::cast::<CError, SwiftError>())?;
        Ok(Self { code, domain: parts[0].to_owned().into(), description: parts[2].to_owned().into() })
    }
}

impl Display for SwiftError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{} ~~~ {} ~~~ {}", self.domain, self.code, self.description)
    }
}

impl Error for SwiftError {}

#[no_mangle]
pub unsafe extern "C" fn tesseract_utils_swift_error_new(
    code: isize, domain: CStringRef, description: CStringRef
) -> ManuallyDrop<SwiftError> {
    ManuallyDrop::new(SwiftError::new(code, domain, description))
}

#[no_mangle]
pub unsafe extern "C" fn tesseract_utils_cerr_new_swift_error(
    code: isize, domain: CStringRef, description: CStringRef
) -> ManuallyDrop<CError> {
    ManuallyDrop::new(SwiftError::new(code, domain, description).try_into().unwrap())
}

#[no_mangle]
pub unsafe extern "C" fn tesseract_utils_cerr_get_description(
    err: &CError
) -> ManuallyDrop<CString> {
    ManuallyDrop::new(err.to_string().into())
}

#[no_mangle]
pub unsafe extern "C" fn tesseract_utils_cerr_get_swift_error(error: &CError) -> ManuallyDrop<SwiftError> {
    ManuallyDrop::new(SwiftError::try_from(error).unwrap())
}

#[no_mangle]
pub unsafe extern "C" fn tesseract_utils_swift_error_free(err: &mut ManuallyDrop<SwiftError>) {
    ManuallyDrop::drop(err);
}

#[no_mangle]
pub unsafe extern "C" fn tesseract_utils_cerror_free(err: &mut ManuallyDrop<CError>) {
    ManuallyDrop::drop(err);
}
