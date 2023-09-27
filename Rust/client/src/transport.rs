use crate::connection::ClientConnection;
use crate::status::ClientStatus;
use std::mem::ManuallyDrop;
use std::sync::Arc;
use tesseract_swift_utils::future::CFuture;
use tesseract_swift_utils::ptr::CAnyDropPtr;
use tesseract_swift_utils::string::{CString, CStringRef};

use async_trait::async_trait;

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
        unsafe {
            let protoid: CString = protocol.id().into();
            let future = ManuallyDrop::into_inner((self.status)(self.as_ref(), protoid.as_ptr()));
            let future = future.try_into_future().unwrap();
            match future.await {
                Err(error) => Status::Error(Box::new(error)),
                Ok(status) => status.into(),
            }
        }
    }

    fn connect(&self, protocol: Box<dyn Protocol>) -> Box<dyn Connection + Sync + Send> {
        unsafe {
            let protoid: CString = protocol.id().into();
            let connection = (self.connect)(self, protoid.as_ptr());
            Box::new(ManuallyDrop::into_inner(connection))
        }
    }
}
