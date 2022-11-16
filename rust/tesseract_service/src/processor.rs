use tesseract_utils::future::{CFuture, Executor, IntoCFuture};
use tesseract_utils::ptr::{SyncPtr, SyncPtrAsVoid, SyncPtrAsType};
use tesseract_utils::data::CData;
use tesseract_utils::Void;
use std::mem::ManuallyDrop;
use std::sync::Arc;

use tesseract::service::{TransportProcessor as TTransportProcessor};

#[repr(C)]
pub struct TransportProcessor {
  ptr: SyncPtr<Void>,
  executor: SyncPtr<Void>
}

impl Drop for TransportProcessor {
  fn drop(&mut self) {
    let ptr = std::mem::replace(&mut self.ptr, SyncPtr::new(std::ptr::null()));
    let executor = std::mem::replace(&mut self.executor, SyncPtr::new(std::ptr::null()));
    let typed_ptr: SyncPtr<Arc<dyn TTransportProcessor + Send + Sync>> = ptr.as_type();
    let typed_executor: SyncPtr<Arc<dyn Executor>> = executor.as_type();
    unsafe { 
      let _ = typed_ptr.into_box();
      let _ = typed_executor.into_box();
    };
  }
}

impl TransportProcessor {
  pub fn new(processor: Arc<dyn TTransportProcessor + Send + Sync>, executor: Arc<dyn Executor>) -> Self {
    Self {
      ptr: SyncPtr::from(Box::new(processor)).as_void(),
      executor: SyncPtr::from(Box::new(executor)).as_void(),
    }
  }
}

#[no_mangle]
pub unsafe extern "C" fn transport_processor_process(
  processor: &TransportProcessor,
  data: *const u8, len: usize
) -> CFuture<ManuallyDrop<CData>> {
  let arc = Arc::clone(processor.ptr.as_ptr_ref::<Arc<dyn TTransportProcessor + Send + Sync>>().as_ref());
  let slice = std::slice::from_raw_parts(data, len);
  let future = async move {
    let response = arc.process(slice).await;
    Ok(ManuallyDrop::new(CData::from(response)))
  };
  let executor = processor.executor.as_ptr_ref::<Arc<dyn Executor>>().as_ref().as_ref();
  future.into_cfuture(executor)
}

#[no_mangle]
pub unsafe extern "C" fn transport_processor_free(processor: &mut ManuallyDrop<TransportProcessor>) {
  let _ = ManuallyDrop::take(processor);
}