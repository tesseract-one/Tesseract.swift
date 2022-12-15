use crate::Void;

#[repr(transparent)]
pub struct SyncPtr<T>(*const T);

impl<T> SyncPtr<T> {
    pub fn new(ptr: *const T) -> Self {
        Self(ptr)
    }

    pub fn null() -> Self {
        Self(std::ptr::null())
    }

    pub fn ptr(&self) -> *const T {
        self.0
    }

    pub fn is_null(&self) -> bool {
        self.0.is_null()
    }

    pub fn as_ptr_ref<N>(&self) -> &SyncPtr<N> {
        unsafe { &*(self as *const SyncPtr<T> as *const SyncPtr<N>) }
    }

    pub unsafe fn into_box(self) -> Box<T> {
        Box::from_raw(self.0 as *mut T)
    }
}

impl<T> AsRef<T> for SyncPtr<T> {
    fn as_ref(&self) -> &T {
        unsafe { self.0.as_ref().unwrap() }
    }
}

pub trait SyncPtrAsVoid: Sized {
    fn as_void(self) -> SyncPtr<Void>;
}

pub trait SyncPtrRefAsVoid {
    fn as_void(&self) -> &SyncPtr<Void>;
}

pub trait SyncPtrAsType: Sized {
    fn as_type<T>(self) -> SyncPtr<T>;
}

pub trait SyncPtrRefAsType {
    fn as_type<T>(&self) -> &SyncPtr<T>;
}

impl<T> SyncPtrAsVoid for SyncPtr<T> {
    fn as_void(self) -> SyncPtr<Void> {
        SyncPtr(self.0 as *const Void)
    }
}

impl<T> SyncPtrRefAsVoid for &SyncPtr<T> {
    fn as_void(&self) -> &SyncPtr<Void> {
        unsafe { &*(*self as *const SyncPtr<T> as *const SyncPtr<Void>) }
    }
}

impl SyncPtrAsType for SyncPtr<Void> {
    fn as_type<T>(self) -> SyncPtr<T> {
        SyncPtr(self.0 as *const T)
    }
}

impl SyncPtrRefAsType for &SyncPtr<Void> {
    fn as_type<T>(&self) -> &SyncPtr<T> {
        unsafe { &*(*self as *const SyncPtr<Void> as *const SyncPtr<T>) }
    }
}

unsafe impl<T: Send> Send for SyncPtr<T> {}
unsafe impl<T: Sync> Sync for SyncPtr<T> {}

impl<T> From<*const T> for SyncPtr<T> {
    fn from(ptr: *const T) -> Self {
        Self(ptr)
    }
}

impl<T> From<&SyncPtr<T>> for *const T {
    fn from(ptr: &SyncPtr<T>) -> Self {
        ptr.0
    }
}

impl<T> From<SyncPtr<T>> for *const T {
    fn from(ptr: SyncPtr<T>) -> Self {
        ptr.0
    }
}

impl<T> From<*mut T> for SyncPtr<T> {
    fn from(ptr: *mut T) -> Self {
        Self(ptr as *const T)
    }
}

impl<T> From<&SyncPtr<T>> for *mut T {
    fn from(ptr: &SyncPtr<T>) -> Self {
        ptr.0 as *mut T
    }
}

impl<T> From<SyncPtr<T>> for *mut T {
    fn from(ptr: SyncPtr<T>) -> Self {
        ptr.0 as *mut T
    }
}

impl<T> From<Box<T>> for SyncPtr<T> {
    fn from(bx: Box<T>) -> Self {
        Box::into_raw(bx).into()
    }
}
