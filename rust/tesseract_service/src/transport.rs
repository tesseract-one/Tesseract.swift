use crate::processor::TransportProcessor;
use std::mem::ManuallyDrop;
use std::sync::Arc;
use tesseract_utils::ptr::SyncPtr;
use tesseract_utils::Void;

use tesseract::service::{
    BoundTransport as TBoundTransport, Transport as TTransport,
    TransportProcessor as TTransportProcessor,
};

#[repr(C)]
pub struct BoundTransport {
    ptr: SyncPtr<Void>,
    release: unsafe extern "C" fn(transport: &mut BoundTransport),
}

impl Drop for BoundTransport {
    fn drop(&mut self) {
        unsafe { (self.release)(self) }
    }
}

impl TBoundTransport for BoundTransport {}

#[repr(C)]
pub struct Transport {
    ptr: SyncPtr<Void>,
    bind: unsafe extern "C" fn(
        transport: ManuallyDrop<Transport>,
        processor: ManuallyDrop<TransportProcessor>,
    ) -> ManuallyDrop<BoundTransport>,
    release: unsafe extern "C" fn(transport: &mut Transport),
}

impl Drop for Transport {
    fn drop(&mut self) {
        unsafe { (self.release)(self) }
    }
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
