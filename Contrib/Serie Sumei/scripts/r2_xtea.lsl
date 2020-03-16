// r2_xtea.lsl - xtea MessageLinked wrapper
// SPDX-License-Identifier: CC-BY-3.0
// Modifications Copyright 2019 Serie Sumei

// v1 - Initial release

// This is a small wrapper around an XTEA implementation from the
// Second Life wiki: http://wiki.secondlife.com/wiki/XTEA_Strong_Encryption_Implementation
// in the 'LSL - PHP' section.
//
// This wrapper responds to LSL link_message events, using the second integer
// argument as a command to select encrypt or decrypt processing. Any scripts
// communicating with it must be in the same prim.

// Encrypting
// Send a link message to LINK_THIS and a command as the second argument:
//
//   llMessageLinked(LINK_THIS, XTEAENCRYPT, llList2CSV(["ALPHA", "feet", -1, 0.0]), "");
//
// The ciphertext will be sent back in a link message using XTEAENCRYPTED
// as the second argument.
//
// If the fourth argument is not "" or "0" in llMessageLinked() rather than
// returning the ciphertext in a link message it is sent via llRegionSay()
// using the fourth argument as the channel.

// Decrypting
// Send a link message to LINK_THIS and a command as the second argument:
//
//   llMessageLinked(LINK_THIS, XTEADECRYPT, ciphertext, "");
//
// The cleartext will be sent back in a link message using XTEADECRYPTED
// as the second argument.

// Fred Beckhusen proposed using this for Ruth 2.0 and his version is at
// https://github.com/RuthAndRoth/Ruth2/blob/master/Contrib/Fred%20Beckhusen/XTEA.lsl
// I created this version because I could not find exactly the source Fred
// used. These are similar but not identical.  I have not perf tested them
// against each other but the size of messages we are dealing with here put
// any differences close to meaningless.
//
// Fred's script reads the key from a notecard, I have chosen to simply make
// it a constant below.  This requires the script to be distributed in
// products no-modify.  The licensing of both versions allow this, the XTEA in
// Fred's version is BSD, the original version of this one is public domain
// per the code headers and all modifications are CC-BY-3.0.

// This is the shared secret that is required at both ends to communicate
// CHANGE THIS if you need any security at all
string SECRET = "OhMyDarlingOhMyDarlingOhMyDarlingClementine";

// Use these constants to control the behaviour of this wrapper

// Set to encrypt 'message' and re-send on channel 'id'
integer XTEAENCRYPT = 13475896;

// Set in the reply to a received XTEAENCRYPT if the passed channel is 0 or ""
integer XTEAENCRYPTED = 8303877;

// Set to decrypt 'message' and reply vi llMessageLinked()
integer XTEADECRYPT = 4690862;

// Set in the reply to a received XTEADECRYPT
integer XTEADECRYPTED = 3450924;

// We don't need the entire 64KB memory space, try to be a good neighbor
integer MEM_LIMIT = 20000;

// ---------- Begin XTEA Lib ----------
//************************************************//
//* Masa's XTEA encryption/decryption v3         *//
//* Modified by SleightOf Hand for Stability and *//
//* intercommunication with PHP version          *//
//************************************************//
// NOTE: This version only encodes 60 bits per 64-bit block!
// This code is public domain.
// Sleight was here 20070522
// masa was here 20070315
// so was strife 20070315
// so was adz 20070812
//
// This was Modified by SleightOf Hand to allow
// Strong encryption between LSL and PHP.
//************************************************//
//* XTEA IMPLEMENTATION                          *//
//************************************************//

integer XTEA_DELTA      = 0x9E3779B9; // (sqrt(5) - 1) * 2^31
integer xtea_num_rounds = 6;
list    xtea_key        = [0, 0, 0, 0];


// Converts any string to a 32 char MD5 string and then to a list of
// 4 * 32 bit integers = 128 bit Key. MD5 ensures always a specific
// 128 bit key is generated for any string passed.
list xtea_key_from_string( string str )
{
    str = llMD5String(str,0); // Use Nonce = 0
    return [    hexdec(llGetSubString(  str,  0,  7)),
                hexdec(llGetSubString(  str,  8,  15)),
                hexdec(llGetSubString(  str,  16,  23)),
                hexdec(llGetSubString(  str,  24,  31))];
}

