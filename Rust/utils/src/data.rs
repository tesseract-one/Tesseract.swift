use super::array::{CArray, CArrayRef};
use super::error::CError;
use super::panic::PanicContext;
use crate::response::CMoveResponse;
use super::traits::TryAsRef;
use std::mem::ManuallyDrop;

pub type CDataRef<'a> = CArrayRef<'a, u8>;
pub type CData = CArray<u8>;

#[no_mangle]
pub unsafe extern "C" fn tesseract_utils_data_clone(
    data: CDataRef,
    res: &mut ManuallyDrop<CData>,
    err: &mut ManuallyDrop<CError>,
) -> bool {
    CError::panic_context(|| data.try_as_ref()).response(res, err)
}

#[no_mangle]
pub unsafe extern "C" fn tesseract_utils_data_free(data: &mut ManuallyDrop<CData>) {
    ManuallyDrop::drop(data);
}