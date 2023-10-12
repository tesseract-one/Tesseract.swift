use super::result::Result;
use super::array::CArray;
use super::traits::TryAsRef;
use std::mem::ManuallyDrop;
use std::collections::{BTreeMap, HashMap};

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

    unsafe fn as_hash_map(&self) -> Result<HashMap<Self::Key, Self::Value>>;
}

pub trait AsBTreeMap {
    type Key: Ord;
    type Value;

    unsafe fn as_btree_map(&self) -> Result<BTreeMap<Self::Key, Self::Value>>;
}

impl<K: Ord + Clone, V: Clone> AsBTreeMap for CArray<CKeyValue<K, V>> {
    type Key = K;
    type Value = V;

    unsafe fn as_btree_map(&self) -> Result<BTreeMap<K, V>> {
        self.try_as_ref()
            .map(|sl| sl.into_iter().cloned().map(|kv| kv.into()).collect())
    }
}

impl<K: std::hash::Hash + Eq + Clone, V: Clone> AsHashMap for CArray<CKeyValue<K, V>> {
    type Key = K;
    type Value = V;

    unsafe fn as_hash_map(&self) -> Result<HashMap<K, V>> {
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
