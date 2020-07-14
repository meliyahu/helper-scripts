#!/bin/bash
cat cf-pw.enc | openssl rsautl -decrypt -inkey /Users/mosheh/.ssh/id_rsa_mosheh

