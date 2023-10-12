#![feature(return_position_impl_trait_in_trait)]
#![feature(async_closure)]

extern crate async_trait;
extern crate errorcon;
extern crate tesseract;
extern crate tesseract_swift_utils;

pub mod error;

#[cfg(feature = "client")]
pub mod client;

#[cfg(feature = "service")]
pub mod service;
