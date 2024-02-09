use sha1::Digest;                   // imports module Digest from the sha1 library 
use std::{                          // imports from the standard library these modules:
    env,                            // used to access command line arguments
    error::Error,                   // used to handle errors
    fs::File,                       // used to open files
    io::{BufRead, BufReader},       // used to read files  
};               

                                                            // main function returns a Result type: Ok(()) or Err
const SHA1_HEX_STRING_LENGTH: usize = 40;                   // () = types associated with Ok - Box<dyn Error> = types associated with Err
                                                            // Box allows you to have a heap pointer to an object that implements Error
fn main() -> Result<(), Box<dyn Error>> {                   // => allows you to return errors of different types without having to explicitly specify them  
    let args: Vec<String> = env::args().collect();          // nv::args() calls the args function and returns an iterator which can be “collected” into  a Vector of String
    if args.len() != 3 { 
        println!("Usage:");
        println!("sha1_cracker: <wordlist.txt> <sha1_hash> ");
        return Ok(());
    }

    let hash_to_crack = args[2].trim();                     // get hash to crack from command line arguments and remove spaces
    if hash_to_crack.len() != SHA1_HEX_STRING_LENGTH {
        return Err("sha1 hash is not valid".into());
    }

    let wordlist_file = File::open(&args[1])?;              // open file from command line arguments
    let reader = BufReader::new(&wordlist_file);            // create a buffer reader to read the file
    for line in reader.lines() {                            // iterate over each line in the file       
        let line = line?;                                   // read the line and handle any errors: '?' if there is an err => propagetes it to the caller => main
        let common_password = line.trim();
        if hash_to_crack == &hex::encode(sha1::Sha1::digest(common_password.as_bytes())){    // if the hash of the common password is equal to the hash to crack
            println!("Password found: {}", &common_password);                               // => print the common password
            return Ok(());
        }
    }
    println!("password not found in wordlist :(");

    Ok(())
}
