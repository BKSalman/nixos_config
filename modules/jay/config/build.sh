#! /usr/bin/env bash

cargo b -r && cp target/release/libconfig.so ~/.config/jay/config.so
