#![feature(async_closure)]

use async_trait::async_trait;
use errorcon::convertible::ErrorContext;
use stderrlog::LogLevelNum;
use tesseract_swift::error::TesseractSwiftError;
use std::mem::ManuallyDrop;
use std::sync::Arc;
use tesseract_one::service::Tesseract;
use tesseract_swift::service::transport::ServiceTransport;
use tesseract_swift::utils::{
    error::CError, future_impls::CFutureBool, ptr::{CAnyDropPtr, SyncPtr},
    response::CMoveResponse, string::{CString, CStringRef}, traits::{TryAsRef, AsCRef},
    Void
};

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

impl tesseract_one::service::Service for TestService {
    type Protocol = tesseract_protocol_test::Test;

    fn protocol(&self) -> &tesseract_protocol_test::Test {
        &tesseract_protocol_test::Test::Protocol
    }

    fn to_executor(self) -> Box<dyn tesseract_one::service::Executor + Send + Sync> {
        Box::new(tesseract_protocol_test::service::TestExecutor::from_service(self))
    }
}

#[async_trait]
impl tesseract_protocol_test::TestService for TestService {
    async fn sign_transaction(self: Arc<Self>, req: &str) -> tesseract_one::Result<String> {
        let cstr: CString = req.into();
        let future = unsafe {
            ManuallyDrop::into_inner((self.ui.approve_tx)(&self.ui, cstr.as_cref()))
        };
        TesseractSwiftError::context_async(async || {
            let allow = future.try_into_future()?.await?;

            if allow {
                if req == "make_error" {
                    Err(tesseract_one::Error::described(tesseract_one::ErrorKind::Weird, "intentional error for test").into())
                } else {
                    Ok(format!("{}{}", req, self.signature))
                }
            } else {
                Err(tesseract_one::Error::kinded(tesseract_one::ErrorKind::Cancelled).into())
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
    value: &mut ManuallyDrop<AppContextPtr>, error: &mut ManuallyDrop<CError>
) -> bool {
    let log_level = if cfg!(debug_assertions) {LogLevelNum::Debug } else { LogLevelNum::Warn };
    TesseractSwiftError::context(|| {
        init::init(log_level)?;

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
