use super::error::CError;
use super::ptr::SyncPtr;
use super::result::Result;
use super::traits::{QuickClone, TryAsRef, AsCRef};
use std::borrow::Borrow;
use std::mem::ManuallyDrop;

#[repr(C)]
#[derive(Debug)]
pub struct CArrayRef<'a, Value> {
    pub ptr: SyncPtr<Value>,
    pub len: usize,
    _lifecycle: std::marker::PhantomData<&'a Value>
}

impl<'a, Value> CArrayRef<'a, Value> {
    pub fn cloned(&self) -> Result<Vec<Value>> where Value: Clone {
        Ok(self.try_as_ref()?.iter().map(|v| v.clone()).collect())
    }

    pub fn quick_cloned(&self) -> Result<Vec<Value>> where Value: Copy {
        Ok(self.try_as_ref()?.to_owned())
    } 
}

impl<'a, Value> TryAsRef<[Value]> for CArrayRef<'a, Value> {
    type Error = CError;

    fn try_as_ref(&self) -> std::result::Result<&'a [Value], Self::Error> {
        if self.ptr.is_null() {
            Err(CError::null::<Self>())
        } else {
            unsafe { Ok(std::slice::from_raw_parts(self.ptr.ptr(), self.len)) }
        }
    }
}

impl<'a, Value, T> From<T> for CArrayRef<'a, Value> where T: Borrow<[Value]> {
    fn from(value: T) -> Self {
        let bw: &[Value] = value.borrow();
        Self{ ptr: bw.as_ptr().into(), len: bw.len(), _lifecycle: std::marker::PhantomData } 
    }
}

#[repr(C)]
#[derive(Debug)]
pub struct CArray<Value> {
    pub ptr: SyncPtr<Value>,
    pub len: usize,
}

impl<Value: Clone> Clone for CArray<Value> {
    fn clone(&self) -> Self {
        let vec: Vec<Value> = self
            .try_as_ref()
            .unwrap()
            .iter()
            .map(|v| v.clone())
            .collect();
        vec.into()
    }
}

impl<Value: Copy> QuickClone for CArray<Value> {
    fn quick_clone(&self) -> Self {
        self.try_as_ref().unwrap().into()
    }
}

impl<Value> Drop for CArray<Value> {
    fn drop(&mut self) {
        let _ = unsafe { Vec::from_raw_parts(self.ptr.ptr() as *mut Value, self.len, self.len) };
        self.ptr = SyncPtr::null();
    }
}

impl<'a, V> AsCRef<CArrayRef<'a, V>> for CArray<V> {
    fn as_cref(&self) -> CArrayRef<'a, V> {
        CArrayRef { ptr: self.ptr.ptr().into(), len: self.len, _lifecycle: std::marker::PhantomData }
    }
}

impl<Value> TryAsRef<[Value]> for CArray<Value> {
    type Error = CError;

    fn try_as_ref(&self) -> Result<&[Value]> {
        if self.ptr.is_null() {
            Err(CError::null::<Self>())
        } else {
            unsafe { Ok(std::slice::from_raw_parts(self.ptr.ptr(), self.len)) }
        }
    }
}

impl<'a, Value> TryFrom<&'a CArray<Value>> for &'a [Value] {
    type Error = CError;

    fn try_from(value: &'a CArray<Value>) -> Result<Self> {
        value.try_as_ref()
    }
}

impl<Value> TryFrom<CArray<Value>> for Vec<Value> {
    type Error = CError;

    fn try_from(value: CArray<Value>) -> Result<Self> {
        if value.ptr.is_null() {
            Err(CError::null::<CArray<Value>>())
        } else {
            let value = ManuallyDrop::new(value); // This is safe. Memory will be owned by Vec
            unsafe {
                Ok(Vec::from_raw_parts(
                    value.ptr.ptr() as *mut Value,
                    value.len,
                    value.len,
                ))
            }
        }
    }
}

impl<V1, V2: Into<V1> + Clone> From<&[V2]> for CArray<V1> {
    fn from(array: &[V2]) -> Self {
        Vec::from(array).into()
    }
}

impl<V1, V2: Into<V1>> From<Vec<V2>> for CArray<V1> {
    fn from(array: Vec<V2>) -> Self {
        let mapped: Vec<V1> = array.into_iter().map(|v| v.into()).collect();
        let mut mapped = ManuallyDrop::new(mapped.into_boxed_slice());
        Self {
            ptr: mapped.as_mut_ptr().into(),
            len: mapped.len(),
        }
    }
}
