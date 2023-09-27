pub use tesseract::{Error, ErrorKind};
pub use tesseract_swift_utils::error::CError;

#[repr(u32)]
#[derive(Debug, Clone, Copy)]
pub enum CErrorCodes {
    EmptyRequest = 0,
    EmptyResponse,
    UnsupportedDataType,
    RequestExpired,
    WrongProtocolId,
    WrongInternalState,
    Serialization,
    Nested,
}

pub trait IntoCError {
    fn into_cerror(self) -> CError;
}

impl IntoCError for Error {
    fn into_cerror(self) -> CError {
        match self.kind {
            ErrorKind::Serialization => {
                CError::ErrorCode(CErrorCodes::Serialization as u32, self.to_string().into())
            }
            ErrorKind::Cancelled => CError::Canceled,
            ErrorKind::Weird => {
                CError::ErrorCode(CErrorCodes::Nested as u32, self.to_string().into())
            }
        }
    }
}

pub trait IntoTesseractError {
    fn into_error(self) -> Error;
}

impl IntoTesseractError for CError {
    fn into_error(self) -> Error {
        match &self {
            CError::Canceled => Error::kinded(ErrorKind::Cancelled),
            CError::ErrorCode(code, reason) => {
                if *code == (CErrorCodes::Serialization as u32) {
                    Error::described(ErrorKind::Serialization, reason.try_into().unwrap())
                } else {
                    Error::new(ErrorKind::Weird, self.to_string().as_str(), self)
                }
            }
            _ => Error::new(ErrorKind::Weird, self.to_string().as_str(), self),
        }
    }
}
