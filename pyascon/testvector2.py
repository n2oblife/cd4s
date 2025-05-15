#!/usr/bin/env python3

"""
KAT implementation for NIST (based on TestVectorGen.zip)
"""

import ascon
import sys
from writer import MultipleWriter



def kat_aead(variant):
    MESSAGE_LENGTH = 16 #Bytes
    ASSOCIATED_DATA_LENGTH = 0 #Bytes

    klen = 16
    nlen = 16
    tlen = 16
    filename = "testvector2"
    assert variant in ["Ascon-AEAD128"]

    key   = bytearray.fromhex("2e45359eff1340ab04b32a1d09bd7f3b")
    nonce = bytearray.fromhex("d10a9b3266cf29de94121a7eaa41e761")
    msg   = bytearray.fromhex("ba19938f2bde7733bf6b16fef6e99ae9")
    ad    = bytearray.fromhex("")
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
