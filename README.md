# Password Manager

This will be an App for storing passwords securely in a single database file.

A user password (entered by the user) will be associated with the database file to unlock it along with a salt string stored in the software settings.

The AES encryption algorithm will be used in CBC (Cipher Block Chaining) mode to encrypt the saved data.

A SHA256 hash of the combined password and salt is saved with the encrypted database, and an IV vector.

## Features

* Suggest easy to remember but hard to crack passwords
* Analyze password strength using the zxcvbn methods
* Store name, password, URL, creation date, last update date, notes
* Search
* List in order of usage frequency
* List in order of updated passwords
* Categories
* Feature to create a copy of the file with incremented index value
* Generate password salt value for each install and allow for display/modification of it
* Import data from Keepass2 database

## Reference Links

[AES Encryption Modes](https://www.highgo.ca/2019/08/08/the-difference-in-five-modes-in-the-aes-encryption-algorithm/)

[KeePass Database Decryption](https://weekly-geekly.imtqy.com/articles/346820/index.html)

[zxcvbn on GitHub](https://github.com/dropbox/zxcvbn)

## Testing

Unit testing is implemented with the GUT framework which may be installed from the Godot Asset Library in the Editor.

The directory for the tests should be set to `res://test`
