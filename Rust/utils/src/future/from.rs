use super::CFuture;
use crate::error::CError;
use crate::result::Result;
use std::future::Future;
use std::pin::Pin;
use std::sync::{Arc, Mutex};
use std::task::{Context, Poll};

enum State<V: 'static> {
    Value(Result<V>),
    Future(CFuture<V>),
    Pending,
    Resolved,
}

pub(crate) struct CFutureWrapper<V: 'static> {
    state: Arc<Mutex<Option<State<V>>>>,
}

impl<V> TryFrom<CFuture<V>> for CFutureWrapper<V> {
    type Error = CError;

    fn try_from(future: CFuture<V>) -> Result<Self> {
        if future.ptr().is_null() {
            return Err(CError::null::<CFuture<V>>());
        } else {
            Ok(Self {
                state: Arc::new(Mutex::new(Some(State::Future(future)))),
            })
        }
    }
}

impl<V> Future for CFutureWrapper<V> {
    type Output = Result<V>;

    fn poll(self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
        let mut state = self.state.lock().unwrap();

        match state.take() {
            None => Poll::Ready(Err(CError::null::<State<V>>())),
            Some(current_state) => {
                match current_state {
                    State::Value(value) => {
                        *state = Some(State::Resolved);
                        Poll::Ready(value)
                    }
                    State::Pending => {
                        *state = Some(State::Pending);
                        Poll::Pending
                    }
                    State::Resolved => {
                        *state = Some(State::Resolved);
                        panic!("CFutureWrapper polled after Poll::Ready!");
                    }
                    State::Future(future) => {
                        let waker = cx.waker().clone();
                        let state2 = Arc::clone(&self.state);
                        let result = future.on_complete(move |res| {
                            let mut state = state2.lock().unwrap();
                            *state = Some(State::Value(res));
                            std::mem::drop(state); // free mutex
                            waker.wake();
                        });

                        match result {
                            None => {
                                *state = Some(State::Pending);
                                Poll::Pending
                            }
                            Some(result) => {
                                *state = Some(State::Resolved);
                                Poll::Ready(result)
                            }
                        }
                    }
                }
            }
        }
    }
}
