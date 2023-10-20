use std::mem::ManuallyDrop;
use std::result::Result;
use super::error::CError;

#[repr(C)]
#[derive(Copy, Clone, Debug)]
pub enum COptionResponseResult {
    Error = 0,
    None,
    Some,
}

pub trait CVoidResponse {
    fn response(self, error: &mut ManuallyDrop<CError>) -> bool;
}

pub trait CCopyResponse<T: Copy, R> {
    fn response(self, value: &mut T, error: &mut ManuallyDrop<CError>) -> R;
}

pub trait CMoveResponse<T, R> {
    fn response(self, value: &mut ManuallyDrop<T>, error: &mut ManuallyDrop<CError>) -> R;
}

impl CVoidResponse for Result<(), CError> {
    fn response(self, error: &mut ManuallyDrop<CError>) -> bool {
        match self {
            Err(err) => {
                *error = ManuallyDrop::new(err);
                false
            }
            Ok(_) => true
        }
    }
}

impl<T: Copy> CCopyResponse<T, bool> for Result<T, CError> {
    fn response(self, value: &mut T, error: &mut ManuallyDrop<CError>) -> bool {
        match self {
            Err(err) => {
                *error = ManuallyDrop::new(err);
                false
            }
            Ok(val) => {
                *value = val;
                true
            }
        }
    }
}

impl<T, IT> CMoveResponse<T, bool> for Result<IT, CError> where IT: Into<T> {
    fn response(self, value: &mut ManuallyDrop<T>, error: &mut ManuallyDrop<CError>) -> bool {
        match self {
            Err(err) => {
                *error = ManuallyDrop::new(err);
                false
            }
            Ok(val) => {
                *value = ManuallyDrop::new(val.into());
                true
            }
        }
    }
}

impl<T: Copy> CCopyResponse<T, COptionResponseResult> for Result<Option<T>, CError> {
    fn response(self, value: &mut T, error: &mut ManuallyDrop<CError>) -> COptionResponseResult {
        match self {
            Err(err) => {
                *error = ManuallyDrop::new(err);
                COptionResponseResult::Error
            }
            Ok(opt) => match opt {
                None => COptionResponseResult::None,
                Some(val) => {
                    *value = val;
                    COptionResponseResult::Some
                }
            },
        }
    }
}

impl<T, IT> CMoveResponse<T, COptionResponseResult> for Result<Option<IT>, CError>
where
   IT: Into<T>,
{
    fn response(
        self,
        value: &mut ManuallyDrop<T>,
        error: &mut ManuallyDrop<CError>,
    ) -> COptionResponseResult {
        match self {
            Err(err) => {
                *error = ManuallyDrop::new(err);
                COptionResponseResult::Error
            }
            Ok(opt) => match opt {
                None => COptionResponseResult::None,
                Some(val) => {
                    *value = ManuallyDrop::new(val.into());
                    COptionResponseResult::Some
                }
            },
        }
    }
}
