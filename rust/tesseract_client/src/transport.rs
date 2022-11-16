use tesseract_utils::future::CFuture;
use tesseract_utils::ptr::SyncPtr;
use tesseract_utils::Void;
use tesseract_utils::string::{CString, CStringRef};
use std::mem::ManuallyDrop;
use crate::connection::NativeConnection;
use crate::status::Status;
use std::sync::Arc;

use async_trait::async_trait;

use tesseract::client::Transport;
use tesseract::client::Connection;
use tesseract::Protocol;
use tesseract::client::transport::{Status as RStatus};

#[repr(C)]
pub struct NativeTransport {
  ptr: SyncPtr<Void>,
  id: unsafe extern "C" fn(transport: &NativeTransport) -> ManuallyDrop<CString>,
  status: unsafe extern "C" fn(transport: &NativeTransport, protocol: CStringRef) -> ManuallyDrop<CFuture<Status>>,
  connect: unsafe extern "C" fn(transport: &NativeTransport, protocol: CStringRef) -> ManuallyDrop<NativeConnection>,
  release: unsafe extern "C" fn(transport: &mut NativeTransport)
}

impl Drop for NativeTransport {
  fn drop(&mut self) {
      unsafe { (self.release)(self) }
  }
}

#[async_trait]
impl Transport for NativeTransport {
    fn id(&self) -> String {
        unsafe {
          ManuallyDrop::into_inner((self.id)(self)).try_into().unwrap()
        }
    }

    async fn status(self: Arc<Self>, protocol: Box<dyn Protocol>) -> RStatus {
      unsafe {
        let protoid: CString = protocol.id().into();
        let future = ManuallyDrop::into_inner((self.status)(self.as_ref(), protoid.as_ptr()));
        let future = future.try_into_future().unwrap();
        match future.await {
          Err(error) => RStatus::Error(Box::new(error)),
          Ok(status) => status.into()
        }
      }
    }

    fn connect(&self, protocol: Box<dyn Protocol>) -> Box<dyn Connection + Sync + Send>  {
      unsafe {
        let protoid: CString = protocol.id().into();
        let connection = (self.connect)(self, protoid.as_ptr());
        Box::new(ManuallyDrop::into_inner(connection))
      }
    }
}
