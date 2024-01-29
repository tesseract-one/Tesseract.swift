use tesseract_protocol_substrate::{AccountType, GetAccountResponse};

use tesseract_swift::protocol::TesseractProtocol;
use tesseract_swift::utils::{
    data::{CData, CDataRef}, string::{CString, CStringRef}, 
    error::CError, ptr::CAnyDropPtr, future::CFuture, future_impls::CFutureData
};
use std::mem::ManuallyDrop;

#[cfg(feature="client")]
pub mod client;

#[cfg(feature="service")]
pub mod service;

#[repr(C)]
pub enum SubstrateAccountType {
    Ed25519, Sr25519, Ecdsa
}

impl From<SubstrateAccountType> for AccountType {
    fn from(value: SubstrateAccountType) -> Self {
        match value {
            SubstrateAccountType::Ecdsa => Self::Ecdsa,
            SubstrateAccountType::Ed25519 => Self::Ed25519,
            SubstrateAccountType::Sr25519 => Self::Sr25519
        }
    }
}

impl From<AccountType> for SubstrateAccountType {
    fn from(value: AccountType) -> Self {
        match value {
            AccountType::Ecdsa => Self::Ecdsa,
            AccountType::Ed25519 => Self::Ed25519,
            AccountType::Sr25519 => Self::Sr25519
        }
    }
}

#[repr(C)]
pub struct SubstrateGetAccountResponse {
    pub public_key: CData,
    pub path: CString
}

impl TryFrom<SubstrateGetAccountResponse> for GetAccountResponse {
    type Error = CError;

    fn try_from(value: SubstrateGetAccountResponse) -> Result<Self, Self::Error> {
        value.public_key.try_into()
            .and_then(|pk| value.path.try_into().map(|pt| (pk, pt)))
            .map(|(pk, pt)|Self{ public_key: pk, path: pt })
    }
}

impl From<GetAccountResponse> for SubstrateGetAccountResponse {
    fn from(response: GetAccountResponse) -> Self {
        Self { public_key: response.public_key.into(), path: response.path.into() }
    }
}


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
        extrinsic_data: CDataRef,
        extrinsic_metadata: CDataRef,
        extrinsic_types: CDataRef
    ) -> ManuallyDrop<CFutureData>,
}

#[no_mangle]
pub unsafe extern "C" fn tesseract_substrate_get_account_response_free(
    res: &mut ManuallyDrop<SubstrateGetAccountResponse>
) {
    ManuallyDrop::drop(res);
}

#[no_mangle]
pub extern "C" fn tesseract_protocol_substrate_new() -> ManuallyDrop<TesseractProtocol> {
    ManuallyDrop::new(TesseractProtocol::new(tesseract_protocol_substrate::Substrate::Protocol))
}