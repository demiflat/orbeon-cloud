#!/bin/bash
cd /orbeon || exit;
npm install;
ant orbeon-dist;
