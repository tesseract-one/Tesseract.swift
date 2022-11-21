use tesseract_utils::future::CFuture;
use tesseract_utils::ptr::SyncPtr;
use tesseract_utils::data::CData;
use tesseract_utils::{Nothing, Void};
use tesseract_common::error::IntoTesseractError;
use std::mem::ManuallyDrop;
use std::sync::Arc;

use async_trait::async_trait;

use tesseract::Result;
use tesseract::client::Connection;


#[repr(C)]
pub struct NativeConnection {
  ptr: SyncPtr<Void>,
  send: unsafe extern "C" fn(connection: &NativeConnection, data: *const u8, len: usize) -> ManuallyDrop<CFuture<Nothing>>,
  receive: unsafe extern "C" fn(connection: &NativeConnection) -> ManuallyDrop<CFuture<CData>>,
  release: unsafe extern "C" fn(connection: &mut NativeConnection)
}

impl Drop for NativeConnection {
    fn drop(&mut self) {
        unsafe { (self.release)(self) }
    }
}

#[async_trait]
impl Connection for NativeConnection {
  async fn send(self: Arc<Self>, request: Vec<u8>) -> Result<()> {
    unsafe {
      let future = (self.as_ref().send)(self.as_ref(), request.as_ptr(), request.len());
      ManuallyDrop::into_inner(future).try_into_future().unwrap()
        .await
        .map(|_| {})
        .map_err(|e| e.into_error())
    }
  }

  async fn receive(self: Arc<Self>) -> Result<Vec<u8>> {
    unsafe {
      let future = ManuallyDrop::into_inner((self.as_ref().receive)(self.as_ref()));
      let future = future.try_into_future().map_err(|e| e.into_error())?;
      future.await.and_then(|d| d.try_into()).map_err(|e| e.into_error())
    }
  }
}