use super::{CFuture, CFutureOnCompleteCallback};
use crate::ptr::*;
use crate::Void;
use crate::result::CResult;
use std::future::Future;
use std::pin::Pin;
use std::mem::ManuallyDrop;
use std::sync::{Arc, Mutex};

struct Context<V> {
    value: Option<CResult<V>>,
    complete: Option<(SyncPtr<Void>, CFutureOnCompleteCallback<V>)>,
}

type ContextArc<V> = Arc<Mutex<Context<V>>>;

unsafe extern "C" fn handler_set_on_complete<V: 'static>(
    future: &CFuture<V>,
    context: SyncPtr<Void>,
    cb: CFutureOnCompleteCallback<V>,
) {
    let arc_ptr: *mut ContextArc<V> = future.get_ptr().as_type().into();
    let arc = Arc::clone(arc_ptr.as_ref().unwrap());
    let mut this = arc.lock().unwrap();
    match this.value.take() {
        None => this.complete = Some((context, cb)),
        Some(response) => {
            this.complete = None;
            std::mem::drop(this); // free mutex
            match response {
                Err(err) => cb(context, std::ptr::null_mut(), &mut ManuallyDrop::new(err)),
                Ok(val) => cb(context, &mut ManuallyDrop::new(val), std::ptr::null_mut()),
            };
        }
    };
}

unsafe extern "C" fn handler_release<V: 'static>(fut: &mut CFuture<V>) {
    println!("WRAPPER RELEASE CALLED!");
    let _ = fut.take_ptr().unwrap().as_type::<ContextArc<V>>().into_box();
}

pub fn wrap_future<V, F>(future: F) -> (CFuture<V>, impl Future<Output = ()>)
where
    F: Future<Output = CResult<V>>,
{
    let context = Arc::new(Mutex::new(Context::<V> {
        value: None,
        complete: None,
    }));

    let cfut = CFuture::new(
        SyncPtr::from(Box::new(Arc::clone(&context))).as_void(),
        handler_set_on_complete,
        handler_release
    );

    let runner = async move {
        let response = future.await;
        let mut this = context.lock().unwrap();
        match this.complete.take() {
            None => {
                this.value = Some(response);
            }
            Some((ctx, cb)) => {
                this.value = None;
                std::mem::drop(this); // free mutex
                unsafe {
                    match response {
                        Err(err) => cb(ctx, std::ptr::null_mut(), &mut ManuallyDrop::new(err)),
                        Ok(val) => cb(ctx, &mut ManuallyDrop::new(val), std::ptr::null_mut()),
                    };
                }
            }
        }
    };

    (cfut, runner)
}

pub trait Executor {
    fn spawn(&self, future: Pin<Box<dyn std::future::Future<Output = ()> + Send>>);
}

pub trait IntoCFuture<V> {
    fn into_cfuture(self, executor: &dyn Executor) -> CFuture<V>;
}

impl<T, V> IntoCFuture<V> for T
where
    V: Send,
    T: 'static + Future<Output = CResult<V>> + Send,
{
    fn into_cfuture(self, executor: &dyn Executor) -> CFuture<V> {
        let (cfut, runner) = wrap_future(self);
        executor.spawn(Box::pin(runner));
        cfut
    }
}
