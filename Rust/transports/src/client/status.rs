use tesseract_swift_utils::error::CError;
use tesseract_swift_utils::future::CFuture;
use tesseract_swift_utils::string::CString;

use tesseract::client::transport::Status;

use crate::error::TesseractSwiftError;

#[repr(C)]
#[derive(Debug, Clone)]
pub enum ClientStatus {
    Ready,
    Unavailable(CString),
    Error(CError),
}

impl From<ClientStatus> for Status {
    fn from(status: ClientStatus) -> Self {
        match status {
            ClientStatus::Ready => Status::Ready,
            ClientStatus::Unavailable(str) => Status::Unavailable(str.try_into().unwrap()),
            ClientStatus::Error(err) => Status::Error(TesseractSwiftError::from(err).into()),
        }
    }
}

impl From<Status> for ClientStatus {
    fn from(status: Status) -> Self {
        match status {
            Status::Ready => Self::Ready,
            Status::Unavailable(str) => Self::Unavailable(str.into()),
            Status::Error(err) =>
                Self::Error(TesseractSwiftError::from(err).into())
        }
    }
}

pub type CFutureClientStatus = CFuture<ClientStatus>;
