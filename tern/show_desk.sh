#!/bin/bash
cat tern-service-desk-credentials.txt.enc | openssl rsautl -decrypt -inkey /Users/a1611590/.ssh/id_rsa_mosheh
