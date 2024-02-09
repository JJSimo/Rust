use std::env;
use std::path::PathBuf;

fn get_chrome_local_pass_path(){
    // Get the USERPROFILE environment variable
    let userprofile = env::var("USERPROFILE").unwrap_or_else(|_| String::from("."));

    // Construct the path
    let local_pass_path = PathBuf::from(format!(r"{}\AppData\Local\Google\Chrome\User Data\Local State", userprofile));

    // Normalize the path
    let normalized_path = local_pass_path.canonicalize().expect("Failed to canonicalize path");
}

fn main() {
    let local_pass_path = get_chrome_local_pass_path();
    println!("Path: {:?}", local_pass_path);
}
