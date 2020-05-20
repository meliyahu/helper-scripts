#!/bin/bash
cat cf-creds.txt.enc | openssl rsautl -decrypt -inkey /Users/mosheh/.ssh/id_rsa_mosheh

