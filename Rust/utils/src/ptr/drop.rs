use super::SyncPtr;
use crate::error::CError;
use crate::result::Result;
use crate::Void;
use std::any::Any;

#[repr(C)]
pub struct CAnyDropPtr {
    ptr: SyncPtr<Void>,
    drop: extern "C" fn(&mut CAnyDropPtr),
}

impl Drop for CAnyDropPtr {
    fn drop(&mut self) {
        (self.drop)(self);
    }
}

impl CAnyDropPtr {
    pub fn new<T: Any>(val: T) -> Self {
        let bx: Box<dyn Any> = Box::new(val);
        bx.into()
    }

    pub fn raw(ptr: SyncPtr<Void>, drop: extern "C" fn(&mut CAnyDropPtr)) -> Self {
        Self { ptr, drop }
    }

    pub fn as_ref<T: Any>(&self) -> Result<&T> {
        unsafe { self.ptr.as_typed_ref::<Box<dyn Any>>() }
            .ok_or_else(|| CError::null::<Self>())
            .and_then(|any| {
                any.downcast_ref::<T>().ok_or_else(|| CError::cast::<Self, T>())
            })
    }

    pub fn as_mut<T: Any>(&mut self) -> Result<&mut T> {
        unsafe { self.ptr.as_typed_mut::<Box<dyn Any>>() }
            .ok_or_else(|| CError::null::<Self>())
            .and_then(|any| {
                any.downcast_mut::<T>().ok_or_else(|| CError::cast::<Self, T>())
            })
    }

    pub fn ptr(&self) -> &SyncPtr<Void> {
        &self.ptr
    }

    pub fn is_null(&self) -> bool {
        self.ptr.is_null()
    }

    extern "C" fn drop_value(ptr: &mut CAnyDropPtr) {
        let _ = unsafe { ptr.ptr.take_typed::<Box<dyn Any>>() };
    }
}

impl From<Box<dyn Any>> for CAnyDropPtr {
    fn from(boxed: Box<dyn Any>) -> Self {
        Self::raw(SyncPtr::new(boxed).as_void(), Self::drop_value)
    }
}
