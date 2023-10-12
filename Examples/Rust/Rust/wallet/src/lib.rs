#![feature(async_closure)]

extern crate async_trait;
extern crate errorcon;
extern crate tesseract;
extern crate tesseract_protocol_test;
extern crate tesseract_swift_transports;
extern crate tesseract_swift_utils;

use async_trait::async_trait;
use errorcon::convertible::ErrorContext;
use log::LogLevel;
use tesseract_swift_transports::error::CTesseractError;
use std::mem::ManuallyDrop;
use std::sync::Arc;
use tesseract::service::Tesseract;
use tesseract_swift_transports::service::ServiceTransport;
use tesseract_swift_utils::future_impls::CFutureBool;
use tesseract_swift_utils::ptr::{CAnyDropPtr, SyncPtr};
use tesseract_swift_utils::response::CMoveResponse;
use tesseract_swift_utils::string::{CString, CStringRef};
use tesseract_swift_utils::traits::{TryAsRef, AsCRef};
use tesseract_swift_utils::Void;

mod init;

#[repr(C)]
pub struct AppContextPtr(SyncPtr<Void>);

impl AppContextPtr {
    fn new(ctx: AppContext) -> Self {
        Self(SyncPtr::new(ctx).as_void())
    }

    unsafe fn owned(&mut self) -> AppContext {
        self.0.take_typed()
    }
}

#[repr(C)]
pub struct UI {
    ptr: CAnyDropPtr,
    approve_tx: unsafe extern "C" fn(this: &UI, tx: CStringRef) -> ManuallyDrop<CFutureBool>,
}

struct TestService {
    ui: UI,
    signature: String,
}

impl TestService {
    pub fn new(ui: UI, signature: String) -> Self {
        Self { ui, signature }
    }
}

impl tesseract::service::Service for TestService {
    type Protocol = tesseract_protocol_test::Test;

    fn protocol(&self) -> &tesseract_protocol_test::Test {
        &tesseract_protocol_test::Test::Protocol
    }

    fn to_executor(self) -> Box<dyn tesseract::service::Executor + Send + Sync> {
        Box::new(tesseract_protocol_test::service::TestExecutor::from_service(self))
    }
}

#[async_trait]
impl tesseract_protocol_test::TestService for TestService {
    async fn sign_transaction(self: Arc<Self>, req: &str) -> tesseract::Result<String> {
        let cstr: CString = req.into();
        let future = unsafe {
            ManuallyDrop::into_inner((self.ui.approve_tx)(&self.ui, cstr.as_cref()))
        };
        CTesseractError::context_async(async || {
            let allow = future.try_into_future()?.await?;

            if allow {
                if req == "make_error" {
                    Err(CTesseractError::Weird("intentional error for test".into()))
                } else {
                    Ok(format!("{}{}", req, self.signature))
                }
            } else {
                Err(CTesseractError::Cancelled)
            }
        }).await
    }
}

struct AppContext {
    _tesseract: Tesseract,
}

#[no_mangle]
pub unsafe extern "C" fn wallet_extension_init(
    signature: CStringRef, ui: UI, transport: ServiceTransport,
    value: &mut ManuallyDrop<AppContextPtr>, error: &mut ManuallyDrop<CTesseractError>
) -> bool {
    let log_level = if cfg!(debug_assertions) {LogLevel::Debug } else { LogLevel::Warn };
    init::init(log_level).and_then(|_| {
        let service = TestService::new(ui, signature.try_as_ref()?.into());

        let tesseract = Tesseract::new().transport(transport).service(service);

        let context = AppContext {
            _tesseract: tesseract,
        };

        Ok(AppContextPtr::new(context))
    }).response(value, error)
}

#[no_mangle]
pub unsafe extern "C" fn wallet_extension_deinit(app: &mut AppContextPtr) {
    let _ = app.owned();
}
