use std::mem::ManuallyDrop;
use std::sync::Arc;
use crate::error::TesseractSwiftError;
use tesseract_swift_utils::data::CDataRef;
use tesseract_swift_utils::future_impls::{CFutureNothing, CFutureData};
use tesseract_swift_utils::ptr::CAnyDropPtr;
use tesseract_swift_utils::traits::AsCRef;

use async_trait::async_trait;
use errorcon::convertible::ErrorContext;

use tesseract::client::Connection;
use tesseract::Result;

#[repr(C)]
pub struct ClientConnection {
    ptr: CAnyDropPtr,
    send: unsafe extern "C" fn(
        this: &ClientConnection,
        data: CDataRef
    ) -> ManuallyDrop<CFutureNothing>,
    receive: unsafe extern "C" fn(this: &ClientConnection) -> ManuallyDrop<CFutureData>,
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
