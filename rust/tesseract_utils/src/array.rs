use super::error::CError;
use super::ptr::SyncPtr;
use super::result::CResult;
use super::traits::{TryAsRef, QuickClone};
use std::collections::{BTreeMap, HashMap};
use std::mem::ManuallyDrop;

#[repr(C)]
pub struct CArray<Value> {
    ptr: SyncPtr<Value>,
    len: usize,
}

// impl<Value> CArray<Value> {
//     unsafe fn _owned(&mut self) -> Vec<Value> {
//         let vec = Vec::from_raw_parts(self.ptr as *mut Value, self.len, self.len);
//         self.ptr = std::ptr::null();
//         self.len = 0;
//         vec
//     }
// }

impl<Value: Clone> Clone for CArray<Value> {
    fn clone(&self) -> Self {
        let vec: Vec<Value> = self.try_as_ref().unwrap().iter().map(|v| v.clone()).collect();
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

impl<Value> TryAsRef<[Value]> for CArray<Value> {
    type Error = CError;

    fn try_as_ref(&self) -> Result<&[Value], Self::Error> {
        if self.ptr.is_null() {
            Err(CError::NullPtr)
        } else {
            unsafe { Ok(std::slice::from_raw_parts(self.ptr.ptr(), self.len)) }
        }
    }
}

impl<'a, Value> TryFrom<&'a CArray<Value>> for &'a [Value] {
    type Error = CError;

    fn try_from(value: &'a CArray<Value>) -> Result<Self, Self::Error> {
        value.try_as_ref()
    }
}

impl<Value> TryFrom<CArray<Value>> for Vec<Value> {
    type Error = CError;

    fn try_from(value: CArray<Value>) -> Result<Self, Self::Error> {
        if value.ptr.is_null() {
            Err(CError::NullPtr)
        } else {
            let value = ManuallyDrop::new(value); // This is safe. Memory will be owned by Vec
            unsafe { Ok(Vec::from_raw_parts(value.ptr.ptr() as *mut Value, value.len, value.len)) }
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

#[repr(C)]
#[derive(Copy, Clone)]
pub struct CKeyValue<K, V> {
    pub key: K,
    pub val: V,
}

impl<K, V> From<(K, V)> for CKeyValue<K, V> {
    fn from(tuple: (K, V)) -> Self {
        Self {
            key: tuple.0,
            val: tuple.1,
        }
    }
}

impl<K, V> From<CKeyValue<K, V>> for (K, V) {
    fn from(kv: CKeyValue<K, V>) -> Self {
        (kv.key, kv.val)
    }
}

pub trait AsHashMap {
    type Key: std::hash::Hash + Eq + Clone;
    type Value: Clone;

    unsafe fn as_hash_map(&self) -> CResult<HashMap<Self::Key, Self::Value>>;
}

pub trait AsBTreeMap {
    type Key: Ord;
    type Value;

    unsafe fn as_btree_map(&self) -> CResult<BTreeMap<Self::Key, Self::Value>>;
}

impl<K: Ord + Clone, V: Clone> AsBTreeMap for CArray<CKeyValue<K, V>> {
    type Key = K;
    type Value = V;

    unsafe fn as_btree_map(&self) -> CResult<BTreeMap<K, V>> {
        self.try_as_ref()
            .map(|sl| sl.into_iter().cloned().map(|kv| kv.into()).collect())
    }
}

impl<K: std::hash::Hash + Eq + Clone, V: Clone> AsHashMap for CArray<CKeyValue<K, V>> {
    type Key = K;
    type Value = V;

    unsafe fn as_hash_map(&self) -> CResult<HashMap<K, V>> {
        self.try_as_ref()
            .map(|sl| sl.into_iter().cloned().map(|kv| kv.into()).collect())
    }
}

impl<K1, K2, V1, V2> From<BTreeMap<K2, V2>> for CArray<CKeyValue<K1, V1>>
where
    K2: Into<K1>,
    V2: Into<V1>,
{
    fn from(map: BTreeMap<K2, V2>) -> Self {
        let kvs: Vec<CKeyValue<K1, V1>> = map
            .into_iter()
            .map(|(k, v)| (k.into(), v.into()).into())
            .collect();
        let mut kvs = ManuallyDrop::new(kvs.into_boxed_slice());
        Self {
            ptr: kvs.as_mut_ptr().into(),
            len: kvs.len(),
        }
    }
}

impl<K1, K2, V1, V2> From<HashMap<K2, V2>> for CArray<CKeyValue<K1, V1>>
where
    K2: Into<K1>,
    V2: Into<V1>,
{
    fn from(map: HashMap<K2, V2>) -> Self {
        let kvs: Vec<CKeyValue<K1, V1>> = map
            .into_iter()
            .map(|(k, v)| (k.into(), v.into()).into())
            .collect();
        let mut kvs = ManuallyDrop::new(kvs.into_boxed_slice());
        Self {
            ptr: kvs.as_mut_ptr().into(),
            len: kvs.len(),
        }
    }
}
