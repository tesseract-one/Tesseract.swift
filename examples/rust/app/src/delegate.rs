use std::{collections::HashMap, sync::Arc};

use async_trait::async_trait;

use tesseract::client::{transport::Status, Delegate};
use tesseract_utils::{ptr::SyncPtr, string::CString, string::CStringRef, Void};

#[repr(C)]
pub struct AlertProvider {
    ptr: SyncPtr<Void>,
    show_alert: unsafe extern "C" fn(&AlertProvider, CStringRef),
    release: unsafe extern "C" fn(&mut AlertProvider),
}

impl AlertProvider {
    fn show_alert(&self, alert: &str) {
        let str: CString = alert.into();
        unsafe { (self.show_alert)(self, str.as_ptr()) };
    }
}

impl Drop for AlertProvider {
    fn drop(&mut self) {
        unsafe {
            (self.release)(self);
        }
    }
}

pub(crate) struct TransportDelegate {
    alerts: AlertProvider,
}

impl TransportDelegate {
    pub(crate) fn arc(alerts: AlertProvider) -> Arc<Self> {
        Arc::new(Self { alerts })
    }
}

#[async_trait]
impl Delegate for TransportDelegate {
    async fn select_transport(&self, transports: &HashMap<String, Status>) -> Option<String> {
        assert_eq!(
            1,
            transports.len(),
            "How the heck do we have more than one transport here?"
        );
        let tid = transports.keys().next().map(String::clone).unwrap();

        let status = &transports[&tid];

        match status {
            Status::Ready => Some(tid),
            Status::Unavailable(reason) => {
                self.alerts.show_alert(&format!(
                    "Transport '{}' is not available because of the following reason: {}",
                    tid, reason
                ));
                None
            }
            Status::Error(e) => {
                self.alerts.show_alert(&format!(
                    "Transport '{}' is not available because the transport produced an error: {}",
                    tid,
                    e.to_string()
                ));
                None
            }
        }
    }
}
