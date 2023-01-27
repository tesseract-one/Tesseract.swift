use super::error::CError;
use super::panic::{handle_exception, handle_exception_result};
use super::ptr::SyncPtr;
use super::response::{COptionResponseResult, CResponse};
use super::traits::{IntoC, QuickClone, TryAsRef};
use std::mem::ManuallyDrop;

#[repr(C)]
pub struct CData {
    ptr: SyncPtr<u8>,
    len: usize,
}

impl Drop for CData {
    fn drop(&mut self) {
        let _ = unsafe { Vec::from_raw_parts(self.ptr.ptr() as *mut u8, self.len, self.len) };
        self.ptr = SyncPtr::null();
    }
}

impl Clone for CData {
    fn clone(&self) -> Self {
        self.try_as_ref().unwrap().into()
    }
}

impl QuickClone for CData {
    fn quick_clone(&self) -> Self {
        self.clone()
    }
}

impl TryAsRef<[u8]> for CData {
    type Error = CError;

    fn try_as_ref(&self) -> Result<&[u8], Self::Error> {
        if self.ptr.is_null() {
            Err(CError::NullPtr)
        } else {
            unsafe { Ok(std::slice::from_raw_parts(self.ptr.ptr(), self.len)) }
        }
    }
}

impl<'a> TryFrom<&'a CData> for &'a [u8] {
    type Error = CError;

    fn try_from(value: &'a CData) -> Result<Self, Self::Error> {
        value.try_as_ref()
    }
}

impl TryFrom<CData> for Vec<u8> {
    type Error = CError;

    fn try_from(value: CData) -> Result<Self, Self::Error> {
        if value.ptr.is_null() {
            Err(CError::NullPtr)
        } else {
            let value = ManuallyDrop::new(value); // This is safe. Memory will be owned by Vec.
            unsafe {
                Ok(Vec::from_raw_parts(
                    value.ptr.ptr() as *mut u8,
                    value.len,
                    value.len,
                ))
            }
        }
    }
}

impl From<&[u8]> for CData {
    fn from(data: &[u8]) -> Self {
        Vec::from(data).into()
    }
}

impl From<Vec<u8>> for CData {
    fn from(data: Vec<u8>) -> Self {
        let mut data = ManuallyDrop::new(data.into_boxed_slice());
        Self {
            ptr: data.as_mut_ptr().into(),
            len: data.len(),
        }
    }
}

impl<E> CResponse<&mut ManuallyDrop<CData>, bool> for Result<Vec<u8>, E>
where
    E: IntoC<CVal = CError>,
{
    fn response(self, value: &mut ManuallyDrop<CData>, error: &mut ManuallyDrop<CError>) -> bool {
        match self {
            Err(err) => {
                *error = ManuallyDrop::new(err.into_c());
                false
            }
            Ok(val) => {
                *value = ManuallyDrop::new(val.into());
                true
            }
        }
    }
}

impl<E> CResponse<&mut ManuallyDrop<CData>, bool> for Result<&[u8], E>
where
    E: IntoC<CVal = CError>,
{
    fn response(self, value: &mut ManuallyDrop<CData>, error: &mut ManuallyDrop<CError>) -> bool {
        match self {
            Err(err) => {
                *error = ManuallyDrop::new(err.into_c());
                false
            }
            Ok(val) => {
                *value = ManuallyDrop::new(val.into());
                true
            }
        }
    }
}

impl<E> CResponse<&mut ManuallyDrop<CData>, COptionResponseResult> for Result<Option<Vec<u8>>, E>
where
    E: IntoC<CVal = CError>,
{
    fn response(
        self,
        value: &mut ManuallyDrop<CData>,
        error: &mut ManuallyDrop<CError>,
    ) -> COptionResponseResult {
        match self {
            Err(err) => {
                *error = ManuallyDrop::new(err.into_c());
                COptionResponseResult::Error
            }
            Ok(opt) => match opt {
                None => {
                    value.ptr = SyncPtr::null();
                    value.len = 0;
                    COptionResponseResult::None
                }
                Some(val) => {
                    *value = ManuallyDrop::new(val.into());
                    COptionResponseResult::Some
                }
            },
        }
    }
}

impl<E> CResponse<&mut ManuallyDrop<CData>, COptionResponseResult> for Result<Option<&[u8]>, E>
where
    E: IntoC<CVal = CError>,
{
    fn response(
        self,
        value: &mut ManuallyDrop<CData>,
        error: &mut ManuallyDrop<CError>,
    ) -> COptionResponseResult {
        match self {
            Err(err) => {
                *error = ManuallyDrop::new(err.into_c());
                COptionResponseResult::Error
            }
            Ok(opt) => match opt {
                None => {
                    value.ptr = SyncPtr::null();
                    value.len = 0;
                    COptionResponseResult::None
                }
                Some(val) => {
                    *value = ManuallyDrop::new(val.into());
                    COptionResponseResult::Some
                }
            },
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn tesseract_utils_data_new(
    ptr: &u8,
    len: usize,
    res: &mut ManuallyDrop<CData>,
    err: &mut ManuallyDrop<CError>,
) -> bool {
    handle_exception(|| std::slice::from_raw_parts(ptr, len)).response(res, err)
}

#[no_mangle]
pub unsafe extern "C" fn tesseract_utils_data_clone(
    data: &CData,
    res: &mut ManuallyDrop<CData>,
    err: &mut ManuallyDrop<CError>,
) -> bool {
    handle_exception_result(|| data.try_as_ref()).response(res, err)
}

#[no_mangle]
pub unsafe extern "C" fn tesseract_utils_data_free(data: &mut ManuallyDrop<CData>) {
    ManuallyDrop::drop(data);
}
