use std::sync::Arc;
use std::{mem::ManuallyDrop, collections::HashMap};

use async_trait::async_trait;
use tesseract::Protocol;
use tesseract::client::{Transport, Tesseract, Service, Delegate, transport,};
use tesseract::serialize::Serializer as TSerializer;
use tesseract_swift_transports::client::{ClientTransport, ClientStatus};
use tesseract_swift_transports::error::TesseractSwiftError;
use tesseract_swift_utils::array::CArray;
use tesseract_swift_utils::future_impls::CFutureString;
use tesseract_swift_utils::traits::AsCRef;
use tesseract_swift_utils::{
    ptr::{SyncPtr, CAnyDropPtr}, Void, array::CArrayRef, 
    map::CKeyValue, string::CString
};

pub type ClientTransportsStatusRef<'a> = CArrayRef<'a, CKeyValue<CString, ClientStatus>>;

#[repr(C)]
pub struct ClientTesseractDelegate {
    ptr: CAnyDropPtr,
    select_transport: unsafe extern "C" fn(
        this: &ClientTesseractDelegate,
        transports: ClientTransportsStatusRef,
    ) -> ManuallyDrop<CFutureString>,
}

#[async_trait]
impl Delegate for ClientTesseractDelegate {
    async fn select_transport(
        &self,
        transports: &HashMap<String, transport::Status>,
    ) -> Option<String> {
        let arr: CArray<CKeyValue<CString, ClientStatus>>  = transports.clone().into();
        let future = unsafe { 
            ManuallyDrop::into_inner((self.select_transport)(self, arr.as_cref()))
        };

        let option: Option<CString> = future.try_into_future().unwrap().await
            .map(|s| Some(s))
            .or_else(|err| {
                let terror = TesseractSwiftError::from(err);
                if terror.is_cancelled() { Ok(None) } else { Err(terror) }
            }).unwrap();
        option.map(|s| s.try_into().unwrap())
    }
}

#[repr(C)]
pub enum Serializer {
    Json, Cbor
}

impl From<Serializer> for TSerializer {
    fn from(value: Serializer) -> Self {
        match value {
            Serializer::Json => Self::Json,
            Serializer::Cbor => Self::Cbor,
        }
    }
}

#[repr(C)]
pub struct ClientTesseract(SyncPtr<Void>);

impl Drop for ClientTesseract {
    fn drop(&mut self) {
        let _ = unsafe { self.0.take_typed::<Tesseract>() };
    }
}

impl ClientTesseract {
    pub fn new(tesseract: Tesseract) -> Self {
        Self(SyncPtr::new(tesseract).as_void())
    }

    pub fn service<P: Protocol + Copy + 'static>(&self, r#for: P) -> Arc<impl Service<Protocol = P>> {
        let tesseract = unsafe {
            self.0.as_typed_ref::<Tesseract>()
        };
        tesseract.unwrap().service(r#for)
    }

    pub fn transport<T: Transport + 'static + Sync + Send>(&mut self, transport: T) -> Self {
        let tesseract = unsafe { 
            self.0.take_typed::<Tesseract>()
        };
        Self::new(tesseract.transport(transport))
    }
}

#[no_mangle]
pub extern "C" fn tesseract_client_new(
    delegate: ClientTesseractDelegate, serializer: Serializer
) -> ManuallyDrop<ClientTesseract> {
    ManuallyDrop::new(ClientTesseract::new(Tesseract::new_with_serializer(Arc::new(delegate), serializer.into())))
}

#[no_mangle]
pub extern "C" fn tesseract_client_add_transport(
    tesseract: &mut ClientTesseract, transport: ClientTransport
) -> ManuallyDrop<ClientTesseract> {
    ManuallyDrop::new(tesseract.transport(transport))
}

#[no_mangle]
pub extern "C" fn tesseract_client_free(tesseract: &mut ManuallyDrop<ClientTesseract>) {
    let _ = unsafe { ManuallyDrop::take(tesseract) };
}