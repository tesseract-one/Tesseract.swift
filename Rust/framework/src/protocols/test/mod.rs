#[cfg(feature="client")]
pub mod client;

#[cfg(feature="service")]
pub mod service;

use std::mem::ManuallyDrop;
use tesseract_swift::protocol::TesseractProtocol;
use tesseract_swift::utils::{ptr::CAnyDropPtr, string::CStringRef, future_impls::CFutureString};

#[repr(C)]
pub struct TestService {
    ptr: CAnyDropPtr,
    sign_transaction: unsafe extern "C" fn(
        this: &TestService,
        req: CStringRef,
    ) -> ManuallyDrop<CFutureString>,
}

#[no_mangle]
pub extern "C" fn tesseract_protocol_test_new() -> ManuallyDrop<TesseractProtocol> {
    ManuallyDrop::new(TesseractProtocol::new(tesseract_protocol_test::Test::Protocol))
}