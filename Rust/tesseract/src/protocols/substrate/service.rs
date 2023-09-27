use std::{mem::ManuallyDrop, sync::Arc};

use async_trait::async_trait;
use tesseract::service::{Service, Executor};
use tesseract_protocol_substrate::{service::SubstrateExecutor, AccountType, GetAccountResponse};
use tesseract_swift_transports::error::IntoTesseractError;
use tesseract_swift_utils::{ptr::CAnyDropPtr, string::{CStringRef, CString}, future_impls::CFutureData, future::CFuture};

use crate::service::ServiceTesseract;

use super::{SubstrateAccountType, SubstrateGetAccountResponse};

#[repr(C)]
pub struct SubstrateService {
    ptr: CAnyDropPtr,
    get_account: unsafe extern "C" fn(
        this: &SubstrateService,
        account_type: SubstrateAccountType,
    ) -> ManuallyDrop<CFuture<SubstrateGetAccountResponse>>,
    sign_transaction: unsafe extern "C" fn(
        this: &SubstrateService,
        account_type: SubstrateAccountType,
        account_path: CStringRef,
        extrinsic_data: *const u8, extrinsic_data_len: usize,
        extrinsic_metadata: *const u8, extrinsic_metadata_len: usize,
        extrinsic_types: *const u8, extrinsic_types_len: usize
    ) -> ManuallyDrop<CFutureData>,
}

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
    async fn get_account(self: Arc<Self>, account_type: AccountType) -> tesseract::Result<GetAccountResponse> {
        let future = unsafe {
            ManuallyDrop::into_inner((self.get_account)(&self, account_type.into()))
        };

        let future = future
            .try_into_future()
            .map_err(|err| err.into_error())?;

        future.await
            .and_then(|res| res.try_into())
            .map_err(|err| err.into_error())
    }

    async fn sign_transaction(
        self: Arc<Self>,
        account_type: AccountType,
        account_path: &str,
        extrinsic_data: &[u8],
        extrinsic_metadata: &[u8],
        extrinsic_types: &[u8],
    ) -> tesseract::Result<Vec<u8>> {
        let future = unsafe {
            let cpath: CString = account_path.into();
            ManuallyDrop::into_inner((self.sign_transaction)(
                &self, account_type.into(), cpath.as_ptr(),
                extrinsic_data.as_ptr(), extrinsic_data.len(),
                extrinsic_metadata.as_ptr(), extrinsic_metadata.len(),
                extrinsic_types.as_ptr(), extrinsic_types.len()
            ))
        };

        let future = future
            .try_into_future()
            .map_err(|err| err.into_error())?;

        future.await
            .and_then(|res| res.try_into())
            .map_err(|err| err.into_error())
    }
}

#[no_mangle]
pub extern "C" fn tesseract_service_add_substrate_service(
    tesseract: &mut ServiceTesseract,
    service: SubstrateService
) -> ManuallyDrop<ServiceTesseract> {
    ManuallyDrop::new(tesseract.service(service))
}