use std::mem::ManuallyDrop;

use tesseract::Protocol;
use tesseract_swift_utils::string::CString;

#[repr(C)]
#[derive(Clone, PartialEq)]
pub struct TesseractProtocol(CString);

impl TesseractProtocol {
    pub fn new<P: Protocol>(protocol: P) -> Self {
        Self(protocol.id().into())
    }

    pub fn new_dyn(protocol: Box<dyn Protocol>) -> Self {
        Self(protocol.id().into())
    }
}

impl Protocol for TesseractProtocol {
    fn id(&self) -> String {
        self.0.clone().try_into().unwrap()
    }
}

#[no_mangle]
pub unsafe extern "C" fn tesseract_protocol_is_equal(lhs: &TesseractProtocol, rhs: &TesseractProtocol) -> bool {
    lhs == rhs
}

#[no_mangle]
pub unsafe extern "C" fn tesseract_protocol_get_id(protocol: &TesseractProtocol) -> ManuallyDrop<CString> {
    ManuallyDrop::new(protocol.0.clone())
}

#[no_mangle]
pub unsafe extern "C" fn tesseract_protocol_free(protocol: &mut ManuallyDrop<TesseractProtocol>) {
    let _ = ManuallyDrop::take(protocol);
}