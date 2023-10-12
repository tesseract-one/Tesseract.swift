#![feature(return_position_impl_trait_in_trait)]
#![feature(async_closure)]

pub mod array;
pub mod data;
pub mod error;
pub mod future;
pub mod future_impls;
pub mod int128;
pub mod option;
pub mod panic;
pub mod ptr;
pub mod response;
pub mod result;
pub mod string;
pub mod traits;
pub mod map;

#[cfg(feature = "bigint")]
extern crate num_bigint;
#[cfg(feature = "bigint")]
pub mod bigint;

#[repr(C)]
#[derive(Debug, Clone, Copy, Default)]
pub struct Nothing(bool);

pub type Void = std::ffi::c_void;
