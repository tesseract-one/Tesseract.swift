use super::connection::ClientConnection;
use super::status::ClientStatus;
use crate::error::TesseractSwiftError;
use crate::protocol::TesseractProtocol;
use std::mem::ManuallyDrop;
use std::sync::Arc;
use tesseract_swift_utils::future::CFuture;
use tesseract_swift_utils::ptr::CAnyDropPtr;
use tesseract_swift_utils::string::CString;

use async_trait::async_trait;
use errorcon::convertible::ErrorContext;

use tesseract::client::transport::Status;
use tesseract::client::Connection;
use tesseract::client::Transport;
use tesseract::Protocol;

#[repr(C)]
pub struct ClientTransport {
    ptr: CAnyDropPtr,
    id: unsafe extern "C" fn(this: &ClientTransport) -> ManuallyDrop<CString>,
    status: unsafe extern "C" fn(
        this: &ClientTransport,
        protocol: ManuallyDrop<TesseractProtocol>,
    ) -> ManuallyDrop<CFuture<ClientStatus>>,
    connect: unsafe extern "C" fn(
        this: &ClientTransport,
        protocol: ManuallyDrop<TesseractProtocol>,
    ) -> ManuallyDrop<ClientConnection>,
}

impl ClientTransport {
    pub fn new<T: Transport + 'static + Sync + Send>(transport: T) -> Self {
        Self {
            ptr: CAnyDropPtr::new(Arc::new(transport)),
            id: transport_id::<T>,
            status: transport_status::<T>,
            connect: transport_connect::<T>
        }
    }

    fn as_ref<T: Transport + 'static + Sync + Send>(&self) -> &Arc<T> {
        self.ptr.as_ref::<Arc<T>>().unwrap()
    }
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
        let proto = TesseractProtocol::new_dyn(protocol);
        let future = unsafe { 
            ManuallyDrop::into_inner((self.status)(self.as_ref(), ManuallyDrop::new(proto)))
        };
        let result: Result<Status, tesseract::Error> =  TesseractSwiftError::context_async(async || {
            let status = future.try_into_future()?.await?;
            Ok(status.into())
        }).await;
        result.or_else(|e| Ok::<_, ()>(Status::Error(e))).unwrap()
    }

    fn connect(&self, protocol: Box<dyn Protocol>) -> Box<dyn Connection + Sync + Send> {
        unsafe {
            let proto = TesseractProtocol::new_dyn(protocol);
            let connection = (self.connect)(self, ManuallyDrop::new(proto));
            Box::new(ManuallyDrop::into_inner(connection))
        }
    }
}

unsafe extern "C" fn transport_id<T: Transport + 'static + Sync + Send>(
    this: &ClientTransport
) -> ManuallyDrop<CString> {
    ManuallyDrop::new(this.ptr.as_ref::<T>().unwrap().id().into())
}

unsafe extern "C" fn transport_status<T: Transport + 'static + Sync + Send>(
    this: &ClientTransport,
    protocol: ManuallyDrop<TesseractProtocol>,
) -> ManuallyDrop<CFuture<ClientStatus>> {
    let arc = Arc::clone(this.as_ref::<T>());
    let proto = ManuallyDrop::into_inner(protocol);

    let future = TesseractSwiftError::context_async(async || {
        Ok(arc.status(Box::new(proto)).await.into())
    });

    ManuallyDrop::new(future.into())
}

unsafe extern "C" fn transport_connect<T: Transport + 'static + Sync + Send>(
    this: &ClientTransport,
    protocol: ManuallyDrop<TesseractProtocol>,
) -> ManuallyDrop<ClientConnection> {
    let proto = ManuallyDrop::into_inner(protocol);
    let connection = this.as_ref::<T>().connect(Box::new(proto));
    ManuallyDrop::new(ClientConnection::new(connection))
}