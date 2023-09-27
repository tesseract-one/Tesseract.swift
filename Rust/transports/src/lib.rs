extern crate async_trait;
extern crate tesseract;
extern crate tesseract_swift_utils;

#[cfg(feature = "client")]
pub mod client;

#[cfg(feature = "service")]
pub mod service;

pub mod error;