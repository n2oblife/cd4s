#!/usr/bin/env python3

"""
KAT implementation for NIST (based on TestVectorGen.zip)
"""

import ascon
import sys
from writer import MultipleWriter



def kat_aead(variant):
    MESSAGE_LENGTH = 48 #Bytes
    ASSOCIATED_DATA_LENGTH = 31 #Bytes

    klen = 16
    nlen = 16
    tlen = 16
    filename = "testvector1"
    assert variant in ["Ascon-AEAD128"]

    key   = bytearray.fromhex("2e45359eff1340ab04b32a1d09bd7f3b")
    nonce = bytearray.fromhex("ea9432a05bf1e53c853086621be55680")
    msg   = bytearray.fromhex("43 6F 6E 67 72 61 74 75 6C 61 74 69 6F 6E 73 2C 20 79 6F 75 20 64 65 63 72 79 70 74 65 64 20 74 68 69 73 20 74 65 73 74 20 74 65 78 74 21 00 00")
    ad    = bytearray.fromhex("54 68 69 73 20 74 65 78 74 20 69 73 20 61 73 73 6F 63 69 61 74 65 64 20 64 61 74 61 2E 00 00 00")
    with MultipleWriter(filename) as w:
        count = 1
        mlen = MESSAGE_LENGTH
        adlen = ASSOCIATED_DATA_LENGTH
        w.open()
        w.append("Count", count)
        count += 1
        w.append("Key", key, klen)
        w.append("Nonce", nonce, nlen)
        w.append("PT", msg, mlen)
        w.append("AD", ad, adlen)
        ct = ascon.ascon_encrypt(key, nonce, ad[:adlen], msg[:mlen], variant)
        assert len(ct) == mlen + tlen
        w.append("CT", ct, len(ct))
        msg2 = ascon.ascon_decrypt(key, nonce, ad[:adlen], ct, variant)
        assert len(msg2) == mlen
        assert msg2 == msg[:mlen]
        w.close()


if __name__ == "__main__":
    variant = "Ascon-AEAD128"
    kat_aead(variant)
