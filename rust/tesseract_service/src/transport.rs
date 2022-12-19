use crate::processor::TransportProcessor;
use std::mem::ManuallyDrop;
use std::sync::Arc;
use tesseract_utils::ptr::CAnyDropPtr;

use tesseract::service::{
    BoundTransport as TBoundTransport, Transport as TTransport,
    TransportProcessor as TTransportProcessor,
};

#[repr(transparent)]
pub struct BoundTransport(CAnyDropPtr);

impl TBoundTransport for BoundTransport {}

#[repr(C)]
pub struct Transport {
    ptr: CAnyDropPtr,
    bind: unsafe extern "C" fn(
        transport: ManuallyDrop<Transport>,
        processor: ManuallyDrop<TransportProcessor>,
    ) -> ManuallyDrop<BoundTransport>,
}

impl TTransport for Transport {
    fn bind(
        self,
        processor: Arc<dyn TTransportProcessor + Send + Sync>,
    ) -> Box<dyn TBoundTransport> {
        let proc = ManuallyDrop::new(TransportProcessor::new(processor));
        unsafe {
            let bound = (self.bind)(ManuallyDrop::new(self), proc);
            Box::new(ManuallyDrop::into_inner(bound))
        }
    }
}
