use super::processor::ServiceTransportProcessor;
use std::mem::ManuallyDrop;
use std::sync::Arc;
use tesseract_swift_utils::ptr::CAnyDropPtr;

use tesseract_one::service::{BoundTransport, Transport, TransportProcessor};

#[repr(transparent)]
pub struct ServiceBoundTransport(CAnyDropPtr);

impl ServiceBoundTransport {
    pub fn new(transport: Box<dyn BoundTransport + Send>) -> Self {
        Self(CAnyDropPtr::new(transport))
    }
}

impl BoundTransport for ServiceBoundTransport {}

#[repr(C)]
pub struct ServiceTransport {
    ptr: CAnyDropPtr,
    bind: unsafe extern "C" fn(
        this: ManuallyDrop<ServiceTransport>,
        processor: ManuallyDrop<ServiceTransportProcessor>,
    ) -> ManuallyDrop<ServiceBoundTransport>,
}

impl ServiceTransport {
    pub fn new<T: Transport + 'static>(transport: T) -> Self {
        Self {
            ptr: CAnyDropPtr::new(transport),
            bind: transport_bind::<T>
        }
    }
}

impl Transport for ServiceTransport {
    fn bind(
        self,
        processor: Arc<dyn TransportProcessor + Send + Sync>,
    ) -> Box<dyn BoundTransport + Send> {
        let proc = ManuallyDrop::new(ServiceTransportProcessor::new(processor));
        unsafe {
            let bound = (self.bind)(ManuallyDrop::new(self), proc);
            Box::new(ManuallyDrop::into_inner(bound))
        }
    }
}

unsafe extern "C" fn transport_bind<T: Transport + 'static>(
    this: ManuallyDrop<ServiceTransport>,
    processor: ManuallyDrop<ServiceTransportProcessor>,
) -> ManuallyDrop<ServiceBoundTransport> {
    let transport = ManuallyDrop::into_inner(this).ptr.take::<T>().unwrap();
    let bound = transport.bind(ManuallyDrop::into_inner(processor).take());
    ManuallyDrop::new(ServiceBoundTransport::new(bound))
}