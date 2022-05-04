# Password Manager

This will be an App for storing passwords securely in a single database file.

The UI will be very user-friendly, easy to use, and look nice.

A user password will be associated with the database file to unlock it.

The AES encryption algorithm will be used in CBC (Cipher Block Chaining) mode.

## Features

* Copy password to clipboard and clear the clipboard after a short time
* Suggest passwords
* Warn user if they enter a common password (maybe)
* Store name, password, URL, creation date, last update date, notes
* Search
* List in order of usage frequency
* List in order of updated passwords
* Categories
* Feature to create a copy of the file with incremented index value
* Attach a random IV value in clear text to each save of the data file (best practice)
* Generate password salt value for each install and allow for display/modification of it
* Import data from Keepass2 database

## Reference material

[AES Encryption Modes](https://www.highgo.ca/2019/08/08/the-difference-in-five-modes-in-the-aes-encryption-algorithm/)

[KeePass Database Decryption](https://weekly-geekly.imtqy.com/articles/346820/index.html)
