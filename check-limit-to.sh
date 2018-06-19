#!/bin/bash
sed -n '/limit-to/p' `find . -name "*.transform"`
