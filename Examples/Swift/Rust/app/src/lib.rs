#![feature(async_closure)]

extern crate async_trait;
extern crate tesseract;
extern crate tesseract_protocol_test;
extern crate tesseract_swift_transports;
extern crate tesseract_swift_utils;
extern crate errorcon;

pub mod delegate;

use delegate::{AlertProvider, TransportDelegate};
use log::LogLevel;
use tesseract::client::Tesseract;
use errorcon::convertible::ErrorContext;

pub use tesseract_swift_transports::client::*;
use tesseract_protocol_test::TestService;
use tesseract_swift_transports::error::CTesseractError;
use tesseract_swift_utils::future_impls::CFutureString;
use tesseract_swift_utils::response::CMoveResponse;
use tesseract_swift_utils::string::CStringRef;
use tesseract_swift_utils::traits::TryAsRef;
use tesseract_swift_utils::ptr::SyncPtr;
use tesseract_swift_utils::error::CError;
pub use tesseract_swift_utils::*;

use std::mem::ManuallyDrop;
use std::sync::Arc;

#[repr(C)]
pub struct AppContextPtr(SyncPtr<Void>);

impl AppContextPtr {
    fn new(ctx: AppContext) -> Self {
        Self(SyncPtr::new(ctx).as_void())
    }

    unsafe fn unowned(&self) -> &AppContext {
        self.0.as_typed_ref().unwrap()
    }

    unsafe fn owned(&mut self) -> AppContext {
        self.0.take_typed()
    }
}

struct AppContext {
    service: Arc<dyn tesseract::client::Service<Protocol = tesseract_protocol_test::Test>>,
}

#[no_mangle]
pub unsafe extern "C" fn app_init(
    alerts: AlertProvider, transport: ClientTransport,
    value: &mut ManuallyDrop<AppContextPtr>, error: &mut ManuallyDrop<CTesseractError>
) -> bool {
    let log_level = if cfg!(debug_assertions) { LogLevel::Debug } else { LogLevel::Warn };
    stderrlog::new()
        .verbosity(log_level as usize)
        .module("DApp")
        .init()
        .map_err(|_| CTesseractError::Logger("logger init failed".into()))
        .map(|_| {
            log_panics::init();

            let tesseract = Tesseract::new(TransportDelegate::arc(alerts))
                .transport(transport);

            let service = tesseract.service(tesseract_protocol_test::Test::Protocol);

            let context = AppContext { service };

            AppContextPtr::new(context)
        }).response(value, error)
}

#[no_mangle]
pub unsafe extern "C" fn app_sign_data(
    app: AppContextPtr,
    data: CStringRef,
) -> ManuallyDrop<CFutureString> {
    let service = Arc::clone(&app.unowned().service);
    let data_str: Result<String, CError> = data.try_as_ref().map(|s| s.into());

    let tx = CTesseractError::context_async(async || {
        Ok(service.sign_transaction(&data_str?).await?.into())
    });

    ManuallyDrop::new(tx.into())
}

#[no_mangle]
pub unsafe extern "C" fn app_deinit(app: &mut AppContextPtr) {
    let _ = app.owned();
}
