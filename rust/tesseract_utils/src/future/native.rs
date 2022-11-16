use super::CFuture;
use crate::result::CResult;
use crate::error::CError;
use std::future::Future;
use std::pin::Pin;
use std::sync::{Arc, Mutex};
use std::task::{Context, Poll};

pub struct NativeFuture<V: 'static> {
    context: Arc<Mutex<NativeFutureContext<V>>>,
}

struct NativeFutureContext<V: 'static> {
    future: Option<CFuture<V>>,
    value: Option<CResult<V>>,
}

impl<V> TryFrom<CFuture<V>> for NativeFuture<V> {
    type Error = CError;

    fn try_from(future: CFuture<V>) -> Result<Self, Self::Error> {
        if future.get_ptr().is_null() {
            return Err(CError::NullPtr);
        } else {
            Ok(Self {
                context: Arc::new(Mutex::new(NativeFutureContext {
                    future: Some(future),
                    value: None,
                })),
            })
        }
    }
}

impl<V> Future for NativeFuture<V> {
    type Output = CResult<V>;

    fn poll(self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
        let mut context = self.context.lock().unwrap();

        match context.value.take() {
            None => {
                match context.future.take() {
                    None => Poll::Pending,
                    Some(future) => {
                        std::mem::drop(context); // free mutex
                        let waker = cx.waker().clone();
                        let context = Arc::clone(&self.context);
                        future.on_complete(move |res| {
                            let mut context = context.lock().unwrap();
                            context.value = Some(res);
                            waker.wake();
                        });
                        Poll::Pending
                    }
                }
            }
            Some(val) => Poll::Ready(val),
        }
    }
}
