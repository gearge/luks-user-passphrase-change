#!/usr/bin/env python

import uuid

def luks_security_key_generator(nth=4):
  uuid4 = uuid.uuid4()
  uuid4HexUpper = uuid4.hex.upper()
  return '-'.join([uuid4HexUpper[i:i+nth] for i in range(0, len(uuid4HexUpper), nth)])

if __name__ == "__main__":
  luksSecurityKey = luks_security_key_generator()
  print(luksSecurityKey)

