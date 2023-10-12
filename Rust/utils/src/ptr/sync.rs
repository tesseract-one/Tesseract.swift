use crate::Void;

#[repr(transparent)]
#[derive(Debug)]
pub struct SyncPtr<T>(*const T);

impl<T> SyncPtr<T> {
    pub fn new(val: T) -> Self {
        Box::new(val).into()
    }

    pub fn raw(ptr: *const T) -> Self {
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

    pub fn as_void(self) -> SyncPtr<Void> {
        SyncPtr(self.0 as *const Void)
    }

    pub unsafe fn as_ref(&self) -> Option<&T> {
        self.0.as_ref()
    }

    pub unsafe fn as_mut(&mut self) -> Option<&mut T> {
        (self.0 as *mut T).as_mut()
    }

    pub unsafe fn take(&mut self) -> T {
        let bx = Box::from_raw(self.0 as *mut T);
        self.0 = std::ptr::null();
        *bx
    }
}

impl SyncPtr<Void> {
    pub fn as_type<N>(self) -> SyncPtr<N> {
        SyncPtr(self.0 as *const N)
    }

    pub unsafe fn as_typed_ref<N>(&self) -> Option<&N> {
        (self.0 as *const N).as_ref()
    }

    pub unsafe fn as_typed_mut<N>(&mut self) -> Option<&mut N> {
        (self.0 as *mut N).as_mut()
    }

    pub unsafe fn take_typed<N>(&mut self) -> N {
        let bx = Box::from_raw(self.0 as *mut N);
        self.0 = std::ptr::null();
        *bx
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

impl<T> From<&mut SyncPtr<T>> for *mut T {
    fn from(ptr: &mut SyncPtr<T>) -> Self {
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
