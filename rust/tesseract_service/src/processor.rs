use std::mem::ManuallyDrop;
use std::sync::Arc;
use tesseract_utils::data::CData;
use tesseract_utils::future::CFuture;
use tesseract_utils::ptr::{SyncPtr, SyncPtrAsType, SyncPtrAsVoid};
use tesseract_utils::Void;

use tesseract::service::TransportProcessor as TTransportProcessor;

#[repr(C)]
pub struct TransportProcessor(SyncPtr<Void>);

impl Drop for TransportProcessor {
    fn drop(&mut self) {
        let ptr = std::mem::replace(&mut self.0, SyncPtr::new(std::ptr::null()));
        let typed_ptr: SyncPtr<Arc<dyn TTransportProcessor + Send + Sync>> = ptr.as_type();
        unsafe {
            let _ = typed_ptr.into_box();
        };
    }
}

impl TransportProcessor {
    pub fn new(processor: Arc<dyn TTransportProcessor + Send + Sync>) -> Self {
        Self(SyncPtr::from(Box::new(processor)).as_void())
    }
}

#[no_mangle]
pub unsafe extern "C" fn transport_processor_process(
    processor: &TransportProcessor,
    data: *const u8,
    len: usize,
) -> CFuture<ManuallyDrop<CData>> {
    let arc = Arc::clone(
        processor
            .0
            .as_ptr_ref::<Arc<dyn TTransportProcessor + Send + Sync>>()
            .as_ref(),
    );
    let slice = std::slice::from_raw_parts(data, len);
    let future = async move {
        let response = arc.process(slice).await;
        Ok(ManuallyDrop::new(CData::from(response)))
    };
    future.into()
}

#[no_mangle]
pub unsafe extern "C" fn transport_processor_free(
    processor: &mut ManuallyDrop<TransportProcessor>,
) {
    let _ = ManuallyDrop::take(processor);
}
