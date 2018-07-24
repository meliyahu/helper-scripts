#!/bin/bash
cat eem-db-creds.txt.enc | openssl rsautl -decrypt -inkey /Users/a1611590/.ssh/id_rsa_mosheh
