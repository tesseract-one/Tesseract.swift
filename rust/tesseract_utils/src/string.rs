use super::error::CError;
use super::panic::handle_exception_result;
use super::response::CResponse;
use super::result::Result;
use super::traits::TryAsRef;
use std::ffi::{CStr as FCStr, CString as FCString};
use std::mem::ManuallyDrop;
use std::os::raw::c_char;

pub type CStringRef = *const c_char;

#[repr(transparent)]
#[derive(Debug)]
pub struct CString(*const c_char);

impl CString {
    pub fn as_ptr(&self) -> CStringRef {
        self.0
    }
}

unsafe impl Sync for CString {}
unsafe impl Send for CString {}

impl Drop for CString {
    fn drop(&mut self) {
        println!("CSTRING FREE!!!");
        let _ = unsafe { FCString::from_raw(self.0 as *mut c_char) };
    }
}

impl Clone for CString {
    fn clone(&self) -> Self {
        self.try_as_ref().unwrap().into()
    }
}

impl TryAsRef<str> for CStringRef {
    type Error = CError;

    fn try_as_ref(&self) -> Result<&str> {
        unsafe { FCStr::from_ptr(*self).to_str().map_err(|err| err.into()) }
    }
}

impl TryAsRef<str> for CString {
    type Error = CError;

    fn try_as_ref(&self) -> Result<&str> {
        self.0.try_as_ref()
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
            Err(CError::NullPtr)
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

impl From<&str> for CString {
    fn from(string: &str) -> Self {
        Self(FCString::new(string).unwrap().into_raw())
    }
}

impl From<String> for CString {
    fn from(string: String) -> Self {
        Self(FCString::new(string).unwrap().into_raw())
    }
}

impl From<&String> for CString {
    fn from(string: &String) -> Self {
        Self(FCString::new(string.as_bytes()).unwrap().into_raw())
    }
}

impl CResponse<ManuallyDrop<CString>, bool> for Result<String> {
    fn response(self, value: &mut ManuallyDrop<CString>, error: &mut ManuallyDrop<CError>) -> bool {
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

impl CResponse<ManuallyDrop<CString>, bool> for Result<&str> {
    fn response(self, value: &mut ManuallyDrop<CString>, error: &mut ManuallyDrop<CError>) -> bool {
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

impl CResponse<ManuallyDrop<CString>, bool> for Result<Option<String>> {
    fn response(self, value: &mut ManuallyDrop<CString>, error: &mut ManuallyDrop<CError>) -> bool {
        match self {
            Err(err) => {
                *error = ManuallyDrop::new(err);
                false
            }
            Ok(opt) => {
                match opt {
                    None => value.0 = std::ptr::null_mut(),
                    Some(val) => *value = ManuallyDrop::new(val.into()),
                }
                true
            }
        }
    }
}

impl CResponse<ManuallyDrop<CString>, bool> for Result<Option<&str>> {
    fn response(self, value: &mut ManuallyDrop<CString>, error: &mut ManuallyDrop<CError>) -> bool {
        match self {
            Err(err) => {
                *error = ManuallyDrop::new(err);
                false
            }
            Ok(opt) => {
                match opt {
                    None => value.0 = std::ptr::null_mut(),
                    Some(val) => *value = ManuallyDrop::new(val.into()),
                }
                true
            }
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn tesseract_utils_cstring_new(
    cstr: CStringRef,
    res: &mut ManuallyDrop<CString>,
    err: &mut ManuallyDrop<CError>,
) -> bool {
    handle_exception_result(|| cstr.try_as_ref()).response(res, err)
}

#[no_mangle]
pub unsafe extern "C" fn tesseract_utils_cstring_free(cstr: ManuallyDrop<CString>) {
    let _ = ManuallyDrop::into_inner(cstr);
}
