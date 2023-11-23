use crate::panic::PanicContext;
use crate::traits::AsCRef;

use super::error::CError;
use super::response::CMoveResponse;
use super::result::Result;
use super::traits::TryAsRef;
use std::ffi::{CStr as FCStr, CString as FCString};
use std::mem::ManuallyDrop;
use std::os::raw::c_char;
use std::borrow::Borrow;

pub type CStringRef = *const c_char;

#[repr(C)]
#[derive(Debug)]
pub struct CString(*const c_char);

unsafe impl Sync for CString {}
unsafe impl Send for CString {}

impl Drop for CString {
    fn drop(&mut self) {
        let _ = unsafe { FCString::from_raw(self.0 as *mut c_char) };
    }
}

impl Clone for CString {
    fn clone(&self) -> Self {
        self.try_as_ref().unwrap().into()
    }
}

impl PartialEq for CString {
    fn eq(&self, other: &Self) -> bool {
        unsafe { FCStr::from_ptr(self.0).eq(FCStr::from_ptr(other.0)) }
    }
}

impl TryAsRef<str> for CStringRef {
    type Error = CError;

    fn try_as_ref(&self) -> Result<&str> {
        unsafe { FCStr::from_ptr(*self).to_str().map_err(|err| err.into()) }
    }
}

impl std::fmt::Display for CString {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let string = self.try_as_ref().map_err(|_| std::fmt::Error)?;
        write!(f, "{}", string)
    }
}

impl TryAsRef<str> for CString {
    type Error = CError;

    fn try_as_ref(&self) -> Result<&str> {
        self.0.try_as_ref()
    }
}

impl AsCRef<CStringRef> for CString {
    fn as_cref(&self) -> CStringRef {
        self.0
    }
}

impl<'a> TryFrom<&'a CString> for &'a str {
    type Error = CError;

    fn try_from(value: &'a CString) -> Result<Self> {
        value.0.try_as_ref()
    }
}

impl TryFrom<CString> for String {
    type Error = CError;

    fn try_from(value: CString) -> Result<Self> {
        if value.0.is_null() {
            Err(CError::null::<CString>())
        } else {
            let value = ManuallyDrop::new(value); // This is safe. Memory will be consumed by rust CString
            unsafe {
                FCString::from_raw(value.0 as *mut c_char)
                    .into_string()
                    .map_err(|err| err.into())
            }
        }
    }
}

impl<T: Borrow<str>> From<T> for CString {
    fn from(value: T) -> Self {
        Self(FCString::new(value.borrow()).unwrap().into_raw())
    }
}

#[no_mangle]
pub unsafe extern "C" fn tesseract_utils_cstring_new(
    cstr: CStringRef,
    res: &mut ManuallyDrop<CString>,
    err: &mut ManuallyDrop<CError>,
) -> bool {
    CError::panic_context(|| cstr.try_as_ref()).response(res, err)
}

#[no_mangle]
pub unsafe extern "C" fn tesseract_utils_cstring_free(cstr: ManuallyDrop<CString>) {
    let _ = ManuallyDrop::into_inner(cstr);
}
