use super::processor::ServiceTransportProcessor;
use std::mem::ManuallyDrop;
use std::sync::Arc;
use tesseract_swift_utils::ptr::CAnyDropPtr;

use tesseract::service::{BoundTransport, Transport, TransportProcessor};

#[repr(transparent)]
pub struct ServiceBoundTransport(CAnyDropPtr);

impl BoundTransport for ServiceBoundTransport {}

#[repr(C)]
pub struct ServiceTransport {
    ptr: CAnyDropPtr,
    bind: unsafe extern "C" fn(
        transport: ManuallyDrop<ServiceTransport>,
        processor: ManuallyDrop<ServiceTransportProcessor>,
    ) -> ManuallyDrop<ServiceBoundTransport>,
}

impl Transport for ServiceTransport {
    fn bind(
        self,
        processor: Arc<dyn TransportProcessor + Send + Sync>,
    ) -> Box<dyn BoundTransport> {
        let proc = ManuallyDrop::new(ServiceTransportProcessor::new(processor));
        unsafe {
            let bound = (self.bind)(ManuallyDrop::new(self), proc);
            Box::new(ManuallyDrop::into_inner(bound))
        }
    }
}
