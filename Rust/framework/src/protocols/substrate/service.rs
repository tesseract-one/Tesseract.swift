use std::{mem::ManuallyDrop, sync::Arc};

use async_trait::async_trait;
use errorcon::convertible::ErrorContext;
use tesseract_one::service::{Service, Executor};
use tesseract_protocol_substrate::{service::SubstrateExecutor, AccountType, GetAccountResponse};
use tesseract_swift::error::TesseractSwiftError;
use tesseract_swift::utils::{string:: CString, traits::AsCRef};

use crate::service::ServiceTesseract;

use super::SubstrateService;

impl Service for SubstrateService {
    type Protocol = tesseract_protocol_substrate::Substrate;

    fn protocol(&self) -> &Self::Protocol {
        &tesseract_protocol_substrate::Substrate::Protocol
    }

    fn to_executor(self) -> Box<dyn Executor + Send + Sync> {
        Box::new(SubstrateExecutor::from_service(self))
    }
}

#[async_trait]
impl tesseract_protocol_substrate::SubstrateService for SubstrateService {
    async fn get_account(self: Arc<Self>, account_type: AccountType) -> tesseract_one::Result<GetAccountResponse> {
        let future = unsafe {
            ManuallyDrop::into_inner((self.get_account)(&self, account_type.into()))
        };
        TesseractSwiftError::context_async(async || {
            Ok(future.try_into_future()?.await?.try_into()?)
        }).await
    }

    async fn sign_transaction(
        self: Arc<Self>,
        account_type: AccountType,
        account_path: &str,
        extrinsic_data: &[u8],
        extrinsic_metadata: &[u8],
        extrinsic_types: &[u8],
    ) -> tesseract_one::Result<Vec<u8>> {
        let cpath: CString = account_path.into();
        let future = unsafe {
            (self.sign_transaction)(
                &self, account_type.into(), cpath.as_cref(),
                extrinsic_data.into(),
                extrinsic_metadata.into(),
                extrinsic_types.into()
            )
        };
        let future = ManuallyDrop::into_inner(future);
        TesseractSwiftError::context_async(async || {
            Ok(future.try_into_future()?.await?.try_into()?)
        }).await
    }
}

#[no_mangle]
pub extern "C" fn tesseract_service_add_substrate_service(
    tesseract: &mut ServiceTesseract,
    service: SubstrateService
) -> ManuallyDrop<ServiceTesseract> {
    ManuallyDrop::new(tesseract.service(service))
}