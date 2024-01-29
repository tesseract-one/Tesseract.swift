use std::mem::ManuallyDrop;
use std::sync::Arc;
use tesseract_swift_utils::data::CDataRef;
use tesseract_swift_utils::future_impls::CFutureData;
use tesseract_swift_utils::ptr::SyncPtr;
use tesseract_swift_utils::Void;

use tesseract_one::service::TransportProcessor;

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

    unsafe fn as_ref(&self) -> &Arc<dyn TransportProcessor + Send + Sync> {
        self.0.as_typed_ref().unwrap()
    }

    pub(super) unsafe fn take(mut self) -> Arc<dyn TransportProcessor + Send + Sync> {
        self.0.take_typed()
    }
}

#[no_mangle]
pub unsafe extern "C" fn tesseract_service_transport_processor_process(
    processor: ManuallyDrop<ServiceTransportProcessor>,
    data: CDataRef
) -> ManuallyDrop<CFutureData> {
    let arc = Arc::clone(processor.as_ref());
    let vec = data.cloned();
    let future = async move {
        Ok(arc.process(vec?.as_ref()).await.into())
    };
    ManuallyDrop::new(future.into())
}

#[no_mangle]
pub unsafe extern "C" fn tesseract_service_transport_processor_free(
    processor: &mut ManuallyDrop<ServiceTransportProcessor>,
) {
    let _ = ManuallyDrop::take(processor);
}
