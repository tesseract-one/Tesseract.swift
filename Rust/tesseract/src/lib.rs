extern crate tesseract_swift_utils;
extern crate tesseract_swift_transports;

#[cfg(feature = "client")]
pub mod client;

#[cfg(feature = "service")]
pub mod service;

pub mod protocols;