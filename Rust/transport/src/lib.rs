#![feature(async_closure)]

pub mod error;
pub mod protocol;
pub use tesseract_swift_utils as utils;

#[cfg(feature = "client")]
pub mod client;

#[cfg(feature = "service")]
pub mod service;

