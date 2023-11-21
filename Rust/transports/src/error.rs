use std::mem::ManuallyDrop;
use thiserror;
use tesseract::{Error as TError, ErrorKind};
use tesseract_swift_utils::{error::{CError, CErrorCode, ErrorCode, SwiftError},
                            traits::TryAsRef, string::CString};

/// cbindgen:add-sentinel
#[repr(u32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub enum CTesseractErrorCode {
    Logger = CErrorCode::Sentinel,
    Cancelled,
    Serialization,
    Weird
}

impl ErrorCode for CTesseractErrorCode {
    const FIRST: u32 = CTesseractErrorCode::Logger as u32;
    #[allow(non_upper_case_globals)]
    const Sentinel: u32 = CTesseractErrorCode::Weird as u32 + 1;
}

#[repr(C)]
#[derive(Debug, thiserror::Error)]
pub enum TesseractSwiftError {
    #[error("TesseractSwiftError::Interop: {0}")]
    Interop(CError),
    #[error("TesseractSwiftError::Swift: {0}")]
    Swift(SwiftError),
    #[error("TesseractSwiftError::Logger: {0}")]
    Logger(String),
    #[error("TesseractSwiftError::Tesseract: {0}")]
    Tesseract(TError),
    #[error("TesseractSwiftError[{0}]: {1}")]
    Custom(u32, String)
}

impl TesseractSwiftError {
    pub fn is_cancelled(&self) -> bool {
        match self {
            Self::Tesseract(terror) => match terror.kind {
                ErrorKind::Cancelled => true,
                _ => false
            },
            _ => false
        }
    }
}

impl From<CError> for TesseractSwiftError {
    fn from(value: CError) -> Self {
        match CErrorCode::from_u32(value.code) {
            Some(code) => match code {
                CErrorCode::Swift => {
                    match SwiftError::try_from(&value) {
                        Err(err) => err.into(),
                        Ok(err) => Self::Swift(err)
                    }
                },
                _ => Self::Interop(value)
            },
            None => match CTesseractErrorCode::from_u32(value.code) {
                Some(code) => match code {
                    CTesseractErrorCode::Logger => Self::Logger(value.reason.try_into().unwrap()),
                    CTesseractErrorCode::Cancelled => 
                        Self::Tesseract(TError::described(ErrorKind::Cancelled, value.reason.try_as_ref().unwrap())),
                    CTesseractErrorCode::Serialization =>
                        Self::Tesseract(TError::described(ErrorKind::Serialization, value.reason.try_as_ref().unwrap())),
                    CTesseractErrorCode::Weird =>
                    Self::Tesseract(TError::described(ErrorKind::Weird, value.reason.try_as_ref().unwrap())),
                },
                None => Self::Custom(value.code - CTesseractErrorCode::Sentinel, value.reason.try_into().unwrap())
            }
        }
    }
}

impl From<TesseractSwiftError> for CError {
    fn from(value: TesseractSwiftError) -> Self {
        match value {
            TesseractSwiftError::Interop(error) => error,
            TesseractSwiftError::Swift(error) => match error.try_into() {
                Err(err) => err,
                Ok(err) => err
            },
            TesseractSwiftError::Logger(reason) => 
                CError { code: CTesseractErrorCode::Logger as u32, reason: reason.into() },
            TesseractSwiftError::Tesseract(error) => {
                let reason = error.description.unwrap_or_default();
                match error.kind {
                    ErrorKind::Cancelled => 
                        CError { code: CTesseractErrorCode::Cancelled as u32, reason: reason.into() },
                    ErrorKind::Serialization => 
                        CError { code: CTesseractErrorCode::Serialization as u32, reason: reason.into() },
                    ErrorKind::Weird => 
                        CError { code: CTesseractErrorCode::Weird as u32, reason: reason.into() }
                }
            },
            TesseractSwiftError::Custom(code, reason) =>
                CError { code: code + CTesseractErrorCode::Sentinel, reason: reason.into() }
        }
    }
}

impl From<TError> for TesseractSwiftError {
    fn from(value: TError) -> Self {
        match value.kind {
            ErrorKind::Weird => {
                let reason = value.description.unwrap_or_else(|| String::new());
                let parts: Vec<&str> = reason.split(" :: ").collect();
                if parts.len() != 2 {
                    return Self::Tesseract(TError::described(ErrorKind::Weird, &reason.clone()));
                }
                match parts[0].parse::<u32>() {
                    Err(_) => Self::Tesseract(TError::described(ErrorKind::Weird, &reason.clone())),
                    Ok(code) => CError::new(code, parts[1].to_owned()).into()
                }
            },
            _ => Self::Tesseract(value)
        }
    }
}

impl From<TesseractSwiftError> for TError {
    fn from(value: TesseractSwiftError) -> Self {
        match value {
            TesseractSwiftError::Tesseract(err) => err,
            err => {
                let cerr: CError = err.into();
                TError::described(ErrorKind::Weird, &format!("{} :: {}", cerr.code, cerr.reason))
            }
        }
    }
}

impl From<log::SetLoggerError> for TesseractSwiftError {
    fn from(value: log::SetLoggerError) -> Self {
        Self::Logger(value.to_string())
    }
}

#[no_mangle]
pub unsafe extern "C" fn tesseract_error_get_description(err: &CError) -> ManuallyDrop<CString> {
    let tesseract: TesseractSwiftError = err.clone().into();
    ManuallyDrop::new(tesseract.to_string().into())
}