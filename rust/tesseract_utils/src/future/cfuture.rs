use crate::error::CError;
use crate::ptr::*;
use crate::Void;
use crate::result::CResult;
use super::NativeFuture;
use std::future::Future;
use std::mem::ManuallyDrop;

pub type CFutureOnCompleteCallback<V> = unsafe extern "C" fn(
    context: SyncPtr<Void>,
    value: *mut ManuallyDrop<V>,
    error: *mut ManuallyDrop<CError>,
);

#[repr(C)]
pub struct CFuture<V: 'static> {
    ptr: SyncPtr<Void>,
    set_on_complete: unsafe extern "C" fn(
        future: &CFuture<V>,
        context: SyncPtr<Void>,
        cb: CFutureOnCompleteCallback<V>,
    ),
    release: unsafe extern "C" fn(fut: &mut CFuture<V>)
}

struct CFutureContext<V: 'static> {
    future: CFuture<V>,
    closure: Option<Box<dyn FnOnce(Result<V, CError>)>>,
}

impl<V: 'static> CFutureContext<V> {
    fn new<F: 'static + FnOnce(Result<V, CError>)>(future: CFuture<V>, closure: F) -> Self {
        Self {
            future: future,
            closure: Some(Box::new(closure)),
        }
    }

    fn resolve(&mut self, result: Result<V, CError>) {
        (self.closure.take().unwrap())(result);
    }

    unsafe fn from_raw(ptr: SyncPtr<Void>) -> Self {
        *ptr.as_type().into_box()
    }

    fn into_raw(self) -> SyncPtr<Void> {
        SyncPtr::from(Box::new(self)).as_void()
    }
}

impl<V> Drop for CFutureContext<V> {
    fn drop(&mut self) {
        println!("CFUTURE CONTEXT DROP CALLED!");
        let release = self.future.release;
        unsafe { release(&mut self.future) };
    }
}

impl<V: 'static> CFuture<V> {
    pub fn new(
        ptr: SyncPtr<Void>,
        set_on_complete: unsafe extern "C" fn(
            future: &CFuture<V>,
            context: SyncPtr<Void>,
            cb: CFutureOnCompleteCallback<V>,
        ),
        release: unsafe extern "C" fn(fut: &mut CFuture<V>)
    ) -> Self {
        Self { ptr, set_on_complete, release }
    }

    pub fn on_complete<F: 'static + FnOnce(Result<V, CError>)>(self, cb: F) {
        let set_on_complete = self.set_on_complete;
        let reference = &self as *const Self; // this is ok. It passed as ref into set_on_complete call only
        let context = CFutureContext::new(self, cb);
        unsafe {
            set_on_complete(
                reference.as_ref().unwrap(),
                context.into_raw(),
                Self::on_complete_handler,
            )
        };
    }

    pub fn get_ptr(&self) -> &SyncPtr<Void> {
        &self.ptr
    }

    pub fn try_into_future(self) -> CResult<impl Future<Output = CResult<V>>> {
        NativeFuture::try_from(self)
    }

    pub fn take_ptr(&mut self) -> Option<SyncPtr<Void>> {
        let ptr = std::mem::replace(&mut self.ptr, std::ptr::null::<Void>().into());
        if ptr.is_null() { None } else { Some(ptr) }
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
