use std::mem::ManuallyDrop;
use std::result::Result;

#[repr(C)]
#[derive(Copy, Clone, Debug)]
pub enum COptionResponseResult {
    Error = 0,
    None,
    Some,
}

pub trait CVoidResponse<E> {
    fn response(self, error: &mut ManuallyDrop<E>) -> bool;
}

pub trait CCopyResponse<T: Copy, E, R> {
    fn response(self, value: &mut T, error: &mut ManuallyDrop<E>) -> R;
}

pub trait CMoveResponse<T, E, R> {
    fn response(self, value: &mut ManuallyDrop<T>, error: &mut ManuallyDrop<E>) -> R;
}

impl <E, IE> CVoidResponse<E> for Result<(), IE> where IE: Into<E> {
    fn response(self, error: &mut ManuallyDrop<E>) -> bool {
        match self {
            Err(err) => {
                *error = ManuallyDrop::new(err.into());
                false
            }
            Ok(_) => true
        }
    }
}

impl<T: Copy, E, IE> CCopyResponse<T, E, bool> for Result<T, IE> where IE: Into<E> {
    fn response(self, value: &mut T, error: &mut ManuallyDrop<E>) -> bool {
        match self {
            Err(err) => {
                *error = ManuallyDrop::new(err.into());
                false
            }
            Ok(val) => {
                *value = val;
                true
            }
        }
    }
}

impl<T, IT, E, IE> CMoveResponse<T, E, bool> for Result<IT, IE> where IT: Into<T>, IE: Into<E> {
    fn response(self, value: &mut ManuallyDrop<T>, error: &mut ManuallyDrop<E>) -> bool {
        match self {
            Err(err) => {
                *error = ManuallyDrop::new(err.into());
                false
            }
            Ok(val) => {
                *value = ManuallyDrop::new(val.into());
                true
            }
        }
    }
}

impl<T: Copy, E, IE> CCopyResponse<T, E, COptionResponseResult> for Result<Option<T>, IE>
where
    IE: Into<E>,
{
    fn response(self, value: &mut T, error: &mut ManuallyDrop<E>) -> COptionResponseResult {
        match self {
            Err(err) => {
                *error = ManuallyDrop::new(err.into());
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

impl<T, IT, E, IE> CMoveResponse<T, E, COptionResponseResult> for Result<Option<IT>, IE>
where
   IT: Into<T>, IE: Into<E>,
{
    fn response(
        self,
        value: &mut ManuallyDrop<T>,
        error: &mut ManuallyDrop<E>,
    ) -> COptionResponseResult {
        match self {
            Err(err) => {
                *error = ManuallyDrop::new(err.into());
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
