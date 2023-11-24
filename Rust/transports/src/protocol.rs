use std::mem::ManuallyDrop;

use tesseract::Protocol;
use tesseract_swift_utils::{string::CString, ptr::SyncPtr, Void};

#[repr(C)]
pub struct TesseractProtocol(SyncPtr<Void>);

impl TesseractProtocol {
    pub fn new<P: Protocol + 'static>(protocol: P) -> Self {
        Self::new_dyn(Box::new(protocol))
    }

    pub fn new_dyn(protocol: Box<dyn Protocol>) -> Self {
        Self(SyncPtr::new(protocol).as_void())
    }
}

impl Protocol for TesseractProtocol {
    fn id(&self) -> String {
        unsafe { self.0.as_typed_ref::<Box<dyn Protocol>>().unwrap().id().into() }
    }
}

impl Drop for TesseractProtocol {
    fn drop(&mut self) {
        let _ = unsafe { self.0.take_typed::<Box<dyn Protocol>>() };
    }
}

#[no_mangle]
pub unsafe extern "C" fn tesseract_protocol_is_equal(lhs: &TesseractProtocol, rhs: &TesseractProtocol) -> bool {
    lhs.id() == rhs.id()
}

#[no_mangle]
pub unsafe extern "C" fn tesseract_protocol_get_id(protocol: &TesseractProtocol) -> ManuallyDrop<CString> {
    ManuallyDrop::new(protocol.id().into())
}

#[no_mangle]
pub unsafe extern "C" fn tesseract_protocol_free(protocol: &mut ManuallyDrop<TesseractProtocol>) {
    let _ = ManuallyDrop::take(protocol);
}