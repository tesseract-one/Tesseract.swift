use crate::transport::Transport;
use tesseract::service::Tesseract;
use tesseract_utils::future::Executor;
use std::sync::Arc;

pub trait UseNativeTransport {
  fn native_transport(self, transport: Transport, executor: &Arc<dyn Executor>) -> Self;
}

impl UseNativeTransport for Tesseract {
  fn native_transport(self, transport: Transport, executor: &Arc<dyn Executor>) -> Self {
    self.transport(transport.executor(executor))
  }
}