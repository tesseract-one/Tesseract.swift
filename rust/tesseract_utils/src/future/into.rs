use crate::result::Result;
use crate::Void;
use crate::ptr::{SyncPtr, SyncPtrRefAsType, SyncPtrAsVoid, SyncPtrAsType};
use std::future::Future;
use std::task::{Wake, Context, Poll};
use std::pin::Pin;
use std::mem::ManuallyDrop;
use std::sync::{Arc, Mutex};

use super::{CFuture, CFutureOnCompleteCallback, CFutureValue};

enum State<V: 'static> {
  Value(Result<V>),
  Callback(SyncPtr<Void>, CFutureOnCompleteCallback<V>),
  Resolved
}

type StateArc<V> = Arc<Mutex<Option<State<V>>>>;

struct FutureWrapper<V: Send + 'static, F: Future<Output = Result<V>> + Send + 'static> {
  rs: Mutex<Pin<Box<F>>>,
  st: StateArc<V>
}

impl<V: Send + 'static, F: Future<Output = Result<V>> + Send + 'static> FutureWrapper<V, F>  {
  pub fn new(rs: Pin<Box<F>>, st: StateArc<V>) -> Self {
      Self { rs: Mutex::new(rs), st }
  }

  fn poll_future(self: Arc<Self>) -> std::result::Result<bool, String> {
    let mut fguard = self.rs.lock().map_err(|e| format!("{}", e))?;
    let waker = Arc::clone(&self).into();
    let mut context = Context::from_waker(&waker);
    
    let poll = fguard.as_mut().poll(&mut context);
    
    std::mem::drop(fguard);

    match poll {
      Poll::Pending => Ok(false),
      Poll::Ready(result) => self.set_response(result).map(|_| true)
    }
  }

  fn set_response(&self, response: Result<V>) -> std::result::Result<(), String> {
    let mut state = self.st.lock().map_err(|e| format!("{}", e))?;
    
    match state.take() {
      None => {
        *state = Some(State::Value(response));
        Ok(())
      },
      Some(current_state) => {
        match current_state {
            State::Value(_) | State::Resolved => {
              *state = Some(current_state);
              Err("It's a bug. Why is the resolved future gets resolved again?".into())
            },
            State::Callback(ctx,cb) => {
              *state = Some(State::Resolved);
              std::mem::drop(state); // free mutex
              unsafe {
                match response {
                  Err(err) => cb(ctx, std::ptr::null_mut(), &mut ManuallyDrop::new(err)),
                  Ok(val) => cb(ctx, &mut ManuallyDrop::new(val), std::ptr::null_mut()),
                };
              };
              Ok(())
            }
        }
      }
    }
  }

  fn wrap(future: F) -> CFuture<V> {
    let boxed = Box::pin(future);
    let state = Arc::new(Mutex::new(None));
    let wrapped = Arc::new(Self::new(boxed, Arc::clone(&state)));
    
    let _ = wrapped.poll_future().unwrap();

    CFuture::new(
      SyncPtr::from(Box::new(state)).as_void(),
      Self::_set_on_complete,
      Self::_release
    )
  }

  unsafe extern "C" fn _set_on_complete(
    future: &CFuture<V>,
    context: SyncPtr<Void>,
    cb: CFutureOnCompleteCallback<V>,
  ) -> ManuallyDrop<CFutureValue<V>> {
    let arc = Arc::clone(future.get_ptr().as_type::<StateArc<V>>().as_ref());
    let mut state = arc.lock().unwrap();
    
    match state.take() {
      None => {
        *state = Some(State::Callback(context, cb));
        ManuallyDrop::new(CFutureValue::None)
      },
      Some(current_state) => {
        match current_state {
          State::Callback(ctx, cb) => {
            *state = Some(State::Callback(ctx, cb));
            panic!("Callback already set for this future");
          },
          State::Resolved => {
            *state = Some(State::Resolved);
            panic!("Future is already resolved");
          },
          State::Value(response) => {
            *state = Some(State::Resolved);
            ManuallyDrop::new(response.into())
          }
        }
      }
    }
  }
  
  unsafe extern "C" fn _release(fut: &mut CFuture<V>) {
    println!("WRAPPER RELEASE CALLED!");
    let _ = fut.take_ptr().unwrap().as_type::<StateArc<V>>().into_box();
  }
}

impl<V: Send, F: Future<Output = Result<V>> + Send> Wake for FutureWrapper<V, F> {
  fn wake(self: Arc<Self>) {
    let _ = self.poll_future().unwrap();
  }
}

impl<V: Send + 'static, F: Future<Output = Result<V>> + Send + 'static> From<F> for CFuture<V> {
  fn from(future: F) -> Self {
    FutureWrapper::wrap(future)
  }
}
