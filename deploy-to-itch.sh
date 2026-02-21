#!/bin/bash

# Zip the webexport contents
cd ../web
zip -r strange-places.zip .
cd ..

# Push to itch.io
butler push web/strange-places.zip ciph3rzer0/strange-places:web --userversion-file VERSION