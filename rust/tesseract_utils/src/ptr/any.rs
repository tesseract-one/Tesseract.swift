use super::SyncPtr;
use crate::error::CError;
use crate::result::Result;
use crate::traits::IntoC;
use crate::Void;
use std::any::{type_name, Any};
use std::mem::ManuallyDrop;

#[repr(C)]
pub struct CAnyRustPtr(SyncPtr<Void>);

impl CAnyRustPtr {
    pub fn new<T: Any>(val: T) -> Self {
        let bx: Box<dyn Any> = Box::new(val);
        bx.into()
    }

    pub fn raw(ptr: SyncPtr<Void>) -> Self {
        Self(ptr)
    }

    pub fn as_ref<T: Any>(&self) -> Result<&T> {
        unsafe { self.0.as_typed_ref::<Box<dyn Any>>() }
            .ok_or_else(|| CError::NullPtr)
            .and_then(|any| {
                any.downcast_ref::<T>()
                    .ok_or_else(|| format!("Bad type: {}", type_name::<T>()).into())
            })
    }

    pub fn as_mut<T: Any>(&mut self) -> Result<&mut T> {
        unsafe { self.0.as_typed_mut::<Box<dyn Any>>() }
            .ok_or_else(|| CError::NullPtr)
            .and_then(|any| {
                any.downcast_mut::<T>()
                    .ok_or_else(|| format!("Bad type: {}", type_name::<T>()).into())
            })
    }

    pub fn take<T: Any>(mut self) -> Result<T> {
        if self.0.is_null() {
            return Err(CError::NullPtr);
        }
        let val = unsafe { self.0.take_typed::<Box<dyn Any>>() };
        std::mem::forget(self);
        val.downcast::<T>().into_c().map(|boxed| *boxed)
    }
}

impl Drop for CAnyRustPtr {
    fn drop(&mut self) {
        let _ = unsafe { self.0.take_typed::<Box<dyn Any>>() };
    }
}

impl From<CAnyRustPtr> for usize {
    fn from(ptr: CAnyRustPtr) -> Self {
        ptr.0.ptr() as usize
    }
}

impl From<usize> for CAnyRustPtr {
    fn from(ptr: usize) -> Self {
        Self::raw(SyncPtr::raw(ptr as *mut Void))
    }
}

impl From<Box<dyn Any>> for CAnyRustPtr {
    fn from(boxed: Box<dyn Any>) -> Self {
        Self::raw(SyncPtr::new(boxed).as_void())
    }
}

pub trait IntoAnyPtr: Any + Sized {
    fn into_any_ptr(self) -> CAnyRustPtr {
        CAnyRustPtr::new(self)
    }
}

impl<T: IntoAnyPtr> From<T> for CAnyRustPtr {
    fn from(val: T) -> Self {
        val.into_any_ptr()
    }
}

impl<T: IntoAnyPtr> IntoAnyPtr for Option<T> {
    fn into_any_ptr(self) -> CAnyRustPtr {
        match self {
            Some(val) => val.into_any_ptr(),
            None => CAnyRustPtr::raw(SyncPtr::null()),
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn tesseract_utils_any_rust_ptr_free(ptr: &mut ManuallyDrop<CAnyRustPtr>) {
    let _ = ManuallyDrop::take(ptr);
}
