use crate::Void;
use crate::error::CError;
use crate::result::{CResult, IntoCResult};
use std::mem::ManuallyDrop;
use std::any::Any;

pub trait AnyPtrRepresentable: Sized + 'static {
    fn any_ptr(self) -> CAnyPtr {
        let b: Box<Box<dyn Any>> = Box::new(Box::new(self));
        b.into()
    }
}

pub trait AnyPtr {
    unsafe fn try_as_ref<T: AnyPtrRepresentable>(&self) -> CResult<&mut T>;
}

pub trait AnyOwnedPtr {
    unsafe fn try_into<T: AnyPtrRepresentable>(self) -> CResult<T>;
}


pub type CAnyPtrRef = *const Void;

#[repr(transparent)]
pub struct CAnyPtr(*const Void);

impl From<CAnyPtr> for usize {
    fn from(ptr: CAnyPtr) -> Self {
        ptr.0 as usize
    }
}

impl From<usize> for CAnyPtr {
    fn from(ptr: usize) -> Self {
        Self(ptr as *mut Void)
    }
}

impl From<Box<Box<dyn Any>>> for CAnyPtr {
    fn from(boxed: Box<Box<dyn Any>>) -> Self {
        Self(Box::into_raw(boxed) as *const Void)
    }
}

unsafe impl Send for CAnyPtr {}
unsafe impl Sync for CAnyPtr {}

impl AnyPtr for CAnyPtrRef {
    unsafe fn try_as_ref<T: AnyPtrRepresentable>(&self) -> CResult<&mut T> {
        if self.is_null() {
            return Err(CError::NullPtr);
        }
        (*self as *mut Box<dyn Any>)
            .as_mut()
            .and_then(|any| any.downcast_mut::<T>())
            .ok_or_else(|| format!("Bad pointer: 0x{:x}", *self as usize).into())
    }
}

impl CAnyPtr {
    pub fn new<T: AnyPtrRepresentable>(val: T) -> Self {
        val.any_ptr()
    }
}

impl AnyPtr for CAnyPtr {
    unsafe fn try_as_ref<T: AnyPtrRepresentable>(&self) -> CResult<&mut T> {
        self.0.try_as_ref()
    }
}

impl AnyOwnedPtr for CAnyPtr {
    unsafe fn try_into<T: AnyPtrRepresentable>(mut self) -> CResult<T> {
        if self.0.is_null() {
            return Err(CError::NullPtr);
        }
        let boxed = *Box::from_raw(self.0 as *mut Box<dyn Any>);
        self.0 = std::ptr::null_mut();
        boxed.downcast::<T>().into_cresult().map(|boxed| *boxed)
    }
}

impl<T: AnyPtrRepresentable> From<T> for CAnyPtr {
    fn from(rep: T) -> Self {
        rep.any_ptr()
    }
}

impl Drop for CAnyPtr {
    fn drop(&mut self) {
        if self.0.is_null() {
            return;
        }
        let _ = unsafe { Box::from_raw(self.0 as *mut Box<dyn Any>) };
        self.0 = std::ptr::null_mut();
    }
}

impl<T: AnyPtrRepresentable> AnyPtrRepresentable for Option<T> {
    fn any_ptr(self) -> CAnyPtr {
        match self {
            Some(val) => val.any_ptr(),
            None => CAnyPtr(std::ptr::null_mut()),
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn tesseract_utils_anyptr_free(ptr: ManuallyDrop<CAnyPtr>) {
    let _ = ManuallyDrop::into_inner(ptr);
}
