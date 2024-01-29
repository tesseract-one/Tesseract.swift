#![feature(async_closure)]

pub mod delegate;

use delegate::{AlertProvider, TransportDelegate};
use stderrlog::LogLevelNum;
use tesseract_one::client::Tesseract;
use errorcon::convertible::ErrorContext;

use tesseract_protocol_test::TestService;
use tesseract_swift::error::TesseractSwiftError;
use tesseract_swift::client::transport::ClientTransport;
use tesseract_swift::utils::{
    future_impls::CFutureString, response::CMoveResponse, string::CStringRef,
    traits::TryAsRef, ptr::SyncPtr, error::CError, Void
};

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
    service: Arc<dyn tesseract_one::client::Service<Protocol = tesseract_protocol_test::Test>>,
}

#[no_mangle]
pub unsafe extern "C" fn app_init(
    alerts: AlertProvider, transport: ClientTransport,
    value: &mut ManuallyDrop<AppContextPtr>, error: &mut ManuallyDrop<CError>
) -> bool {
    let log_level = if cfg!(debug_assertions) { LogLevelNum::Debug } else { LogLevelNum::Warn };
    TesseractSwiftError::context(|| {
        stderrlog::new().verbosity(log_level).show_module_names(true).init()?;
        log_panics::init();

        let tesseract = Tesseract::new(TransportDelegate::arc(alerts))
                .transport(transport);

        let service = tesseract.service(tesseract_protocol_test::Test::Protocol);

        let context = AppContext { service };

        Ok(AppContextPtr::new(context))
    }).response(value, error)
}

#[no_mangle]
pub unsafe extern "C" fn app_sign_data(
    app: AppContextPtr,
    data: CStringRef,
) -> ManuallyDrop<CFutureString> {
    let service = Arc::clone(&app.unowned().service);
    let data_str: Result<String, CError> = data.try_as_ref().map(|s| s.into());

    let tx = TesseractSwiftError::context_async(async || {
        Ok(service.sign_transaction(&data_str?).await?.into())
    });

    ManuallyDrop::new(tx.into())
}

#[no_mangle]
pub unsafe extern "C" fn app_deinit(app: &mut AppContextPtr) {
    let _ = app.owned();
}
