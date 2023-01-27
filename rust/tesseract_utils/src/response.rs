use super::error::CError;
use super::result::Result;
use std::mem::ManuallyDrop;

#[repr(u8)]
#[derive(Copy, Clone, Debug)]
pub enum CResponseOption {
    Error = 0,
    None,
    Some,
}

pub trait CResponse<T, R> {
    fn response(self, value: T, error: &mut ManuallyDrop<CError>) -> R;
}

impl CResponse<(), bool> for Result<()> {
    fn response(self, _value: (), error: &mut ManuallyDrop<CError>) -> bool {
        match self {
            Err(err) => {
                *error = ManuallyDrop::new(err);
                false
            }
            Ok(_) => true,
        }
    }
}

impl<T> CResponse<&mut ManuallyDrop<T>, bool> for Result<T> {
    fn response(self, value: &mut ManuallyDrop<T>, error: &mut ManuallyDrop<CError>) -> bool {
        match self {
            Err(err) => {
                *error = ManuallyDrop::new(err);
                false
            }
            Ok(val) => {
                *value = ManuallyDrop::new(val);
                true
            }
        }
    }
}

impl<T: Copy> CResponse<&mut T, CResponseOption> for Result<Option<T>> {
    fn response(self, value: &mut T, error: &mut ManuallyDrop<CError>) -> CResponseOption {
        match self {
            Err(err) => {
                *error = ManuallyDrop::new(err);
                CResponseOption::Error
            }
            Ok(opt) => match opt {
                None => CResponseOption::None,
                Some(val) => {
                    *value = val;
                    CResponseOption::Some
                }
            },
        }
    }
}

impl<T> CResponse<&mut ManuallyDrop<T>, CResponseOption> for Result<Option<T>> {
    fn response(
        self,
        value: &mut ManuallyDrop<T>,
        error: &mut ManuallyDrop<CError>,
    ) -> CResponseOption {
        match self {
            Err(err) => {
                *error = ManuallyDrop::new(err);
                CResponseOption::Error
            }
            Ok(opt) => match opt {
                None => CResponseOption::None,
                Some(val) => {
                    *value = ManuallyDrop::new(val);
                    CResponseOption::Some
                }
            },
        }
    }
}
