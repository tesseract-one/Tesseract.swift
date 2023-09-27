use tesseract::service::{Tesseract, Service, Transport};
use tesseract_swift_utils::ptr::SyncPtr;
use tesseract_swift_utils::Void;
use tesseract_swift_transports::service::ServiceTransport;

use std::mem::ManuallyDrop;

#[repr(C)]
pub struct ServiceTesseract(SyncPtr<Void>);

impl Drop for ServiceTesseract {
    fn drop(&mut self) {
        let _ = unsafe { self.0.take_typed::<Tesseract>() };
    }
}

impl ServiceTesseract {
    pub fn new(tesseract: Tesseract) -> Self {
        Self(SyncPtr::new(tesseract).as_void())
    }

    pub fn service<S: Service>(&mut self, service: S) -> Self {
        let tesseract = unsafe { self.0.take_typed::<Tesseract>() };
        Self::new(tesseract.service(service))
    }

    pub fn transport<T: Transport>(&mut self, transport: T) -> Self {
        let tesseract = unsafe { self.0.take_typed::<Tesseract>() };
        Self::new(tesseract.transport(transport))
    }
}

#[no_mangle]
pub extern "C" fn tesseract_service_new() -> ManuallyDrop<ServiceTesseract> {
    ManuallyDrop::new(ServiceTesseract::new(Tesseract::new()))
}

#[no_mangle]
pub extern "C" fn tesseract_service_add_transport(tesseract: &mut ServiceTesseract, transport: ServiceTransport) -> ManuallyDrop<ServiceTesseract> {
    ManuallyDrop::new(tesseract.transport(transport))
}

#[no_mangle]
pub extern "C" fn tesseract_service_free(tesseract: &mut ManuallyDrop<ServiceTesseract>) {
    let _ = unsafe { ManuallyDrop::take(tesseract) };
}