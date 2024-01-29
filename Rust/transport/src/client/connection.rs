use std::mem::ManuallyDrop;
use std::sync::Arc;
use crate::error::TesseractSwiftError;
use tesseract_swift_utils::Nothing;
use tesseract_swift_utils::data::CDataRef;
use tesseract_swift_utils::future_impls::{CFutureNothing, CFutureData};
use tesseract_swift_utils::ptr::CAnyDropPtr;
use tesseract_swift_utils::traits::{AsCRef, TryAsRef};

use async_trait::async_trait;
use errorcon::convertible::ErrorContext;

use tesseract_one::client::Connection;
use tesseract_one::Result;

#[repr(C)]
pub struct ClientConnection {
    ptr: CAnyDropPtr,
    send: unsafe extern "C" fn(
        this: &ClientConnection,
        data: CDataRef
    ) -> ManuallyDrop<CFutureNothing>,
    receive: unsafe extern "C" fn(this: &ClientConnection) -> ManuallyDrop<CFutureData>,
}

impl ClientConnection {
    pub fn new(connection: Box<dyn Connection + Sync + Send>) -> Self {
        let arc: Arc<dyn Connection + Sync + Send> = connection.into();
        Self { 
            ptr: CAnyDropPtr::new(arc),
            send: connection_send,
            receive: connection_receive
        }
    }

    fn as_ref(&self) -> &Arc<dyn Connection + Sync + Send> {
        self.ptr.as_ref::<Arc<dyn Connection + Sync + Send>>().unwrap()
    }
}

#[async_trait]
impl Connection for ClientConnection {
    async fn send(self: Arc<Self>, request: Vec<u8>) -> Result<()> {
        let future = unsafe { 
            ManuallyDrop::into_inner((self.as_ref().send)(self.as_ref(), request.as_cref()))
        };
        
        TesseractSwiftError::context_async(async || {
            future.try_into_future()?.await?;
            Ok(())
        }).await
    }

    async fn receive(self: Arc<Self>) -> Result<Vec<u8>> {
        let future = unsafe { 
            ManuallyDrop::into_inner((self.as_ref().receive)(self.as_ref()))
        };
        TesseractSwiftError::context_async(async || {
            let cdata = future.try_into_future()?.await?;
            Ok(cdata.try_into()?)
        }).await
    }
}

unsafe extern "C" fn connection_send(
    this: &ClientConnection,
    data: CDataRef
) -> ManuallyDrop<CFutureNothing> {
    let arc = Arc::clone(this.as_ref());
    let vec = data.try_as_ref().unwrap().to_owned();

    let future = TesseractSwiftError::context_async(async || {
        arc.send(vec).await?;
        Ok(Nothing::default())
    });

    ManuallyDrop::new(future.into())
}

unsafe extern "C" fn connection_receive(this: &ClientConnection) -> ManuallyDrop<CFutureData> {
    let arc = Arc::clone(this.as_ref());

    let future = TesseractSwiftError::context_async(async || {
        Ok(arc.receive().await?.into())
    });

    ManuallyDrop::new(future.into())
}