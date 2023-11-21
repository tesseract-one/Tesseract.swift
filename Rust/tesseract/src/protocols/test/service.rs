use async_trait::async_trait;
use errorcon::convertible::ErrorContext;
use tesseract::service::{Executor, Service};
use tesseract_protocol_test::service::TestExecutor;
use tesseract_swift_transports::error::TesseractSwiftError;
use tesseract_swift_utils::string::CString;
use tesseract_swift_utils::traits::AsCRef;

use super::TestService;
use crate::service::ServiceTesseract;

use std::mem::ManuallyDrop;
use std::sync::Arc;

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
        let cstr: CString = req.into();
        let future = unsafe { 
            ManuallyDrop::into_inner((self.sign_transaction)(&self, cstr.as_cref()))
        };
        TesseractSwiftError::context_async(async || {
            Ok(future.try_into_future()?.await?.try_into()?)
        }).await
    }
}

#[no_mangle]
pub extern "C" fn tesseract_service_add_test_service(
    tesseract: &mut ServiceTesseract,
    service: TestService
) -> ManuallyDrop<ServiceTesseract> {
    ManuallyDrop::new(tesseract.service(service))
}