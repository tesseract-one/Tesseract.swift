use std::{mem::ManuallyDrop, sync::Arc};

use crate::client::ClientTesseract;
use super::{SubstrateService, SubstrateAccountType, SubstrateGetAccountResponse};
use errorcon::convertible::ErrorContext;
use tesseract_protocol_substrate::{Substrate, SubstrateService as TSubstrateService};
use tesseract_swift::error::TesseractSwiftError;
use tesseract_swift::utils::{
    string::CStringRef, future_impls::CFutureData, ptr::CAnyDropPtr, future::CFuture, data::CDataRef, traits::TryAsRef
};

pub type Service = Arc<dyn tesseract_one::client::Service<Protocol = Substrate>>;

#[no_mangle]
pub extern "C" fn tesseract_client_get_substrate_service(
    tesseract: &ClientTesseract,
) -> ManuallyDrop<SubstrateService> {
    let sub_service: Service = tesseract.service(Substrate::Protocol);
    let service = SubstrateService { 
        ptr: CAnyDropPtr::new(sub_service),
        get_account: substrate_sevice_get_account,
        sign_transaction: substrate_sevice_sign_transaction
    };
    ManuallyDrop::new(service)
}

unsafe extern "C" fn substrate_sevice_get_account(
    this: &SubstrateService,
    account_type: SubstrateAccountType,
) -> ManuallyDrop<CFuture<SubstrateGetAccountResponse>> {
    let service: Result<_, TesseractSwiftError> = TesseractSwiftError::context(|| {
        Ok(Arc::clone(this.ptr.as_ref::<Service>()?))
    });
    let future = TesseractSwiftError::context_async(async || {
        let sub_service = service?;
        Ok(sub_service.get_account(account_type.into()).await?.into())
    });
    ManuallyDrop::new(future.into())
}

unsafe extern "C" fn substrate_sevice_sign_transaction(
    this: &SubstrateService,
    account_type: SubstrateAccountType,
    account_path: CStringRef,
    extrinsic_data: CDataRef,
    extrinsic_metadata: CDataRef,
    extrinsic_types: CDataRef
) -> ManuallyDrop<CFutureData> {
    let params: Result<_, TesseractSwiftError> = TesseractSwiftError::context(|| {
        Ok((account_path.try_as_ref()?.to_owned(),
            extrinsic_data.try_as_ref()?.to_owned(),
            extrinsic_metadata.try_as_ref()?.to_owned(),
            extrinsic_types.try_as_ref()?.to_owned(),
            Arc::clone(this.ptr.as_ref::<Service>()?)))
    });
    let future = TesseractSwiftError::context_async(async || {
        let (path, data, meta, types, service) = params?;
        Ok(service.sign_transaction(
            account_type.into(), &path, &data, &meta, &types
        ).await?.into())
    });
    ManuallyDrop::new(future.into())
}