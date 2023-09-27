use std::mem::ManuallyDrop;
use std::sync::Arc;
use crate::error::IntoTesseractError;
use tesseract_swift_utils::data::CData;
use tesseract_swift_utils::future::CFuture;
use tesseract_swift_utils::ptr::CAnyDropPtr;
use tesseract_swift_utils::Nothing;

use async_trait::async_trait;

use tesseract::client::Connection;
use tesseract::Result;

#[repr(C)]
pub struct ClientConnection {
    ptr: CAnyDropPtr,
    send: unsafe extern "C" fn(
        connection: &ClientConnection,
        data: *const u8,
        len: usize,
    ) -> ManuallyDrop<CFuture<Nothing>>,
    receive: unsafe extern "C" fn(connection: &ClientConnection) -> ManuallyDrop<CFuture<CData>>,
}

#[async_trait]
impl Connection for ClientConnection {
    async fn send(self: Arc<Self>, request: Vec<u8>) -> Result<()> {
        unsafe {
            let future = (self.as_ref().send)(self.as_ref(), request.as_ptr(), request.len());
            ManuallyDrop::into_inner(future)
                .try_into_future()
                .unwrap()
                .await
                .map(|_| {})
                .map_err(|e| e.into_error())
        }
    }

    async fn receive(self: Arc<Self>) -> Result<Vec<u8>> {
        unsafe {
            let future = ManuallyDrop::into_inner((self.as_ref().receive)(self.as_ref()));
            let future = future.try_into_future().map_err(|e| e.into_error())?;
            future
                .await
                .and_then(|d| d.try_into())
                .map_err(|e| e.into_error())
        }
    }
}
