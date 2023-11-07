use tesseract_protocol_substrate::{AccountType, GetAccountResponse};
use tesseract_swift_utils::{data::CData, string::CString, error::CError};
use std::mem::ManuallyDrop;

#[cfg(feature="protocol-substrate-service")]
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

#[no_mangle]
pub unsafe extern "C" fn tesseract_substrate_get_account_response_free(
    res: &mut ManuallyDrop<SubstrateGetAccountResponse>
) {
    ManuallyDrop::drop(res);
}
