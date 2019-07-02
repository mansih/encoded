#!/bin/bash
demo="$1"
local_creds="~/.aws/.pg-aws"
cmd="scp -r $local_creds $demo:~/.pg-aws"
eval "$cmd"
