use super::error::CError;
use super::traits::IntoC;
use std::mem::ManuallyDrop;
use std::result::Result;

#[repr(C)]
#[derive(Copy, Clone, Debug)]
pub enum COptionResponseResult {
    Error = 0,
    None,
    Some,
}

pub trait CResponse<T, R> {
    fn response(self, value: T, error: &mut ManuallyDrop<CError>) -> R;
}

impl<E> CResponse<(), bool> for Result<(), E>
where
    E: IntoC<CVal = CError>,
{
    fn response(self, _value: (), error: &mut ManuallyDrop<CError>) -> bool {
        match self {
            Err(err) => {
                *error = ManuallyDrop::new(err.into_c());
                false
            }
            Ok(_) => true,
        }
    }
}

impl<T: Copy, E> CResponse<&mut T, bool> for Result<T, E>
where
    E: IntoC<CVal = CError>,
{
    fn response(self, value: &mut T, error: &mut ManuallyDrop<CError>) -> bool {
        match self {
            Err(err) => {
                *error = ManuallyDrop::new(err.into_c());
                false
            }
            Ok(val) => {
                *value = val;
                true
            }
        }
    }
}

impl<T, E> CResponse<&mut ManuallyDrop<T>, bool> for Result<T, E>
where
    E: IntoC<CVal = CError>,
{
    fn response(self, value: &mut ManuallyDrop<T>, error: &mut ManuallyDrop<CError>) -> bool {
        match self {
            Err(err) => {
                *error = ManuallyDrop::new(err.into_c());
                false
            }
            Ok(val) => {
                *value = ManuallyDrop::new(val);
                true
            }
        }
    }
}

impl<T: Copy, E> CResponse<&mut T, COptionResponseResult> for Result<Option<T>, E>
where
    E: IntoC<CVal = CError>,
{
    fn response(self, value: &mut T, error: &mut ManuallyDrop<CError>) -> COptionResponseResult {
        match self {
            Err(err) => {
                *error = ManuallyDrop::new(err.into_c());
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

impl<T, E> CResponse<&mut ManuallyDrop<T>, COptionResponseResult> for Result<Option<T>, E>
where
    E: IntoC<CVal = CError>,
{
    fn response(
        self,
        value: &mut ManuallyDrop<T>,
        error: &mut ManuallyDrop<CError>,
    ) -> COptionResponseResult {
        match self {
            Err(err) => {
                *error = ManuallyDrop::new(err.into_c());
                COptionResponseResult::Error
            }
            Ok(opt) => match opt {
                None => COptionResponseResult::None,
                Some(val) => {
                    *value = ManuallyDrop::new(val);
                    COptionResponseResult::Some
                }
            },
        }
    }
}
