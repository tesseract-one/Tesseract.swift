use super::connection::ClientConnection;
use super::status::ClientStatus;
use crate::error::TesseractSwiftError;
use std::mem::ManuallyDrop;
use std::sync::Arc;
use tesseract_swift_utils::error::CError;
use tesseract_swift_utils::future::CFuture;
use tesseract_swift_utils::ptr::CAnyDropPtr;
use tesseract_swift_utils::traits::AsCRef;
use tesseract_swift_utils::string::{CString, CStringRef};

use async_trait::async_trait;
use errorcon::convertible::ErrorContext;

use tesseract::client::transport::Status;
use tesseract::client::Connection;
use tesseract::client::Transport;
use tesseract::Protocol;

#[repr(C)]
pub struct ClientTransport {
    ptr: CAnyDropPtr,
    id: unsafe extern "C" fn(transport: &ClientTransport) -> ManuallyDrop<CString>,
    status: unsafe extern "C" fn(
        transport: &ClientTransport,
        protocol: CStringRef,
    ) -> ManuallyDrop<CFuture<ClientStatus>>,
    connect: unsafe extern "C" fn(
        transport: &ClientTransport,
        protocol: CStringRef,
    ) -> ManuallyDrop<ClientConnection>,
}

#[async_trait]
impl Transport for ClientTransport {
    fn id(&self) -> String {
        unsafe {
            ManuallyDrop::into_inner((self.id)(self))
                .try_into()
                .unwrap()
        }
    }

    async fn status(self: Arc<Self>, protocol: Box<dyn Protocol>) -> Status {
        let protoid: CString = protocol.id().into();
        let future = unsafe { 
            ManuallyDrop::into_inner((self.status)(self.as_ref(), protoid.as_cref()))
        };
        let result: Result<Status, CError> =  TesseractSwiftError::context_async(async || {
            let status = future.try_into_future()?.await?;
            Ok(status.into())
        }).await;
        result.or_else(|e| Ok::<_, ()>(Status::Error(Box::new(e)))).unwrap()
    }

    fn connect(&self, protocol: Box<dyn Protocol>) -> Box<dyn Connection + Sync + Send> {
        unsafe {
            let protoid: CString = protocol.id().into();
            let connection = (self.connect)(self, protoid.as_cref());
            Box::new(ManuallyDrop::into_inner(connection))
        }
    }
}
