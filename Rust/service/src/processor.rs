use std::mem::ManuallyDrop;
use std::sync::Arc;
use tesseract_swift_utils::data::CData;
use tesseract_swift_utils::future::CFuture;
use tesseract_swift_utils::ptr::SyncPtr;
use tesseract_swift_utils::Void;

use tesseract::service::TransportProcessor;

#[repr(C)]
pub struct ServiceTransportProcessor(SyncPtr<Void>);

impl Drop for ServiceTransportProcessor {
    fn drop(&mut self) {
        let _ = unsafe {
            self.0
                .take_typed::<Arc<dyn TransportProcessor + Send + Sync>>()
        };
    }
}

impl ServiceTransportProcessor {
    pub fn new(processor: Arc<dyn TransportProcessor + Send + Sync>) -> Self {
        Self(SyncPtr::new(processor).as_void())
    }

    pub unsafe fn as_ref(&self) -> &Arc<dyn TransportProcessor + Send + Sync> {
        self.0.as_typed_ref().unwrap()
    }
}

#[no_mangle]
pub unsafe extern "C" fn tesseract_service_transport_processor_process(
    processor: ManuallyDrop<ServiceTransportProcessor>,
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
pub unsafe extern "C" fn tesseract_service_transport_processor_free(
    processor: &mut ManuallyDrop<ServiceTransportProcessor>,
) {
    let _ = ManuallyDrop::take(processor);
}
