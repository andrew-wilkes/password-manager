# Data Encryption

To encrypt our raw data we will make use of AES encryption that is available in Godot. This allows us to encode and decode our data easily and quickly.

AES encryption is used by U.S. for securing sensitive but unclassified material.

We will use AES encryption in two stages using both of the available modes.

## Stage 1 - CBC Mode

This mode uses a key plus initial vector and encodes chunks of data such that cracking one chunk doesn't help to crack the other chunks.

This gives us an array of bytes that represent our encrypted data.

But, our salted password/key may be cracked by brute force as determined by getting data in a recognizable format. So our next trick is to make the data not be recognizable by encrypting it a second time in stage 2.

## Stage 2 - EBC Mode

This mode only needs a key, and we will use our password salt value for the key. We don't aim to be super secure in this stage, just scramble the data.

So now we have our encrypted data ready to save to a file.

## Decrypting the data

This is a simple process of reversing what we did to encrypt the data. ECB followed by CBC using our salt (stored on the device) and password (entered by the user).
