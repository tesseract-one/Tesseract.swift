extern crate cbindgen;

use std::env;
use std::path::Path;

fn main() {
    let crate_dir = env::var("CARGO_MANIFEST_DIR").unwrap();
    let profile = env::var("PROFILE").unwrap();
    let name = env::var("CARGO_PKG_NAME").unwrap();
    let header_path = Path::new(&crate_dir)
        .join("..")
        .join("..")
        .join("target")
        .join(&profile)
        .join("include")
        .join(format!("{}.h", name));

    cbindgen::generate(&crate_dir)
        .expect("Unable to generate bindings")
        .write_to_file(&header_path);
}
