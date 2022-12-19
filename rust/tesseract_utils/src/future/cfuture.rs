use super::from::CFutureWrapper;
use super::value::CFutureValue;
use crate::error::CError;
use crate::ptr::*;
use crate::result::Result;
use crate::Void;
use std::future::Future;
use std::mem::ManuallyDrop;

pub type CFutureOnCompleteCallback<V> = unsafe extern "C" fn(
    context: SyncPtr<Void>,
    value: *mut ManuallyDrop<V>,
    error: *mut ManuallyDrop<CError>,
);

#[repr(C)]
pub struct CFuture<V: 'static> {
    ptr: CAnyDropPtr,
    set_on_complete: unsafe extern "C" fn(
        future: &CFuture<V>,
        context: SyncPtr<Void>,
        cb: CFutureOnCompleteCallback<V>,
    ) -> ManuallyDrop<CFutureValue<V>>,
}

struct CFutureContext<V: 'static> {
    _future: CFuture<V>,
    closure: Option<Box<dyn FnOnce(Result<V>)>>,
}

impl<V: 'static> CFutureContext<V> {
    fn new<F: 'static + FnOnce(Result<V>)>(future: CFuture<V>, closure: F) -> Self {
        Self {
            _future: future,
            closure: Some(Box::new(closure)),
        }
    }

    fn resolve(&mut self, result: Result<V>) {
        (self.closure.take().unwrap())(result);
    }

    unsafe fn from_raw(mut ptr: SyncPtr<Void>) -> Self {
        ptr.take_typed()
    }

    fn into_raw(self) -> SyncPtr<Void> {
        SyncPtr::new(self).as_void()
    }
}

impl<V: 'static> CFuture<V> {
    pub fn new(
        ptr: CAnyDropPtr,
        set_on_complete: unsafe extern "C" fn(
            future: &CFuture<V>,
            context: SyncPtr<Void>,
            cb: CFutureOnCompleteCallback<V>,
        ) -> ManuallyDrop<CFutureValue<V>>,
    ) -> Self {
        Self {
            ptr,
            set_on_complete,
        }
    }

    pub fn on_complete<F: 'static + FnOnce(Result<V>)>(self, cb: F) -> Option<Result<V>> {
        let set_on_complete = self.set_on_complete;
        let reference = &self as *const Self; // this is ok. It passed as ref into set_on_complete call only
        let context = CFutureContext::new(self, cb).into_raw().ptr();
        let value = unsafe {
            set_on_complete(
                reference.as_ref().unwrap(),
                SyncPtr::raw(context),
                Self::on_complete_handler,
            )
        };
        let value: Option<Result<V>> = ManuallyDrop::into_inner(value).into();
        if value.is_some() {
            // Context is non-needed. Callback never will be called
            let _ = unsafe { CFutureContext::<V>::from_raw(SyncPtr::raw(context)) };
        }
        value
    }

    pub fn ptr(&self) -> &CAnyDropPtr {
        &self.ptr
    }

    pub fn try_into_future(self) -> Result<impl Future<Output = Result<V>>> {
        CFutureWrapper::try_from(self)
    }

    unsafe extern "C" fn on_complete_handler(
        context: SyncPtr<Void>,
        value: *mut ManuallyDrop<V>,
        error: *mut ManuallyDrop<CError>,
    ) {
        let mut context = CFutureContext::from_raw(context);
        if error.is_null() {
            context.resolve(Ok(ManuallyDrop::take(value.as_mut().unwrap())));
        } else {
            context.resolve(Err(ManuallyDrop::take(error.as_mut().unwrap())));
        }
    }
}
