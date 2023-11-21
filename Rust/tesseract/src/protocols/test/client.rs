use std::{mem::ManuallyDrop, sync::Arc};

use crate::client::ClientTesseract;
use super::TestService;
use errorcon::convertible::ErrorContext;
use tesseract_protocol_test::{Test, TestService as TTestService};
use tesseract_swift_transports::error::TesseractSwiftError;
use tesseract_swift_utils::{string::CStringRef, future_impls::CFutureString, ptr::CAnyDropPtr, traits::TryAsRef};

pub type Service = Arc<dyn tesseract::client::Service<Protocol = Test>>;

#[no_mangle]
pub extern "C" fn tesseract_client_get_test_service(
    tesseract: &ClientTesseract,
) -> ManuallyDrop<TestService> {
    let test_service: Service = tesseract.service(Test::Protocol);
    let service = TestService { 
        ptr: CAnyDropPtr::new(test_service),
        sign_transaction: test_service_sign_transaction
    };
    ManuallyDrop::new(service)
}

unsafe extern "C" fn test_service_sign_transaction(
    this: &TestService,
    req: CStringRef,
) -> ManuallyDrop<CFutureString> {
    let params: Result<_, TesseractSwiftError> = TesseractSwiftError::context(|| {
        let request = req.try_as_ref()?.to_owned();
        let service = Arc::clone(this.ptr.as_ref::<Service>()?);
        Ok((request, service))
    });
    let future = TesseractSwiftError::context_async(async || {
        let (request, service) = params?;
        Ok(service.sign_transaction(&request).await?.into())
    });
    ManuallyDrop::new(future.into())
}