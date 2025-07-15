#!/bin/bash
PRIVATE_KEY=$(wg genkey)
echo "{\"privateKey\":\"$PRIVATE_KEY\"}"
