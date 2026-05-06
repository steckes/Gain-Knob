fn main() {
    println!("cargo:rerun-if-changed=src/gui");
    slint_build::compile("src/gui/ui.slint").unwrap();
}
