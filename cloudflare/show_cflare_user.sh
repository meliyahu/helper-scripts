#!/bin/bash
cat cf-creds.txt.enc | openssl rsautl -decrypt -inkey /Users/a1611590/.ssh/id_rsa_mosheh

