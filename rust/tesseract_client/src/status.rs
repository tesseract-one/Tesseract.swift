use tesseract_utils::error::CError;
use tesseract_utils::future::CFuture;
use tesseract_utils::string::CString;

use tesseract::client::transport::Status as RStatus;

#[repr(C)]
#[derive(Debug, Clone)]
pub enum Status {
    Ready,
    Unavailable(CString),
    Error(CError),
}

impl From<Status> for RStatus {
    fn from(status: Status) -> Self {
        match status {
            Status::Ready => RStatus::Ready,
            Status::Unavailable(str) => RStatus::Unavailable(str.try_into().unwrap()),
            Status::Error(err) => RStatus::Error(Box::new(err)),
        }
    }
}

pub type CFutureStatus = CFuture<Status>;
