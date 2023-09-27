use async_trait::async_trait;
use tesseract::service::{Executor, Service};
use tesseract_protocol_test::service::TestExecutor;
use tesseract_swift_transports::error::IntoTesseractError;
use tesseract_swift_utils::string::{CString, CStringRef};
use tesseract_swift_utils::{ptr::CAnyDropPtr, future_impls::CFutureString};

use crate::service::ServiceTesseract;

use std::mem::ManuallyDrop;
use std::sync::Arc;

#[repr(C)]
pub struct TestService {
    ptr: CAnyDropPtr,
    sign_transaction: unsafe extern "C" fn(
        this: &TestService,
        req: CStringRef,
    ) -> ManuallyDrop<CFutureString>,
}

impl Service for TestService {
    type Protocol = tesseract_protocol_test::Test;

    fn protocol(&self) -> &Self::Protocol {
        &tesseract_protocol_test::Test::Protocol
    }

    fn to_executor(self) -> Box<dyn Executor + Send + Sync> {
        Box::new(TestExecutor::from_service(self))
    }
}

#[async_trait]
impl tesseract_protocol_test::TestService for TestService {
    async fn sign_transaction(self: Arc<Self>, req: &str) -> tesseract::Result<String> {
        let future = unsafe {
            let cstr: CString = req.into();
            ManuallyDrop::into_inner((self.sign_transaction)(&self, cstr.as_ptr()))
        };

        let future = future
            .try_into_future()
            .map_err(|err| err.into_error())?;

        future.await
            .and_then(|cstr| cstr.try_into())
            .map_err(|err| err.into_error())
    }
}

#[no_mangle]
pub extern "C" fn tesseract_service_add_test_service(
    tesseract: &mut ServiceTesseract,
    service: TestService
) -> ManuallyDrop<ServiceTesseract> {
    ManuallyDrop::new(tesseract.service(service))
}