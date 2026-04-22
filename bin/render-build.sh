#!/usr/bin/env bash
set -o errexit

bundle config set --local deployment 'true'
bundle config set --local without 'development test'
bundle install