// Encipher two integers and return the result as a 12-byte string
// containing two base64-encoded integers.
string xtea_encipher( integer v0, integer v1 )
{
    integer num_rounds = xtea_num_rounds;
    integer sum = 0;
    do {
        // LSL does not have unsigned integers, so when shifting right we
        // have to mask out sign-extension bits.
        v0  += (((v1 << 4) ^ ((v1 >> 5) & 0x07FFFFFF)) + v1) ^ (sum + llList2Integer(xtea_key, sum & 3));
        sum +=  XTEA_DELTA;
        v1  += (((v0 << 4) ^ ((v0 >> 5) & 0x07FFFFFF)) + v0) ^ (sum + llList2Integer(xtea_key, (sum >> 11) & 3));

    } while( --num_rounds );
    //return only first 6 chars to remove "=="'s and compact encrypted text.
    return llGetSubString(llIntegerToBase64(v0),0,5) +
           llGetSubString(llIntegerToBase64(v1),0,5);
}

// Decipher two base64-encoded integers and return the FIRST 30 BITS of
// each as one 10-byte base64-encoded string.
string xtea_decipher( integer v0, integer v1 )
{
    integer num_rounds = xtea_num_rounds;
    integer sum = XTEA_DELTA*xtea_num_rounds;
    do {
        // LSL does not have unsigned integers, so when shifting right we
        // have to mask out sign-extension bits.
        v1  -= (((v0 << 4) ^ ((v0 >> 5) & 0x07FFFFFF)) + v0) ^ (sum + llList2Integer(xtea_key, (sum>>11) & 3));
        sum -= XTEA_DELTA;
        v0  -= (((v1 << 4) ^ ((v1 >> 5) & 0x07FFFFFF)) + v1) ^ (sum + llList2Integer(xtea_key, sum  & 3));
    } while ( --num_rounds );

    return llGetSubString(llIntegerToBase64(v0), 0, 4) +
           llGetSubString(llIntegerToBase64(v1), 0, 4);
}

// Encrypt a full string using XTEA.
string xtea_encrypt_string( string str )
{
    // encode string
    str = llStringToBase64(str);
    // remove trailing =s so we can do our own 0 padding
    integer i = llSubStringIndex( str, "=" );
    if ( i != -1 )
        str = llDeleteSubString( str, i, -1 );

    // we don't want to process padding, so get length before adding it
    integer len = llStringLength(str);

    // zero pad
    str += "AAAAAAAAAA=";

    string result;
    i = 0;

    do {
        // encipher 30 (5*6) bits at a time.
        result += xtea_encipher(
            llBase64ToInteger(llGetSubString(str,   i, i += 4) + "A="),
            llBase64ToInteger(llGetSubString(str, ++i, i += 4) + "A=")
        );
    } while ( ++i < len );

    return result;
}

// Decrypt a full string using XTEA
string xtea_decrypt_string( string str ) {
    integer len = llStringLength(str);
    integer i;
    string result;
    do {
        result += xtea_decipher(
            llBase64ToInteger(llGetSubString(str,   i, i += 5) + "=="),
            llBase64ToInteger(llGetSubString(str, ++i, i += 5) + "==")
        );
    } while ( ++i < len );

    // Replace multiple trailing zeroes with a single one
    i = llStringLength(result) - 1;
    while ( llGetSubString(result, --i, i+1) == "AA" )
        result = llDeleteSubString(result, i+1, i+1);
    return llBase64ToString( result + "====" );
}
// ---------- End XTEA Lib ----------

// The following code is based on Fred's wrapper and is licensed
// as CC-BY-3.0.

integer hexdec(string hex) {
    if(llGetSubString(hex,0,1) == "0x")
        return (integer)hex;
    if(llGetSubString(hex,0,0) == "x")
        return (integer)("0"+hex);
    return(integer)("0x"+hex);
}

default {
    state_entry() {
        llSetMemoryLimit(MEM_LIMIT);

        // Generate the required XTEA key from a seed string
        // CHANGE THIS at the top of this file if you require any actual security.
        xtea_key = xtea_key_from_string(SECRET);

        llOwnerSay("r2_xtea: Free memory: " + (string)llGetFreeMemory() + "  Limit: " + (string)MEM_LIMIT);
    }

    link_message(integer sender_number, integer number, string message, key id) {
        if (number == XTEAENCRYPT) {
            // Encrypt message

            // Can't cast a key directly to integer?
            string channel = (string)id;
            if (channel == "" || (integer)channel == 0) {
                // Rather than speak on a channel, return the ciphertext via llMessageLinked
                llMessageLinked(LINK_THIS, XTEAENCRYPTED, xtea_encrypt_string(message), "");
            } else {
                // Say the ciphertext on channel passed in id
                llRegionSay((integer)channel, xtea_encrypt_string(message));
            }
        }
        else if (number == XTEADECRYPT) {
            // Decrypt message

            // Return the cleartext via llMessageLinked
            llMessageLinked(LINK_THIS, XTEADECRYPTED, xtea_decrypt_string(message), "");
        }
    }

    changed(integer change) {
        if (change & (CHANGED_OWNER | CHANGED_INVENTORY)) {
            llResetScript();
        }
    }
}
