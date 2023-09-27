use tesseract_swift_utils::error::CError;
use tesseract_swift_utils::future::CFuture;
use tesseract_swift_utils::string::CString;

use tesseract::client::transport::Status;

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
            ClientStatus::Error(err) => Status::Error(Box::new(err)),
        }
    }
}

pub type CFutureClientStatus = CFuture<ClientStatus>;
