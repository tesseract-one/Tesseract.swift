
use tesseract::{Error, ErrorKind};
use tesseract_utils::error::CError;

pub trait IntoTesseractError {
  fn into_error(self) -> Error;
}

impl IntoTesseractError for CError {
  fn into_error(self) -> Error {
    match self {
        CError::Canceled => Error::kinded(ErrorKind::Cancelled),
        _ => Error::new_boxed_error(ErrorKind::Weird, format!("{}", self).as_str(), Box::new(self))
    }
  }
}