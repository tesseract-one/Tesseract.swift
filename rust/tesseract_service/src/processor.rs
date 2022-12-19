use std::mem::ManuallyDrop;
use std::sync::Arc;
use tesseract_utils::data::CData;
use tesseract_utils::future::CFuture;
use tesseract_utils::ptr::SyncPtr;
use tesseract_utils::Void;

use tesseract::service::TransportProcessor as TTransportProcessor;

#[repr(C)]
pub struct TransportProcessor(SyncPtr<Void>);

impl Drop for TransportProcessor {
    fn drop(&mut self) {
        let _ = unsafe {
            self.0
                .take_typed::<Arc<dyn TTransportProcessor + Send + Sync>>()
        };
    }
}

impl TransportProcessor {
    pub fn new(processor: Arc<dyn TTransportProcessor + Send + Sync>) -> Self {
        Self(SyncPtr::new(processor).as_void())
    }

    pub unsafe fn as_ref(&self) -> &Arc<dyn TTransportProcessor + Send + Sync> {
        self.0.as_typed_ref().unwrap()
    }
}

#[no_mangle]
pub unsafe extern "C" fn transport_processor_process(
    processor: ManuallyDrop<TransportProcessor>,
    data: *const u8,
    len: usize,
) -> CFuture<ManuallyDrop<CData>> {
    let arc = Arc::clone(processor.as_ref());
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
