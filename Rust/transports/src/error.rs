use std::mem::ManuallyDrop;

use thiserror;
use tesseract::{Error as TError, ErrorKind};
use tesseract_swift_utils::{error::{CError, CErrorCode, ErrorCode, SwiftError},
                            string::CString, traits::TryAsRef};

/// cbindgen:add-sentinel
#[repr(u32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub enum CTesseractErrorCode {
    Cancelled = CErrorCode::Sentinel,
    Serialization,
    Weird
}

impl ErrorCode for CTesseractErrorCode {
    const FIRST: u32 = CTesseractErrorCode::Cancelled as u32;
    #[allow(non_upper_case_globals)]
    const Sentinel: u32 = CTesseractErrorCode::Weird as u32 + 1;
}

#[repr(C)]
#[derive(Debug, Clone, thiserror::Error)]
pub enum CTesseractError {
    #[error("TesseractError::Null: {0}")]
    Null(CString),
    #[error("TesseractError::Panic: {0}")]
    Panic(CString),
    #[error("TesseractError::Logger: {0}")]
    Logger(CString),
    #[error("TesseractError::UTF8: {0}")]
    Utf8(CString),
    #[error("TesseractError::Cast: {0}")]
    Cast(CString),
    #[error("TesseractError::Swift: {0}")]
    Swift(#[from] SwiftError),
    #[error("TesseractError::Cancelled")]
    Cancelled,
    #[error("TesseractError::Serialization: {0}")]
    Serialization(CString),
    #[error("TesseractError::Weird: {0}")]
    Weird(CString),
    #[error("TesseractError[{0}]: {1}")]
    Custom(u32, CString)
}

impl From<CError> for CTesseractError {
    fn from(value: CError) -> Self {
        match CErrorCode::from_u32(value.code) {
            Some(code) => match code {
                CErrorCode::Null => Self::Null(value.reason),
                CErrorCode::Panic => Self::Panic(value.reason),
                CErrorCode::Cast => Self::Cast(value.reason),
                CErrorCode::Logger => Self::Logger(value.reason),
                CErrorCode::Utf8 => Self::Utf8(value.reason),
                CErrorCode::Swift => {
                    match SwiftError::try_from(&value) {
                        Err(err) => err.into(),
                        Ok(err) => Self::Swift(err)
                    }
                }
            },
            None => match CTesseractErrorCode::from_u32(value.code) {
                Some(code) => match code {
                    CTesseractErrorCode::Cancelled => Self::Cancelled,
                    CTesseractErrorCode::Serialization => Self::Serialization(value.reason),
                    CTesseractErrorCode::Weird => Self::Weird(value.reason),
                },
                None => Self::Custom(value.code - CTesseractErrorCode::Sentinel, value.reason)
            }
        }
    }
}

impl From<CTesseractError> for CError {
    fn from(value: CTesseractError) -> Self {
        match value {
            CTesseractError::Null(reason) => CError { code: CErrorCode::Null as u32, reason },
            CTesseractError::Panic(reason) => CError { code: CErrorCode::Panic as u32, reason },
            CTesseractError::Logger(reason) => CError { code: CErrorCode::Logger as u32, reason },
            CTesseractError::Utf8(reason) => CError { code: CErrorCode::Utf8 as u32, reason },
            CTesseractError::Cast(reason) => CError { code: CErrorCode::Cast as u32, reason },
            CTesseractError::Swift(error) => match error.try_into() {
                Err(err) => err,
                Ok(err) => err
            },
            CTesseractError::Cancelled => CError { code: CTesseractErrorCode::Cancelled as u32, reason: "".into() },
            CTesseractError::Serialization(reason) => 
                CError { code: CTesseractErrorCode::Serialization as u32, reason },
            CTesseractError::Weird(reason) => CError { code: CTesseractErrorCode::Weird as u32, reason },
            CTesseractError::Custom(code, reason) =>
                CError { code: code + CTesseractErrorCode::Sentinel, reason }
        }
    }
}

impl From<TError> for CTesseractError {
    fn from(value: TError) -> Self {
        match value.kind {
            ErrorKind::Cancelled => Self::Cancelled,
            ErrorKind::Serialization => {
                let reason = value.description.unwrap_or_else(|| String::new());
                Self::Serialization(reason.into())
            },
            ErrorKind::Weird => {
                let reason = value.description.unwrap_or_else(|| String::new());
                let parts: Vec<&str> = reason.split(" :: ").collect();
                if parts.len() != 2 { return Self::Weird(reason.into()); }
                match parts[0].parse::<u32>() {
                    Err(_) => Self::Weird(reason.into()),
                    Ok(code) => CError::new(code, parts[1].to_owned()).into()
                }
            }
        }
    }
}

impl From<CTesseractError> for TError {
    fn from(value: CTesseractError) -> Self {
        match value {
            CTesseractError::Cancelled => TError::kinded(ErrorKind::Cancelled),
            CTesseractError::Serialization(reason) =>
                TError::described(ErrorKind::Serialization, reason.try_as_ref().unwrap()),
            err => {
                let cerr: CError = err.into();
                TError::described(ErrorKind::Weird, &format!("{} :: {}", cerr.code, cerr.reason))
            }
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn tesseract_error_from_cerror(cerr: &mut ManuallyDrop<CError>) -> ManuallyDrop<CTesseractError> {
    ManuallyDrop::new(ManuallyDrop::take(cerr).into())
}

#[no_mangle]
pub unsafe extern "C" fn tesseract_error_to_cerror(core: &mut ManuallyDrop<CTesseractError>) -> ManuallyDrop<CError> {
    ManuallyDrop::new(ManuallyDrop::take(core).into())
}

#[no_mangle]
pub unsafe extern "C" fn tesseract_error_get_description(
    err: &CTesseractError
) -> ManuallyDrop<CString> {
    ManuallyDrop::new(err.to_string().into())
}

#[no_mangle]
pub unsafe extern "C" fn tesseract_error_free(core: &mut ManuallyDrop<CTesseractError>) {
    ManuallyDrop::drop(core)
}
