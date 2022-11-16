use tesseract_utils::{ptr::SyncPtr, future::Executor};
use tesseract_utils::Void;
use std::mem::ManuallyDrop;
use std::sync::Arc;
use crate::processor::TransportProcessor;

use tesseract::service::{ BoundTransport as TBoundTransport, Transport as TTransport, TransportProcessor as TTransportProcessor };

#[repr(C)]
pub struct BoundTransport {
  ptr: SyncPtr<Void>,
  release: unsafe extern "C" fn(transport: &mut BoundTransport)
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
    transport: Transport,
    processor: ManuallyDrop<TransportProcessor>
  ) -> ManuallyDrop<BoundTransport>,
  release: unsafe extern "C" fn(transport: &mut Transport)
}

impl Drop for Transport {
    fn drop(&mut self) {
        unsafe { (self.release)(self) }
    }
}

impl Transport {
  pub fn executor(self, executor: &Arc<dyn Executor>) -> ExecutorTransport {
    ExecutorTransport { transport: self, executor: Arc::clone(executor) }
  }
}

pub struct ExecutorTransport {
  transport: Transport,
  executor: Arc<dyn Executor>
}

impl TTransport for ExecutorTransport {
    fn bind(self, processor: Arc<dyn TTransportProcessor + Send + Sync>) -> Box<dyn TBoundTransport> {
        let proc =  ManuallyDrop::new(TransportProcessor::new(processor, self.executor));
        unsafe {
          let bound = (self.transport.bind)(self.transport, proc);
          Box::new(ManuallyDrop::into_inner(bound))
        }
    }
}

